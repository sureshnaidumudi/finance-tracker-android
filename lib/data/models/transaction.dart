import 'package:intl/intl.dart';

/// Transaction types
enum TransactionType {
  DEBIT,  // Expense
  CREDIT, // Income/Refund
}

/// Represents a financial transaction in the system.
/// Every transaction affects either:
/// - Main account balance (if payment mode is ACCOUNT type)
/// - Wallet balance (if payment mode is WALLET type)
/// - No balance (if payment mode is CASH type, only records transaction)
class Transaction {
  final int? id;
  final double amount;
  final TransactionType type;
  final int paymentModeId;
  final int? walletId; // Only set if payment mode requires wallet
  final String purpose;
  final DateTime transactionDate;
  final String monthKey; // Format: YYYY-MM, e.g., "2026-02"
  final DateTime createdAt;

  Transaction({
    this.id,
    required this.amount,
    required this.type,
    required this.paymentModeId,
    this.walletId,
    required this.purpose,
    required this.transactionDate,
    required this.monthKey,
    required this.createdAt,
  });

  /// Generate month key from a date (YYYY-MM format)
  static String generateMonthKey(DateTime date) {
    return DateFormat('yyyy-MM').format(date);
  }

  /// Convert Transaction object to Map for SQLite insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'type': type.name,
      'payment_mode_id': paymentModeId,
      'wallet_id': walletId,
      'purpose': purpose,
      'transaction_date': transactionDate.millisecondsSinceEpoch,
      'month_key': monthKey,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Create Transaction object from SQLite Map
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int,
      amount: map['amount'] as double,
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
      ),
      paymentModeId: map['payment_mode_id'] as int,
      walletId: map['wallet_id'] as int?,
      purpose: map['purpose'] as String,
      transactionDate: DateTime.fromMillisecondsSinceEpoch(
        map['transaction_date'] as int,
      ),
      monthKey: map['month_key'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int,
      ),
    );
  }

  /// Check if this is a debit transaction
  bool isDebit() => type == TransactionType.DEBIT;

  /// Check if this is a credit transaction
  bool isCredit() => type == TransactionType.CREDIT;
}
