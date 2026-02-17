/// Represents a bank account in the finance tracking system.
/// Currently, the app supports ONE main account.
class Account {
  final int? id;
  final String name;
  final double openingBalance;
  final double currentBalance;
  final DateTime createdAt;

  Account({
    this.id,
    required this.name,
    required this.openingBalance,
    required this.currentBalance,
    required this.createdAt,
  });

  /// Convert Account object to Map for SQLite insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'opening_balance': openingBalance,
      'current_balance': currentBalance,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  /// Create Account object from SQLite Map
  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int,
      name: map['name'] as String,
      openingBalance: map['opening_balance'] as double,
      currentBalance: map['current_balance'] as double,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  /// Create a copy of Account with updated fields
  Account copyWith({
    int? id,
    String? name,
    double? openingBalance,
    double? currentBalance,
    DateTime? createdAt,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
