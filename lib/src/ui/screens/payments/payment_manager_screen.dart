import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../viewmodels/payment_manager_viewmodel.dart';
import '../../../models/payment_model.dart';
import 'package:intl/intl.dart';

class PaymentManagerScreen extends StatefulWidget {
  const PaymentManagerScreen({super.key});

  @override
  State<PaymentManagerScreen> createState() => _PaymentManagerScreenState();
}

class _PaymentManagerScreenState extends State<PaymentManagerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PaymentManagerViewModel>().loadManagerData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager View'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () => context.read<PaymentManagerViewModel>().loadManagerData(),
          ),
        ],
      ),
      body: Consumer<PaymentManagerViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.stats == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null && viewModel.stats == null) {
            return Center(child: Text(viewModel.error!));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatsGrid(viewModel.stats!),
              const SizedBox(height: 24),
              const Text(
                'All System Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...viewModel.allTransactions.map((tx) => _buildManagerTransactionItem(tx)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(dynamic stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _statCard('Total Revenue', '€${stats.totalRevenue}', Colors.green),
        _statCard('Active Subs', '${stats.activeSubscriptions}', Colors.blue),
        _statCard('Churn Rate', '${stats.churnRate}%', Colors.red),
        _statCard('MoM Growth', '+12.5%', Colors.purple),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildManagerTransactionItem(Transaction tx) {
    final dateFormat = DateFormat('MMM dd, HH:mm');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _getStatusColor(tx.status).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(tx.status),
              size: 16,
              color: _getStatusColor(tx.status),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.description, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                Text(dateFormat.format(tx.date), style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          Text(
            '€${tx.amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed: return Colors.green;
      case TransactionStatus.pending: return Colors.orange;
      case TransactionStatus.failed: return Colors.red;
    }
  }

  IconData _getStatusIcon(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed: return LucideIcons.check;
      case TransactionStatus.pending: return LucideIcons.clock;
      case TransactionStatus.failed: return LucideIcons.alertCircle;
    }
  }
}
