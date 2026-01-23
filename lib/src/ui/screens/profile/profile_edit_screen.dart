import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/athlete_profile_service.dart';
import '../../widgets/glass_card.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  late TextEditingController _leanMassController;
  late TextEditingController _dobController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final profileService = context.read<AthleteProfileService>();
    final p = profileService.currentProfile;
    
    _weightController = TextEditingController(text: p.weight?.toString() ?? '');
    _heightController = TextEditingController(text: p.height?.toString() ?? '');
    _leanMassController = TextEditingController(text: p.leanMass?.toString() ?? '');
    _dobController = TextEditingController(text: p.dob != null ? "${p.dob!.year}-${p.dob!.month}-${p.dob!.day}" : '');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _leanMassController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final double? weight = double.tryParse(_weightController.text);
      final double? height = double.tryParse(_heightController.text);
      final double? leanMass = double.tryParse(_leanMassController.text);
      // Simple parse for YYYY-MM-DD
      DateTime? dob;
      if (_dobController.text.isNotEmpty) {
        try {
           dob = DateTime.tryParse(_dobController.text);
        } catch (_) {}
      }

      await context.read<AthleteProfileService>().updateProfile(
        weight: weight,
        height: height,
        leanMass: leanMass,
        dob: dob,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profilo aggiornato con successo')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Errore aggiornamento: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Modifica Profilo', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Dati Biometrici",
                style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Questi dati sono fondamentali per il calcolo accurato del VLamax e delle zone di allenamento.",
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 20),
              
              _buildTextField(
                controller: _weightController,
                label: "Peso (kg)",
                icon: Icons.monitor_weight,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _heightController,
                label: "Altezza (cm)",
                icon: Icons.height,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _leanMassController,
                label: "Massa Magra (kg) - Opzionale",
                icon: Icons.fitness_center,
                keyboardType: TextInputType.number,
                helperText: "Lascia vuoto se non conosciuto. Verrà stimato dal peso.",
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _dobController,
                label: "Data di Nascita (YYYY-MM-DD)",
                icon: Icons.calendar_today,
                keyboardType: TextInputType.datetime,
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("SALVA MODIFICHE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? helperText,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          helperText: helperText,
          helperStyle: const TextStyle(color: Colors.white24),
          icon: Icon(icon, color: Colors.blueAccent),
          border: InputBorder.none,
        ),
        validator: (value) {
           // Basic validation
           if (label.contains("Peso") || label.contains("Altezza")) {
             if (value == null || value.isEmpty) return "Campo obbligatorio";
           }
           return null;
        },
      ),
    );
  }
}
