import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spatial_cosmic_mobile/src/models/workout_template.dart';

class LibraryService {
  // Simulating a database fetch
  Future<List<WorkoutTemplate>> getStandardWorkouts() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Fake network play
    return [
      WorkoutTemplate(
        id: 'ramp_test_01',
        title: 'Ramp Test',
        description: 'Standard incremental ramp test to estimate FTP. Start easy and hold on as long as you can!',
        durationSeconds: 1200, // 20 min approx
        tss: 45,
        category: 'Test',
        zwoContent: '''
<workout_file>
  <workout>
    <SteadyState Duration="300" Power="0.45" />    
    <SteadyState Duration="60" Power="0.50" />
    <SteadyState Duration="60" Power="0.54" />
    <SteadyState Duration="60" Power="0.58" />
    <SteadyState Duration="60" Power="0.62" />
    <SteadyState Duration="60" Power="0.66" />
    <SteadyState Duration="60" Power="0.70" />
    <SteadyState Duration="60" Power="0.74" />
    <SteadyState Duration="60" Power="0.78" />
    <SteadyState Duration="60" Power="0.82" />
    <SteadyState Duration="60" Power="0.86" />
    <SteadyState Duration="60" Power="0.90" />
    <SteadyState Duration="60" Power="0.94" />
    <SteadyState Duration="60" Power="0.98" />
    <SteadyState Duration="60" Power="1.02" />
    <SteadyState Duration="60" Power="1.06" />
    <SteadyState Duration="60" Power="1.10" />
    <SteadyState Duration="60" Power="1.14" />
    <SteadyState Duration="60" Power="1.18" />
    <SteadyState Duration="60" Power="1.22" />
  </workout>
</workout_file>
''',
      ),
      WorkoutTemplate(
        id: 'ftp_test_20',
        title: 'FTP Test (20 min)',
        description: 'Classic 20-minute time trial protocol. Pacing is key.',
        durationSeconds: 3600,
        tss: 80,
        category: 'Test',
        zwoContent: '''
<workout_file>
  <workout>
    <SteadyState Duration="1200" Power="0.55" />
    <SteadyState Duration="300" Power="1.10" />
    <SteadyState Duration="300" Power="0.50" />
    <SteadyState Duration="1200" Power="1.00" /> <!-- The Test Block -->
    <SteadyState Duration="600" Power="0.40" />
  </workout>
</workout_file>
''',
      ),
      WorkoutTemplate(
        id: 'sweet_spot_base',
        title: 'Sweet Spot Base',
        description: 'Efficient aerobic training. 3x10min at 90% FTP.',
        durationSeconds: 3600,
        tss: 65,
        category: 'Intervals',
        zwoContent: '''
<workout_file>
  <workout>
    <SteadyState Duration="600" Power="0.50" />
    <IntervalsT Repeat="3" OnDuration="600" OffDuration="300" OnPower="0.90" OffPower="0.50" />
    <SteadyState Duration="300" Power="0.50" />
  </workout>
</workout_file>
''',
      ),
      // NEW TESTS
      WorkoutTemplate(
        id: 'cp3_test',
        title: 'CP3 Test',
        description: '3 Minute Max Effort. All-out pacing.',
        durationSeconds: 1800,
        tss: 40,
        category: 'Test',
        zwoContent: '''
<workout_file>
  <workout>
    <SteadyState Duration="900" Power="0.50" />
    <SteadyState Duration="180" Power="1.20" /> <!-- 3 min effort, user handles pacing -->
    <SteadyState Duration="720" Power="0.40" />
  </workout>
</workout_file>
''',
      ),
      WorkoutTemplate(
        id: 'cp5_test',
        title: 'CP5 Test',
        description: '5 Minute VO2max test.',
        durationSeconds: 2100,
        tss: 50,
        category: 'Test',
        zwoContent: '''
<workout_file>
  <workout>
    <SteadyState Duration="900" Power="0.50" />
    <SteadyState Duration="300" Power="1.15" /> <!-- 5 min effort -->
    <SteadyState Duration="900" Power="0.40" />
  </workout>
</workout_file>
''',
      ),
      WorkoutTemplate(
        id: 'cp12_test',
        title: 'CP12 Test',
        description: '12 Minute Threshold/VO2 mix.',
        durationSeconds: 2700,
        tss: 60,
        category: 'Test',
        zwoContent: '''
<workout_file>
  <workout>
    <SteadyState Duration="900" Power="0.50" />
    <SteadyState Duration="720" Power="1.05" /> <!-- 12 min effort -->
    <SteadyState Duration="1080" Power="0.40" />
  </workout>
</workout_file>
''',
      ),
      WorkoutTemplate(
        id: '2x8_test',
        title: '2x8 Minute Test',
        description: 'Two 8-minute threshold efforts with recovery.',
        durationSeconds: 3600,
        tss: 75,
        category: 'Test',
        zwoContent: '''
<workout_file>
  <workout>
    <SteadyState Duration="1200" Power="0.50" />
    <SteadyState Duration="480" Power="1.10" /> <!-- Effort 1 -->
    <SteadyState Duration="600" Power="0.40" /> <!-- Recovery -->
    <SteadyState Duration="480" Power="1.10" /> <!-- Effort 2 -->
    <SteadyState Duration="840" Power="0.40" />
  </workout>
</workout_file>
''',
      ),
      WorkoutTemplate(
        id: 'pmax_slope_test',
        title: 'Pmax Test (Slope)',
        description: 'Max Sprint Test using Slope Mode. Manual resistance control.',
        durationSeconds: 900,
        tss: 20,
        category: 'Test',
        zwoContent: '''
<workout_file>
  <workout>
    <!-- Use a special flag or just handle logic in service knowing ID -->
    <SteadyState Duration="600" Power="0.50" />
    <SteadyState Duration="15" Power="3.00" /> <!-- Max Sprint -->
    <SteadyState Duration="285" Power="0.40" />
  </workout>
</workout_file>
''',
      ),
    ];
  }
  Future<List<WorkoutTemplate>> getAssignedWorkouts() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return [];

      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      
      final data = await supabase
          .from('assignments')
          .select('*')
          .eq('athlete_id', user.id)
          .gte('date', todayStr) // Fetch today and future
          .order('date', ascending: true);

      return (data as List).map((json) {
        final map = json as Map<String, dynamic>;
        // Use workout_data (ZWO) if available, otherwise fallback or empty
        String zwoContent = map['workout_data'] as String? ?? '';
        
        return WorkoutTemplate(
          id: map['id'] as String,
          title: map['workout_name'] as String? ?? 'Assigned Workout',
          description: map['notes'] as String? ?? 'No notes provided.',
          durationSeconds: 0, 
          tss: 0,
          category: 'Assigned',
          zwoContent: zwoContent,
          structure: map,
        );
      }).toList();
    } catch (e) {
      print('Error fetching assigned workouts: $e');
      return [];
    }
  }
}
