/// Represents a wallet (GPay Lite, PhonePe Lite) with independent balance.
/// Wallets maintain their own balance separate from the main account.
class Wallet {
  final int? id;
  final String name;
  final double balance;
  final DateTime createdAt;

  Wallet({
    this.id,
    required this.name,
    required this.balance,
    required this.createdAt,
  });

  /// Convert Wallet object to Map for SQLite insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Create Wallet object from SQLite Map
  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] as int,
      name: map['name'] as String,
      balance: map['balance'] as double,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Create a copy of Wallet with updated fields
  Wallet copyWith({
    int? id,
    String? name,
    double? balance,
    DateTime? createdAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
