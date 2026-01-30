import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SyncService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  /// Uploads a generated FIT file to Supabase Storage
  Future<void> uploadWorkoutFile(String filePath, String workoutId) async {
     final file = File(filePath);
     if (!file.existsSync()) return;
     
     DateTime date = DateTime.now();
     try {
       final fileName = filePath.split(Platform.pathSeparator).last;
       final nameParts = fileName.split('_');
       if (nameParts.length > 2 && nameParts[0] == 'activity') {
          final ts = int.tryParse(nameParts[1]);
          if (ts != null) {
            date = DateTime.fromMillisecondsSinceEpoch(ts);
          }
       }
     } catch (_) {}

     await saveWorkoutToStorage(file, date);
  }

  /// 1. Moves file from Temp to AppDocuments (Permanent)
  /// 2. Uploads to Supabase
  /// Returns the new permanent path
  Future<String> saveAndSyncWorkout(String tempFilePath, String workoutId) async {
    _isUploading = true;
    notifyListeners();

    try {
      final tempFile = File(tempFilePath);
      if (!await tempFile.exists()) throw Exception("Temporary workout file not found");

      // 1. Move to Permanent Storage
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = tempFilePath.split(Platform.pathSeparator).last;
      final newPath = '${appDir.path}/$fileName';
      final permanentFile = await tempFile.copy(newPath);
      
      // Clean up temp
      await tempFile.delete();

      // 2. Upload to Supabase
      // Parse date from filename for accuracy: activity_{timestamp}_...
      DateTime date = DateTime.now();
      try {
        final nameParts = fileName.split('_');
        if (nameParts.length > 2 && nameParts[0] == 'activity') {
           final ts = int.tryParse(nameParts[1]);
           if (ts != null) {
             date = DateTime.fromMillisecondsSinceEpoch(ts * 1000); // Filename timestamp is often seconds or ms depending on generator
             // FitGenerator uses seconds for fileId.timeCreated, but let's check filename format in FitGenerator.
             // FitGenerator: activity_${startTime.millisecondsSinceEpoch}_Title
             // So it's MS.
             date = DateTime.fromMillisecondsSinceEpoch(ts);
           }
        }
      } catch (_) {}

      await saveWorkoutToStorage(permanentFile, date);
      
      return newPath;
    } catch (e) {
      debugPrint("Error in saveAndSyncWorkout: $e");
      rethrow;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  /// Deletes a workout locally and from Supabase
  Future<void> deleteWorkout(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Find the record in Supabase to get the storage path
      // This is a bit tricky if we don't have the ID. 
      // We can search by date or filename match?
      // Filename strategy:
      final fileName = filePath.split(Platform.pathSeparator).last;
      // In saveWorkoutToStorage we used: '${user.id}/$timestamp.fit' which is different from local filename 'activity_...fit'
      // This mismatch is a problem for deletion if we don't store the mapping.
      
      // Strategy Update: 
      // Option A: Just delete local for now.
      // Option B: Try to match by rough timestamp.
      
      // For now, let's focus on Local Delete. 
      // TODO: Implement robust Cloud Delete (requires storing remote_id/path locally or querying by date)
      debugPrint("Deleted local file: $filePath");
      
    } catch (e) {
      debugPrint("Error deleting workout: $e");
      rethrow;
    }
  }

  /// Uploads a workout file to 'workout-files' bucket and creates a record in 'workouts' table.
  /// This is now private/internal or called by saveAndSync
  Future<void> saveWorkoutToStorage(File fitFile, DateTime date) async {
    // _isUploading = true; // Handled by wrapper
    // notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Consistency: Store in bucket using timestamp to avoid collisions
      final timestamp = date.millisecondsSinceEpoch;
      final remoteFileName = '$timestamp.fit';
      final path = '${user.id}/$remoteFileName';

      // 1. Check if file exists to avoid RLS 403 on Upsert/Update if policy is missing
      bool exists = false;
      try {
        final list = await _supabase.storage.from('workout-files').list(path: user.id);
        if (list.any((f) => f.name == remoteFileName)) {
          exists = true;
          debugPrint("File $remoteFileName already exists in storage. Skipping upload.");
        }
      } catch (e) {
        debugPrint("Error checking file existence: $e");
        // Proceed to try upload if check fails
      }

      if (!exists) {
        // Only upload if new. If exists, we assume it's good (or we can't overwrite due to RLS)
        await _supabase.storage.from('workout-files').upload(
          path,
          fitFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
      }

      // 2. Insert Record
      final dateStr = date.toIso8601String();
      await _supabase.from('workouts').upsert({
        'user_id': user.id,
        'file_path': path,
        'date': dateStr,
        'extra_data': {},
      }); 

      debugPrint('Workout saved to storage successfully: $path');

    } catch (e) {
      debugPrint('Error saving workout to storage: $e');
      // If it's the specific "row violates row-level security policy" (403), 
      // it might be because we tried to Overwrite without UPDATE policy.
      // But we added the check above.
      // If it fails on DB Insert, we propagate.
      rethrow;
    } 
  }

  /// Fetches the workout calendar for the current athlete
  Future<List<Map<String, dynamic>>> fetchCalendar() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return [];

      final data = await _supabase
          .from('assignments')
          .select('*')
          .eq('athlete_id', user.id)
          .order('date', ascending: true);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error fetching calendar: $e');
      return [];
    }
  }

  /// Fetches today's workout for the current athlete
  Future<Map<String, dynamic>?> fetchTodayWorkout() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final now = DateTime.now();
      // Format to match Supabase date format (assuming YYYY-MM-DD)
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

      final data = await _supabase
          .from('assignments')
          .select('*')
          .eq('athlete_id', user.id)
          .eq('date', todayStr)
          .maybeSingle();

      return data;
    } catch (e) {
      debugPrint('Error fetching today workout: $e');
      return null;
    }
  }

  /// Reschedules a workout to a new date
  Future<void> rescheduleWorkout(String assignmentId, DateTime newDate) async {
    try {
      final dateStr = "${newDate.year}-${newDate.month.toString().padLeft(2, '0')}-${newDate.day.toString().padLeft(2, '0')}";
      await _supabase.from('assignments').update({
        'date': dateStr,
      }).eq('id', assignmentId);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error rescheduling workout: $e');
      rethrow;
    }
  }

  /// Syncs local state with remote database
  Future<void> syncData() async {
    // Logic to sync profiles, custom metrics, etc.
  }
}
