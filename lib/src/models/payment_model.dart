enum TransactionStatus { pending, completed, failed }

class Transaction {
  final String id;
  final double amount;
  final DateTime date;
  final String description;
  final TransactionStatus status;

  Transaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.description,
    required this.status,
  });
}

class PaymentMethod {
  final String id;
  final String type; // e.g., 'credit_card', 'paypal'
  final String lastFour;
  final String provider;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.lastFour,
    required this.provider,
  });
}
