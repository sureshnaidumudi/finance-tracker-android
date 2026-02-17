import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/transaction.dart' as models;

/// Repository for managing Transaction operations.
/// Provides CRUD operations and query methods for transactions.
class TransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Get database instance
  Future<Database> get _db async => await _dbHelper.database;

  /// Create a new transaction
  Future<int> createTransaction(models.Transaction transaction) async {
    final db = await _db;
    return await db.insert(
      DatabaseHelper.tableTransactions,
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get transaction by ID
  Future<models.Transaction?> getTransactionById(int id) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableTransactions,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return models.Transaction.fromMap(maps.first);
  }

  /// Get all transactions (with pagination)
  Future<List<models.Transaction>> getAllTransactions({
    int? limit,
    int? offset,
  }) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableTransactions,
      orderBy: 'transaction_date DESC, created_at DESC',
      limit: limit,
      offset: offset,
    );

    return List.generate(maps.length, (i) => models.Transaction.fromMap(maps[i]));
  }

  /// Get transactions for a specific month
  Future<List<models.Transaction>> getTransactionsByMonth(String monthKey) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableTransactions,
      where: 'month_key = ?',
      whereArgs: [monthKey],
      orderBy: 'transaction_date DESC',
    );

    return List.generate(maps.length, (i) => models.Transaction.fromMap(maps[i]));
  }

  /// Get transactions within a date range
  Future<List<models.Transaction>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableTransactions,
      where: 'transaction_date BETWEEN ? AND ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'transaction_date DESC',
    );

    return List.generate(maps.length, (i) => models.Transaction.fromMap(maps[i]));
  }

  /// Get total debit for a specific month
  Future<double> getTotalDebitForMonth(String monthKey) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total 
      FROM ${DatabaseHelper.tableTransactions}
      WHERE month_key = ? AND type = 'DEBIT'
    ''', [monthKey]);

    return (result.first['total'] as double?) ?? 0.0;
  }

  /// Get total credit for a specific month
  Future<double> getTotalCreditForMonth(String monthKey) async {
    final db = await _db;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total 
      FROM ${DatabaseHelper.tableTransactions}
      WHERE month_key = ? AND type = 'CREDIT'
    ''', [monthKey]);

    return (result.first['total'] as double?) ?? 0.0;
  }

  /// Update transaction
  Future<int> updateTransaction(models.Transaction transaction) async {
    final db = await _db;
    return await db.update(
      DatabaseHelper.tableTransactions,
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  /// Delete transaction
  Future<int> deleteTransaction(int id) async {
    final db = await _db;
    return await db.delete(
      DatabaseHelper.tableTransactions,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get transaction count
  Future<int> getTransactionCount() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableTransactions}',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
