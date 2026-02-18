import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // For HapticFeedback
// For BytesSource
import 'package:flutter/material.dart'; // For Colors
import 'package:audioplayers/audioplayers.dart';
import '../logic/zwo_parser.dart';
import 'bluetooth_service.dart';
import 'settings_service.dart';

enum WorkoutMode { erg, slope, resistance }

class WorkoutService extends ChangeNotifier {
  WorkoutWorkout? currentWorkout;
  int currentBlockIndex = 0;
  int elapsedInBlock = 0;
  Timer? _timer;
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool isActive = false;
  bool isPaused = false;
  
  // Countdown State
  bool _isCountingDown = false;
  bool get isCountingDown => _isCountingDown;
  
  int _countdownValue = 0;
  int get countdownValue => _countdownValue;

  // Mode Management
  WorkoutMode _mode = WorkoutMode.erg;
  WorkoutMode get mode => _mode;
  
  // ... (rest of state) ...

  WorkoutService() {
    _initAudio();
  }
  
  static Color getZoneColor(double p) {
    // p is fraction of FTP (e.g. 1.0 = 100%)
    if (p < 0.55) return Colors.grey; // Z1 (Active Recovery)
    if (p < 0.75) return Colors.blueAccent; // Z2 (Endurance)
    if (p < 0.90) return Colors.greenAccent; // Z3 (Tempo)
    if (p < 1.05) return Colors.yellowAccent; // Z4 (Threshold)
    if (p < 1.20) return Colors.orangeAccent; // Z5 (VO2 Max)
    return Colors.redAccent; // Z6 (Anaerobic)
  }

  Future<void> _initAudio() async {
    // Configure AudioContext to mix with other apps (e.g. Spotify) and NOT duck/pause them.
    await _audioPlayer.setAudioContext(AudioContext(
      android: const AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
        contentType: AndroidContentType.sonification,
        usageType: AndroidUsageType.assistanceSonification,
        audioFocus: AndroidAudioFocus.none, // KEY: Do not request focus, just mix.
      ),
      iOS: AudioContextIOS(
        category: AVAudioSessionCategory.ambient, // Ambient = mix with others
        options: const {
          AVAudioSessionOptions.mixWithOthers
        },
      ),
    ));
  }
  
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
  // RR Intervals: List of {timestamp, rr_intervals}
  List<Map<String, dynamic>> rrHistory = [];
  int totalElapsed = 0;
  
  // VISUAL SYNC only (for graph gaps)
  int currentWorkoutTime = 0;
  List<int> workoutTimeHistory = [];
  
  double totalDistance = 0.0; // km
  double totalCalories = 0.0; // kcal

  double currentSpeed = 0.0;
  int userFtp = 200; 
  int intensityPercentage = 100;
  
  // Target Calculation Helper
  int get currentTargetWatts => (currentTargetPowerFactor * userFtp).round();

  // Returns the target Power Factor (e.g. 0.5 for 50% FTP) scaling with intensity
  double get currentTargetPowerFactor => currentWorkout != null && currentWorkout!.blocks.isNotEmpty
      ? _getTargetPowerFromCurrentBlock() * (intensityPercentage / 100.0)
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

  // Live Data Properties (Available even when paused)
  double currentPower = 0.0;
  int currentCadence = 0;
  int currentHr = 0;
  double currentTemp = 0.0;
  int currentNp = 0; // Live Normalized Power

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

  double _getTargetPowerFromCurrentBlock() {
    if (currentWorkout == null || currentBlockIndex >= currentWorkout!.blocks.length) return 0.0;
    
    final block = currentWorkout!.blocks[currentBlockIndex];
    if (block is SteadyState) return block.power;
    if (block is Ramp) {
       double progress = elapsedInBlock / block.duration;
       if (progress > 1.0) progress = 1.0;
       return block.powerLow + (block.powerHigh - block.powerLow) * progress;
    }
    if (block is IntervalsT) {
      int cycleTime = block.onDuration + block.offDuration;
      int withinCycle = elapsedInBlock % cycleTime;
      return withinCycle < block.onDuration ? block.onPower : block.offPower;
    }
    return 0.0;
  }

  // Legacy method - kept for reference if needed, but primary logic now uses current block
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
        if (block is Ramp) {
           int elapsedInStep = seconds - cumulative;
           double progress = elapsedInStep / block.duration;
           // Linear interpolation
           return block.powerLow + (block.powerHigh - block.powerLow) * progress;
        }
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
      blocks: workout.blocks.map((b) => b.copy()).toList()
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
    rrHistory = [];
    totalDistance = 0.0;
    totalCalories = 0.0; 
    
    // VISUAL SYNC
    currentWorkoutTime = 0;
    workoutTimeHistory = []; 
    
    // RESET LIVE DATA
    currentPower = 0.0;
    currentCadence = 0;
    currentHr = 0;
    currentTemp = 0.0;
    currentNp = 0;
    currentSpeed = 0.0;
    _powerBuffer.clear();
    _tempBuffer.clear();

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
  
  // User manually requested next interval
  void nextInterval() {
    if (currentWorkout == null) return;
    
    // Start Countdown 3-2-1
    if (!_isCountingDown) {
       _isCountingDown = true;
       _countdownValue = 3;
       // Start immediately for responsiveness
       _playBeep();
       notifyListeners();
    }
  }

  // Internal method to actually switch block
  void _advanceToNextBlock() {
     if (currentBlockIndex < currentWorkout!.blocks.length - 1) {
      // Avanza semplicemente allo step successivo senza falsare il tempo totale.
      // Così il "TOTAL TIME" e la durata finale NON includono gli step saltati.
      currentBlockIndex++;
      elapsedInBlock = 0;

      // VISUAL SYNC: Jump to the start of the new block
      int newBlockStart = 0;
      for (int i = 0; i < currentBlockIndex; i++) {
        newBlockStart += currentWorkout!.blocks[i].duration;
      }
      currentWorkoutTime = newBlockStart;

      // Vibration / Sound Feedback
      if (settingsService?.vibration == true) {
         HapticFeedback.mediumImpact();
      }
      
      // CRITICAL FIX: Notify listeners to update chart and target immediately
      notifyListeners();
      
    } else {
      // Check if this is a RAMP TEST (Infinite)
      // We look for a specific ID or title pattern
      if (currentWorkout?.id == 'ramp_test' || (currentWorkout?.title.toLowerCase().contains('ramp test') ?? false)) {
          _addRampStep();
          return;
      }

      stopWorkout();
      if (settingsService?.vibration == true) {
         HapticFeedback.heavyImpact();
      }
    }
    notifyListeners();
  }

  void _addRampStep() {
      // Get last block properties
      final lastBlock = currentWorkout!.blocks.last;
      if (lastBlock is SteadyState) {
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
      }
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
  final List<double> _tempBuffer = [];
  static const int _smoothingWindow = 3; 
  static const int _tempSmoothingWindow = 10; // More smoothing for temp 

  void _tick() {
    // Countdown Logic
    if (_isCountingDown) {
       _countdownValue--;
       notifyListeners();
       
       if (_countdownValue <= 0) {
          _isCountingDown = false;
          _advanceToNextBlock();
       }
       return; // Skip normal tick processing during countdown
    }
    
    if (currentWorkout == null) return;

    // --- 1. FETCH & PROCESS LIVE DATA (Regardless of Pause State) ---

    double activePower = 0.0;
    int activeHr = 0;
    double activeTemp = 0.0;
    double activeSpeed = 0.0;
    int activeCadence = 0;

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
       // Physics-based Speed Simulation
       if (activePower > 0) {
          activeSpeed = pow(activePower / 0.032, 1/3).toDouble() * 3.6; // result in km/h
       } else {
          activeSpeed = 0.0;
       }
    }
    
    // Heart Rate Logic
    if (bluetoothService != null && bluetoothService!.heartRateSensor != null) {
       activeHr = bluetoothService!.heartRate;
    }
    
    // Cadence Logic
    if (bluetoothService != null) {
        activeCadence = bluetoothService!.cadence;
    }

    // Temp Logic
    if (bluetoothService != null && bluetoothService!.coreSensor != null) {
       double rawTemp = bluetoothService!.coreTemp;
       if (rawTemp > 0) {
         _tempBuffer.add(rawTemp);
         if (_tempBuffer.length > _tempSmoothingWindow) {
           _tempBuffer.removeAt(0);
         }
         // Average
         activeTemp = _tempBuffer.reduce((a, b) => a + b) / _tempBuffer.length;
       }
    }

    // UPDATE LIVE PROPERTIES
    currentPower = activePower;
    currentSpeed = activeSpeed;
    currentCadence = activeCadence;
    currentHr = activeHr;
    currentTemp = activeTemp;
    
    // Auto-Pause Check (Logic depends on LIVE values)
    if (settingsService?.disableAutoStartStop == false) {
       if (isActive && !isPaused && currentCadence == 0 && currentPower < 10) {
          isPaused = true; 
          // Notify is handled at end of function
       }
       
       if (isActive && isPaused && (currentCadence > 10 || currentPower > 10)) {
          isPaused = false;
       }
    }

    // DISCONNECTION WATCHDOG
    // If we are active and recording, but the trainer disappears, PAUSE.
    if (isActive && !isPaused && bluetoothService != null) {
       // If we were expecting a trainer (based on previous state maybe? or just if it's null now)
       // This check assumes the user STARTED with a trainer. 
       // For now, if trainer connection drops, we pause.
       if (bluetoothService!.trainer == null && bluetoothService!.powerMeter == null) {
           // No source of power connected?
           // Only pause if we rely on them. 
           // Simple heuristic: If all sensors are gone, pause.
       }
    }
    
    // --- 2. RECORDING LOGIC (Only if NOT Paused) ---
    
    if (isPaused) {
       notifyListeners(); // Update UI with live values even if paused
       return; 
    }
    
    totalElapsed++;
    elapsedInBlock++;
    
    // VISUAL SYNC
    currentWorkoutTime++;
    workoutTimeHistory.add(currentWorkoutTime);

    // Accumulate Distance and Calories
    double distIncrementMeters = (activeSpeed / 3.6);
    totalDistance += distIncrementMeters / 1000.0; // km

    double activeCals = (activePower * 1.0) / 4184.0 / 0.24; 
    totalCalories += activeCals;

    powerHistory.add(activePower);
    hrHistory.add(activeHr);
    cadenceHistory.add(activeCadence);
    tempHistory.add(activeTemp);
    speedHistory.add(activeSpeed);
    
    // Calculate Live NP (Incremental optimization could be done, but recalculating full list every second is fast enough for <5h)
    // 30s rolling avg optimization:
    if (powerHistory.isNotEmpty) {
       currentNp = _calculateLiveNp(powerHistory);
    }
    
    // Capture RR intervals if available
    if (bluetoothService != null && bluetoothService!.heartRateSensor != null) {
      if (bluetoothService!.rrIntervals.isNotEmpty) {
        rrHistory.add({
          'timestamp': DateTime.now().toIso8601String(),
          'elapsed': totalElapsed,
          'rr': List<int>.from(bluetoothService!.rrIntervals),
        });
        // Clear the buffer after capturing to avoid duplicates
        bluetoothService!.rrIntervals.clear();
      }
    } 

    // History is NOT truncated anymore to ensure complete FIT file generation.
    // 14,400 points (4 hours) is negligible in RAM (~hundreds of KB).

    final currentBlock = currentWorkout!.blocks[currentBlockIndex];
    
    // Check for Auto-Extend Recovery
    bool isRecovery = false;
    double targetFactor = 0.0;
    if (currentBlock is SteadyState) {
      targetFactor = currentBlock.power;
    } else if (currentBlock is IntervalsT) targetFactor = currentBlock.offPower; 
    
    if (targetFactor < 0.65) isRecovery = true;

    bool shouldExtend = false;
    if (elapsedInBlock >= currentBlock.duration) {
       if (settingsService?.autoExtendRecovery == true && isRecovery) {
           shouldExtend = true;
       }
    }

    // 3 Beeps at the end of the step (Counter starts at 3, so trigger at 4s remaining)
    int remainingInBlock = currentBlock.duration - elapsedInBlock;
    if (remainingInBlock <= 4 && remainingInBlock > 0 && !shouldExtend) {
       _playBeep();
    }

    if (!shouldExtend && elapsedInBlock >= currentBlock.duration) {
       _advanceToNextBlock();
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
  
  Future<void> _playBeep() async {
    final beepType = settingsService?.intervalBeepType ?? 'Volume alto';
    if (beepType == 'Silenzioso') return;
    
    double volume = 1.0;
    if (beepType == 'Volume medio') volume = 0.6;
    if (beepType == 'Volume basso') volume = 0.3;
    
    try {
      if (_audioPlayer.state == PlayerState.playing) {
          // await _audioPlayer.stop(); // Don't stop explicitely to avoid focus loss issues?
          // Actually, stop might be needed if users want distinct beeps.
          // Yet user complained about music stopping.
          // Let's try just play() which should mix if configured correctly.
          // But to be safe against "Player exception", checking state is good.
          await _audioPlayer.stop();
      }
      await _audioPlayer.setVolume(volume);
      // Generate a 150ms beep at 800Hz (Square Wave)
      final bytes = _generateBeepWav(milliseconds: 150, freq: 880);
      await _audioPlayer.play(BytesSource(bytes));
    } catch (e) {
       debugPrint("Audio beep failed: $e, falling back to system sound");
       SystemSound.play(SystemSoundType.click);
    }
  }

  Uint8List _generateBeepWav({required int milliseconds, required int freq}) {
    // 8000 Hz Sample Rate, 8-bit Mono
    const int sampleRate = 8000;
    final int numSamples = (sampleRate * milliseconds) ~/ 1000;
    final int dataSize = numSamples;
    const int headerSize = 44;
    final int totalSize = headerSize + dataSize;
    
    final buffer = Uint8List(totalSize);
    final view = ByteData.view(buffer.buffer);
    
    // RIFF header
    _writeString(buffer, 0, "RIFF");
    view.setUint32(4, 36 + dataSize, Endian.little); // File size - 8
    _writeString(buffer, 8, "WAVE");
    
    // fmt chunk
    _writeString(buffer, 12, "fmt ");
    view.setUint32(16, 16, Endian.little); // Chunk size
    view.setUint16(20, 1, Endian.little); // Audio format (1 = PCM)
    view.setUint16(22, 1, Endian.little); // Num channels (1)
    view.setUint32(24, sampleRate, Endian.little); // Sample rate
    view.setUint32(28, sampleRate, Endian.little); // Byte rate (SampleRate * NumChannels * BitsPerSample/8)
    view.setUint16(32, 1, Endian.little); // Block align
    view.setUint16(34, 8, Endian.little); // Bits per sample
    
    // data chunk
    _writeString(buffer, 36, "data");
    view.setUint32(40, dataSize, Endian.little); // Data size
    
    // Generate Square Wave samples
    final int period = sampleRate ~/ freq;
    for (int i = 0; i < numSamples; i++) {
        // High 200, Low 55 (Audible square wave)
        buffer[44 + i] = (i % period) < (period ~/ 2) ? 200 : 55;
    }
    
    return buffer;
  }
  
  void _writeString(Uint8List buffer, int offset, String s) {
    for (int i = 0; i < s.length; i++) {
      buffer[offset + i] = s.codeUnitAt(i);
    }
  }
  
  // State for command optimization
  int _lastSentTargetWatts = -1;

  // NP Calculation Logic (Simplified version of FitGenerator's, kept local for UI)
  int _calculateLiveNp(List<double> powers) {
     if (powers.length < 30) return 0;
     // Optimization: We could cache the rolling averages, but for modern CPUs, 
     // iterating 10-20k items is instant. We'll do a slightly optimized loop.
     
     // 1. Calculate 30s Rolling Averages
     int count = powers.length;
     double sumFourth = 0;
     int rollingCount = 0;
     
     // We only need to iterate from 29 to end
     // To optimize: Only calculate the NEWEST rolling avg? 
     // No, NP is an average of ALL rolling averages. So we must accumulate all.
     // For a LONG ride (4h = 14400s), O(N) every second is 14400 ops. Totally fine (1ms).
     
     for (int i = 29; i < count; i++) {
        // Calculate average of window [i-29] to [i]
        // Optimization: Sliding window sum
        // But naive loop is safer to implement quickly.
        double wSum = 0;
        for (int j = 0; j < 30; j++) {
           wSum += powers[i-j];
        }
        double avg30 = wSum / 30.0;
        sumFourth += pow(avg30, 4);
        rollingCount++;
     }
     
     if (rollingCount == 0) return 0;
     double np = pow(sumFourth / rollingCount, 0.25).toDouble();
     return np.round();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
