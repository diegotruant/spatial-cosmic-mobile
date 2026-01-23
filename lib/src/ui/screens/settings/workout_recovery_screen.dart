import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../widgets/glass_card.dart';
import '../../../services/sync_service.dart';

class WorkoutRecoveryScreen extends StatefulWidget {
  const WorkoutRecoveryScreen({super.key});

  @override
  State<WorkoutRecoveryScreen> createState() => _WorkoutRecoveryScreenState();
}

class _WorkoutRecoveryScreenState extends State<WorkoutRecoveryScreen> {
  bool _isLoading = true;
  List<FileSystemEntity> _fitFiles = [];

  @override
  void initState() {
    super.initState();
    _scanForFiles();
  }

  Future<void> _scanForFiles() async {
    setState(() => _isLoading = true);
    try {
      final dir = await getApplicationDocumentsDirectory();
      // List all .fit files
      final files = dir.listSync()
          .where((entity) => entity.path.toLowerCase().endsWith('.fit'))
          .toList();
      
      // Sort by modification time (newest first)
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      
      setState(() {
        _fitFiles = files;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error scanning files: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadFile(File file) async {
    final syncService = context.read<SyncService>();
    
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Caricamento in corso..."))
    );

    try {
      // Use modification time as workout date if filename isn't timestamped
      // Assumption: Filename is timestamp.fit
      final filename = file.uri.pathSegments.last;
      
      await syncService.uploadWorkoutFile(file.path, 'recovered_${filename.replaceAll('.fit', '')}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Recupero completato con successo!"), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Errore upload: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        title: const Text("Recupero Workout", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
        : _fitFiles.isEmpty 
           ? const Center(child: Text("Nessun file .fit trovato.", style: TextStyle(color: Colors.white54)))
           : ListView.builder(
               padding: const EdgeInsets.all(20),
               itemCount: _fitFiles.length,
               itemBuilder: (context, index) {
                 final file = _fitFiles[index] as File;
                 final stat = file.statSync();
                 final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(stat.modified);
                 final sizeKb = (stat.size / 1024).toStringAsFixed(1);
                 
                 return Padding(
                   padding: const EdgeInsets.only(bottom: 12),
                   child: GlassCard(
                     padding: const EdgeInsets.all(16),
                     borderRadius: 12,
                     child: Row(
                       children: [
                         const Icon(LucideIcons.fileCode, color: Colors.cyanAccent),
                         const SizedBox(width: 16),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text("Workout ${index + 1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                               Text(dateStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                               Text("$sizeKb KB", style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
                             ],
                           ),
                         ),
                         IconButton(
                           icon: const Icon(Icons.cloud_upload, color: Colors.greenAccent),
                           onPressed: () => _uploadFile(file),
                         ),
                       ],
                     ),
                   ),
                 );
               },
             ),
    );
  }
}
