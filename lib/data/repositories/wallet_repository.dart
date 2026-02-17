import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/wallet.dart';

/// Repository for managing Wallet operations.
/// Wallets have independent balances and are used with wallet-type payment modes.
class WalletRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Get database instance
  Future<Database> get _db async => await _dbHelper.database;

  /// Create a new wallet
  Future<int> createWallet(Wallet wallet) async {
    final db = await _db;
    return await db.insert(
      DatabaseHelper.tableWallets,
      wallet.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get wallet by ID
  Future<Wallet?> getWalletById(int id) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableWallets,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Wallet.fromMap(maps.first);
  }

  /// Get all wallets
  Future<List<Wallet>> getAllWallets() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableWallets,
      orderBy: 'name ASC',
    );

    return List.generate(maps.length, (i) => Wallet.fromMap(maps[i]));
  }

  /// Update wallet balance
  /// This should be called within a transaction context
  Future<int> updateWalletBalance(int walletId, double newBalance) async {
    final db = await _db;
    return await db.update(
      DatabaseHelper.tableWallets,
      {'balance': newBalance},
      where: 'id = ?',
      whereArgs: [walletId],
    );
  }

  /// Update wallet details
  Future<int> updateWallet(Wallet wallet) async {
    final db = await _db;
    return await db.update(
      DatabaseHelper.tableWallets,
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }

  /// Delete wallet
  Future<int> deleteWallet(int id) async {
    final db = await _db;
    return await db.delete(
      DatabaseHelper.tableWallets,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get wallet by name
  Future<Wallet?> getWalletByName(String name) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableWallets,
      where: 'name = ?',
      whereArgs: [name],
    );

    if (maps.isEmpty) return null;
    return Wallet.fromMap(maps.first);
  }
}
