import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class SyncService extends ChangeNotifier {
  SupabaseClient get _supabase => Supabase.instance.client;

  // ========================================
  // RETRY & OFFLINE QUEUE CONFIGURATION
  // ========================================
  static const int MAX_RETRIES = 3;
  static const Duration INITIAL_RETRY_DELAY = Duration(seconds: 2);
  
  List<Map<String, dynamic>> _offlineQueue = [];
  List<Map<String, dynamic>> get offlineQueue => _offlineQueue;

  bool _isUploading = false;
  bool get isUploading => _isUploading;
  
  SyncService() {
    _loadOfflineQueue();
  }
  
  /// Load offline queue from persistent storage
  Future<void> _loadOfflineQueue() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final queueFile = File('${dir.path}/offline_queue.json');
      
      if (await queueFile.exists()) {
        final contents = await queueFile.readAsString();
        final List<dynamic> json = jsonDecode(contents);
        _offlineQueue = json.map((e) => Map<String, dynamic>.from(e)).toList();
        debugPrint('📥 Loaded ${_offlineQueue.length} items from offline queue');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error loading offline queue: $e');
    }
  }
  
  /// Save offline queue to persistent storage
  Future<void> _saveOfflineQueue() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final queueFile = File('${dir.path}/offline_queue.json');
      await queueFile.writeAsString(jsonEncode(_offlineQueue));
      debugPrint('💾 Saved ${_offlineQueue.length} items to offline queue');
    } catch (e) {
      debugPrint('❌ Error saving offline queue: $e');
    }
  }
  
  /// Add workout to offline queue
  Future<void> _addToOfflineQueue(File fitFile, DateTime date, String? assignmentId) async {
    final queueItem = {
      'file_path': fitFile.path,
      'date': date.toIso8601String(),
      'assignment_id': assignmentId,
      'added_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    };
    
    _offlineQueue.add(queueItem);
    await _saveOfflineQueue();
    notifyListeners();
    
    debugPrint('📴 Added workout to offline queue (${_offlineQueue.length} pending)');
  }
  
  /// Process offline queue
  Future<void> processOfflineQueue() async {
    if (_offlineQueue.isEmpty) return;
    if (_isUploading) return; // Don't overlap
    
    debugPrint('🔄 Processing ${_offlineQueue.length} offline workouts...');
    
    final itemsToProcess = List<Map<String, dynamic>>.from(_offlineQueue);
    
    for (var item in itemsToProcess) {
      try {
        final file = File(item['file_path'] as String);
        if (!await file.exists()) {
          // File deleted, remove from queue
          _offlineQueue.remove(item);
          continue;
        }
        
        final date = DateTime.parse(item['date'] as String);
        final assignmentId = item['assignment_id'] as String?;
        
        // Try to upload with retry
        // TODO: Implement _uploadWithRetry method
        // await _uploadWithRetry(file, date, assignmentId: assignmentId);
        await saveWorkoutToStorage(file, date, assignmentId: assignmentId);
        
        // Success! Remove from queue
        _offlineQueue.remove(item);
        await _saveOfflineQueue();
        notifyListeners();
        
        debugPrint('✅ Uploaded offline workout: ${file.path}');
      } catch (e) {
        debugPrint('❌ Failed to upload offline workout: $e');
        // Keep in queue for next attempt
      }
    }
    
    if (_offlineQueue.isEmpty) {
      debugPrint('✅ All offline workouts synced!');
    }
  }

  /// Uploads a generated FIT file to Supabase Storage
  /// Also tries to link it to an existing assignment if found
  Future<void> uploadWorkoutFile(String filePath, String workoutId) async {
     final file = File(filePath);
     if (!file.existsSync()) return;
     
     DateTime date = DateTime.now();
     String? assignmentId;
     try {
       final fileName = filePath.split(Platform.pathSeparator).last;
       final nameParts = fileName.split('_');
       if (nameParts.length > 2 && nameParts[0] == 'activity') {
          final ts = int.tryParse(nameParts[1]);
          if (ts != null) {
            date = DateTime.fromMillisecondsSinceEpoch(ts);
          }
       }
       
       // Try to find matching assignment by date
       final user = _supabase.auth.currentUser;
       if (user != null) {
         final dateStr = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
         final assignments = await _supabase
             .from('assignments')
             .select('id')
             .eq('athlete_id', user.id)
             .eq('date', dateStr)
             .eq('status', 'COMPLETED')
             .limit(1);
         
         if (assignments.isNotEmpty) {
           assignmentId = assignments.first['id'] as String?;
           debugPrint('[SyncService] Found matching assignment: $assignmentId for date $dateStr');
         }
       }
     } catch (e) {
       debugPrint('[SyncService] Error parsing date or finding assignment: $e');
     }

     await saveWorkoutToStorage(file, date, assignmentId: assignmentId);
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

      // 5. Ingest diretto per Lab (RR/DFA) - nessun trigger/webhook necessario
      final token = _supabase.auth.currentSession?.accessToken ?? '';
      await _ingestForLab(fitFile, token);

    } catch (e) {
      debugPrint('Error saving workout to storage: $e');
      rethrow;
    } 
  }

  /// Chiama l'API ingest della piattaforma web per popolare activities (Lab/DFA).
  /// Fallisce in silenzio se URL non configurato o errore di rete.
  Future<void> _ingestForLab(File fitFile, String accessToken) async {
    final baseUrl = AppConfig.coachPlatformUrl;
    if (baseUrl.isEmpty) return;

    try {
      final uri = Uri.parse('$baseUrl/api/ingest/fit');
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $accessToken';
      request.files.add(await http.MultipartFile.fromPath('file', fitFile.path, filename: fitFile.path.split(Platform.pathSeparator).last));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('Lab ingest: attività salvata per analisi RR/DFA');
      } else {
        debugPrint('Lab ingest: ${response.statusCode} - ${response.body.substring(0, response.body.length.clamp(0, 100))}');
      }
    } catch (e) {
      debugPrint('Lab ingest skip: $e');
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
