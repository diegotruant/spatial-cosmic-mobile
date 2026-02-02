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
  Future<String> saveAndSyncWorkout(String tempFilePath, String customName, {String? assignmentId}) async {
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
             // FitGenerator uses seconds for fileId.timeCreated, but let's check filename format in FitGenerator.
             // FitGenerator: activity_${startTime.millisecondsSinceEpoch}_Title
             // So it's MS.
             date = DateTime.fromMillisecondsSinceEpoch(ts);
           }
        }
      } catch (_) {}

      await saveWorkoutToStorage(permanentFile, date, assignmentId: assignmentId);
      
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
      
      // Filename strategy: extract timestamp from activity_{timestamp}_{title}.fit
      // Matches the storage path format used in saveWorkoutToStorage: ${user.id}/$timestamp.fit
      final parts = fileName.split('_');
      String? timestampStr;
      if (parts.length >= 2 && parts[0] == 'activity') {
        timestampStr = parts[1];
      }

      if (timestampStr != null) {
        final path = '${user.id}/$timestampStr.fit';
        
        // 1. Delete from storage bucket
        try {
          await _supabase.storage.from('workout-files').remove([path]);
          debugPrint("Cloud Delete: Removed $path from storage");
        } catch (e) {
          debugPrint("Cloud Delete Warning: Storage removal failed: $e");
        }

        // 2. Delete from 'workouts' table
        try {
          await _supabase.from('workouts').delete().eq('file_path', path);
          debugPrint("Cloud Delete: Removed record from workouts table");
        } catch (e) {
          debugPrint("Cloud Delete Warning: Table deletion failed: $e");
        }

        // 3. Mark corresponding assignment as PENDING (or delete?)
        // Deleting the assignment is more consistent if the user wants it GONE from history.
        try {
           await _supabase.from('assignments')
            .delete()
            .eq('status', 'COMPLETED')
            .filter('activity_data->>file_path', 'eq', path);
           debugPrint("Cloud Delete: Removed assignment record");
        } catch (e) {
           debugPrint("Cloud Delete Warning: Assignment deletion failed: $e");
        }
      }
      
      debugPrint("Deleted local file: $filePath");
      
    } catch (e) {
      debugPrint("Error deleting workout: $e");
      rethrow;
    }
  }

  /// Uploads a workout file to 'workout-files' bucket and creates a record in 'workouts' table.
  /// This is now private/internal or called by saveAndSync
  Future<void> saveWorkoutToStorage(File fitFile, DateTime date, {String? assignmentId}) async {
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
          debugPrint("File $remoteFileName already exists in storage. Checking for record.");
        }
      } catch (e) {
        debugPrint("Error checking file existence: $e");
        // Proceed to try upload if check fails
      }

      // 2. Upload if not exists
      if (!exists) {
        await _supabase.storage.from('workout-files').upload(path, fitFile);
        debugPrint("Cloud Sync: Uploaded $path");
      }

      // 3. Create or Update record in 'workouts' table
      await _supabase.from('workouts').upsert({
        'user_id': user.id,
        'file_path': path,
        'date': date.toIso8601String(),
        'extra_data': {
          'assignment_id': assignmentId,
          'local_filename': fitFile.path.split(Platform.pathSeparator).last,
        },
      });

      // 4. Update assignment status if linked
      if (assignmentId != null) {
        // We update the assignment to COMPLETED and store the activity reference
        await _supabase.from('assignments').update({
          'status': 'COMPLETED',
          'activity_data': {
            'file_path': path,
            'source': 'mobile_app',
            'completed_at': DateTime.now().toIso8601String(),
          }
        }).eq('id', assignmentId);
        debugPrint("Cloud Sync: Marked assignment $assignmentId as COMPLETED");
      }

      debugPrint('Workout saved to storage successfully: $path');

    } catch (e) {
      debugPrint('Error saving workout to storage: $e');
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
