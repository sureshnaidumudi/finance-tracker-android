import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Singleton DatabaseHelper class for managing SQLite database operations.
/// Handles database creation, table schema, migrations, and provides
/// the database instance to repositories.
/// Just To test the git version
class DatabaseHelper {
  // Singleton instance
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  // Database configuration
  static const String _databaseName = 'finance_app.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String tableAccounts = 'accounts';
  static const String tableWallets = 'wallets';
  static const String tablePaymentModes = 'payment_modes';
  static const String tableTransactions = 'transactions';
  static const String tableMonthlySummary = 'monthly_summary';

  // Private constructor
  DatabaseHelper._internal();

  // Factory constructor returns singleton instance
  factory DatabaseHelper() {
    return _instance;
  }

  /// Get database instance (lazy initialization)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    // Get application documents directory
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);

    // Open database with version management
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables on first run
  Future<void> _onCreate(Database db, int version) async {
    // Create accounts table
    await db.execute('''
      CREATE TABLE $tableAccounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        opening_balance REAL NOT NULL,
        current_balance REAL NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Create wallets table
    await db.execute('''
      CREATE TABLE $tableWallets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        balance REAL NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Create payment_modes table
    await db.execute('''
      CREATE TABLE $tablePaymentModes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL CHECK(type IN ('ACCOUNT', 'WALLET', 'CASH'))
      )
    ''');

    // Create transactions table with proper indexing
    await db.execute('''
      CREATE TABLE $tableTransactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('DEBIT', 'CREDIT')),
        payment_mode_id INTEGER NOT NULL,
        wallet_id INTEGER,
        purpose TEXT NOT NULL,
        transaction_date INTEGER NOT NULL,
        month_key TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        FOREIGN KEY (payment_mode_id) REFERENCES $tablePaymentModes (id),
        FOREIGN KEY (wallet_id) REFERENCES $tableWallets (id)
      )
    ''');

    // Create indexes for fast transaction queries
    await db.execute('''
      CREATE INDEX idx_transactions_date 
      ON $tableTransactions (transaction_date)
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_month_key 
      ON $tableTransactions (month_key)
    ''');

    // Create monthly_summary table
    await db.execute('''
      CREATE TABLE $tableMonthlySummary (
        month_key TEXT PRIMARY KEY,
        opening_balance REAL NOT NULL,
        total_credit REAL NOT NULL,
        total_debit REAL NOT NULL,
        closing_balance REAL NOT NULL
      )
    ''');

    print('Database tables created successfully');
  }

  /// Handle database upgrades/migrations
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future schema changes here
    // Example: if (oldVersion < 2) { await db.execute('ALTER TABLE...'); }
    print('Database upgraded from version $oldVersion to $newVersion');
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Delete database (for testing purposes)
  Future<void> deleteDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
