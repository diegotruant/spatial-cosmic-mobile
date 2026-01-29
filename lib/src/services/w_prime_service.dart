import 'dart:async';
import 'package:flutter/foundation.dart';
import 'athlete_profile_service.dart';
import 'bluetooth_service.dart';

class WPrimeService extends ChangeNotifier {
  // Constants
  static const double _rechargeFactor = 0.1; // "Simple Exponential" factor as requested

  // Internal state
  double _currentWPrime = 0.0;
  double _maxWPrime = 0.0;
  double _cp = 0.0;
  
  // Timer for calculation
  DateTime? _lastUpdateTime;
  
  // Dependencies
  BluetoothService? _bluetooth;
  AthleteProfileService? _profile;

  // Getters
  double get currentWPrime => _currentWPrime;
  double get maxWPrime => _maxWPrime;
  bool get isDepleting => (_bluetooth?.power ?? 0) > _cp;
  double get cp => _cp;

  WPrimeService();

  /// Called by ChangeNotifierProxyProvider whenever dependencies change.
  /// Also serves as the "tick" for calculation if BluetoothService notifies frequently.
  void update(BluetoothService bluetooth, AthleteProfileService profile) {
    _bluetooth = bluetooth;
    _profile = profile;

    _syncProfileData();
    _calculateWPrime();
  }

  void _syncProfileData() {
    if (_profile == null) return;
    
    // Use FTP as Critical Power (CP)
    // If CP should be different, we might need a specific CP field in AthleteProfile
    if (_profile!.ftp != null) {
      _cp = _profile!.ftp!;
    }

    // Use wPrime from profile as Max Capacity
    if (_profile!.wPrime != null) {
      double newMax = _profile!.wPrime!;
      
      // If Max W' changes (e.g. profile update), scale current W'
      if (newMax != _maxWPrime && _maxWPrime > 0) {
        // Option 1: Reset to full?
        // Option 2: Scale proportionally?
        // Let's just update limit. If new max is higher, we just have more room to recharge.
        // If new max is lower, clamp.
      }
      
      _maxWPrime = newMax;
      
      // Initializaion: if not initialized or invalid, start full
      if (_currentWPrime <= 0 && _maxWPrime > 0 && _lastUpdateTime == null) {
        _currentWPrime = _maxWPrime;
      }
    }
  }

  void _calculateWPrime() {
    if (_bluetooth == null) return;
    if (_maxWPrime <= 0 || _cp <= 0) return; // Cannot calculate without valid profile

    final now = DateTime.now();
    
    // First run initialization
    if (_lastUpdateTime == null) {
      _lastUpdateTime = now;
      return;
    }

    // Calculate time delta
    final dtSeconds = now.difference(_lastUpdateTime!).inMicroseconds / 1000000.0;
    _lastUpdateTime = now;

    if (dtSeconds <= 0) return;

    final currentPower = _bluetooth!.power;

    if (currentPower > _cp) {
      // Depletion Mode
      // User Logic: Consume = (Power - CP) * Time
      double depletion = (currentPower - _cp) * dtSeconds;
      _currentWPrime -= depletion;
    } else {
      // Recharge Mode
      // User Logic: Recharge = (CP - Power) * Constant (0.1)
      // Assuming this is a rate per second.
      // Recharge Amount = Rate * Time
      double recharge = (_cp - currentPower) * _rechargeFactor * dtSeconds;
      _currentWPrime += recharge;
    }

    // Constraints
    if (_currentWPrime > _maxWPrime) _currentWPrime = _maxWPrime;
    if (_currentWPrime < 0) _currentWPrime = 0;
    
    // Notify UI
    notifyListeners();
  }
  
  /// Manually reset W' to full (e.g. start of new ride)
  void reset() {
    _currentWPrime = _maxWPrime;
    _lastUpdateTime = null; // Reset time tracking
    notifyListeners();
  }
}
