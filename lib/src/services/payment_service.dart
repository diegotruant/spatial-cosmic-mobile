import '../models/payment_model.dart';

class PaymentStats {
  final double totalRevenue;
  final int activeSubscriptions;
  final double churnRate;
  final List<double> monthlyRevenue;

  PaymentStats({
    required this.totalRevenue,
    required this.activeSubscriptions,
    required this.churnRate,
    required this.monthlyRevenue,
  });
}

class PaymentService {
  // Client Methods
  Future<List<Transaction>> getTransactionHistory() async {
    await Future.delayed(const Duration(seconds: 1));
    return _mockTransactions.take(5).toList();
  }

  Future<bool> processPayment(double amount, String paymentMethodId) async {
    await Future.delayed(const Duration(seconds: 2));
    return true; 
  }

  Future<List<PaymentMethod>> getPaymentMethods() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      PaymentMethod(id: 'pm_1', type: 'credit_card', lastFour: '4242', provider: 'Visa'),
    ];
  }

  // Manager/Admin Methods
  Future<List<Transaction>> getAllTransactions() async {
    await Future.delayed(const Duration(seconds: 1));
    return _mockTransactions;
  }

  Future<PaymentStats> getPaymentStats() async {
    await Future.delayed(const Duration(seconds: 1));
    return PaymentStats(
      totalRevenue: 12450.75,
      activeSubscriptions: 248,
      churnRate: 2.5,
      monthlyRevenue: [1200, 1500, 1800, 1400, 2100, 2500],
    );
  }

  // Shared Mock Data
  final List<Transaction> _mockTransactions = [
    Transaction(id: '1', amount: 49.99, date: DateTime.now().subtract(const Duration(hours: 2)), description: 'Monthly Subscription - User A', status: TransactionStatus.completed),
    Transaction(id: '2', amount: 49.99, date: DateTime.now().subtract(const Duration(hours: 5)), description: 'Monthly Subscription - User B', status: TransactionStatus.completed),
    Transaction(id: '3', amount: 49.99, date: DateTime.now().subtract(const Duration(days: 1)), description: 'Monthly Subscription - User C', status: TransactionStatus.failed),
    Transaction(id: '4', amount: 49.99, date: DateTime.now().subtract(const Duration(days: 1, hours: 2)), description: 'Monthly Subscription - User D', status: TransactionStatus.completed),
    Transaction(id: '5', amount: 49.99, date: DateTime.now().subtract(const Duration(days: 2)), description: 'Monthly Subscription - User E', status: TransactionStatus.pending),
    Transaction(id: '6', amount: 49.99, date: DateTime.now().subtract(const Duration(days: 3)), description: 'Monthly Subscription - User F', status: TransactionStatus.completed),
  ];
}
