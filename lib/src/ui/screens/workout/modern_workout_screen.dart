import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../services/bluetooth_service.dart';
import '../../../services/workout_service.dart';
import '../../../services/settings_service.dart';
import '../../widgets/big_metric_tile.dart'; // NEW
import '../../widgets/live_workout_chart.dart';
import '../../../logic/zwo_parser.dart';
import '../../widgets/glass_card.dart';
import '../settings/bluetooth_scan_screen.dart' as com_bluetooth;
import '../settings/settings_screens.dart' as com_settings;
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../logic/fit_generator.dart';
import 'post_workout_analysis_screen.dart';
import '../../../services/athlete_profile_service.dart' as src_profile;
import '../../../services/w_prime_service.dart';

class ModernWorkoutScreen extends StatefulWidget {
  const ModernWorkoutScreen({super.key});

  @override
  State<ModernWorkoutScreen> createState() => _ModernWorkoutScreenState();
}

class _ModernWorkoutScreenState extends State<ModernWorkoutScreen> {
  final int _intensity = 100;
  bool _isChartZoomed = false; // Zoom state
  bool _showPercentHr = false;
  final bool _showAvgPower = false;
  // New Interactive States
  bool _showRemainingTime = false;
  bool _showPercentPower = false;
  bool _showTotalRemainingTime = false; // New state for Total Time
  
  Color _getZoneColor(int watts, int ftp) {
    if (ftp <= 0) return Colors.cyanAccent;
    double p = watts / ftp;
    
    if (p < 0.55) return Colors.grey; // Z1 (Active Recovery)
    if (p < 0.75) return Colors.blueAccent; // Z2 (Endurance)
    if (p < 0.90) return Colors.greenAccent; // Z3 (Tempo)
    if (p < 1.05) return Colors.yellowAccent; // Z4 (Threshold)
    if (p < 1.20) return Colors.orangeAccent; // Z5 (VO2 Max)
    return Colors.redAccent; // Z6 (Anaerobic)
  }

  @override
  void initState() {
    super.initState();
    // Force Landscape
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    WakelockPlus.enable(); // Keep screen on
  }

  @override
  void dispose() {
    // Reset Orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    WakelockPlus.disable(); // Allow screen off
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bluetooth = context.watch<BluetoothService>();
    final workoutService = context.watch<WorkoutService>();
    
    // Formatting time
    String formatTime(int totalSeconds) {
      int minutes = totalSeconds ~/ 60;
      int seconds = totalSeconds % 60;
      return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
    }

    return PopScope(
      canPop: true, // Allow pop, but we intercept to show snackbar? No, just allow pop is fine for minimize.
      onPopInvoked: (didPop) {
         if (didPop) {
             // System Back Pressed -> Minimize
             // We can't show SnackBar here easily as context might be unmounted, 
             // but logic keeps running.
         }
      },
      child: Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Subtle background glow
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.05),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.blueAccent.withOpacity(0.1), blurRadius: 150, spreadRadius: 50)
                ],
              ),
            ),
          ),
          
          SafeArea(
              bottom: false, // Let controls go to bottom
              child: Row(
                  children: [
                      // Main Content (Metrics + Chart)
                      Expanded(
                          child: Padding(
                              padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4), 
                              child: Column(
                                children: [
                                  _buildTopBar(),
                                  Expanded(child: _buildLandscapeLayout(bluetooth, workoutService, formatTime)),
                                ],
                              ),
                          ),
                      ),
                      // Vertical Controls
                      _buildVerticalControlBar(workoutService),
                  ],
              ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildLandscapeLayout(BluetoothService bluetooth, WorkoutService workoutService, String Function(int) formatTime) {
    // Landscape: Left Panel (Metrics) + Right Panel (Chart)
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left Side: Metrics Panel
        Expanded(
          flex: 4, // 40% width
          child: Column(
            children: [
              // Row 1: Timers
              Expanded(
                flex: 12, // Ratio 1.2
                child: Row(
                  children: [
                     Expanded(child: _buildIntervalTimer(workoutService, formatTime)),
                     const SizedBox(width: 8),
                     Expanded(child: _buildTotalTimeTile(workoutService, formatTime)),
                     const SizedBox(width: 8),
                     Expanded(child: _buildNextStep(workoutService, formatTime)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              
              // Row 2: MAIN POWER & TARGET
              Expanded(
                 flex: 20, // Ratio 2.0
                 child: Row(
                    children: [
                       Expanded(child: _buildMainPowerTile(workoutService)),
                       const SizedBox(width: 8),
                       Expanded(child: _buildTargetPowerTile(workoutService)),
                    ],
                 )
              ),
              const SizedBox(height: 8),
              
              // Row 3: Secondary Metrics (SCROLLABLE)
              Expanded(
                flex: 12, // Ratio 1.2

                child: PageView(
                  children: [
                    // Page 1: Standard
                    Row(
                       children: [
                          Expanded(child: _buildHeartRateTile(bluetooth)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildCadenceTile(bluetooth)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildWPrimeTile(context.watch<WPrimeService>())),
                       ]
                    ),
                    // Page 2: Extended Stats
                    Row(
                       children: [
                          Expanded(child: _buildSpeedDistTile(workoutService)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildBalanceTile(bluetooth)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildCoreTempTile(bluetooth)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildNpTile(workoutService)),
                       ]
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Right Side: Advanced Graph
        Expanded(
          flex: 6, // 60% width
          child: _buildChartWithControls(),
        ),
      ],
    );
  }

  Widget _buildPortraitLayout(BluetoothService bluetooth, WorkoutService workoutService, String Function(int) formatTime) {
    return Column(
      children: [
        // Top: Chart
        SizedBox(
          height: 250, // Fixed height for chart in portrait
          child: _buildChartWithControls(),
        ),
        const SizedBox(height: 12),
        
        // Bottom: Metrics Grid (Custom Column/Row for better control)
        Expanded(
           child: Column(
              children: [
                 // Row 1: Timers
                 Expanded(
                    flex: 1,
                    child: Row(
                       children: [
                          Expanded(child: _buildIntervalTimer(workoutService, formatTime)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildTotalTimeTile(workoutService, formatTime)),
                       ],
                    ),
                 ),
                 const SizedBox(height: 8),
                 // Row 2: MAIN POWER
                 Expanded(
                    flex: 2, // Huge
                    child: Row(
                       children: [
                          Expanded(child: _buildPowerAndTargetSplit(workoutService)), // Split or just Power? Let's do Split 
                       ],
                    ),
                 ),
                 const SizedBox(height: 8),
                 // Row 3: Secondary (SCROLLABLE)
                 Expanded(
                    flex: 1,
                    child: PageView(
                       children: [
                          Row(
                             children: [
                                Expanded(child: _buildHeartRateTile(bluetooth)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildCadenceTile(bluetooth)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildNextStep(workoutService, formatTime)),
                             ],
                          ),
                          Row(
                             children: [
                                Expanded(child: _buildWPrimeTile(context.watch<WPrimeService>())),
                                const SizedBox(width: 8),
                                Expanded(child: _buildSpeedDistTile(workoutService)),
                                const SizedBox(width: 8),
                                Expanded(child: _buildCoreTempTile(bluetooth)),
                             ],
                          ),
                          // Optional Page 3 for Balance if needed
                          Row(
                             children: [
                                Expanded(child: _buildBalanceTile(bluetooth)),
                                const SizedBox(width: 8),
                                const Spacer(flex: 2), 
                             ],
                          )
                       ],
                    ),
                 ),
                 // Row 4: Extra if space permits? Or merge into others.
                 // Let's keep it simple for now to match TrainerDay look
              ],
           ),
        ),
      ],
    );
  }

  // --- Helper Builders for Tiles ---

  Widget _buildIntervalTimer(WorkoutService service, String Function(int) formatTime) {
      return GestureDetector(
        onTap: () => setState(() => _showRemainingTime = !_showRemainingTime),
        child: BigMetricTile(
          label: _showRemainingTime ? 'INT REM' : 'INTERVAL', 
          value: _showRemainingTime 
             ? (service.currentWorkout != null && service.currentBlockIndex < service.currentWorkout!.blocks.length
                 ? formatTime(service.currentWorkout!.blocks[service.currentBlockIndex].duration - service.elapsedInBlock)
                 : '-')
             : formatTime(service.elapsedInBlock), 
          unit: '',
          accentColor: Colors.blueAccent,
          isHuge: false,
          labelFontSize: 9.0,
        ),
      );
  }

  Widget _buildTotalTimeTile(WorkoutService service, String Function(int) formatTime) {
      return GestureDetector(
        onTap: () => setState(() => _showTotalRemainingTime = !_showTotalRemainingTime),
        child: BigMetricTile(
          label: _showTotalRemainingTime ? 'TOT REM' : 'TOT.TIME', 
          value: _showTotalRemainingTime
              ? formatTime(_calculateTotalDuration(service) - service.totalElapsed)
              : formatTime(service.totalElapsed),
          unit: '',
          accentColor: Colors.grey,
          isHuge: false,
          labelFontSize: 9.0,
        ),
      );
  }

  Widget _buildNextStep(WorkoutService service, String Function(int) formatTime) {
     final blocks = service.currentWorkout?.blocks;
     if (blocks == null || service.currentBlockIndex >= blocks.length - 1) {
        return const BigMetricTile(label: 'NEXT', value: 'FINISH', unit: '', accentColor: Colors.grey);
     }
     final nextBlock = blocks[service.currentBlockIndex + 1];
     Color zoneColor = _calculateBlockColor(nextBlock, service.userFtp);
     
     return BigMetricTile(
        label: 'NEXT STEP',
        value: formatTime(nextBlock.duration),
        unit: '', 
        accentColor: zoneColor,
        valueColor: zoneColor,
        labelFontSize: 9.0,
     );
  }

  Widget _buildMainPowerTile(WorkoutService service) {
     final currentWatts = service.currentPower.toInt(); // Use Live Property
     final color = _getZoneColor(currentWatts, service.userFtp);
     
     return GestureDetector(
        onTap: () => setState(() => _showPercentPower = !_showPercentPower),
        child: BigMetricTile(
           label: _showPercentPower ? 'POWER %' : 'POWER',
           value: _showPercentPower 
              ? (service.userFtp > 0 ? ((currentWatts / service.userFtp) * 100).toStringAsFixed(0) : '-')
              : currentWatts.toString(),
           unit: _showPercentPower ? '%' : 'W',
           accentColor: color,
           valueColor: color,
           isHuge: true,
        ),
     );
  }

  Widget _buildTargetPowerTile(WorkoutService service) {
     return BigMetricTile(
        label: 'TARGET',
        value: service.currentTargetWatts.toString(),
        unit: 'W',
        accentColor: Colors.white,
        isHuge: true,
     );
  }
  
  Widget _buildPowerAndTargetSplit(WorkoutService service) {
      // For Portrait: Combine Power and Target side-by-side in one huge row
      return Row(
          children: [
              Expanded(child: _buildMainPowerTile(service)),
              const SizedBox(width: 8),
              Expanded(child: _buildTargetPowerTile(service)),
          ],
      );
  }

  Widget _buildHeartRateTile(BluetoothService bt) {
     return GestureDetector(
        onTap: () => setState(() => _showPercentHr = !_showPercentHr),
        child: BigMetricTile(
           label: _showPercentHr ? 'HR %' : 'HR',
           value: _showPercentHr 
              ? (context.read<SettingsService>().hrMax > 0 && bt.heartRate > 0 ? ((bt.heartRate / context.read<SettingsService>().hrMax) * 100).toInt().toString() : '-') 
              : bt.heartRate > 0 ? bt.heartRate.toString() : '-',
           unit: _showPercentHr ? '%' : 'BPM',
           accentColor: Colors.redAccent,
        )
     );
  }

  Widget _buildCadenceTile(BluetoothService bt) {
      return BigMetricTile(
          label: 'CAD',
          value: bt.cadence > 0 ? bt.cadence.toString() : '-',
          unit: 'RPM',
          accentColor: Colors.greenAccent
      );
  }

  Widget _buildWPrimeTile(WPrimeService wPrime) {
      return BigMetricTile(
          label: 'W\' BAL',
          value: (wPrime.currentWPrime / 1000).toStringAsFixed(1),
          unit: 'kJ',
          accentColor: wPrime.isDepleting ? Colors.orangeAccent : Colors.purpleAccent,
      );
  }
  
  // Reusing intensity logic but wrapping in tile if needed, or just regular widget?
  // Let's make a custom tile that creates the intensity UI inside
  Widget _buildIntensityControlTile(WorkoutService service) {
      // We can wrap the existing intensity control
      // But for the tile layout, maybe just display Intensity % ?
      // Let's use the BigMetricTile to show the % and onTap opens the control?
      // Or just put the control widget directly in the row.
      return Container(
         padding: const EdgeInsets.all(8),
         decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
         ),
         child: _buildIntensityControl(), // Reusing existing method
      );
  }

  // --- Helpers ---
  int _calculateTotalDuration(WorkoutService service) {
    int total = 0;
    if (service.currentWorkout != null) {
      for (var b in service.currentWorkout!.blocks) {
        total += b.duration;
      }
    }
    return total;
  }

  Color _calculateBlockColor(dynamic block, int ftp) {
      double target = 0;
      if (block is SteadyState) target = block.power * ftp; 
      if (block is IntervalsT) target = block.onPower * ftp; 
      return _getZoneColor(target.toInt(), ftp);
  }

  Widget _buildChartWithControls() {
    final profileService = context.watch<src_profile.AthleteProfileService>();
    final settings = context.watch<SettingsService>();
    final workoutService = context.watch<WorkoutService>();
    return Stack(
      children: [
        LiveWorkoutChart(
          isZoomed: _isChartZoomed, 
          showPowerZones: settings.showPowerZones,
          wPrime: profileService.wPrime,
          cp: profileService.ftp?.toInt() ?? 250,
          userFtp: workoutService.userFtp,
        ),
        Positioned(
          top: 8,
          right: 48,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _isChartZoomed = !_isChartZoomed),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Icon(
                  _isChartZoomed ? LucideIcons.minimize2 : LucideIcons.maximize2,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Additional Helper Builders ---

  Widget _buildSpeedDistTile(WorkoutService service) {
      return BigMetricTile(
          label: 'SPD / DIST',
          value: '${service.currentSpeed.toStringAsFixed(1)} / ${service.totalDistance.toStringAsFixed(1)}',
          unit: 'km/h / km',
          accentColor: Colors.blueAccent
      );
  }

  Widget _buildBalanceTile(BluetoothService bt) {
      final val = (bt.leftPowerBalance != null && bt.rightPowerBalance != null)
        ? '${bt.leftPowerBalance}/${bt.rightPowerBalance}'
        : '-';
      return BigMetricTile(
          label: 'BAL',
          value: val,
          unit: '%',
          accentColor: Colors.cyanAccent
      );
  }

  Widget _buildCoreTempTile(BluetoothService bt) {
      final temp = bt.coreTemp;
      Color tempColor = Colors.greenAccent;
      if (temp > 38.0) {
        tempColor = Colors.redAccent;
      } else if (temp > 37.0) tempColor = Colors.yellowAccent;
      else if (temp <= 0) tempColor = Colors.grey;

      return BigMetricTile(
          label: 'CORE',
          value: temp > 0 ? temp.toStringAsFixed(1) : '-',
          unit: '°C',
          accentColor: tempColor,
          valueColor: tempColor,
      );
  }

  Widget _buildNpTile(WorkoutService service) {
      return BigMetricTile(
          label: 'NP (LIVE)',
          value: service.currentNp > 0 ? service.currentNp.toString() : '-',
          unit: 'W',
          accentColor: Colors.deepPurpleAccent,
          valueColor: Colors.deepPurpleAccent,
      );
  }


  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 30), // Changed icon to indicate minimize
            onPressed: () {
               // Minimize (Run in Background)
               Navigator.pop(context);
               
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(
                   content: Text('Allenamento ridotto a icona. Tocca il ciclista verde per riprendere.'),
                   backgroundColor: Colors.blueAccent,
                   duration: Duration(seconds: 2),
                 )
               );
            },
          ),
          Text(
            context.watch<WorkoutService>().currentWorkout?.title ?? 'PEDALATA LIBERA',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12),
          ),
          Row(
            children: [
              // Sensor Count Indicator -> Click to Scan
              GestureDetector(
                onTap: () {
                   Navigator.push(
                     context,
                     MaterialPageRoute(builder: (context) => const com_bluetooth.BluetoothScanScreen()),
                   );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.bluetooth, color: Colors.blueAccent, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '${context.watch<BluetoothService>().connectedDeviceCount}', 
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Battery Status
              GestureDetector(
                onTap: () {
                   showDialog(
                     context: context,
                     builder: (ctx) => AlertDialog(
                       backgroundColor: const Color(0xFF1A1A2E),
                       title: const Text("Livello Batteria Sensori", style: TextStyle(color: Colors.white)),
                       content: Column(
                         mainAxisSize: MainAxisSize.min,
                         children: context.watch<BluetoothService>().batteryLevels.entries.map((entry) {
                            // Resolve Name
                            final bt = context.read<BluetoothService>();
                            String name = entry.key; // Fallback to ID
                            
                            if (bt.trainer?.remoteId.toString() == entry.key) {
                              name = bt.trainer?.platformName ?? "Trainer";
                            } else if (bt.heartRateSensor?.remoteId.toString() == entry.key) name = bt.heartRateSensor?.platformName ?? "HR Monitor";
                            else if (bt.powerMeter?.remoteId.toString() == entry.key) name = bt.powerMeter?.platformName ?? "Power Meter";
                            else if (bt.cadenceSensor?.remoteId.toString() == entry.key) name = bt.cadenceSensor?.platformName ?? "Cadence Sensor";
                            else if (bt.coreSensor?.remoteId.toString() == entry.key) name = bt.coreSensor?.platformName ?? "CORE Sensor";
                            
                            return ListTile(
                              leading: const Icon(LucideIcons.battery, color: Colors.greenAccent),
                              title: Text(name, style: const TextStyle(color: Colors.white70, fontSize: 14)), 
                              trailing: Text('${entry.value}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            );
                         }).toList(),
                       ),
                       actions: [
                         TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Chiudi"))
                       ],
                     ),
                   );
                },
                child: const Icon(LucideIcons.battery, color: Colors.greenAccent, size: 18),
              ),
              const SizedBox(width: 12),
              // Settings -> Advanced Options
              IconButton(
                icon: const Icon(LucideIcons.settings, color: Colors.white70, size: 20),
                onPressed: () {
                   Navigator.push(
                     context,
                     MaterialPageRoute(builder: (context) => const com_settings.AdvancedOptionsScreen()),
                   );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar(WorkoutService workoutService) {
    return GlassCard(
      borderRadius: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      borderColor: Colors.white.withOpacity(0.05),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildControlButton(
              workoutService.isPaused ? LucideIcons.play : LucideIcons.pause, 
              workoutService.isPaused ? Colors.cyanAccent : Colors.orangeAccent, 
              () => workoutService.togglePlayPause()
            ),
            const SizedBox(width: 16),
            _buildControlButton(LucideIcons.square, Colors.purpleAccent, () async {
              workoutService.stopWorkout();
              
              // Generate FIT File
              showDialog(
                context: context, 
                barrierDismissible: false,
                builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
              );

              try {
                 // final bluetooth = context.read<BluetoothService>(); // Snapshot if needed
                 
                   final file = await FitGenerator.generateActivityFit(
                     powerHistory: workoutService.powerHistory,
                     hrHistory: workoutService.hrHistory,
                     cadenceHistory: workoutService.cadenceHistory,
                     speedHistory: workoutService.speedHistory,
                     avgPower: workoutService.powerHistory.isNotEmpty 
                        ? workoutService.powerHistory.reduce((a, b) => a + b) / workoutService.powerHistory.length 
                        : 0.0,
                     maxHr: workoutService.hrHistory.isNotEmpty 
                        ? workoutService.hrHistory.reduce(max) 
                        : 0,
                     durationSeconds: workoutService.totalElapsed,
                     totalDistance: workoutService.totalDistance * 1000,
                     totalCalories: workoutService.totalCalories.toInt(),
                     startTime: DateTime.now().subtract(Duration(seconds: workoutService.totalElapsed)),
                     workoutTitle: workoutService.currentWorkout?.title ?? "Manual Workout",
                     rrHistory: workoutService.rrHistory,  // Include RR intervals
                     coreTempHistory: workoutService.tempHistory,
                   );
                 
                  if (context.mounted) {
                    Navigator.pop(context); // Pop loading dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostWorkoutAnalysisScreen(
                          fitFilePath: file.path, 
                          workoutId: workoutService.currentWorkout?.id,
                          isNewWorkout: true, // Flag to show Save/Discard buttons
                        )
                      ),
                    );
                  }
              } catch (e) {
                 if (context.mounted) {
                   Navigator.pop(context); // Pop dialog
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error generating FIT file: $e")));
                 }
              }
            }),
            const SizedBox(width: 16),
            // Skip Interval Button
            _buildControlButton(LucideIcons.skipForward, Colors.white, () {
               workoutService.nextInterval();
            }),
            const SizedBox(width: 16),
            _buildModeSelector(workoutService),
            const SizedBox(width: 16), // Replaced Spacer with fixed spacing in scroll view
            _buildIntensityControl(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildIntensityControl({bool isVertical = false}) {
    // Read from service directly to stay in sync
    final service = context.watch<WorkoutService>();
    final isSlope = service.mode == WorkoutMode.slope;
    final isResist = service.mode == WorkoutMode.resistance;
    
    String displayValue = '';
    if (isSlope) {
      displayValue = '${service.currentSlope.toStringAsFixed(1)}%';
    } else if (isResist) displayValue = '${service.currentResistance}%';
    else displayValue = '${service.intensityPercentage}%';
    
    String label = 'INTENSITY';
    if (isSlope) {
      label = 'SLOPE';
    } else if (isResist) label = 'RESIST';

    List<Widget> children = [
        IconButton(
          icon: const Icon(Icons.remove, color: Colors.white),
          onPressed: () {
             service.decreaseIntensity();
          },
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isSlope ? Colors.purpleAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSlope ? Colors.purpleAccent.withOpacity(0.5) : Colors.white10),
          ),
          child: Text(
            displayValue,
            style: TextStyle(color: isSlope ? Colors.purpleAccent : Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add, color: Colors.white),
          onPressed: () {
             service.increaseIntensity();
          },
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.bold)),
    ];

    if (isVertical) {
       return Column(children: children);
    }
    return Row(children: children);
  }

  Widget _buildModeSelector(WorkoutService service, {bool isVertical = false}) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: isVertical 
      ? Column(
         mainAxisSize: MainAxisSize.min,
         children: [
          _buildModeItem(WorkoutMode.erg, 'ERG', service),
          _buildModeItem(WorkoutMode.slope, 'SIM', service),
          _buildModeItem(WorkoutMode.resistance, 'RES', service),
         ],
      )
      : Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeItem(WorkoutMode.erg, 'ERG', service),
          _buildModeItem(WorkoutMode.slope, 'SIM', service),
          _buildModeItem(WorkoutMode.resistance, 'RES', service),
        ],
      ),
    );
  }

  Widget _buildModeItem(WorkoutMode mode, String label, WorkoutService service) {
    final isSelected = service.mode == mode;
    return GestureDetector(
      onTap: () => service.setMode(mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blueAccent : Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalControlBar(WorkoutService workoutService) {
    return GlassCard(
      borderRadius: 0,
       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
       borderColor: Colors.white.withOpacity(0.05),
       child: SingleChildScrollView(
         scrollDirection: Axis.vertical,
         child: Column(
           children: [
             _buildControlButton(
               workoutService.isPaused ? LucideIcons.play : LucideIcons.pause, 
               workoutService.isPaused ? Colors.cyanAccent : Colors.orangeAccent, 
               () => workoutService.togglePlayPause()
             ),
             const SizedBox(height: 16),
             _buildControlButton(LucideIcons.skipForward, Colors.white, () {
                workoutService.nextInterval();
             }),
             const SizedBox(height: 16),
             _buildModeSelector(workoutService, isVertical: true),
             const SizedBox(height: 16),
             _buildIntensityControl(isVertical: true),
             const SizedBox(height: 32),
             _buildControlButton(LucideIcons.square, Colors.purpleAccent, () async {
                 // Stop logic duplicated for now or extract to method
                 workoutService.stopWorkout();
                  showDialog(
                    context: context, 
                    barrierDismissible: false,
                    builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
                  );
                  try {
                       final file = await FitGenerator.generateActivityFit(
                         powerHistory: workoutService.powerHistory,
                         hrHistory: workoutService.hrHistory,
                         cadenceHistory: workoutService.cadenceHistory,
                         speedHistory: workoutService.speedHistory,
                         avgPower: workoutService.powerHistory.isNotEmpty 
                            ? workoutService.powerHistory.reduce((a, b) => a + b) / workoutService.powerHistory.length 
                            : 0.0,
                         maxHr: workoutService.hrHistory.isNotEmpty 
                            ? workoutService.hrHistory.reduce(max) 
                            : 0,
                         durationSeconds: workoutService.totalElapsed,
                         totalDistance: workoutService.totalDistance * 1000,
                         totalCalories: workoutService.totalCalories.toInt(),
                         startTime: DateTime.now().subtract(Duration(seconds: workoutService.totalElapsed)),
                         workoutTitle: workoutService.currentWorkout?.title ?? "Manual Workout",
                         rrHistory: workoutService.rrHistory,
                       );
                      if (context.mounted) {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PostWorkoutAnalysisScreen(
                              fitFilePath: file.path, 
                              workoutId: workoutService.currentWorkout?.id,
                              isNewWorkout: true,
                            )
                          ),
                        );
                      }
                  } catch (e) {
                     if (context.mounted) {
                       Navigator.pop(context);
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                     }
                  }
             }),
           ],
         ),
       ),
    );
  }
}

