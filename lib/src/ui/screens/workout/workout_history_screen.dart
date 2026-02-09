import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:intl/intl.dart'; // Add intl dependency if not present, or use manual formatting for now
import '../../widgets/glass_card.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../../logic/fit_reader.dart';
import 'post_workout_analysis_screen.dart';
import 'package:provider/provider.dart';
import '../../../services/sync_service.dart';
import '../../../services/integration_service.dart';
import '../../../services/intervals_service.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  List<FileSystemEntity> _files = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    final dir = await getApplicationDocumentsDirectory();
    final List<FileSystemEntity> files = dir.listSync().where((file) {
      return file.path.toLowerCase().endsWith('.fit');
    }).toList();

    // Sort by modification time (newest first) or by filename timestamp
    // Filename logic is robust if modification time changes on copy
    files.sort((a, b) {
      // Extract timestamp from filename if possible for better sorting
      // activity_{timestamp}_...
      final nameA = a.path.split(Platform.pathSeparator).last;
      final nameB = b.path.split(Platform.pathSeparator).last;
      return nameB.compareTo(nameA); // Descending string compare works for timestamp prefix
    });

    if (mounted) {
      setState(() {
        _files = files;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('STORICO ATTIVITÀ', style: AppTextStyles.h3.copyWith(fontSize: 16, letterSpacing: 1.5)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
          : _files.isEmpty
              ? const Center(child: Text("Nessuna attività registrata", style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    final meta = FitReader.parseFilename(file.path);
                    return _buildHistoryItem(context, file.path, meta);
                  },
                ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, String path, Map<String, dynamic> meta) {
    final DateTime date = meta['date'];
    final String title = meta['title'];
    
    // Manual date formatting to avoid intl dependency if not wanted, or simple enough
    final dateStr = "${date.day.toString().padLeft(2,'0')}/${date.month.toString().padLeft(2,'0')}/${date.year} ${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}";

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PostWorkoutAnalysisScreen(fitFilePath: path)),
          );
        },
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 12,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.bike, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white30),
              const SizedBox(width: 8),
              _buildActionMenu(context, path, title),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionMenu(BuildContext context, String path, String title) {
    final intervalsService = context.read<IntervalsService>();
    
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.moreVertical, color: Colors.white54),
      color: const Color(0xFF1A1A2E),
      onSelected: (value) => _handleAction(context, value, path),
      itemBuilder: (context) {
        final items = <PopupMenuItem<String>>[
          PopupMenuItem(
            value: 'sync',
            child: Row(children: [
              const Icon(LucideIcons.upload, color: Colors.blueAccent, size: 20), 
              const SizedBox(width: 12), 
              const Text('Sincronizza Cloud', style: TextStyle(color: Colors.white)),
            ]),
          ),
          PopupMenuItem(
            value: 'strava',
            child: Row(children: [const Icon(LucideIcons.activity, color: Colors.orange, size: 20), const SizedBox(width: 12), const Text('Invia a Strava', style: TextStyle(color: Colors.white))]),
          ),
          PopupMenuItem(
            value: 'repair_strava',
            child: Row(children: [const Icon(LucideIcons.wrench, color: Colors.orangeAccent, size: 20), const SizedBox(width: 12), const Text('Ripara e Invia (Strava)', style: TextStyle(color: Colors.white))]),
          ),
        ];
        
        // Mostra Intervals.icu solo se connesso
        if (intervalsService.isConnected) {
          items.add(
            PopupMenuItem(
              value: 'intervals',
              child: Row(children: [const Icon(LucideIcons.barChart, color: Colors.purpleAccent, size: 20), const SizedBox(width: 12), const Text('Invia a Intervals.icu', style: TextStyle(color: Colors.white))]),
            ),
          );
        }
        
        items.add(
          PopupMenuItem(
            value: 'delete',
            child: Row(children: [const Icon(LucideIcons.trash2, color: Colors.redAccent, size: 20), const SizedBox(width: 12), const Text('Elimina', style: TextStyle(color: Colors.white))]),
          ),
        );
        
        return items;
      },
    );
  }

  Future<void> _handleAction(BuildContext context, String action, String path) async {
    final file = File(path);
    if (!file.existsSync()) return;

    try {
      if (action == 'delete') {
         _showDeleteConfirmation(context, path);
      } else if (action == 'sync') {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caricamento su Cloud in corso...')));
         await context.read<SyncService>().uploadWorkoutFile(path, 'history');
         if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sincronizzazione completata!'), backgroundColor: Colors.green));
      } else if (action == 'strava') {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invio a Strava in corso...')));
         final result = await context.read<IntegrationService>().uploadActivityToStrava(file);
         if (mounted) {
           if (result == 'Success' || result.startsWith('Success')) {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
               content: Text('Inviato a Strava!'),
               backgroundColor: Colors.orange,
             ));
           } else {
             // Show detailed error returned by IntegrationService (es. non connesso, token scaduto, errore Strava)
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Errore invio Strava: $result'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ));
            }
          }
      } else if (action == 'repair_strava') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PostWorkoutAnalysisScreen(fitFilePath: path)),
          );
      } else if (action == 'intervals') {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invio a Intervals.icu in corso...')));
         final result = await context.read<IntervalsService>().uploadActivity(file);
         
         if (mounted) {
           if (result == 'Success') {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inviato a Intervals.icu!'), backgroundColor: Colors.purpleAccent));
           } else {
              // Show detailed error in a dialog or long snackbar
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(result), 
                backgroundColor: Colors.red, 
                duration: const Duration(seconds: 5)
              ));
           }
         }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red));
    }
  }


  Future<void> _showDeleteConfirmation(BuildContext context, String path) async {
     final confirmed = await showDialog<bool>(
       context: context,
       builder: (ctx) => AlertDialog(
         backgroundColor: AppColors.surface,
         title: const Text('Elimina Allenamento', style: TextStyle(color: AppColors.textPrimary)),
         content: const Text(
           'Sei sicuro di voler eliminare questo allenamento? L\'azione è irreversibile.',
           style: TextStyle(color: AppColors.textSecondary),
         ),
         actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annulla', style: TextStyle(color: AppColors.textDim)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Elimina'),
            ),
         ],
       ),
     );

     if (confirmed == true) {
        try {
           // Use Sync Service to delete local and remote (if synced)
           await context.read<SyncService>().deleteWorkout(path);
           _loadFiles(); // Refresh list
           
           if (context.mounted) {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Allenamento eliminato')),
               );
           }
        } catch (e) {
           if (context.mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Errore durante l\'eliminazione: $e'), backgroundColor: Colors.redAccent),
             );
           }
        }
     }
  }
}
