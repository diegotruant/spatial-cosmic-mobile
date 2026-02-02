import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/workout_chart.dart';
import '../../../services/physiological_service.dart';
import '../../../services/athlete_profile_service.dart';
import '../../../services/events_service.dart';
import '../../../services/settings_service.dart';
import '../physiological/hrv_measurement_screen.dart';
import '../workout/modern_workout_screen.dart';
import '../settings/settings_screens.dart';
import '../settings/bluetooth_scan_screen.dart';
import '../profile/medical_certificate_screen.dart';
import '../profile/metabolic_calculator_screen.dart';
import '../workout/workout_history_screen.dart';
import '../../../logic/zwo_parser.dart';
import '../../../services/workout_service.dart';
import '../workout/workout_library_screen.dart';
import '../../../l10n/app_localizations.dart';
import '../../../services/sync_service.dart';
import '../../../services/oura_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/integration_service.dart';
import '../../../logic/fit_generator.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/platform_selector.dart';
import '../events/add_event_screen.dart';
import '../../widgets/anaerobic_battery_gauge.dart';
import '../../../models/metabolic_profile.dart';
import '../../../services/w_prime_service.dart';
import 'package:share_plus/share_plus.dart';

class ModernDashboardScreen extends StatefulWidget {
  const ModernDashboardScreen({super.key});

  @override
  State<ModernDashboardScreen> createState() => _ModernDashboardScreenState();
}

class _ModernDashboardScreenState extends State<ModernDashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch Oura Data on startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchOuraData();
    });
  }

  Future<void> _fetchOuraData() async {
    final oura = context.read<OuraService>();
    final physio = context.read<PhysiologicalService>();
    
    if (!oura.hasToken) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connetti Oura nelle impostazioni prima di sincronizzare.'))
      );
      return;
    }

    try {
      final readinessData = await oura.fetchDailyReadiness();
      final sleepData = await oura.fetchDailySleep();
      
      int score = 0;
      if (readinessData != null) {
        score = (readinessData['score'] as num?)?.toInt() ?? 0;
      }
      
      double? rmssd;
      if (sleepData != null) {
        rmssd = (sleepData['average_hrv'] as num?)?.toDouble() ?? (sleepData['hrv_rmssd'] as num?)?.toDouble();
      }

      if (rmssd != null || score > 0) {
        // Fix: Do not default to 45.0 if rmssd is null. 
        // We only update if we have actual data.
        if (rmssd != null && rmssd > 0) {
           final result = await physio.updateFromOura(rmssd, score);
           final isError = result.startsWith('Error') || result.startsWith('DB Error');
           final isWarning = result.contains('Saved Locally');
           
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Sync Oura: $result'), 
               backgroundColor: isError ? Colors.red : (isWarning ? Colors.orange : Colors.green)
              )
           );
        } else {
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Dati Oura incompleti (manca HRV).'))
             );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nessun dato Oura trovato per oggi.'))
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore durante la sincronizzazione Oura: $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: _buildGlowCircle(AppColors.primary.withOpacity(0.15), 300),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildGlowCircle(AppColors.accentPurple.withOpacity(0.1), 250),
          ),
          
          SafeArea(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildHomeTab(context),
                const WorkoutLibraryScreen(isTab: true),
                _buildScheduleTab(),
                _buildProgressTab(), // Lab Tab
                const WorkoutHistoryScreen(),
                _buildSettingsTab(context),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildScheduleTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: context.read<SyncService>().fetchCalendar(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
        }
        
        final workouts = snapshot.data ?? [];
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        
        // Generate list of 7 days starting from today
        final weekDays = List.generate(7, (i) => todayStart.add(Duration(days: i)));

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              AppLocalizations.of(context).get('weekly_calendar') ?? 'CALENDARIO SETTIMANALE', 
              style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)
            ),
            const SizedBox(height: 16),
            
            ...weekDays.map((date) {
              final dayName = _getDayName(date.weekday);
              final dayNum = date.day.toString();
              final isToday = date.isAtSameMomentAs(todayStart);

              // Filter workouts for this specific day
              final dayWorkouts = workouts.where((w) {
                final wDateStr = w['date'] as String? ?? '';
                final wDate = DateTime.tryParse(wDateStr);
                if (wDate == null) return false;
                return wDate.year == date.year && wDate.month == date.month && wDate.day == date.day;
              }).toList();

              if (dayWorkouts.isEmpty) {
                // Return a "Rest Day" or empty placeholder card
                return _buildCalendarItem(
                  dayName: dayName,
                  dayNum: dayNum,
                  title: 'Giorno di Recupero',
                  subtitle: 'Nessun allenamento pianificato',
                  isDone: false,
                  isPlaceholder: true,
                  isToday: isToday,
                );
              }

              return Column(
                children: dayWorkouts.map((w) {
                  final name = w['workout_name'] as String? ?? 'Allenamento';
                  final isDone = w['status'] == 'completed';
                  return _buildCalendarItem(
                    dayName: dayName,
                    dayNum: dayNum,
                    title: name,
                    subtitle: isDone ? 'Completato' : 'In programma',
                    isDone: isDone,
                    isPlaceholder: false,
                    isToday: isToday,
                    onSendToDevice: isDone ? null : () => _sendAssignmentToDevice(w),
                  );
                }).toList(),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildCalendarItem({
    required String dayName,
    required String dayNum,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isPlaceholder,
    required bool isToday,
    VoidCallback? onSendToDevice,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 12,
        borderColor: isToday ? Colors.blueAccent.withOpacity(0.5) : (isDone ? Colors.greenAccent.withOpacity(0.3) : Colors.white10),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: isToday ? Colors.blueAccent.withOpacity(0.2) : (isDone ? Colors.greenAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05)),
                borderRadius: BorderRadius.circular(12),
                border: isToday ? Border.all(color: Colors.blueAccent.withOpacity(0.5)) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dayName, style: TextStyle(color: isToday ? Colors.blueAccent : (isDone ? Colors.greenAccent : Colors.white70), fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(dayNum, style: TextStyle(color: isToday ? Colors.white : (isDone ? Colors.greenAccent : Colors.white), fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title, 
                    style: TextStyle(
                      color: isPlaceholder ? Colors.white38 : Colors.white, 
                      fontWeight: isPlaceholder ? FontWeight.normal : FontWeight.w600, 
                      fontSize: 16
                    )
                  ),
                  Text(
                    subtitle, 
                    style: TextStyle(color: isDone ? Colors.greenAccent : Colors.white38, fontSize: 12)
                  ),
                ],
              ),
            ),
            if (isDone) const Icon(LucideIcons.checkCircle, color: Colors.greenAccent, size: 24),
            if (!isDone && !isPlaceholder) 
              Row(
                children: [
                  if (onSendToDevice != null)
                    IconButton(
                      icon: const Icon(LucideIcons.send, color: Colors.blueAccent, size: 18),
                      onPressed: onSendToDevice,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  const SizedBox(width: 12),
                  const Icon(LucideIcons.chevronRight, color: Colors.white24, size: 20),
                ],
              ),
            if (isPlaceholder) Icon(LucideIcons.coffee, color: Colors.white.withOpacity(0.1), size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _sendAssignmentToDevice(Map<String, dynamic> assignment) async {
    final integrationService = context.read<IntegrationService>();
    final settingsService = context.read<SettingsService>();
    
    // 1. Selection Dialog (Premium Style)
    final platform = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent, 
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
                const CircularProgressIndicator(color: Colors.blueAccent),
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
      final ftp = settingsService.ftp;
      final file = await FitGenerator.generateFromAssignment(assignment, ftp);
      
      bool success = false;
      if (platform == 'wahoo') {
        if (!integrationService.isWahooConnected) {
          if (mounted) Navigator.of(context, rootNavigator: true).pop(); // Close loading
          await integrationService.initiateWahooAuth();
          return;
        }
        success = await integrationService.uploadWorkoutToWahoo(file);
      } else if (platform == 'tp') {
        if (!integrationService.isTPConnected) {
          if (mounted) Navigator.of(context, rootNavigator: true).pop(); // Close loading
          await integrationService.initiateTrainingPeaksAuth();
          return;
        }
        success = await integrationService.uploadWorkoutToTrainingPeaks(file);
      } else if (platform == 'export') {
        if (mounted) Navigator.of(context, rootNavigator: true).pop(); // Close loading
        await Share.shareXFiles([XFile(file.path)], text: 'Allenamento Spatial Cosmic: ${assignment['workout_name']}');
        return; // Success handled by share sheet
      }

      if (mounted) Navigator.of(context, rootNavigator: true).pop(); // Close loading safely

      if (success) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(
               content: Text("🚀 Allenamento inviato correttamente!"),
               backgroundColor: Colors.green,
               behavior: SnackBarBehavior.floating,
             ),
           );
        }
      } else {
         throw "Errore durante l'upload: Verifica la connessione o l'account.";
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Ensure loading is closed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _getDayName(int weekday) {
    const days = ['Lun', 'Mar', 'Mer', 'Gio', 'Ven', 'Sab', 'Dom'];
    return days[(weekday - 1) % 7];
  }

  Widget _buildProgressTab() {
    final profileService = context.watch<AthleteProfileService>();
    final profile = profileService.currentProfile;
    final metabolicProfile = profileService.metabolicProfile;

    // We no longer return an empty screen if ANY data is present.
    // We only show the "No Data" screen if absolutely everything is null.
    if (profile.vlamax == null && profile.vo2max == null && profile.ftp == null && metabolicProfile == null) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
           Text(AppLocalizations.of(context).get('athlete_profile'), style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)),
           const SizedBox(height: 16),
           GlassCard(
             padding: const EdgeInsets.all(32),
             borderRadius: 16,
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 const Icon(LucideIcons.flaskConical, color: Colors.white24, size: 64),
                 const SizedBox(height: 24),
                 const Text("Nessun Dato Metabolic Lab", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 12),
                 Text(
                   "Esegui un test di performance o aspetta che il coach analizzi i tuoi allenamenti per vedere qui il tuo profilo fisiologico (VLamax, VO2max, FTP).",
                   textAlign: TextAlign.center,
                   style: TextStyle(color: Colors.white.withOpacity(0.6), height: 1.5),
                 ),
                 const SizedBox(height: 24),
                 ElevatedButton(
                   onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MetabolicCalculatorScreen()));
                   }, 
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                   child: const Text("CALCOLA PROFILO"),
                 )
               ],
             ),
           )
        ],
      );
    }
    
    Color typeColor;
    IconData typeIcon;
    switch (profile.type) {
      case AthleteType.sprinter:
        typeColor = AppColors.zone5;
        typeIcon = LucideIcons.zap;
        break;
      case AthleteType.climber:
        typeColor = AppColors.zone3;
        typeIcon = LucideIcons.mountain;
        break;
      case AthleteType.timeTrialist:
        typeColor = AppColors.zone2;
        typeIcon = LucideIcons.clock;
        break;
      case AthleteType.allRounder:
        typeColor = AppColors.zone7;
        typeIcon = LucideIcons.target;
        break;
      default:
        typeColor = AppColors.textDim;
        typeIcon = LucideIcons.helpCircle;
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Metabolic Curve Section (Prominent)
        _buildMetabolicCurveSection(profileService),
        const SizedBox(height: 24),

        // Athlete Type Card
        Text(AppLocalizations.of(context).get('athlete_profile'), style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 16,
          borderColor: typeColor.withOpacity(0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(typeIcon, color: typeColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profileService.getTypeLabel(profile.type),
                          style: TextStyle(color: typeColor, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                        ),
                        const SizedBox(height: 4),
                        Text(AppLocalizations.of(context).get('based_on_power_curve'), style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(profile.description, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        // VLamax and VO2max
        Text(AppLocalizations.of(context).get('metabolism'), style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.droplet, color: AppColors.zone6, size: 16),
                        const SizedBox(width: 8),
                        const Text('VLamax', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile.vlamax?.toStringAsFixed(2) ?? '-',
                      style: const TextStyle(color: AppColors.zone6, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    Text('mmol/L/s', style: TextStyle(color: AppColors.zone6.withOpacity(0.6), fontSize: 10)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(LucideIcons.wind, color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        const Text('VO2max', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile.vo2max?.toStringAsFixed(1) ?? '-',
                      style: const TextStyle(color: AppColors.primary, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    Text('ml/kg/min', style: TextStyle(color: AppColors.primary.withOpacity(0.6), fontSize: 10)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // FTP Card
        const Text('POTENZA CRITICA', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('FTP Stimato', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('${profile.ftp?.toInt() ?? '-'} W', style: const TextStyle(color: Colors.cyanAccent, fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('W\' (Battery)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text('${((profile.wPrime ?? 0) / 1000).toStringAsFixed(1)} kJ', style: const TextStyle(color: Colors.orangeAccent, fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        // Training Recommendation
        const Text('RACCOMANDAZIONE', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 12,
          borderColor: Colors.amberAccent.withOpacity(0.2),
          child: Row(
            children: [
              const Icon(LucideIcons.lightbulb, color: Colors.amberAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  profileService.getTrainingRecommendation(),
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const SizedBox(height: 24),
      ],
    );
  }


  Widget _buildMetabolicCurveSection(AthleteProfileService profileService) {
    final metabolicProfile = profileService.metabolicProfile;
    
    if (metabolicProfile == null || metabolicProfile.combustionCurve.isEmpty) {
      // No curve data - show button to calculate
      return GlassCard(
        padding: const EdgeInsets.all(20),
        borderRadius: 16,
        child: Column(
          children: [
            const Icon(LucideIcons.flame, color: Colors.orangeAccent, size: 40),
            const SizedBox(height: 16),
            const Text('CURVA METABOLICA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              'Esegui il calcolo del profilo metabolico per visualizzare la tua curva di utilizzo grassi/carboidrati.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MetabolicCalculatorScreen())),
              icon: const Icon(LucideIcons.calculator, size: 18),
              label: const Text('CALCOLA PROFILO'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }
    
    // Show the curve
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('CURVA METABOLICA', style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.orangeAccent, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 6),
                      const Text('Grassi', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                  Row(
                    children: [
                      Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 6),
                      const Text('Carboidrati', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    ],
                  ),
                  Text('FatMax: ${metabolicProfile.metabolic.fatMaxWatt.toInt()}W', 
                       style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 180,
                child: CustomPaint(
                  size: const Size(double.infinity, 180),
                  painter: _MetabolicCurvePainter(metabolicProfile.combustionCurve),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MetabolicCalculatorScreen())),
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: const Text('Ricalcola'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white54),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }




  Widget _buildSettingsTab(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final profile = context.watch<AthleteProfileService>();
    
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Main Settings
        _buildSettingsRow('Sport:', settings.sport, onTap: () {}),
        _buildSettingsFtpRow('CYCLING FTP', settings.ftp, (val) => settings.setFtp(val)),
        _buildSettingsFtpRow('MAX HEART RATE', settings.hrMax, (val) => settings.setHrMax(val)), // Using FtpRow generic style for number input
        _buildSettingsRow(AppLocalizations.of(context).get('add_devices'), '', isAction: true, icon: Icons.add_circle_outline, onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const BluetoothScanScreen()));
        }),
        
        const SizedBox(height: 24),
        const Divider(color: Colors.white12),
        const SizedBox(height: 16),
        
        // Menu Items
        _buildMenuRow('Altre opzioni', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdvancedOptionsScreen()))),
        _buildMenuRow('Lingua', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LanguageScreen()))),
        _buildMenuRow('Informazioni sull\'account utente', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountInfoScreen()))),
        _buildMenuRow('Connessioni', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ConnectionsScreen()))),

        
        const SizedBox(height: 24),
        const Divider(color: Colors.white12),
        const SizedBox(height: 16),
        
        // Info Section
        _buildSettingsRow('Stato sottoscrizione:', settings.subscriptionStatus, valueColor: AppColors.success),
        
        const SizedBox(height: 32),
        
        // Logout
        GestureDetector(
          onTap: () async {
            await context.read<AuthService>().signOut();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Logged out')));
            }
          },
          child: const Text('Logout/Reset', style: TextStyle(color: AppColors.error, fontSize: 16)),
        ),
      ],
    );
  }
  
  Widget _buildSettingsRow(String label, String value, {bool isAction = false, IconData? icon, Color? valueColor, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 15))),
            if (value.isNotEmpty) Text(value, style: TextStyle(color: valueColor ?? Colors.white54)),
            if (icon != null) Icon(icon, color: Colors.white54, size: 24),
            if (isAction && icon == null) const Icon(LucideIcons.chevronRight, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingsFtpRow(String label, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 15)),
          const SizedBox(width: 8),
          const Icon(LucideIcons.info, color: Colors.white24, size: 16),
          const Spacer(),
          GestureDetector(
            onTap: () => _showNumberInputDialog(context, label, value, onChanged),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$value', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showNumberInputDialog(BuildContext context, String label, int currentValue, Function(int) onSave) {
    final controller = TextEditingController(text: currentValue.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(label, style: const TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 24),
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background.withOpacity(0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              final newValue = int.tryParse(controller.text);
              if (newValue != null) {
                onSave(newValue);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMenuRow(String label, VoidCallback onTap) {
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
  
  void _showAdvancedOptions(BuildContext context, SettingsService settings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Altre opzioni', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 20),
            
            // Toggle Options
            _buildToggleOption('Abilita tempo di recupero autoestendi', 'Continua a pedalare fino a quando non vuoi ferm...', settings.autoExtendRecovery, () => settings.toggleAutoExtendRecovery()),
            _buildToggleOption('Livellamento Potenza', 'Leviga linea potenza nel grafico.', settings.powerSmoothing, () => settings.togglePowerSmoothing()),
            _buildToggleOption('Pressione Breve per Intervallo Successivo', 'Consenti pressione breve per saltare gli intervalli. P...', settings.shortPressNextInterval, () => settings.toggleShortPressNextInterval()),
            _buildToggleOption('Power Match', 'L\'allenatore intelligente corrisponderà alla potenza...', settings.powerMatch, () => settings.togglePowerMatch()),
            _buildToggleOption('Doppia potenza laterale singola', 'Vedi 1/2 della potenza? Accendi questo', settings.doubleSidedPower, () => settings.toggleDoubleSidedPower()),
            _buildToggleOption('Disabilitare Auto-Start/Stop quando il misur...', 'La disabilitazione richiede la pressione del pulsant...', settings.disableAutoStartStop, () => settings.toggleDisableAutoStartStop()),
            _buildToggleOption('Vibrazione', 'Feedback aptico durante l\'interazione con l\'interfa...', settings.vibration, () => settings.toggleVibration()),
            _buildToggleOption('Mostra le zone di potenza', 'Questo mostrerà indicatori colorati se sei dentro o ...', settings.showPowerZones, () => settings.toggleShowPowerZones()),
            _buildToggleOption('Visualizzazione dell\'allenamento in tempo r...', 'Fare clic qui per copiare l\'URL. Fare clic qui per sap...', settings.liveWorkoutView, () => settings.toggleLiveWorkoutView()),
            _buildToggleOption('Modalità Sim/Slope', 'Specifica la tua resistenza usando gli angoli di pen...', settings.simSlopeMode, () => settings.toggleSimSlopeMode()),
            
            _buildMenuRow('Tipo di beep a intervalli: ${settings.intervalBeepType}', () {}),
            
            const SizedBox(height: 24),
            const Divider(color: Colors.white12),
            const SizedBox(height: 16),
            
            // Numeric Settings
            _buildNumericSetting('HR soglia', settings.hrThreshold, (v) => settings.setHrThreshold(v)),
            _buildNumericSetting('Aumento ERG %', settings.ergIncreasePercent, (v) => settings.setErgIncrease(v)),
            _buildNumericSetting('Aumento HR', settings.hrIncrease, (v) => settings.setHrIncrease(v)),
            _buildNumericSetting('Aumento Slope %', settings.slopeIncreasePercent, (v) => settings.setSlopeIncrease(v)),
            _buildNumericSetting('Resistance Inc %', settings.resistanceIncreasePercent, (v) => settings.setResistanceIncrease(v)),
            
            const SizedBox(height: 24),
            const Divider(color: Colors.white12),
            const SizedBox(height: 16),
            
            _buildMenuRow('Valutaci', () {}),
            _buildMenuRow('ContattaCI / Feedback', () {}),
            _buildMenuRow('Termini e condizioni', () {}),
            
            const SizedBox(height: 16),
            Row(
              children: const [
                Text('Versione', style: TextStyle(color: Colors.white54)),
                Spacer(),
                Text('1.0.0', style: TextStyle(color: Colors.white54)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildToggleOption(String title, String subtitle, bool value, VoidCallback onToggle) {
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
  
  Widget _buildNumericSetting(String label, int? value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white))),
          const Icon(LucideIcons.info, color: Colors.white24, size: 16),
          const Spacer(),
          GestureDetector(
            onTap: () => _showNumberInputDialog(context, label, value ?? 0, onChanged),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(value?.toString() ?? '-', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showLanguageSelector(BuildContext context, SettingsService settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lingua', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: settings.languages.length,
              itemBuilder: (_, i) {
                final lang = settings.languages[i];
                final isSelected = lang == settings.language;
                return ListTile(
                  title: Text(lang, style: TextStyle(color: isSelected ? Colors.white : Colors.white70)),
                  trailing: isSelected ? const Icon(Icons.check_circle, color: Colors.blueAccent) : null,
                  tileColor: isSelected ? Colors.blueAccent.withOpacity(0.1) : null,
                  onTap: () {
                    settings.setLanguage(lang);
                    Navigator.pop(ctx);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  void _showAccountInfo(BuildContext context, SettingsService settings) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Informazioni sull\'account utente', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 20),
            _buildAccountRow(
              'Nome utente', 
              settings.username.isEmpty ? '-' : settings.username,
              onTap: () => _showTextInputDialog(context, 'Nome utente', settings.username, (v) => settings.setUsername(v))
            ),
            
            if (settings.coachName != null) ...[
               const SizedBox(height: 12),
               const Text('COACH', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 12)),
               _buildAccountRow('Nome', settings.coachName!),
               if (settings.coachEmail != null) _buildAccountRow('Email', settings.coachEmail!),
               const Divider(color: Colors.white12, height: 24),
            ],

            _buildToggleOption('Unità metriche (km/kg)', 'Spento è miglia/libbre', settings.useMetricUnits, () => settings.toggleMetricUnits()),
            _buildNumericSetting('Peso del pilota', settings.weight, (v) => settings.setWeight(v)),
            _buildNumericSetting('Peso della bicicletta', settings.bikeWeight, (v) => settings.setBikeWeight(v)),
            const SizedBox(height: 20),
          ],
        ),
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
  
  void _showTextInputDialog(BuildContext context, String label, String currentValue, Function(String) onSave) {
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }
  
  void _showConnections(BuildContext context, SettingsService settings) {
    final connections = [
      {'key': 'intervalsIcu', 'name': 'Intervals.icu (Bridge)', 'desc': 'Sincronizza il tuo calendario e invia automaticamente i workout a Garmin, Wahoo e Strava utilizzando Intervals.icu come ponte.', 'color': Colors.redAccent},
    ];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Connessioni', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close, color: Colors.white54), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const SizedBox(height: 20),
            ...connections.map((c) => _buildConnectionCard(
              c['name'] as String, 
              c['desc'] as String, 
              c['color'] as Color,
              settings.connections[c['key']] ?? false,
              () => settings.toggleConnection(c['key'] as String),
            )),
          ],
        ),
      ),
    );
  }
  
  Widget _buildConnectionCard(String name, String desc, Color logoColor, bool isConnected, VoidCallback onTap) {
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
            child: Text(isConnected ? 'Scollega' : 'Collega'),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        _buildMedicalCertificateAlert(context),
        const SizedBox(height: 20),
        _buildHeader(context),
        const SizedBox(height: 24),
        _buildReadinessCard(context),
        const SizedBox(height: 32),
        _buildMainWorkoutCard(),
        const SizedBox(height: 30),
        _buildMetabolicProfile(context),
        const SizedBox(height: 30),
        _buildUpcomingEvents(context),
        const SizedBox(height: 30),
        _buildActionButtons(context),
        const SizedBox(height: 40),
      ],
    );
  }


  Widget _buildMedicalCertificateAlert(BuildContext context) {
    final profile = context.watch<AthleteProfileService>();
    final expiry = profile.certExpiryDate;
    
    // If no date set, maybe show a reminder? Or silent? 
    // User asked for alerts when expiring. 
    if (expiry == null) return const SizedBox.shrink(); 

    final daysRemaining = expiry.difference(DateTime.now()).inDays;
    
    // Only show if < 30 days
    if (daysRemaining > 30) return const SizedBox.shrink();

    String message = "";
    Color color = Colors.orangeAccent;
    IconData icon = LucideIcons.alertTriangle;

    if (daysRemaining < 0) {
      final days = daysRemaining.abs();
      message = "CERTIFICATO MEDICO SCADUTO DA $days GIORNI";
      color = AppColors.error;
      icon = LucideIcons.alertOctagon;
    } else if (daysRemaining < 7) {
       message = "Certificato in scadenza tra $daysRemaining giorni";
       color = AppColors.error;
    } else {
       message = "Certificato in scadenza tra $daysRemaining giorni";
       color = AppColors.warning;
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicalCertificateScreen())),
      child: Container(
        margin: const EdgeInsets.only(top: 20, bottom: 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13))),
            Icon(LucideIcons.chevronRight, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 50,
          )
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.network(
                  'https://raw.githubusercontent.com/diegotruant/spatial-cosmic/main/assets/logo.png', // Placeholder URL
                  height: 30,
                  errorBuilder: (context, error, stackTrace) => const Icon(LucideIcons.zap, color: Colors.cyanAccent, size: 30),
                ),
                const SizedBox(width: 8),
                const Text(
                  'CYCLING COACH',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome back, Diego',
              style: AppTextStyles.body,
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HrvMeasurementScreen()),
            );
          },
          child: const CircleAvatar(
            backgroundColor: Colors.white10,
            child: Icon(LucideIcons.activity, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildReadinessCard(BuildContext context) {
    final physiological = context.watch<PhysiologicalService>();
    final lastHrv = physiological.history.isNotEmpty ? physiological.history.first : null;
    
    final analysis = lastHrv != null 
        ? physiological.analyzeHRV(lastHrv.rmssd, ouraScore: lastHrv.ouraScore) 
        : null;

    Color statusColor;
    String statusTitle;
    IconData statusIcon;

    if (analysis == null) {
      statusColor = Colors.white24;
      statusTitle = 'MEASURE HRV';
      statusIcon = LucideIcons.activity;
    } else {
      switch (analysis.status) {
        case ReadinessStatus.green:
          statusColor = AppColors.success;
          statusTitle = 'PRONTO AL TEST';
          statusIcon = LucideIcons.checkCircle2;
          break;
        case ReadinessStatus.yellow:
          statusColor = AppColors.warning;
          statusTitle = 'ATTENZIONE';
          statusIcon = LucideIcons.alertTriangle;
          break;
        case ReadinessStatus.red:
          statusColor = AppColors.error;
          statusTitle = 'RECUPERO';
          statusIcon = LucideIcons.xCircle;
          break;
      }
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 16,
      borderColor: statusColor.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1.1,
                      ),
                    ),
                    if (lastHrv != null && lastHrv.averageHR == 0)
                      Text(
                        'SINCRONIZZATO DA OURA',
                        style: TextStyle(color: Colors.blueAccent.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
              if (lastHrv != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${lastHrv.rmssd.toStringAsFixed(0)} ms',
                      style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'rMSSD',
                      style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            analysis?.recommendation ?? 'Misura l\'HRV o sincronizza Oura per vedere i suggerimenti di oggi.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              height: 1.4,
              fontStyle: analysis == null ? FontStyle.italic : FontStyle.normal,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Spacer(),
              Consumer<OuraService>(
                builder: (context, oura, _) => ElevatedButton.icon(
                  onPressed: oura.isLoading ? null : _fetchOuraData,
                  icon: oura.isLoading 
                    ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent))
                    : const Icon(LucideIcons.refreshCw, size: 14),
                  label: Text(
                    oura.isLoading ? 'SYNCING...' : 'SYNC OURA', 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent.withOpacity(0.1),
                    foregroundColor: Colors.blueAccent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.blueAccent.withOpacity(0.3)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HrvMeasurementScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor.withOpacity(0.1),
                  foregroundColor: statusColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: statusColor.withOpacity(0.5)),
                  ),
                ),
                child: const Text('DETTAGLI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWPrimeCard(BuildContext context) {
    return Consumer<WPrimeService>(
      builder: (context, wPrime, _) {
        // Only show if maxWPrime is configured (meaning profile is set)
        if (wPrime.maxWPrime <= 0) return const SizedBox.shrink();

        return GlassCard(
          padding: const EdgeInsets.all(20),
          borderRadius: 16,
          // Change border color based on depletion status
          borderColor: wPrime.isDepleting ? Colors.orangeAccent.withOpacity(0.5) : Colors.greenAccent.withOpacity(0.3),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("ANAEROBIC BATTERY (W')", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Icon(LucideIcons.batteryCharging, color: wPrime.isDepleting ? Colors.orangeAccent : Colors.greenAccent, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              AnaerobicBatteryGauge(
                currentWPrime: wPrime.currentWPrime, 
                maxWPrime: wPrime.maxWPrime, 
                isDepleting: wPrime.isDepleting
              ),
              const SizedBox(height: 8),
              Text(
                "${(wPrime.currentWPrime / 1000).toStringAsFixed(1)} kJ / ${(wPrime.maxWPrime / 1000).toStringAsFixed(1)} kJ",
                style: const TextStyle(color: Colors.white54, fontSize: 12, fontFamily: 'monospace'),
              ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildAprCalculatorButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MetabolicCalculatorScreen())),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.calculator, color: Colors.purpleAccent, size: 24),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("CALCOLO APR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("Configura Profilo Metabolico", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Icon(LucideIcons.chevronRight, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainWorkoutCard() {
    return Consumer<SyncService>(
      builder: (context, sync, child) {
        return FutureBuilder<Map<String, dynamic>?>(
          future: sync.fetchTodayWorkout(),
          builder: (context, snapshot) {
            
            if (snapshot.connectionState == ConnectionState.waiting) {
               return GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
               );
            }

            final workoutData = snapshot.data;
            
            if (workoutData == null) {
              return GlassCard(
                borderColor: Colors.white10,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(LucideIcons.calendarCheck, size: 48, color: Colors.white24),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).get('no_workout_today') ?? 'Nessun workout oggi',
                      style: const TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            // Parse Workout Data
            // Assuming 'workout_data' column exists and contains ZWO/XML or JSON.
            // If strictly ZWO string:
            final rawData = workoutData['workout_data'] as String?;
            final workoutId = workoutData['id'] as String;
            final workoutName = workoutData['workout_name'] as String?; // Get name from database
            
            WorkoutWorkout? workout;
            int duration = 0;
            int targetPower = 0;
            String timeStr = "--:--";
            
            // 1. Try Parsing ZWO (String) - pass workoutName as title override
            if (rawData != null && rawData.isNotEmpty) {
               try {
                 workout = ZwoParser.parse(rawData, titleOverride: workoutName);
               } catch (e) {
                 debugPrint("Error parsing ZWO XML: $e");
               }
            }

            // 2. Fallback: Parse JSON Structure (already uses workout_name)
            if (workout == null || workout.blocks.isEmpty) {
               try {
                 workout = ZwoParser.parseJson(workoutData);
               } catch (e) {
                 debugPrint("Error parsing JSON structure: $e");
               }
            }

            // 3. Calculate Stats if workout exists
            if (workout != null && workout.blocks.isNotEmpty) {
                 final settings = context.read<SettingsService>();
                 final stats = ZwoParser.getStats(workout, settings.ftp);
                 duration = stats['duration'];
                 targetPower = stats['targetPower'];
                 
                 final minutes = duration ~/ 60;
                 final seconds = duration % 60;
                 timeStr = '$minutes:${seconds.toString().padLeft(2, '0')}';
            }

            return GlassCard(
              borderColor: Colors.blueAccent.withOpacity(0.3),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Today's Workout",
                        style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.calendarClock, color: Colors.white70),
                        onPressed: () => _showRescheduleDialog(context, workoutId),
                        tooltip: 'Sposta Workout',
                      )
                    ],
                  ),

                  const SizedBox(height: 12),
                  WorkoutChart(workout: workout),
                  const SizedBox(height: 16),
                  
                  if (workout != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${targetPower}W',
                            style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 32, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'TARGET POWER',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, letterSpacing: 1.2),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            timeStr,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.normal),
                          ),
                          Text(
                            'TOTAL TIME',
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, letterSpacing: 1.2),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: workout != null ? () {
                         final settings = context.read<SettingsService>();
                         context.read<WorkoutService>().startWorkout(workout!, ftp: settings.ftp);
                         Navigator.push(context, MaterialPageRoute(builder: (_) => const ModernWorkoutScreen()));
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.white10,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 8,
                        shadowColor: Colors.blueAccent.withOpacity(0.5),
                      ),
                      child: Text(workout != null ? 'INIZIA ALLENAMENTO' : 'DATI MANCANTI', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showRescheduleDialog(BuildContext context, String workoutId) async {
    final now = DateTime.now();
    final newDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
               primary: Colors.blueAccent,
               onPrimary: Colors.white,
               surface: Color(0xFF1A1A2E),
               onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newDate != null && context.mounted) {
      try {
        await context.read<SyncService>().rescheduleWorkout(workoutId, newDate);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout spostato con successo')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => setState(() => _currentIndex = 1), // Switch to Library Tab
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent.withOpacity(0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.purpleAccent.withOpacity(0.5)),
              ),
            ),
            child: Column(
              children: const [
                Icon(LucideIcons.library, color: Colors.purpleAccent),
                SizedBox(height: 4),
                Text('TEST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
               // Start Free Ride (1 Hour default, extendable)
               final settings = context.read<SettingsService>();
               final freeRide = WorkoutWorkout(
                  title: 'PEDALATA LIBERA',
                  blocks: [
                  SteadyState(duration: 3600 * 24, power: 1.0) // 1.0 = 100% FTP
               ]);
               
               context.read<WorkoutService>().startWorkout(freeRide, ftp: settings.ftp);
               Navigator.push(context, MaterialPageRoute(builder: (_) => const ModernWorkoutScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent.withOpacity(0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.greenAccent.withOpacity(0.5)),
              ),
            ),
            child: Column(
              children: const [
                 Icon(LucideIcons.bike, color: Colors.greenAccent),
                 SizedBox(height: 4),
                 Text('GIRO LIBERO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => const MetabolicCalculatorScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent.withOpacity(0.2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.cyanAccent.withOpacity(0.5)),
              ),
            ),
            child: Column(
              children: const [
                 const Icon(LucideIcons.flaskConical, color: Colors.cyanAccent),
                 const SizedBox(height: 4),
                 const Text('METABOLIC LAB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: [
        _buildMetricItem(LucideIcons.activity, 'Heart Rate', '142 BPM', Colors.redAccent),
        _buildMetricItem(LucideIcons.repeat, 'Cadence', '92 RPM', Colors.greenAccent),
        _buildMetricItem(LucideIcons.zap, 'Avg Power', '224 W', Colors.orangeAccent),
        _buildMetricItem(LucideIcons.flame, 'Calories', '842 kCal', Colors.deepOrange),
      ],
    );
  }

  Widget _buildMetricItem(IconData icon, String label, String value, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color.withOpacity(0.8), size: 20),
          const SizedBox(height: 12),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.black,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.white24,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: [
          BottomNavigationBarItem(icon: const Icon(LucideIcons.layoutDashboard), label: 'Home'),
          BottomNavigationBarItem(icon: const Icon(LucideIcons.library), label: 'Test'),
          BottomNavigationBarItem(icon: const Icon(LucideIcons.calendar), label: 'Schedule'),
          BottomNavigationBarItem(icon: const Icon(LucideIcons.flaskConical), label: 'Metabolic Lab'), 
          BottomNavigationBarItem(icon: const Icon(LucideIcons.history), label: 'History'),
          BottomNavigationBarItem(icon: const Icon(LucideIcons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildMetabolicProfile(BuildContext context) {
    final profileService = context.watch<AthleteProfileService>();
    final profile = profileService.currentProfile;
    final vlamax = profile.vlamax;
    final vo2max = profile.vo2max;
    final metabolicProfile = profileService.metabolicProfile;
    
    // Map profile type to Italian labels
    String typeLabel = profileService.getTypeLabel(profile.type);

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'METABOLIC LAB',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                ),
                child: Text(
                  typeLabel,
                  style: const TextStyle(
                      color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetabolicMetric(
                  'VLamax',
                  vlamax?.toStringAsFixed(3) ?? '-',
                  'mmol/L/s',
                  Colors.orangeAccent,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white10),
              Expanded(
                child: _buildMetabolicMetric(
                  'VO2max',
                  vo2max?.toStringAsFixed(1) ?? '-',
                  'mL/min/kg',
                  Colors.blueAccent,
                ),
              ),
            ],
          ),
          
          if (metabolicProfile != null) ...[
            const SizedBox(height: 24),
            _buildMetabolicCurveSection(profileService),
          ],
        ],
      ),
    );
  }

  Widget _buildMetabolicMetric(String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(unit, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
      ],
    );
  }

  Widget _buildUpcomingEvents(BuildContext context) {
    return Consumer<EventsService>(
      builder: (context, eventsService, _) {
        final upcoming = eventsService.upcomingEvents;
        // Take top 3
        final displayEvents = upcoming.take(3).toList();
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 const Text(
                    'PROSSIMI EVENTI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.plus, color: AppColors.primary, size: 20),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEventScreen()));
                    },
                  )
              ],
            ),
            const SizedBox(height: 8),
            if (displayEvents.isEmpty)
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(LucideIcons.calendar, color: Colors.white24),
                    const SizedBox(width: 12),
                    const Text("Nessun evento in programma.", style: TextStyle(color: Colors.white54)),
                  ],
                ),
              )
            else
              ...displayEvents.map((e) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getEventColor(e.type).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                           Text(e.date.day.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                           Text(_getMonthName(e.date.month), style: const TextStyle(color: Colors.white54, fontSize: 10)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.type.name.toUpperCase(), style: TextStyle(color: _getEventColor(e.type), fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(e.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          if (e.description != null && e.description!.isNotEmpty)
                            Text(e.description!, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    )
                  ],
                ),
              )).toList(),
          ],
        );
      }
    );
  }
  
  Color _getEventColor(EventType type) {
    switch(type) {
      case EventType.race: return AppColors.primary;
      case EventType.test: return Colors.purpleAccent;
      case EventType.objective: return Colors.greenAccent;
      default: return Colors.blueAccent;
    }
  }
  
  String _getMonthName(int month) {
    const months = ['GEN', 'FEB', 'MAR', 'APR', 'MAG', 'GIU', 'LUG', 'AGO', 'SET', 'OTT', 'NOV', 'DIC'];
    return months[month - 1];
  }
}

/// Custom painter for metabolic curve (fat/carb oxidation)
class _MetabolicCurvePainter extends CustomPainter {
  final List<CombustionData> data;
  
  _MetabolicCurvePainter(this.data);
  
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    
    final fatPaint = Paint()
      ..color = Colors.orangeAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    
    final carbPaint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    
    final fatFillPaint = Paint()
      ..color = Colors.orangeAccent.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    
    final carbFillPaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    
    // Find max values for scaling
    final maxWatt = data.map((d) => d.watt).reduce((a, b) => a > b ? a : b);
    final maxOxidation = data.map((d) => d.fatOxidation > d.carbOxidation ? d.fatOxidation : d.carbOxidation)
        .reduce((a, b) => a > b ? a : b);
    
    if (maxWatt == 0 || maxOxidation == 0) return;
    
    // Build paths
    final fatPath = Path();
    final carbPath = Path();
    final fatFillPath = Path();
    final carbFillPath = Path();
    
    fatFillPath.moveTo(0, size.height);
    carbFillPath.moveTo(0, size.height);
    
    for (int i = 0; i < data.length; i++) {
      final x = (data[i].watt / maxWatt) * size.width;
      final fatY = size.height - (data[i].fatOxidation / maxOxidation) * size.height * 0.9;
      final carbY = size.height - (data[i].carbOxidation / maxOxidation) * size.height * 0.9;
      
      if (i == 0) {
        fatPath.moveTo(x, fatY);
        carbPath.moveTo(x, carbY);
        fatFillPath.lineTo(x, fatY);
        carbFillPath.lineTo(x, carbY);
      } else {
        fatPath.lineTo(x, fatY);
        carbPath.lineTo(x, carbY);
        fatFillPath.lineTo(x, fatY);
        carbFillPath.lineTo(x, carbY);
      }
    }
    
    // Close fill paths
    final lastX = (data.last.watt / maxWatt) * size.width;
    fatFillPath.lineTo(lastX, size.height);
    fatFillPath.close();
    carbFillPath.lineTo(lastX, size.height);
    carbFillPath.close();
    
    // Draw fills first
    canvas.drawPath(fatFillPath, fatFillPaint);
    canvas.drawPath(carbFillPath, carbFillPaint);
    
    // Draw lines on top
    canvas.drawPath(fatPath, fatPaint);
    canvas.drawPath(carbPath, carbPaint);
    
    // Draw axis labels
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    
    // X-axis: 0W ... maxW
    textPainter.text = TextSpan(text: '0W', style: TextStyle(color: Colors.white38, fontSize: 9));
    textPainter.layout();
    textPainter.paint(canvas, Offset(2, size.height - 12));
    
    textPainter.text = TextSpan(text: '${maxWatt.toInt()}W', style: TextStyle(color: Colors.white38, fontSize: 9));
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width - textPainter.width - 2, size.height - 12));
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
