import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../../services/events_service.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  DateTime _date = DateTime.now();
  EventType _type = EventType.race;
  String? _description;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
         backgroundColor: Colors.transparent,
         elevation: 0,
         leading: IconButton(
           icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
           onPressed: () => Navigator.pop(context),
         ),
         title: const Text("Nuovo Evento", style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               GlassCard(
                 padding: const EdgeInsets.all(24),
                 borderRadius: 20,
                 child: Column(
                   children: [
                      // Title
                      TextFormField(
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Titolo Evento', LucideIcons.flag),
                        validator: (v) => v == null || v.isEmpty ? 'Inserisci un titolo' : null,
                        onSaved: (v) => _title = v!,
                      ),
                      const SizedBox(height: 20),
                      
                      // Date Picker
                      GestureDetector(
                        onTap: _pickDate,
                        child: AbsorbPointer(
                           child: TextFormField(
                             controller: TextEditingController(text: "${_date.day}/${_date.month}/${_date.year}"),
                             style: const TextStyle(color: Colors.white),
                             decoration: _buildInputDecoration('Data', LucideIcons.calendar),
                           ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Type Dropdown
                      DropdownButtonFormField<EventType>(
                        value: _type,
                        dropdownColor: const Color(0xFF2A2A40),
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Tipo', LucideIcons.tag),
                        items: EventType.values.map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.name.toUpperCase()),
                        )).toList(),
                        onChanged: (v) => setState(() => _type = v!),
                      ),
                      const SizedBox(height: 20),
                      
                      // Description
                      TextFormField(
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: _buildInputDecoration('Note / Descrizione', LucideIcons.fileText),
                        onSaved: (v) => _description = v,
                      ),
                   ],
                 ),
               ),
               const SizedBox(height: 32),
               SizedBox(
                 width: double.infinity,
                 child: ElevatedButton(
                   onPressed: _isLoading ? null : _submit,
                   style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                   ),
                   child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text("AGGIUNGI EVENTO", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                 ),
               )
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: Colors.white54, size: 20),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
           data: ThemeData.dark().copyWith(
             colorScheme: const ColorScheme.dark(
               primary: AppColors.primary,
               onPrimary: Colors.black,
               surface: Color(0xFF1E1E2E),
             ),
           ),
           child: child!,
        );
      }
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    setState(() => _isLoading = true);
    
    try {
      await context.read<EventsService>().addEvent(_title, _date, _type, _description);
      if (mounted) {
         Navigator.pop(context);
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Evento aggiunto!"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Errore: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
