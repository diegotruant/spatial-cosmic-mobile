import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class SyncService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  /// Uploads a generated FIT file to Supabase Storage
  Future<void> uploadWorkoutFile(String filePath, String workoutId) async {
     await saveWorkoutToStorage(File(filePath), DateTime.now());
  }

  /// Uploads a workout file to 'workout-files' bucket and creates a record in 'workouts' table.
  Future<void> saveWorkoutToStorage(File fitFile, DateTime date) async {
    _isUploading = true;
    notifyListeners();

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final timestamp = date.millisecondsSinceEpoch;
      final fileName = '$timestamp.fit';
      final path = '${user.id}/$fileName';

      // 1. Upload File
      await _supabase.storage.from('workout-files').upload(
        path,
        fitFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      // 2. Insert Record
      await _supabase.from('workouts').insert({
        'user_id': user.id,
        'file_path': path,
        'date': date.toIso8601String(),
      });

      debugPrint('Workout saved to storage successfully: $path');

    } catch (e) {
      debugPrint('Error saving workout to storage: $e');
      rethrow;
    } finally {
      _isUploading = false;
      notifyListeners();
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
