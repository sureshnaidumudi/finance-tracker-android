/// Payment mode types
enum PaymentModeType {
  ACCOUNT, // GPay, PhonePe, Debit Card - affects main account
  WALLET,  // GPay Lite, PhonePe Lite - affects wallet balance
  CASH,    // Cash transactions - no balance impact
}

/// Represents a payment method available for transactions.
class PaymentMode {
  final int? id;
  final String name;
  final PaymentModeType type;

  PaymentMode({
    this.id,
    required this.name,
    required this.type,
  });

  /// Convert PaymentMode object to Map for SQLite insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name, // Store enum as string
    };
  }

  /// Create PaymentMode object from SQLite Map
  factory PaymentMode.fromMap(Map<String, dynamic> map) {
    return PaymentMode(
      id: map['id'] as int,
      name: map['name'] as String,
      type: PaymentModeType.values.firstWhere(
        (e) => e.name == map['type'],
      ),
    );
  }

  /// Check if this payment mode affects the main account balance
  bool affectsAccount() {
    return type == PaymentModeType.ACCOUNT;
  }

  /// Check if this payment mode requires a wallet selection
  bool requiresWallet() {
    return type == PaymentModeType.WALLET;
  }

  /// Check if this is a cash payment (no balance impact)
  bool isCash() {
    return type == PaymentModeType.CASH;
  }
}
