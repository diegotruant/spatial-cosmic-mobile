import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/athlete_profile_service.dart';
import '../../widgets/glass_card.dart';

class MedicalCertificateScreen extends StatefulWidget {
  const MedicalCertificateScreen({super.key});

  @override
  State<MedicalCertificateScreen> createState() => _MedicalCertificateScreenState();
}

class _MedicalCertificateScreenState extends State<MedicalCertificateScreen> {
  DateTime? _expiryDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AthleteProfileService>();
    _expiryDate = profile.certExpiryDate;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)), // Allow expired
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
         return Theme(
           data: ThemeData.dark().copyWith(
             colorScheme: const ColorScheme.dark(
               primary: Colors.blueAccent,
               onPrimary: Colors.white,
               surface: Color(0xFF1A1A2E),
               onSurface: Colors.white,
             ),
           ),
           child: child!,
         );
      }
    );

    if (picked != null) {
      setState(() => _expiryDate = picked);
      await _saveDate(picked);
    }
  }

  Future<void> _saveDate(DateTime date) async {
    setState(() => _isLoading = true);
    try {
      await context.read<AthleteProfileService>().updateProfile(certExpiryDate: date);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data scadenza aggiornata')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore salvataggio: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Color _getStatusColor(int daysRemaining) {
    if (daysRemaining < 0) return Colors.redAccent;
    if (daysRemaining < 30) return Colors.orangeAccent;
    return Colors.greenAccent;
  }
  
  String _getStatusText(int daysRemaining) {
    if (daysRemaining < 0) return "SCADUTO";
    if (daysRemaining < 30) return "IN SCADENZA";
    return "VALIDO";
  }

  @override
  Widget build(BuildContext context) {
    final expiry = _expiryDate;
    final now = DateTime.now();
    
    int daysRemaining = 0;
    if (expiry != null) {
      daysRemaining = expiry.difference(now).inDays;
    }
    
    final statusColor = expiry != null ? _getStatusColor(daysRemaining) : Colors.grey;
    final statusText = expiry != null ? _getStatusText(daysRemaining) : "NON INSERITO";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Certificato Medico', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                     expiry == null ? LucideIcons.fileQuestion : (daysRemaining < 0 ? LucideIcons.alertCircle : LucideIcons.fileHeart), 
                     size: 60, 
                     color: statusColor
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Stato: $statusText",
                    style: TextStyle(color: statusColor, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (expiry != null)
                    Text(
                      "Scade il ${DateFormat('dd MMMM yyyy').format(expiry)}", 
                      style: const TextStyle(color: Colors.white70, fontSize: 16)
                    )
                  else
                    const Text("Nessuna data inserita", style: TextStyle(color: Colors.white54)),
                    
                  if (expiry != null) ...[
                     const SizedBox(height: 12),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                       decoration: BoxDecoration(
                         color: statusColor.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: Text(
                         daysRemaining < 0 
                           ? "Scaduto da ${daysRemaining.abs()} giorni" 
                           : "Mancano $daysRemaining giorni",
                         style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                       ),
                     ),
                  ],
                  
                  const SizedBox(height: 24),
                  const Text(
                    "Mantieni aggiornata la data di scadenza del tuo certificato medico agonistico. Riceverai notifiche prima della scadenza.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white38),
                  ),
                ],
              ),
            ),
            const Spacer(),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _pickDate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(LucideIcons.calendar, color: Colors.white),
                label: Text(expiry == null ? "INSERISCI DATA SCADENZA" : "AGGIORNA DATA SCADENZA", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
