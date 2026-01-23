import 'package:flutter/material.dart';
import '../models/payment_model.dart';
import '../services/payment_service.dart';

class PaymentViewModel extends ChangeNotifier {
  final PaymentService _paymentService = PaymentService();

  List<Transaction> _transactions = [];
  List<PaymentMethod> _paymentMethods = [];
  bool _isLoading = false;
  String? _error;

  List<Transaction> get transactions => _transactions;
  List<PaymentMethod> get paymentMethods => _paymentMethods;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPaymentData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await _paymentService.getTransactionHistory();
      _paymentMethods = await _paymentService.getPaymentMethods();
    } catch (e) {
      _error = 'Failed to load payment data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> makePayment(double amount, String paymentMethodId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _paymentService.processPayment(amount, paymentMethodId);
      if (success) {
        await loadPaymentData(); // Refresh history
      }
      return success;
    } catch (e) {
      _error = 'Payment failed: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
