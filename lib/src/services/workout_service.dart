import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
import '../logic/zwo_parser.dart';
import 'bluetooth_service.dart';
import 'settings_service.dart';

enum WorkoutMode { erg, slope, resistance }

class WorkoutService extends ChangeNotifier {
  WorkoutWorkout? currentWorkout;
  int currentBlockIndex = 0;
  int elapsedInBlock = 0;
  Timer? _timer;

  bool isActive = false;
  bool isPaused = false;
  
  // Mode Management
  WorkoutMode _mode = WorkoutMode.erg;
  WorkoutMode get mode => _mode;
  
  // Mode State
  double _currentSlope = 0.0; // 0% to 20%
  double get currentSlope => _currentSlope;
  
  int _currentResistance = 10; // 0-100%
  int get currentResistance => _currentResistance;

  List<double> powerHistory = [];
  List<int> hrHistory = [];
  List<int> cadenceHistory = [];
  List<double> tempHistory = [];
  List<double> speedHistory = []; 
  int totalElapsed = 0;
  
  double totalDistance = 0.0; // km
  double totalCalories = 0.0; // kcal

  double currentSpeed = 0.0;
  int userFtp = 200; 
  int intensityPercentage = 100;
  
  // Target Calculation Helper
  int get currentTargetWatts => (currentTargetPowerFactor * userFtp).round();

  // Returns the target Power Factor (e.g. 0.5 for 50% FTP) scaling with intensity
  double get currentTargetPowerFactor => currentWorkout != null && currentWorkout!.blocks.isNotEmpty
      ? _getTargetPowerAt(totalElapsed) * (intensityPercentage / 100.0)
      : 0.0;

  void updateFtp(int ftp) {
    userFtp = ftp;
    notifyListeners();
  }
  
  // Toggle Mode
  void setMode(WorkoutMode newMode) {
    _mode = newMode;
    notifyListeners();
  }
  
  // Set Slope directly
  void setSlope(double slope) {
    _currentSlope = slope.clamp(0.0, 20.0);
    // Send command immediately for responsiveness
    bluetoothService?.setSlope(_currentSlope);
    notifyListeners();
  }

  // Set Resistance directly
  void setResistance(int level) {
    _currentResistance = level.clamp(0, 100);
    bluetoothService?.setResistanceLevel(_currentResistance);
    notifyListeners();
  }
  
  void setIntensity(int percent) {
    intensityPercentage = percent;
    notifyListeners();
  }

  void increaseIntensity() {
    if (_mode == WorkoutMode.erg) {
      int step = settingsService?.ergIncreasePercent ?? 1;
      setIntensity((intensityPercentage + step).clamp(20, 200));
    } else if (_mode == WorkoutMode.slope) {
      int step = settingsService?.slopeIncreasePercent ?? 1; 
      double increment = (step > 0 ? step : 1) * 0.5; 
      setSlope((_currentSlope + increment));
    } else {
      // Resistance mode: +5% steps or per settings? 
      // Using 5% as a sensible default for resistance steps
      setResistance((_currentResistance + 5).clamp(0, 100));
    }
  }
  
  void decreaseIntensity() {
    if (_mode == WorkoutMode.erg) {
      int step = settingsService?.ergIncreasePercent ?? 1;
      setIntensity((intensityPercentage - step).clamp(20, 200));
    } else if (_mode == WorkoutMode.slope) {
      int step = settingsService?.slopeIncreasePercent ?? 1;
      double decrement = (step > 0 ? step : 1) * 0.5;
      setSlope((_currentSlope - decrement));
    } else {
      setResistance((_currentResistance - 5).clamp(0, 100));
    }
  }

  double _getTargetPowerAt(int seconds) {
    if (currentWorkout == null) return 0.0;
    
    // Handle infinite duration block
    if (currentWorkout!.blocks.length == 1 && currentWorkout!.blocks.first.duration > 86400) {
       final block = currentWorkout!.blocks.first;
       return (block is SteadyState) ? block.power : 0.0;
    }

    int cumulative = 0;
    for (var block in currentWorkout!.blocks) {
      if (seconds < cumulative + block.duration) {
        if (block is SteadyState) return block.power;
        if (block is IntervalsT) {
          int cycleTime = block.onDuration + block.offDuration;
          int withinCycle = (seconds - cumulative) % cycleTime;
          return withinCycle < block.onDuration ? block.onPower : block.offPower;
        }
      }
      cumulative += block.duration;
    }
    return 0.0;
  }

  void startWorkout(WorkoutWorkout workout, {int? ftp, String? workoutId}) {
    currentWorkout = WorkoutWorkout(
      id: workoutId ?? workout.id,
      title: workout.title, 
      blocks: workout.blocks
    );
    if (ftp != null) userFtp = ftp;
    
    // Auto-detect mode based on workout ID or logic
    if (workoutId == 'pmax_slope_test' || 
        workoutId == 'flow_protocol_1' || 
        workoutId == 'flow_protocol_2') {
      _mode = WorkoutMode.slope;
      _currentSlope = 2.0; // Default 2%
    } else {
      _mode = WorkoutMode.erg;
      intensityPercentage = 100;
    }
    
    currentBlockIndex = 0;
    elapsedInBlock = 0;
    totalElapsed = 0;
    powerHistory = [];
    hrHistory = [];
    cadenceHistory = [];
    tempHistory = [];
    speedHistory = []; 
    totalDistance = 0.0;
    totalCalories = 0.0; 
    _lastSentTargetWatts = -1; // Reset control state
    isActive = true;
    isPaused = true; // Start PAUSED per user request
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPaused) _tick();
    });
    notifyListeners();
  }

  void togglePlayPause() {
    isPaused = !isPaused;
    notifyListeners();
  }
  
  void stopWorkout() {
    _timer?.cancel();
    isActive = false;
    isPaused = true;
    
    // Auto-update Max HR
    if (hrHistory.isNotEmpty && settingsService != null) {
      int maxHr = hrHistory.reduce(max);
      if (maxHr > settingsService!.hrMax) {
         // Found new max!
         settingsService!.setHrMax(maxHr);
         // Note: We can't show snackbar here easily as we don't have context, 
         // but the settings update will persist and UI will reflect if watching settings.
      }
    }

    notifyListeners();
  }
  
  void nextInterval() {
    if (currentWorkout == null) return;
    
    if (currentBlockIndex < currentWorkout!.blocks.length - 1) {
      // 1. Calculate cumulative duration of finished blocks (including the one being skipped)
      int cumulativeDuration = 0;
      for (int i = 0; i <= currentBlockIndex; i++) {
        cumulativeDuration += currentWorkout!.blocks[i].duration;
      }
      
      // Calculate Gap
      int gap = cumulativeDuration - totalElapsed;

      // 2. Advance state
      currentBlockIndex++;
      elapsedInBlock = 0;
      totalElapsed = cumulativeDuration; // Jump time forward to start of next block
      
      // 3. Fill History Gaps (Fix for Chart Alignment)
      // When skipping, we must pad the history so the "cursor" moves forward on the chart
      // and timestamps remain aligned with planned blocks.
      if (gap > 0) {
        // Limit gap filler to avoid memory spikes if skipping huge chunks (e.g. > 1 hour?)
        // But we need consistency. 3600 limit handles memory.
        for (int k = 0; k < gap; k++) {
             powerHistory.add(0.0);
             hrHistory.add(0); // Maintain last HR? No, assume 0/gap.
             cadenceHistory.add(0);
             tempHistory.add(0.0);
             speedHistory.add(0.0);
        }
        
        // Handle max size limit here too if needed, but _tick does it.
        // We'll let next _tick clean it up if it exceeds.
      }

      // Vibration / Sound Feedback
      if (settingsService?.vibration == true) {
         HapticFeedback.mediumImpact();
      }
      
    } else {
      // Check if this is a RAMP TEST (Infinite)
      // We look for a specific ID or title pattern
      if (currentWorkout?.id == 'ramp_test' || (currentWorkout?.title.toLowerCase().contains('ramp test') ?? false)) {
          // Infinite Logic: Add new step
          // Last block was presumably the step.
          // Get last block properties
          final lastBlock = currentWorkout!.blocks.last;
          if (lastBlock is SteadyState) {
             // Create next step: +25W (approx 0.08 of 300W, or just fixed calculation if absolute)
             // But here we use Factor relative to FTP.
             // Assume Ramp Step is usually 1 min @ +X%
             // Let's assume the previous step diff defined the ramp rate.
             // Or just add 6% FTP (approx 20W for 330W FTP) every step?
             // Standard MAP test: +25W every minute.
             
             // Calculate current watts
             double currentFactor = lastBlock.power;
             int currentWatts = (currentFactor * userFtp).round();
             int nextWatts = currentWatts + 25; // Add 25 Watts
             double nextFactor = nextWatts / userFtp;
             
             // Add new block
             currentWorkout!.blocks.add(SteadyState(
               duration: 60, // 1 minute
               power: nextFactor,
             ));
             
             // Advance
             currentBlockIndex++;
             elapsedInBlock = 0;
             // totalElapsed continues normally
             
             if (settingsService?.vibration == true) {
               HapticFeedback.mediumImpact();
             }
             notifyListeners();
             return; // Continue!
          }
      }

      stopWorkout();
      if (settingsService?.vibration == true) {
         HapticFeedback.heavyImpact();
      }
    }
    notifyListeners();
  }

  BluetoothService? bluetoothService;
  SettingsService? settingsService; 

  void updateBluetoothService(BluetoothService service) {
    bluetoothService = service;
  }
  
  void updateSettingsService(SettingsService service) {
    settingsService = service;
  }

  // Smoothing Buffer
  final List<double> _powerBuffer = [];
  static const int _smoothingWindow = 3; 

  void _tick() {
    if (currentWorkout == null) return;
    
    // Auto-Pause Check
    if (settingsService?.disableAutoStartStop == false) {
       int currentCadence = bluetoothService?.cadence ?? 0;
       double currentPower = bluetoothService?.power ?? 0;
       
       if (isActive && !isPaused && currentCadence == 0 && currentPower < 10) {
          isPaused = true;
          notifyListeners();
          return;
       }
       
       if (isActive && isPaused && (currentCadence > 10 || currentPower > 10)) {
          isPaused = false;
          notifyListeners();
       }
    }
    
    if (isPaused) return; 
    
    totalElapsed++;
    elapsedInBlock++;

    double activePower = 0.0;
    int activeHr = 0;
    double activeTemp = 0.0;
    double activeSpeed = 0.0;

    // Power Logic
    if (bluetoothService != null && (bluetoothService!.trainer != null || bluetoothService!.powerMeter != null)) {
       activePower = bluetoothService!.power;
    } 
    
    // Double Sided Power
    if (settingsService?.doubleSidedPower == true) {
       activePower *= 2; 
    }

    // Power Smoothing
    double processedPower = activePower;
    if (settingsService?.powerSmoothing == true) {
      _powerBuffer.add(activePower);
      if (_powerBuffer.length > _smoothingWindow) {
        _powerBuffer.removeAt(0);
      }
      if (_powerBuffer.isNotEmpty) {
        processedPower = _powerBuffer.reduce((a, b) => a + b) / _powerBuffer.length;
      }
    } else {
      _powerBuffer.clear();
    }
    activePower = processedPower; 
    
    // Speed Logic
    if (bluetoothService != null && bluetoothService!.trainer != null && bluetoothService!.speed > 0) {
       activeSpeed = bluetoothService!.speed; // Use trainer speed if available and valid
    } else {
       // Physics-based Speed Simulation (Simple)
       // Power = 0.5 * rho * CdA * v^3 + Crr * mass * g * v
       // Simplified: v = (Power / 0.035)^(1/3) roughly for road bike on flat
       // 0.035 is an aggregate constant. 
       // V in m/s. 
       if (activePower > 0) {
          activeSpeed = pow(activePower / 0.032, 1/3).toDouble() * 3.6; // result in km/h
       } else {
          activeSpeed = 0.0;
       }
    }
    currentSpeed = activeSpeed;
    
    // Heart Rate Logic
    if (bluetoothService != null && bluetoothService!.heartRateSensor != null) {
       activeHr = bluetoothService!.heartRate;
    }
    
    int activeCadence = 0;
    if (bluetoothService != null) {
        activeCadence = bluetoothService!.cadence;
    }

    // Temp Logic
    if (bluetoothService != null && bluetoothService!.coreSensor != null) {
       activeTemp = bluetoothService!.coreTemp;
    }

    // Accumulate Distance (Speed is km/h, time is 1s)
    // Distance = Speed * Time. 
    // m/s = km/h / 3.6
    double distIncrementMeters = (activeSpeed / 3.6);
    totalDistance += distIncrementMeters / 1000.0; // km

    // Accumulate Calories
    // Joules = Watts * Seconds. 1 kcal = 4.184 kJ = 4184 J.
    // Efficiency ~24% (0.24). Metabolic Work = Mechanical Work / Efficiency.
    // Calories = (Watts * 1s) / 4184 / 0.24
    double activeCals = (activePower * 1.0) / 4184.0 / 0.24; 
    totalCalories += activeCals;

    powerHistory.add(activePower);
    hrHistory.add(activeHr);
    cadenceHistory.add(activeCadence);
    tempHistory.add(activeTemp);
    speedHistory.add(activeSpeed); 

    if (powerHistory.length > 3600) { 
       if (powerHistory.length > 7200) { // Limit huge history
         powerHistory.removeAt(0);
         hrHistory.removeAt(0);
         cadenceHistory.removeAt(0);
         tempHistory.removeAt(0);
         speedHistory.removeAt(0);
       }
    }

    final currentBlock = currentWorkout!.blocks[currentBlockIndex];
    
    // Check for Auto-Extend Recovery
    bool isRecovery = false;
    double targetFactor = 0.0;
    if (currentBlock is SteadyState) targetFactor = currentBlock.power;
    else if (currentBlock is IntervalsT) targetFactor = currentBlock.offPower; 
    
    if (targetFactor < 0.65) isRecovery = true;

    bool shouldExtend = false;
    if (elapsedInBlock >= currentBlock.duration) {
       if (settingsService?.autoExtendRecovery == true && isRecovery) {
           shouldExtend = true;
       }
    }

    if (!shouldExtend && elapsedInBlock >= currentBlock.duration) {
      nextInterval();
    }
    
     // --- Bluetooth Control Loop ---
    if (bluetoothService != null && bluetoothService!.trainer != null) { // Only if trainer connected
       if (_mode == WorkoutMode.erg) {
          int targetW = currentTargetWatts;
          if (targetW != _lastSentTargetWatts || (totalElapsed % 5 == 0)) {
             bluetoothService!.setTargetPower(targetW);
             _lastSentTargetWatts = targetW;
          }
       } else if (_mode == WorkoutMode.resistance) {
          // Keep sending resistance every 10s for health/integrity
          if (totalElapsed % 10 == 0) {
             bluetoothService!.setResistanceLevel(_currentResistance);
          }
       }
       // Slope mode updates are handled directly in setSlope to be responsive
    }

    notifyListeners();
  }
  
  // State for command optimization
  int _lastSentTargetWatts = -1;
}
