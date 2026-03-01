import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spatial_cosmic_mobile/src/config/app_config.dart';
import 'package:spatial_cosmic_mobile/src/services/log_service.dart';
import 'package:spatial_cosmic_mobile/src/services/secure_storage_service.dart';

class ActivityUploadScreen extends StatefulWidget {
  const ActivityUploadScreen({super.key});

  @override
  State<ActivityUploadScreen> createState() => _ActivityUploadScreenState();
}

class _ActivityUploadScreenState extends State<ActivityUploadScreen> {
  bool _isUploading = false;
  bool _isProcessing = false;
  String? _selectedFileName;
  String? _uploadStatus;
  String? _processingStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carica Attività'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Upload Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seleziona File .FIT',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Carica i tuoi file di attività per un\'analisi avanzata con metriche professionali',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_selectedFileName != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.fitness_center,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedFileName!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _selectedFileName = null;
                                  _uploadStatus = null;
                                  _processingStatus = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ElevatedButton.icon(
                      onPressed: _isUploading || _isProcessing ? null : _selectFile,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_selectedFileName == null ? 'Seleziona File .FIT' : 'Cambia File'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Upload Button
            if (_selectedFileName != null) ...[
              ElevatedButton.icon(
                onPressed: _isUploading || _isProcessing ? null : _uploadFile,
                icon: _isUploading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload),
                label: Text(_isUploading ? 'Caricamento...' : 'Carica Attività'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Status Messages
            if (_uploadStatus != null) ...[
              Card(
                color: _uploadStatus!.contains('Errore') 
                  ? Theme.of(context).colorScheme.errorContainer
                  : Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        _uploadStatus!.contains('Errore') 
                          ? Icons.error 
                          : Icons.check_circle,
                        color: _uploadStatus!.contains('Errore')
                          ? Theme.of(context).colorScheme.onErrorContainer
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _uploadStatus!,
                          style: TextStyle(
                            color: _uploadStatus!.contains('Errore')
                              ? Theme.of(context).colorScheme.onErrorContainer
                              : Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Processing Status
            if (_isProcessing) ...[
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Analisi in Corso...',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _processingStatus ?? 'Elaborazione metriche avanzate...',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(
                        'Il sistema sta calcolando: Potenza Normalizzata, IF, TSS, Curve di Potenza, Analisi AI',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const Spacer(),
            
            // Info Section
            Card(
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Metriche Calcolate',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...[
                      'Potenza Normalizzata (NP)',
                      'Intensity Factor (IF)',
                      'Training Stress Score (TSS)',
                      'Curve di Potenza',
                      'Bilancio W\' (Skiba)',
                      'Analisi AI (Groq LPU)',
                    ].map((metric) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            metric,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['fit'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFileName = result.files.single.name;
          _uploadStatus = null;
          _processingStatus = null;
        });
        
        LogService.info('File FIT selezionato: ${result.files.single.name}');
      }
    } catch (e) {
      LogService.error('Errore selezione file: $e');
      setState(() {
        _uploadStatus = 'Errore nella selezione del file';
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFileName == null) return;

    setState(() {
      _isUploading = true;
      _uploadStatus = null;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('Utente non autenticato');
      }

      final filePicker = await FilePicker.platform.pickFiles();
      if (filePicker == null || filePicker.files.single.path == null) {
        throw Exception('Nessun file selezionato');
      }

      final file = File(filePicker.files.single.path!);
      final fileName = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.fit';

      LogService.info('Inizio upload file: $fileName');

      // Upload to Supabase Storage
      final uploadResponse = await Supabase.instance.client.storage
          .from('activities')
          .upload(fileName, file);

      if (uploadResponse.error != null) {
        throw Exception('Upload fallito: ${uploadResponse.error!.message}');
      }

      // Get public URL
      final publicUrl = Supabase.instance.client.storage
          .from('activities')
          .getPublicUrl(fileName);

      // Create activity record in database
      final activityData = {
        'athlete_id': user.id,
        'title': _selectedFileName!.replaceAll('.fit', '').replaceAll('_', ' '),
        'date': DateTime.now().toIso8601String(),
        'source_file_url': publicUrl,
        'status': 'pending',
      };

      final insertResponse = await Supabase.instance.client
          .from('activities')
          .insert(activityData)
          .select()
          .single();

      if (insertResponse.error != null) {
        throw Exception('Creazione attività fallita: ${insertResponse.error!.message}');
      }

      final activityId = insertResponse.data['id'];

      LogService.info('Upload completato, inizio elaborazione: $activityId');

      setState(() {
        _isUploading = false;
        _isProcessing = true;
        _uploadStatus = 'File caricato con successo!';
        _processingStatus = 'Avvio elaborazione metriche...';
      });

      // Start processing
      await _startProcessing(activityId);

    } catch (e) {
      LogService.error('Errore upload: $e');
      setState(() {
        _isUploading = false;
        _uploadStatus = 'Errore: ${e.toString()}';
      });
    }
  }

  Future<void> _startProcessing(String activityId) async {
    try {
      final analysisServiceUrl = AppConfig.analysisServiceUrl;
      if (analysisServiceUrl.isEmpty) {
        throw Exception('URL servizio analisi non configurato');
      }

      final response = await Supabase.instance.client.functions.invoke(
        'process-activity',
        body: {
          'activity_id': activityId,
        },
      );

      if (response.error != null) {
        throw Exception('Avvio elaborazione fallito: ${response.error!.message}');
      }

      setState(() {
        _processingStatus = 'Elaborazione in corso sul server...';
      });

      // Start polling for status
      _pollProcessingStatus(activityId);

    } catch (e) {
      LogService.error('Errore avvio elaborazione: $e');
      setState(() {
        _isProcessing = false;
        _processingStatus = 'Errore: ${e.toString()}';
      });
    }
  }

  Future<void> _pollProcessingStatus(String activityId) async {
    const maxAttempts = 60; // 5 minutes max
    int attempts = 0;

    while (attempts < maxAttempts && mounted) {
      await Future.delayed(const Duration(seconds: 5));

      try {
        final response = await Supabase.instance.client
            .from('activities')
            .select('status, processing_error')
            .eq('id', activityId)
            .single();

        final status = response.data['status'];
        final error = response.data['processing_error'];

        if (status == 'completed') {
          setState(() {
            _isProcessing = false;
            _processingStatus = 'Analisi completata con successo!';
          });
          
          _showSuccessDialog();
          break;
        } else if (status == 'error') {
          setState(() {
            _isProcessing = false;
            _processingStatus = 'Errore nell\'elaborazione';
          });
          
          _showErrorDialog(error ?? 'Errore sconosciuto');
          break;
        } else {
          setState(() {
            _processingStatus = 'Elaborazione in corso... (${attempts * 5}s)';
          });
        }

        attempts++;
      } catch (e) {
        LogService.error('Errore polling status: $e');
        attempts++;
      }
    }

    if (attempts >= maxAttempts && mounted) {
      setState(() {
        _isProcessing = false;
        _processingStatus = 'Timeout elaborazione';
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Analisi Completata!'),
        content: const Text(
          'La tua attività è stata analizzata con successo. Puoi visualizzare le metriche avanzate nella dashboard del coach.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Errore'),
        content: Text('Si è verificato un errore: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
