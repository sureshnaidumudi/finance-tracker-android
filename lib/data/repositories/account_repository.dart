import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/account.dart';

/// Repository for managing Account operations.
/// Provides CRUD operations and balance updates for the main account.
class AccountRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Get database instance
  Future<Database> get _db async => await _dbHelper.database;

  /// Create a new account
  Future<int> createAccount(Account account) async {
    final db = await _db;
    return await db.insert(
      DatabaseHelper.tableAccounts,
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get main account (there should only be one)
  Future<Account?> getMainAccount() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableAccounts,
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Account.fromMap(maps.first);
  }

  /// Get account by ID
  Future<Account?> getAccountById(int id) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableAccounts,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Account.fromMap(maps.first);
  }

  /// Update account balance
  /// This should be called within a transaction context
  Future<int> updateAccountBalance(int accountId, double newBalance) async {
    final db = await _db;
    return await db.update(
      DatabaseHelper.tableAccounts,
      {'current_balance': newBalance},
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  /// Update account details
  Future<int> updateAccount(Account account) async {
    final db = await _db;
    return await db.update(
      DatabaseHelper.tableAccounts,
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  /// Delete account
  Future<int> deleteAccount(int id) async {
    final db = await _db;
    return await db.delete(
      DatabaseHelper.tableAccounts,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get all accounts
  Future<List<Account>> getAllAccounts() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableAccounts,
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) => Account.fromMap(maps[i]));
  }
}
