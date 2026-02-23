import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'workout_recovery_screen.dart';
import 'terms_screen.dart';
import 'privacy_policy_screen.dart';
import '../../../services/settings_service.dart';
import '../../../services/integration_service.dart';
import '../../../services/oura_service.dart';
import '../../../services/intervals_service.dart';
import '../../../l10n/app_localizations.dart';
import '../profile/profile_edit_screen.dart';
import '../profile/medical_certificate_screen.dart';
import '../../widgets/glass_card.dart';


class AdvancedOptionsScreen extends StatelessWidget {
  const AdvancedOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.get('other_options'), style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Toggle Options
          _buildToggleOption(context, l10n.get('auto_extend_recovery'), l10n.get('auto_extend_recovery_desc'), settings.autoExtendRecovery, () => settings.toggleAutoExtendRecovery()),
          _buildToggleOption(context, l10n.get('power_smoothing'), l10n.get('power_smoothing_desc'), settings.powerSmoothing, () => settings.togglePowerSmoothing()),
          _buildToggleOption(context, l10n.get('short_press_next'), l10n.get('short_press_next_desc'), settings.shortPressNextInterval, () => settings.toggleShortPressNextInterval()),
          _buildToggleOption(context, l10n.get('power_match'), l10n.get('power_match_desc'), settings.powerMatch, () => settings.togglePowerMatch()),
          _buildToggleOption(context, l10n.get('double_sided_power'), l10n.get('double_sided_power_desc'), settings.doubleSidedPower, () => settings.toggleDoubleSidedPower()),
          _buildToggleOption(context, l10n.get('disable_auto_start'), l10n.get('disable_auto_start_desc'), settings.disableAutoStartStop, () => settings.toggleDisableAutoStartStop()),
          _buildToggleOption(context, l10n.get('vibration'), l10n.get('vibration_desc'), settings.vibration, () => settings.toggleVibration()),
          _buildToggleOption(context, l10n.get('show_power_zones'), l10n.get('show_power_zones_desc'), settings.showPowerZones, () => settings.toggleShowPowerZones()),
          _buildToggleOption(context, l10n.get('live_workout_view'), l10n.get('live_workout_view_desc'), settings.liveWorkoutView, () => settings.toggleLiveWorkoutView()),
          _buildToggleOption(context, l10n.get('sim_slope_mode'), l10n.get('sim_slope_mode_desc'), settings.simSlopeMode, () => settings.toggleSimSlopeMode()),
          
          const SizedBox(height: 12),
          _buildBeepSelector(context, settings, l10n),
          
          const SizedBox(height: 24),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),
          
          // Numeric Settings
          _buildNumericSetting(context, l10n.get('hr_threshold'), settings.hrThreshold, (v) => settings.setHrThreshold(v)),
          _buildNumericSetting(context, 'FC Max', settings.hrMax, (v) => settings.setHrMax(v)),
          _buildNumericSetting(context, l10n.get('erg_increase'), settings.ergIncreasePercent, (v) => settings.setErgIncrease(v)),
          _buildNumericSetting(context, l10n.get('hr_increase'), settings.hrIncrease, (v) => settings.setHrIncrease(v)),
          _buildNumericSetting(context, l10n.get('slope_increase'), settings.slopeIncreasePercent, (v) => settings.setSlopeIncrease(v)),
          _buildNumericSetting(context, l10n.get('resistance_increase'), settings.resistanceIncreasePercent, (v) => settings.setResistanceIncrease(v)),
          
          const SizedBox(height: 24),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),
          
          _buildMenuRow(context, 'Recupera Workout Persi', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkoutRecoveryScreen()))),
          _buildMenuRow(context, 'Termini e Condizioni', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsScreen()))), // New
          _buildMenuRow(context, l10n.get('privacy_policy'), () {
             Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
          }),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.get('version'), style: const TextStyle(color: Colors.white54)),
              const Text('1.0.0', style: TextStyle(color: Colors.white54)),
            ],
          ),
          const SizedBox(height: 32),
          
          GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.get('delete_account')))),
            child: Text(l10n.get('delete_account'), style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
          ),
        ],
      ),
    );
  }
  
  Widget _buildToggleOption(BuildContext context, String title, String subtitle, bool value, VoidCallback onToggle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: (_) => onToggle(),
            activeThumbColor: Colors.blueAccent,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNumericSetting(BuildContext context, String label, int value, Function(int) onChanged) {
    return GestureDetector(
      onTap: () => _showNumberInputDialog(context, label, value, onChanged),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white))),
            const Icon(LucideIcons.info, color: Colors.white24, size: 16),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$value', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMenuRow(BuildContext context, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15))),
            const Icon(LucideIcons.chevronRight, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBeepSelector(BuildContext context, SettingsService settings, AppLocalizations l10n) {
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: const Color(0xFF1A1A2E),
          builder: (ctx) => Column(
            mainAxisSize: MainAxisSize.min,
            children: settings.beepTypes.map((type) => ListTile(
              title: Text(type, style: const TextStyle(color: Colors.white)),
              trailing: type == settings.intervalBeepType ? const Icon(Icons.check, color: Colors.blueAccent) : null,
              onTap: () {
                settings.setBeepType(type);
                Navigator.pop(ctx);
              },
            )).toList(),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(child: Text('${l10n.get('interval_beep_type')}:', style: const TextStyle(color: Colors.white, fontSize: 15))),
            Text(settings.intervalBeepType, style: const TextStyle(color: Colors.white54)),
            const SizedBox(width: 8),
            const Icon(LucideIcons.chevronRight, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
  
  void _showNumberInputDialog(BuildContext context, String label, int currentValue, Function(int) onSave) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: currentValue.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 24),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.get('cancel'), style: const TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final newValue = int.tryParse(controller.text);
              if (newValue != null) {
                onSave(newValue);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: Text(l10n.get('save')),
          ),
        ],
      ),
    );
  }
}

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.get('language'), style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: settings.languages.length,
        itemBuilder: (_, i) {
          final lang = settings.languages[i];
          final isSelected = lang == settings.language;
          return ListTile(
            title: Text(lang, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 16)),
            trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blueAccent) : null,
            tileColor: isSelected ? Colors.blueAccent.withOpacity(0.1) : null,
            onTap: () {
              settings.setLanguage(lang);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}

class AccountInfoScreen extends StatelessWidget {
  const AccountInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final l10n = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.get('account_info'), style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildAccountRow(
            l10n.get('username'), 
            settings.username.isEmpty ? '-' : settings.username, 
            onTap: () => _showTextInputDialog(context, l10n.get('username'), settings.username, (v) => settings.setUsername(v))
          ),
          const SizedBox(height: 16),
          
          if (settings.coachName != null) ...[
             const Padding(
               padding: EdgeInsets.only(bottom: 8),
               child: Text('COACH', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
             ),
             _buildAccountRow('Nome', settings.coachName!),
             if (settings.coachEmail != null) _buildAccountRow('Email', settings.coachEmail!),
             const Divider(color: Colors.white12, height: 32),
          ],

          _buildToggleOption(context, l10n.get('metric_units'), l10n.get('metric_units_desc'), settings.useMetricUnits, () => settings.toggleMetricUnits()),
          const SizedBox(height: 16),
          _buildNumericSetting(context, l10n.get('rider_weight'), settings.weight, settings.useMetricUnits ? 'KG' : 'LB', (v) => settings.setWeight(v)),
          _buildNumericSetting(context, l10n.get('bike_weight'), settings.bikeWeight, settings.useMetricUnits ? 'KG' : 'LB', (v) => settings.setBikeWeight(v)),
          
          const SizedBox(height: 16),
          _buildMenuRow(context, 'Modifica Profilo Completo', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileEditScreen()))),
          _buildMenuRow(context, 'Certificato Medico', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const MedicalCertificateScreen()))),

          
          const Divider(color: Colors.white12, height: 32),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('INTEGRAZIONI DISPONIBILI', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          
          _buildMenuRow(context, 'Connessioni e App (Strava, Oura...)', () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ConnectionsScreen()))),

        ],
      ),
    );
  }
  
  Widget _buildAccountRow(String label, String value, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Text(label, style: const TextStyle(color: Colors.white)),
            const Spacer(),
            Text(value, style: const TextStyle(color: Colors.white54)),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.edit, color: Colors.white24, size: 16),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildMenuRow(BuildContext context, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15))),
            const Icon(LucideIcons.chevronRight, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
  
  void _showTextInputDialog(BuildContext context, String label, String currentValue, Function(String) onSave) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.get('cancel'), style: const TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: Text(l10n.get('save')),
          ),
        ],
      ),
    );
  }
  
  Widget _buildToggleOption(BuildContext context, String title, String subtitle, bool value, VoidCallback onToggle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: (_) => onToggle(),
            activeThumbColor: Colors.blueAccent,
          ),
        ],
      ),
    );
  }
  
  Widget _buildNumericSetting(BuildContext context, String label, int? value, String unit, Function(int) onChanged) {
    return GestureDetector(
      onTap: () => _showNumberInputDialog(context, label, value, onChanged),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Text(value?.toString() ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text(unit, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showNumberInputDialog(BuildContext context, String label, int? currentValue, Function(int) onSave) {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: currentValue?.toString() ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(label, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontSize: 24),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            hintText: '0',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.get('cancel'), style: const TextStyle(color: Colors.white54))),
          ElevatedButton(
            onPressed: () {
              final newValue = int.tryParse(controller.text);
              if (newValue != null) onSave(newValue);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: Text(l10n.get('save')),
          ),
        ],
      ),
    );
  }
}

class ConnectionsScreen extends StatelessWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final integrationService = context.watch<IntegrationService>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Connessioni', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Oura Section
            Consumer<OuraService>(
              builder: (context, oura, _) => _buildOuraSection(context, oura),
            ),
            const SizedBox(height: 16),

            // Strava Section
            _buildConnectionCard(
              context,
              'Strava',
              'Sincronizza attività automaticamente',
              integrationService.isStravaConnected,
              (val) => integrationService.initiateStravaAuth(), // Toggle/Auth logic
              const Color(0xFFFC4C02), // Strava Color
              LucideIcons.activity,
            ),
            
            // Manual Sync Button (Fallback)
            if (!integrationService.isStravaConnected)
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 16, right: 16),
                child: TextButton.icon(
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verifica connessione in corso...')));
                    await integrationService.syncFromSupabase();
                    if (context.mounted) {
                       if (integrationService.isStravaConnected) {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connesso con successo!')));
                       } else {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ancora nessuna connessione trovata.')));
                       }
                    }
                  },
                  icon: const Icon(Icons.refresh, color: Colors.blueAccent, size: 16),
                  label: const Text('Verifica Stato Connessione (Se il login è avvenuto)', style: TextStyle(color: Colors.blueAccent)),
                ),
              ),

            const SizedBox(height: 24),
            
            // Info Note
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),
            const Text(
              'NOTA: Per Garmin, Wahoo, Karoo e Bryton, utilizza la funzione "Esporta file .fit" dalla schermata di riepilogo o dallo storico e caricalo manualmente via app o USB.',
              style: TextStyle(color: Colors.white38, fontSize: 13, fontStyle: FontStyle.italic, height: 1.4),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildOuraSection(BuildContext context, OuraService oura) {
    // keeping simplified UI for Oura
    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      borderColor: Colors.cyanAccent.withOpacity(0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Oura Ring', style: TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold)),
              if (oura.hasToken)
                const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Sincronizza recupero e sonno.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (!oura.hasToken)
            ElevatedButton(
              onPressed: () => oura.initiateOAuth(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent.withOpacity(0.2), foregroundColor: Colors.cyanAccent),
              child: const Text('CONNETTI'),
            )
          else
            OutlinedButton(
               onPressed: () => oura.setAccessToken(''),
               child: const Text('DISCONNETTI'),
            )
        ],
      ),
    );
  }

  Widget _buildConnectionCard(BuildContext context, String title, String subtitle, bool isConnected, Function(bool) onToggle, Color color, IconData icon) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      borderColor: isConnected ? color.withOpacity(0.5) : Colors.white10,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isConnected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isConnected ? color : Colors.white24, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: isConnected, 
            onChanged: onToggle,
            activeColor: color,
            activeTrackColor: color.withOpacity(0.3),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.transparent,
          ),
        ],
      ),
    );
  }
}
