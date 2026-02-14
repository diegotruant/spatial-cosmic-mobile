import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as blue;

enum CadenceSource { none, trainer, dedicated }

class BluetoothService extends ChangeNotifier {
  blue.BluetoothDevice? trainer;
  blue.BluetoothDevice? heartRateSensor;
  blue.BluetoothDevice? powerMeter;
  blue.BluetoothDevice? coreSensor;
  blue.BluetoothDevice? cadenceSensor;

  // Real-time data
  double power = 0.0;
  double speed = 0.0;
  int heartRate = 0;
  int cadence = 0;
  double coreTemp = 0.0;
  List<int> rrIntervals = [];
  int? leftPowerBalance;
  int? rightPowerBalance;
  
  // Cadence source tracking
  CadenceSource cadenceSource = CadenceSource.none;

  // Trainer Sensor Preferences
  bool useTrainerPower = true;
  bool useTrainerCadence = true;
  bool useTrainerSpeed = true;

  bool isScanning = false;
  List<blue.ScanResult> scanResults = [];
  
  // Debug Logs
  List<String> logs = [];

  BluetoothService() {
    _init();
  }
  
  void log(String msg) {
    debugPrint(msg);
    logs.add("${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second} $msg");
    if (logs.length > 50) logs.removeAt(0); // Keep last 50
    notifyListeners();
  }

  void _init() {
    blue.FlutterBluePlus.isScanning.listen((scanning) {
      isScanning = scanning;
      notifyListeners();
    });
  }

  Future<void> startScan() async {
    scanResults.clear();
    await blue.FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    blue.FlutterBluePlus.onScanResults.listen((results) {
      scanResults = results;
      notifyListeners();
    });
  }

  Future<void> stopScan() async {
    await blue.FlutterBluePlus.stopScan();
  }

  Future<void> connectToDevice(blue.BluetoothDevice device, String type) async {
    await device.connect();
    
    switch (type) {
      case 'TRAINER':
        trainer = device;
        _setupTrainer(device);
        break;
      case 'HR':
        heartRateSensor = device;
        _setupHeartRate(device);
        break;
      case 'POWER':
        powerMeter = device;
        _setupPowerMeter(device);
        break;
      case 'CORE':
        coreSensor = device;
        _setupCoreSensor(device);
        break;
      case 'CADENCE':
        cadenceSensor = device;
        _setupCadenceSensor(device);
        break;
    }
    // Always check for battery
    _setupBatteryService(device);
    notifyListeners();
  }

  void _setupCoreSensor(blue.BluetoothDevice device) async {
    // Service UUID: 00002100-5B1E-4347-B07C-97B514DAE121
    // Characteristic UUID: 00002101-5B1E-4347-B07C-97B514DAE121
    log("Setting up Core Sensor: ${device.platformName}");
    List<blue.BluetoothService> services = await device.discoverServices();
    log("Core Sensor Services found: ${services.length}");
    
    bool foundService = false;
    for (var service in services) {
      log("Service UUID: ${service.uuid}");
      if (service.uuid.toString().toUpperCase().contains("2100")) { 
        log("Found Core Service!");
        foundService = true;
        for (var characteristic in service.characteristics) {
          log("Char UUID: ${characteristic.uuid}");
          if (characteristic.uuid.toString().toUpperCase().contains("2101")) {
            log("Found Core Data Characteristic!");
            
            // Try reading first
            try {
               final initialVal = await characteristic.read();
               log("Initial Core Read: $initialVal");
               if (initialVal.isNotEmpty) _parseCoreData(initialVal);
            } catch (e) {
               log("Error reading Core char: $e");
            }

            try {
              await characteristic.setNotifyValue(true);
              characteristic.onValueReceived.listen((value) {
                _parseCoreData(value);
              });
              log("Subscribed to Core Data");
            } catch (e) {
              log("Error subscribing: $e");
            }
          }
        }
      }
    }
    
    if (!foundService) {
       log("ERROR: Core Service (2100) NOT FOUND in ${services.length} services.");
    }
  }

  void _parseCoreData(List<int> value) {
    log("Core Data Raw: $value");
    if (value.length < 4) return;
    
    // Based on logs: [55, 126, 14, 104, 12...]
    // Bytes 2-3: 14, 104 -> 0x0E68 = 3688 -> 36.88 degC
    // Format appears to be Big Endian at Offset 2.
    
    try {
      int rawCore = (value[2] << 8) | value[3]; // Big Endian
      double temp = rawCore * 0.01;
      log("Parsed Core Temp (Offset 2, BE): $temp");
      
      // Sanity check (20C to 50C)
      if (temp > 20 && temp < 50) {
        coreTemp = temp;
        notifyListeners();
      } else {
        log("Core Temp disregarded (out of range): $temp");
      }
    } catch (e) {
      log("Error parsing core data: $e");
    }
  }

  // Last cadence calculation data
  int _lastCrankRevolutions = -1;
  int _lastCrankEventTime = -1;

  // --- Power Meter Setup ---
  void _setupPowerMeter(blue.BluetoothDevice device) async {
    // Power Meter Service: 0x1818
    // Power Measurement Characteristic: 0x2A63
    List<blue.BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toUpperCase().contains("1818")) { // Cycling Power Service
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toUpperCase().contains("2A63")) { // Power Measurement
            await characteristic.setNotifyValue(true);
            characteristic.onValueReceived.listen((value) {
              _parsePowerMeasurement(value);
            });
          }
        }
      }
    }
  }

  void _parsePowerMeasurement(List<int> value) {
    if (value.isEmpty) return;

    // Flags (2 bytes)
    int flags = value[0] | (value[1] << 8);
    int offset = 2;

    // Instantaneous Power (2 bytes, signed integer)
    if (offset + 2 <= value.length) {
      int rawPower = value[offset] | (value[offset + 1] << 8);
      // Power is signed, so handle negative values if necessary (though usually positive)
      if (rawPower & 0x8000 != 0) { // Check if 16th bit is set (negative number)
        rawPower = -(0x10000 - rawPower);
      }
      power = rawPower.toDouble();
      offset += 2;
    }

    // Optional fields (e.g., Pedal Power Balance, Accumulated Torque, Wheel/Crank Revolutions)
    // For simplicity, we'll just parse instantaneous power for now.
    // If Pedal Power Balance Present (Bit 0)
    if ((flags & 0x01) != 0 && offset + 1 <= value.length) {
      final rawBalance = value[offset];
      final isRightReference = (rawBalance & 0x80) != 0;
      final balance = rawBalance & 0x7F; // 0-100%
      if (balance > 0 && balance <= 100) {
        if (isRightReference) {
          rightPowerBalance = balance;
          leftPowerBalance = 100 - balance;
        } else {
          leftPowerBalance = balance;
          rightPowerBalance = 100 - balance;
        }
      } else {
        leftPowerBalance = null;
        rightPowerBalance = null;
      }
      offset += 1;
    }

    // If Accumulated Torque Present (Bit 1)
    if ((flags & 0x02) != 0) offset += 2;

    // If Wheel Revolution Data Present (Bit 2)
    if ((flags & 0x04) != 0) offset += 6; // Cumulative Wheel Revolutions (4 bytes) + Last Wheel Event Time (2 bytes)

    // If Crank Revolution Data Present (Bit 3)
    if ((flags & 0x08) != 0) {
      if (offset + 4 <= value.length) {
        int cumCrankRevs = value[offset] | (value[offset + 1] << 8);
        int lastCrankTime = value[offset + 2] | (value[offset + 3] << 8); // 1/1024s unit

        if (_lastCrankRevolutions != -1 && _lastCrankEventTime != -1) {
          int revsDiff = cumCrankRevs - _lastCrankRevolutions;
          int timeDiff = lastCrankTime - _lastCrankEventTime;

          // Handle rollover for 16-bit values
          if (timeDiff < 0) timeDiff += 65536;
          if (revsDiff < 0) revsDiff += 65536;

          if (timeDiff > 0 && revsDiff >= 0) {
            double rpm = (revsDiff * 1024 * 60) / timeDiff;
            updateCadence(rpm.round(), CadenceSource.dedicated); // Treat power meter cadence as dedicated
          }
        }
        _lastCrankRevolutions = cumCrankRevs;
        _lastCrankEventTime = lastCrankTime;
      }
      offset += 4;
    }

    notifyListeners();
  }

  // --- FTMS (Trainer) Setup ---
  void _setupTrainer(blue.BluetoothDevice device) async {
    // Indoor Bike Data: 0x2AD2
    List<blue.BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toUpperCase().contains("1826")) { // Fitness Machine Service
        for (var characteristic in service.characteristics) {
          String uuid = characteristic.uuid.toString().toUpperCase();
          if (uuid.contains("2AD2")) { // Indoor Bike Data
            await characteristic.setNotifyValue(true);
            characteristic.onValueReceived.listen((value) {
              _parseIndoorBikeData(value);
            });
          } else if (uuid.contains("2AD9")) { // Control Point
             _ftmsControlPoint = characteristic;
             await characteristic.setNotifyValue(true); // Indication usually required
             // Request Control immediately upon finding
             _requestControl();
          }
        }
      }
    }
  }

  void _parseIndoorBikeData(List<int> value) {
    if (value.isEmpty) return;
    
    // Flags (16-bit)
    int flags = value[0] | (value[1] << 8);
    int offset = 2; // Start after flags

    // FTMS 0x2AD2 structure:
    // Flags (2 bytes)
    // Instantaneous Speed (if Bit 1 set not explicitly but implied by offset? No, Speed is Mandatory in 2AD2)
    // Actually Speed IS Mandatory FIRST field.
    
    // Check if we have enough data for speed and if user wants it
    if (offset + 2 <= value.length) {
      if (useTrainerSpeed) {
         int rawSpeed = value[offset] | (value[offset + 1] << 8);
         speed = rawSpeed * 0.01; // km/h
      }
      offset += 2;
    }

    // Determine presence of optional fields based on Flags
    // Bit 0: More Data (not a field)
    bool avgSpeedPresent = (flags & 0x02) != 0;       // Bit 1
    bool instCadencePresent = (flags & 0x04) != 0;    // Bit 2
    bool avgCadencePresent = (flags & 0x08) != 0;     // Bit 3
    bool totalDistancePresent = (flags & 0x10) != 0;  // Bit 4
    bool resistanceLevelPresent = (flags & 0x20) != 0;// Bit 5
    bool instPowerPresent = (flags & 0x40) != 0;      // Bit 6
    bool avgPowerPresent = (flags & 0x80) != 0;       // Bit 7
    
    // Average Speed (if Bit 1 set)
    if (avgSpeedPresent) offset += 2;
    
    // Instantaneous Cadence (if Bit 2 set)
    if (instCadencePresent) {
      if (offset + 2 <= value.length) {
        if (useTrainerCadence) {
           int rawCadence = value[offset] | (value[offset + 1] << 8); 
           // Resolution is 0.5 RPM
           updateCadence((rawCadence * 0.5).round(), CadenceSource.trainer);
        }
        offset += 2;
      }
    }
    
    // Average Cadence (if Bit 3 set)
    if (avgCadencePresent) offset += 2;
    
    // Total Distance (if Bit 4 set) - 3 bytes (UINT24)
    if (totalDistancePresent) offset += 3;
    
    // Resistance Level (if Bit 5 set) - 2 bytes (INT16)
    if (resistanceLevelPresent) offset += 2;
    
    // Instantaneous Power (if Bit 6 set) - 2 bytes (INT16)
    if (instPowerPresent) {
      if (offset + 2 <= value.length) {
         // RAW Power from Trainer
         int rawPower = value[offset] | (value[offset + 1] << 8);
         
         // ONLY update if USER wants Trainer Power
         if (useTrainerPower) {
            power = rawPower.toDouble();
            notifyListeners();
         }
         // No need to increment offset further unless we parse more
      }
    }
    
    notifyListeners();
  }

  // --- Dedicated Cadence Sensor Setup (CSC Service) ---
  void _setupCadenceSensor(blue.BluetoothDevice device) async {
    // Cycling Speed and Cadence Service: 0x1816
    // CSC Measurement Characteristic: 0x2A5B
    cadenceSource = CadenceSource.dedicated;
    
    List<blue.BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toUpperCase().contains("1816")) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toUpperCase().contains("2A5B")) {
             await characteristic.setNotifyValue(true);
             characteristic.onValueReceived.listen((value) {
               _parseCSCData(value);
             });
          }
        }
      }
    }
  }

  void _parseCSCData(List<int> value) {
    // Flags (8-bit)
    int flags = value[0];
    int offset = 1;
    
    bool wheelRevPresent = (flags & 0x01) != 0;
    bool crankRevPresent = (flags & 0x02) != 0;
    
    if (wheelRevPresent) {
      offset += 6; // Cumulative Wheel Revs (4) + Last Wheel Event Time (2)
    }
    
    if (crankRevPresent) {
      if (offset + 4 <= value.length) {
        int cumCrankRevs = value[offset] | (value[offset + 1] << 8);
        int lastCrankTime = value[offset + 2] | (value[offset + 3] << 8); // 1/1024s unit
        
        if (_lastCrankRevolutions != -1 && _lastCrankEventTime != -1) {
          int revsDiff = cumCrankRevs - _lastCrankRevolutions;
          int timeDiff = lastCrankTime - _lastCrankEventTime;
          
          // Handle rollover
          if (timeDiff < 0) timeDiff += 65536;
          if (revsDiff < 0) revsDiff += 65536; // 16-bit rollover? Actually CumCrank might be 16 or 32? 
          // Spec says CumCrank is UINT16. So yes.
          
          if (timeDiff > 0 && revsDiff >= 0) { // Valid
             // RPM = (Revs / Time(s)) * 60
             // Time(s) = timeDiff / 1024
             // RPM = (Revs * 1024 * 60) / timeDiff
             double rpm = (revsDiff * 1024 * 60) / timeDiff;
             updateCadence(rpm.round(), CadenceSource.dedicated);
          }
        }
        
        _lastCrankRevolutions = cumCrankRevs;
        _lastCrankEventTime = lastCrankTime;
      }
    }
  }

  // --- Heart Rate Setup (with RR Intervals) ---
  void _setupHeartRate(blue.BluetoothDevice device) async {
    // Standard HR Service: 0x180D, Characteristic: 0x2A37
     List<blue.BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toUpperCase().contains("180D")) {
        for (var characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toUpperCase().contains("2A37")) {
             await characteristic.setNotifyValue(true);
             characteristic.onValueReceived.listen((value) {
               _parseHeartRate(value);
             });
          }
        }
      }
    }
  }

  void _parseHeartRate(List<int> value) {
     if (value.isEmpty) return;
     
     int flags = value[0];
     // Bit 0: HR Format (0: UINT8, 1: UINT16)
     bool isUint16 = (flags & 0x01) != 0;
     // Bit 4: RR-Interval Present
     bool rrPresent = (flags & 0x10) != 0;
     
     int offset = 1;
     
     if (isUint16) {
       if (offset + 2 <= value.length) {
         heartRate = value[offset] | (value[offset + 1] << 8);
         offset += 2;
       }
     } else {
       if (offset + 1 <= value.length) {
         heartRate = value[offset];
         offset += 1;
       }
     }
     
     // Skip Energy Expended if present (Bit 3)
     if ((flags & 0x08) != 0) {
       offset += 2;
     }
     
     // Parsing RR Intervals
     if (rrPresent) {
       while (offset + 2 <= value.length) {
         int rr = value[offset] | (value[offset + 1] << 8);
         // rr is in 1/1024 seconds. Convert to ms? 
         // Usually RMSSD calcs expect ms. 
         // (rr / 1024) * 1000 = rr * 0.9765625 ≈ rr
         // Storing raw or ms? Let's store raw for now or converting to ms int
         int rrMs = ((rr / 1024.0) * 1000).round();
         rrIntervals.add(rrMs);
         offset += 2;
       }
     }
     
     // Notify right away
     notifyListeners();
  }


  // Update cadence (called from data parsing)
  void updateCadence(int newCadence, CadenceSource source) {
    // Dedicated sensor has priority over trainer
    if (source == CadenceSource.dedicated || cadenceSource != CadenceSource.dedicated) {
      cadence = newCadence;
      notifyListeners();
    }
  }

  // --- Command Control Variables ---
  blue.BluetoothCharacteristic? _ftmsControlPoint;

  // Set Target Power (ERG Mode - OpCode 0x05)
  Future<void> setTargetPower(int watts) async {
    if (_ftmsControlPoint == null) return;
    
    // OpCode 0x05 (Set Target Power) + Watts (INT16, 2 bytes)
    int w = watts.clamp(0, 3000);
    List<int> command = [0x05, w & 0xFF, (w >> 8) & 0xFF];
    
    try {
      await _ftmsControlPoint!.write(command, withoutResponse: false);
    } catch (e) {
      debugPrint("Error setting target power: $e");
    }
  }

  // Set Slope (Sim Mode - OpCode 0x11)
  // Param: slope is percentage (e.g. 2.5 for 2.5%)
  Future<void> setSlope(double slope) async {
    if (_ftmsControlPoint == null) return;
    
    int gradeVal = (slope * 100).round();
    
    List<int> command = [
      0x11, 
      0x00, 0x00, // Wind Speed (0)
      gradeVal & 0xFF, (gradeVal >> 8) & 0xFF, // Grade
      0x28, // Crr (0.004 -> 40 -> 0x28)
      0x33  // Cw (0.51 -> 51 -> 0x33)
    ];

    try {
       await _ftmsControlPoint!.write(command, withoutResponse: false);
    } catch (e) {
       debugPrint("Error setting slope: $e");
    }
  }

  // Set Resistance Level (OpCode 0x04)
  // Param: level 0-100% (Resolution 0.1, but often used as 1% steps)
  Future<void> setResistanceLevel(int level) async {
    if (_ftmsControlPoint == null) return;
    
    // OpCode 0x04 (Set Resistance Level) + Level (UINT8)
    // Percentage is level/1.0
    int l = level.clamp(0, 100);
    List<int> command = [0x04, l];
    
    try {
      await _ftmsControlPoint!.write(command, withoutResponse: false);
    } catch (e) {
      debugPrint("Error setting resistance level: $e");
    }
  }

  // Request Control (OpCode 0x00)
  Future<void> _requestControl() async {
    if (_ftmsControlPoint == null) return;
    try {
      await _ftmsControlPoint!.write([0x00], withoutResponse: false);
    } catch (e) {
      debugPrint("Error requesting control: $e");
    }
  }

  // --- Battery Monitoring ---
  Map<String, int> batteryLevels = {}; // DeviceId -> Level
  
  void _setupBatteryService(blue.BluetoothDevice device) async {
    List<blue.BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (service.uuid.toString().toUpperCase().contains("180F")) { // Battery Service
        for (var characteristic in service.characteristics) {
           if (characteristic.uuid.toString().toUpperCase().contains("2A19")) { // Battery Level
              await characteristic.setNotifyValue(true);
              // Read initial
              List<int> val = await characteristic.read();
              if (val.isNotEmpty) {
                 batteryLevels[device.remoteId.toString()] = val[0];
                 notifyListeners();
              }
              // Listen
              characteristic.onValueReceived.listen((value) {
                 if (value.isNotEmpty) {
                    batteryLevels[device.remoteId.toString()] = value[0];
                    notifyListeners();
                 }
              });
           }
        }
      }
    }
  }
  
  String get cadenceSourceLabel {
    switch (cadenceSource) {
      case CadenceSource.trainer:
        return 'da Trainer';
      case CadenceSource.dedicated:
        return 'Sensore';
      case CadenceSource.none:
        return 'N/D';
    }
  }

  int get connectedDeviceCount {
    int count = 0;
    if (trainer != null) count++;
    if (heartRateSensor != null) count++;
    if (powerMeter != null) count++;
    if (coreSensor != null) count++;
    if (cadenceSensor != null) count++;
    return count;
  }

  // --- Automatic Device Type Detection ---
  
  // Returns a list of potential types because a device can be multiple things (e.g. Trainer is also Power + Cadence)
  // We prioritize the "most complex" capability.
  String? detectDeviceType(blue.ScanResult result) {
    final services = result.advertisementData.serviceUuids.map((u) => u.toString().toUpperCase()).toList();
    final name = result.device.platformName.toUpperCase();
    
    // Check for Specific Service UUIDs
    
    // 1. CORE Sensor (Custom UUID)
    if (services.any((s) => s.contains("2100"))) return 'CORE';
    
    // 2. Fitness Machine (Trainer) - 0x1826 or FTMS
    // Many trainers also advertise CPS (0x1818), so FTMS check must come first or be higher priority
    if (services.any((s) => s.contains("1826"))) return 'TRAINER';
    
    // 3. Power Meter - 0x1818
    if (services.any((s) => s.contains("1818"))) return 'POWER';
    
    // 4. Heart Rate - 0x180D
    if (services.any((s) => s.contains("180D"))) return 'HR';
    
    // 5. Cadence/Speed - 0x1816
    if (services.any((s) => s.contains("1816"))) return 'CADENCE';
    
    // Fallback: Name based detection (if services are missing in advertisement)
    if (name.contains("CORE")) return 'CORE';
    if (name.contains("HRM") || name.contains("HEART")) return 'HR';
    if (name.contains("TICKR")) return 'HR';
    if (name.contains("POLAR")) return 'HR';
    if (name.contains("KICKR")) return 'TRAINER';
    if (name.contains("TACX")) return 'TRAINER';
    if (name.contains("WAHOO") && !name.contains("ELEMNT")) return 'TRAINER'; // Assumption
    if (name.contains("ASSIOMA")) return 'POWER';
    if (name.contains("VECTOR")) return 'POWER';
    if (name.contains("STAGES")) return 'POWER';
    
    return null; // Unknown, ask user
  }
  
  // ========================================
  // DISCONNECT METHODS
  // ========================================
  
  /// Disconnects a specific device by type and clears its reference
  Future<void> disconnectDevice(String deviceType) async {
    try {
      blue.BluetoothDevice? deviceToDisconnect;
      
      switch (deviceType) {
        case 'TRAINER':
          deviceToDisconnect = trainer;
          trainer = null;
          power = 0.0;
          speed = 0.0;
          // Reset cadence if it was from trainer
          if (cadenceSource == CadenceSource.trainer) {
            cadence = 0;
            cadenceSource = CadenceSource.none;
          }
          break;
          
        case 'HR':
          deviceToDisconnect = heartRateSensor;
          heartRateSensor = null;
          heartRate = 0;
          rrIntervals.clear();
          break;
          
        case 'POWER':
          deviceToDisconnect = powerMeter;
          powerMeter = null;
          power = 0.0;
          leftPowerBalance = null;
          rightPowerBalance = null;
          // Reset cadence if it was from power meter
          if (cadenceSource == CadenceSource.dedicated) {
            cadence = 0;
            cadenceSource = CadenceSource.none;
          }
          _lastCrankRevolutions = -1;
          _lastCrankEventTime = -1;
          break;
          
        case 'CORE':
          deviceToDisconnect = coreSensor;
          coreSensor = null;
          coreTemp = 0.0;
          break;
          
        case 'CADENCE':
          deviceToDisconnect = cadenceSensor;
          cadenceSensor = null;
          cadence = 0;
          cadenceSource = CadenceSource.none;
          break;
      }
      
      // Actually disconnect the BLE device
      if (deviceToDisconnect != null) {
        await deviceToDisconnect.disconnect();
        debugPrint('✅ Disconnected $deviceType: ${deviceToDisconnect.platformName}');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error disconnecting $deviceType: $e');
      // Still clear the reference even if disconnect fails
      notifyListeners();
    }
  }
  
  /// Disconnects all devices
  Future<void> disconnectAll() async {
    await Future.wait([
      if (trainer != null) disconnectDevice('TRAINER'),
      if (heartRateSensor != null) disconnectDevice('HR'),
      if (powerMeter != null) disconnectDevice('POWER'),
      if (coreSensor != null) disconnectDevice('CORE'),
      if (cadenceSensor != null) disconnectDevice('CADENCE'),
    ]);
  }
  
  /// Gets the device type from a BluetoothDevice reference
  String? getDeviceType(blue.BluetoothDevice device) {
    if (trainer?.remoteId == device.remoteId) return 'TRAINER';
    if (heartRateSensor?.remoteId == device.remoteId) return 'HR';
    if (powerMeter?.remoteId == device.remoteId) return 'POWER';
    if (coreSensor?.remoteId == device.remoteId) return 'CORE';
    if (cadenceSensor?.remoteId == device.remoteId) return 'CADENCE';
    return null;
  }
}

