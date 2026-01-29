import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:spatial_cosmic_mobile/src/services/workout_service.dart';
import 'package:spatial_cosmic_mobile/src/l10n/app_localizations.dart';
import 'package:spatial_cosmic_mobile/src/services/library_service.dart';
import 'package:spatial_cosmic_mobile/src/models/workout_template.dart';
import 'package:spatial_cosmic_mobile/src/logic/zwo_parser.dart';
import '../../widgets/glass_card.dart';
import 'modern_workout_screen.dart';
import 'package:spatial_cosmic_mobile/src/services/integration_service.dart';
import 'package:spatial_cosmic_mobile/src/logic/fit_generator.dart';
import 'package:spatial_cosmic_mobile/src/services/settings_service.dart';
import '../../widgets/platform_selector.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class WorkoutLibraryScreen extends StatefulWidget {
  final bool isTab;
  const WorkoutLibraryScreen({super.key, this.isTab = false});

  @override
  State<WorkoutLibraryScreen> createState() => _WorkoutLibraryScreenState();
}

class _WorkoutLibraryScreenState extends State<WorkoutLibraryScreen> {
  final LibraryService _libraryService = LibraryService();
  List<WorkoutTemplate> _workouts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    final standardWorkouts = await _libraryService.getStandardWorkouts();
    List<WorkoutTemplate> combined = [];

    if (widget.isTab) {
      // If it's the main Workout Tab, we want assigned AND standard workouts
      // Previously it filtered only 'Test', which was incorrect for a general 'Workouts' tab
      final assignedWorkouts = await _libraryService.getAssignedWorkouts();
      // Optionally filter standard workouts? No, show all.
      combined = [...assignedWorkouts, ...standardWorkouts];
    } else {
      final assignedWorkouts = await _libraryService.getAssignedWorkouts();
      combined = [...assignedWorkouts, ...standardWorkouts];
    }
    
    if (mounted) {
      setState(() {
        _workouts = combined;
        _isLoading = false;
      });
    }
  }

  void _startWorkout(WorkoutTemplate template) {
    try {
      final parsedWorkout = ZwoParser.parse(template.zwoContent, titleOverride: template.title);
      final ftp = context.read<SettingsService>().ftp;
      context.read<WorkoutService>().startWorkout(parsedWorkout, workoutId: template.id, ftp: ftp);
      
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ModernWorkoutScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error parsing workout: $e')),
      );
    }
  }

  Future<void> _sendToDevice(WorkoutTemplate template) async {
    // 1. Selection Dialog (Premium Style)
    final platform = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent, // Allow glass effect
      isScrollControlled: true,
      builder: (ctx) => SyncPlatformSelector(
        onSelect: (p) => Navigator.pop(ctx, p),
      ),
    );

    if (platform == null) return;
    if (!mounted) return;
    
    // 2. Show Premium Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: GlassCard(
            padding: const EdgeInsets.all(32),
            borderRadius: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 20),
                Text(
                  "Sincronizzazione in corso...", 
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      WorkoutWorkout? parsedWorkout;
      
      // 1. Try ZWO
      if (template.zwoContent.isNotEmpty) {
        try {
           parsedWorkout = ZwoParser.parse(template.zwoContent, titleOverride: template.title);
        } catch (e) {
           debugPrint('Error parsing ZWO for ${template.title}: $e');
        }
      }

      // 2. Fallback to Structure
      if (parsedWorkout == null && template.structure != null) {
         try {
           parsedWorkout = ZwoParser.parseJson(template.structure!);
         } catch (e) {
           debugPrint('Error parsing JSON structure for ${template.title}: $e');
         }
      }

      if (parsedWorkout == null) {
         throw 'Impossibile caricare il workout: dati mancanti o non validi.';
      }

      final ftp = context.read<SettingsService>().ftp; // Get user FTP for scaling
      await context.read<IntegrationService>().uploadWorkoutDirectly(parsedWorkout!, platform, ftp);
      
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sincronizzazione completata!'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withOpacity(0.05),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppColors.accentPurple.withOpacity(0.1), blurRadius: 150, spreadRadius: 50)
                ],
              ),
            ),
          ),

          Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildWorkoutGrid(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.isTab)
            const SizedBox(width: 48)
          else
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
              onPressed: () => Navigator.pop(context),
            ),
          Text(
            AppLocalizations.of(context).get('workout_library'),
            style: AppTextStyles.h3.copyWith(letterSpacing: 2.0),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildWorkoutGrid() {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 600 ? 2 : 1;
    
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: crossAxisCount == 1 ? 1.3 : 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _workouts.length,
      itemBuilder: (context, index) {
        return _buildWorkoutCard(_workouts[index]);
      },
    );
  }

  Widget _buildWorkoutCard(WorkoutTemplate workout) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: Colors.white10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: workout.category == 'Test' ? Colors.redAccent.withOpacity(0.2) : 
                     workout.category == 'Assigned' ? Colors.greenAccent.withOpacity(0.2) :
                     Colors.blueAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: workout.category == 'Test' ? Colors.redAccent.withOpacity(0.5) : 
                                        workout.category == 'Assigned' ? Colors.greenAccent.withOpacity(0.5) :
                                        Colors.blueAccent.withOpacity(0.5)),
            ),
            child: Text(
              workout.category.toUpperCase(),
              style: TextStyle(
                color: workout.category == 'Test' ? Colors.redAccent : 
                       workout.category == 'Assigned' ? Colors.greenAccent :
                       Colors.blueAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          Text(
            workout.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            workout.description,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          const Spacer(),
          
          // Metrics Row
          Row(
            children: [
              const Icon(LucideIcons.clock, color: Colors.white30, size: 14),
              const SizedBox(width: 4),
              Text(
                '${workout.durationSeconds ~/ 60} min',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              const Icon(LucideIcons.zap, color: AppColors.zone4, size: 14),
              const SizedBox(width: 4),
              Text(
                '${workout.tss} TSS',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _startWorkout(workout),
                  child: Text(AppLocalizations.of(context).get('start'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                ),
                onPressed: () => _sendToDevice(workout),
                icon: const Icon(LucideIcons.send, color: AppColors.primary, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
