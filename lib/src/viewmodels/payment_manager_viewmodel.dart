import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class PaymentManagerViewModel extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();

  List<Transaction> _allTransactions = [];
  PaymentStats? _stats;
  bool _isLoading = false;
  String? _error;

  List<Transaction> get allTransactions => _allTransactions;
  PaymentStats? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadManagerData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _paymentService.getAllTransactions(),
        _paymentService.getPaymentStats(),
      ]);
      
      _allTransactions = results[0] as List<Transaction>;
      _stats = results[1] as PaymentStats;
    } catch (e) {
      _error = 'Failed to load manager data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Filter logic can be added here later
}
