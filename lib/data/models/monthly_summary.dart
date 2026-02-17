/// Represents a pre-calculated monthly financial summary.
/// This ensures fast app startup by avoiding full transaction history calculation.
/// Each month's summary is updated incrementally as transactions are added.
class MonthlySummary {
  final String monthKey; // Primary key, format: YYYY-MM
  final double openingBalance;
  final double totalCredit;
  final double totalDebit;
  final double closingBalance;

  MonthlySummary({
    required this.monthKey,
    required this.openingBalance,
    required this.totalCredit,
    required this.totalDebit,
    required this.closingBalance,
  });

  /// Convert MonthlySummary object to Map for SQLite insertion
  Map<String, dynamic> toMap() {
    return {
      'month_key': monthKey,
      'opening_balance': openingBalance,
      'total_credit': totalCredit,
      'total_debit': totalDebit,
      'closing_balance': closingBalance,
    };
  }

  /// Create MonthlySummary object from SQLite Map
  factory MonthlySummary.fromMap(Map<String, dynamic> map) {
    return MonthlySummary(
      monthKey: map['month_key'] as String,
      openingBalance: map['opening_balance'] as double,
      totalCredit: map['total_credit'] as double,
      totalDebit: map['total_debit'] as double,
      closingBalance: map['closing_balance'] as double,
    );
  }

  /// Calculate closing balance from opening balance and transactions
  /// Closing = Opening + Credits - Debits
  static double calculateClosingBalance({
    required double openingBalance,
    required double totalCredit,
    required double totalDebit,
  }) {
    return openingBalance + totalCredit - totalDebit;
  }

  /// Create a copy of MonthlySummary with updated fields
  MonthlySummary copyWith({
    String? monthKey,
    double? openingBalance,
    double? totalCredit,
    double? totalDebit,
    double? closingBalance,
  }) {
    return MonthlySummary(
      monthKey: monthKey ?? this.monthKey,
      openingBalance: openingBalance ?? this.openingBalance,
      totalCredit: totalCredit ?? this.totalCredit,
      totalDebit: totalDebit ?? this.totalDebit,
      closingBalance: closingBalance ?? this.closingBalance,
    );
  }
}
