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
import '../profile/metabolic_calculator_screen.dart';

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
            activeColor: Colors.blueAccent,
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
            activeColor: Colors.blueAccent,
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
    final settings = context.watch<SettingsService>();
    final l10n = AppLocalizations.of(context);
    
    final connections = [
      {'key': 'strava', 'name': 'STRAVA', 'descKey': 'strava_desc', 'color': Colors.orange},
    ];
    
    final integration = context.watch<IntegrationService>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(l10n.get('connections'), style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Consumer2<IntegrationService, OuraService>(
          builder: (context, integration, oura, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildOuraSection(context, oura, l10n),
              const SizedBox(height: 16),
              _buildConnectionCard(context, l10n, 'Strava', 'Sincronizza attività e percorsi.', Colors.orangeAccent, integration.isStravaConnected, () {
                if (integration.isStravaConnected) {
                  integration.disconnectStrava();
                } else {
                  integration.initiateStravaAuth();
                }
              }),
              const SizedBox(height: 24),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),
              const Text(
                'NOTA: Garmin Connect non è più supportato direttamente. Utilizza "Esporta per Outdoor" dal calendario per caricare l\'allenamento sul tuo dispositivo Garmin via USB.',
                style: TextStyle(color: Colors.white38, fontSize: 11, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOuraSection(BuildContext context, OuraService oura, AppLocalizations l10n) {
    final tokenController = TextEditingController();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Oura Ring', style: TextStyle(color: Colors.cyanAccent, fontSize: 22, fontWeight: FontWeight.bold)),
              if (oura.hasToken)
                const Icon(Icons.check_circle, color: Colors.greenAccent, size: 24),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Sincronizza rMSSD e Readiness per ottimizzare i tuoi allenamenti.',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (!oura.hasToken) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => oura.initiateOAuth(),
                icon: const Icon(Icons.open_in_browser),
                label: const Text('CONNETTI CON OURA (Auto)', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent.withOpacity(0.1),
                  foregroundColor: Colors.cyanAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Colors.cyanAccent)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(child: Text('oppure inserisci il token manualmente:', style: TextStyle(color: Colors.white38, fontSize: 11))),
            const SizedBox(height: 12),
            TextField(
              controller: tokenController,
              decoration: _inputDecoration('Personal Access Token (PAT)'),
              obscureText: true,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => launchUrl(Uri.parse('https://cloud.ouraring.com/personal-access-tokens')),
              child: const Text('Genera un PAT sul sito Oura', style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (tokenController.text.isNotEmpty) {
                    await oura.setAccessToken(tokenController.text);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Token salvato correttamente!')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white12, foregroundColor: Colors.white),
                child: const Text('SALVA TOKEN MANUALE'),
              ),
            ),
          ] else ...[
             Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                   const Icon(Icons.link, color: Colors.greenAccent),
                   const SizedBox(width: 12),
                   Expanded(
                     child: const Text(
                       'Oura Collegato Correttamente', 
                       style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)
                     ),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => oura.setAccessToken(''),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                foregroundColor: Colors.white54,
                side: const BorderSide(color: Colors.white24),
              ),
              child: const Text('DISCONNETTI'),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.black.withOpacity(0.3),
              child: Text(
                'DEBUG LOG: ${oura.lastLog}',
                style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIntervalsSection(BuildContext context, IntervalsService intervals, AppLocalizations l10n) {
    final idController = TextEditingController(text: intervals.athleteId);
    final keyController = TextEditingController(text: intervals.apiKey);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Intervals.icu', style: TextStyle(color: Colors.redAccent, fontSize: 22, fontWeight: FontWeight.bold)),
              if (intervals.isConnected)
                const Icon(Icons.check_circle, color: Colors.greenAccent, size: 24),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Collega il tuo account per sincronizzare wellness, pianificazione e storico attività.',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
          ),
          const SizedBox(height: 20),
          if (!intervals.isConnected) ...[
            TextField(
              controller: idController,
              decoration: _inputDecoration('Athlete ID (es. i12345)'),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyController,
              decoration: _inputDecoration('API Key'),
              obscureText: true,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => launchUrl(Uri.parse('https://intervals.icu/settings')),
              child: const Text('Trova ID e API Key nelle impostazioni di Intervals.icu', style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: intervals.isLoading ? null : () async {
                  final success = await intervals.connect(idController.text, keyController.text);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connesso con successo!')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Errore di connessione. Controlla ID e Key.')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: intervals.isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('CONNETTI', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.greenAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.link, color: Colors.greenAccent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: const Text(
                      'Account Collegato Correttamente', 
                      style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => intervals.disconnect(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 40),
                foregroundColor: Colors.white54,
                side: const BorderSide(color: Colors.white24),
              ),
              child: const Text('DISCONNETTI'),
            ),
          ],
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38),
      filled: true,
      fillColor: Colors.black26,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
  
  Widget _buildConnectionCard(BuildContext context, AppLocalizations l10n, String name, String desc, Color logoColor, bool isConnected, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: TextStyle(color: logoColor, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(desc, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: isConnected ? Colors.grey.shade800 : Colors.redAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(isConnected ? l10n.get('disconnect') : l10n.get('connect')),
          ),
        ],
      ),
    );
  }
}
