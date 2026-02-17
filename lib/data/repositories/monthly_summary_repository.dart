import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/monthly_summary.dart';

/// Repository for managing MonthlySummary operations.
/// Monthly summaries are pre-calculated and updated incrementally for performance.
class MonthlySummaryRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Get database instance
  Future<Database> get _db async => await _dbHelper.database;

  /// Create or update monthly summary
  Future<int> upsertMonthlySummary(MonthlySummary summary) async {
    final db = await _db;
    return await db.insert(
      DatabaseHelper.tableMonthlySummary,
      summary.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get monthly summary by month key
  Future<MonthlySummary?> getMonthlySummary(String monthKey) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableMonthlySummary,
      where: 'month_key = ?',
      whereArgs: [monthKey],
    );

    if (maps.isEmpty) return null;
    return MonthlySummary.fromMap(maps.first);
  }

  /// Get all monthly summaries (ordered by month descending)
  Future<List<MonthlySummary>> getAllMonthlySummaries() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableMonthlySummary,
      orderBy: 'month_key DESC',
    );

    return List.generate(maps.length, (i) => MonthlySummary.fromMap(maps[i]));
  }

  /// Get the most recent monthly summary (latest month)
  Future<MonthlySummary?> getLatestMonthlySummary() async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableMonthlySummary,
      orderBy: 'month_key DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return MonthlySummary.fromMap(maps.first);
  }

  /// Get previous month's summary
  Future<MonthlySummary?> getPreviousMonthSummary(String currentMonthKey) async {
    final db = await _db;
    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseHelper.tableMonthlySummary,
      where: 'month_key < ?',
      whereArgs: [currentMonthKey],
      orderBy: 'month_key DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return MonthlySummary.fromMap(maps.first);
  }

  /// Delete monthly summary
  Future<int> deleteMonthlySummary(String monthKey) async {
    final db = await _db;
    return await db.delete(
      DatabaseHelper.tableMonthlySummary,
      where: 'month_key = ?',
      whereArgs: [monthKey],
    );
  }

  /// Update monthly summary with new transaction
  /// This incrementally updates credits/debits and recalculates closing balance
  Future<void> updateSummaryWithTransaction({
    required String monthKey,
    required double amount,
    required bool isDebit,
    required double accountOpeningBalance,
  }) async {
    // Get existing summary or create new one
    MonthlySummary? summary = await getMonthlySummary(monthKey);
    
    if (summary == null) {
      // Create new summary if it doesn't exist
      // Opening balance = previous month's closing balance or account opening balance
      final previousMonth = await getPreviousMonthSummary(monthKey);
      final openingBalance = previousMonth?.closingBalance ?? accountOpeningBalance;
      
      summary = MonthlySummary(
        monthKey: monthKey,
        openingBalance: openingBalance,
        totalCredit: isDebit ? 0.0 : amount,
        totalDebit: isDebit ? amount : 0.0,
        closingBalance: MonthlySummary.calculateClosingBalance(
          openingBalance: openingBalance,
          totalCredit: isDebit ? 0.0 : amount,
          totalDebit: isDebit ? amount : 0.0,
        ),
      );
    } else {
      // Update existing summary
      final newTotalCredit = summary.totalCredit + (isDebit ? 0.0 : amount);
      final newTotalDebit = summary.totalDebit + (isDebit ? amount : 0.0);
      
      summary = summary.copyWith(
        totalCredit: newTotalCredit,
        totalDebit: newTotalDebit,
        closingBalance: MonthlySummary.calculateClosingBalance(
          openingBalance: summary.openingBalance,
          totalCredit: newTotalCredit,
          totalDebit: newTotalDebit,
        ),
      );
    }
    
    await upsertMonthlySummary(summary);
  }
}
