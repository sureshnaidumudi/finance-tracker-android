import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/payment_mode.dart';

/// Repository for managing PaymentMode operations.
/// Payment modes define how transactions are processed and which balances they affect.
class PaymentModeRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Get database instance
  Future<Database> get _db async => await _dbHelper.database;

  /// Create a new payment mode
  Future<int> createPaymentMode(PaymentMode paymentMode) async {
    final db = await _db;
    return await db.insert(
      DatabaseHelper.tablePaymentModes,
      paymentMode.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get payment mode by ID
  Future<PaymentMode?> getPaymentModeById(int id) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tablePaymentModes,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return PaymentMode.fromMap(maps.first);
  }

  /// Get all payment modes
  Future<List<PaymentMode>> getAllPaymentModes() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tablePaymentModes,
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => PaymentMode.fromMap(maps[i]));
  }

  /// Get payment modes by type
  Future<List<PaymentMode>> getPaymentModesByType(
      PaymentModeType type) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tablePaymentModes,
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => PaymentMode.fromMap(maps[i]));
  }

  /// Update payment mode
  Future<int> updatePaymentMode(PaymentMode paymentMode) async {
    final db = await _db;
    return await db.update(
      DatabaseHelper.tablePaymentModes,
      paymentMode.toMap(),
      where: 'id = ?',
      whereArgs: [paymentMode.id],
    );
  }

  /// Delete payment mode
  Future<int> deletePaymentMode(int id) async {
    final db = await _db;
    return await db.delete(
      DatabaseHelper.tablePaymentModes,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get payment mode by name
  Future<PaymentMode?> getPaymentModeByName(String name) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tablePaymentModes,
      where: 'name = ?',
      whereArgs: [name],
    );

    if (maps.isEmpty) return null;
    return PaymentMode.fromMap(maps.first);
  }
}
