import 'package:sqflite/sqflite.dart';
import '../data/database/database_helper.dart';
import '../data/models/transaction.dart' as models;
import '../data/models/payment_mode.dart';
import '../data/models/account.dart';
import '../data/models/wallet.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/account_repository.dart';
import '../data/repositories/wallet_repository.dart';
import '../data/repositories/payment_mode_repository.dart';
import '../data/repositories/monthly_summary_repository.dart';

/// Service for handling complex transaction operations.
/// Ensures atomic updates to transactions, balances, and monthly summaries.
class TransactionService {
  final TransactionRepository _transactionRepo = TransactionRepository();
  final AccountRepository _accountRepo = AccountRepository();
  final WalletRepository _walletRepo = WalletRepository();
  final PaymentModeRepository _paymentModeRepo = PaymentModeRepository();
  final MonthlySummaryRepository _summaryRepo = MonthlySummaryRepository();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Add a new transaction with atomic balance and summary updates
  /// All updates happen within a single database transaction for consistency
  Future<int> addTransaction({
    required double amount,
    required models.TransactionType type,
    required int paymentModeId,
    int? walletId,
    required String purpose,
    required DateTime transactionDate,
  }) async {
    final db = await _dbHelper.database;
    int transactionId = -1;

    try {
      // Get payment mode BEFORE starting transaction to avoid deadlock
      final paymentMode = await _paymentModeRepo.getPaymentModeById(paymentModeId);
      if (paymentMode == null) {
        throw Exception('Payment mode not found');
      }

      // Get account BEFORE transaction
      final account = await _accountRepo.getMainAccount();
      if (account == null) {
        throw Exception('Main account not found');
      }

      // Execute all operations in a single atomic transaction
      await db.transaction((txn) async {

        // Validate wallet requirement
        if (paymentMode.requiresWallet() && walletId == null) {
          throw Exception('Wallet is required for this payment mode');
        }

        // Create transaction record
        final monthKey = models.Transaction.generateMonthKey(transactionDate);
        final transaction = models.Transaction(
          amount: amount,
          type: type,
          paymentModeId: paymentModeId,
          walletId: walletId,
          purpose: purpose,
          transactionDate: transactionDate,
          monthKey: monthKey,
          createdAt: DateTime.now(),
        );

        // Insert transaction
        transactionId = await txn.insert(
          DatabaseHelper.tableTransactions,
          transaction.toMap(),
        );

        // Update balances based on payment mode type
        if (paymentMode.affectsAccount()) {
          // Update main account balance
          await _updateAccountBalance(txn, amount, type);
        } else if (paymentMode.requiresWallet() && walletId != null) {
          // Update wallet balance
          await _updateWalletBalance(txn, walletId, amount, type);
        }
        // Cash transactions don't affect any balance

        // Update monthly summary (using account fetched before transaction)
        await _updateMonthlySummary(
          txn,
          monthKey: monthKey,
          amount: amount,
          isDebit: type == models.TransactionType.DEBIT,
          accountOpeningBalance: account.openingBalance,
        );
      });

      return transactionId;
    } catch (e) {
      print('Error adding transaction: $e');
      rethrow;
    }
  }

  /// Update main account balance within a transaction
  Future<void> _updateAccountBalance(
    DatabaseExecutor txn,
    double amount,
    models.TransactionType type,
  ) async {
    // Get account from transaction context
    final maps = await txn.query(
      DatabaseHelper.tableAccounts,
      limit: 1,
    );
    if (maps.isEmpty) {
      throw Exception('Main account not found');
    }
    final currentBalance = maps.first['current_balance'] as double;
    final accountId = maps.first['id'] as int;

    // Calculate new balance
    // Credit = add to balance, Debit = subtract from balance
    final newBalance = type == models.TransactionType.CREDIT
        ? currentBalance + amount
        : currentBalance - amount;

    // Update account balance
    await txn.update(
      DatabaseHelper.tableAccounts,
      {'current_balance': newBalance},
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }

  /// Update wallet balance within a transaction
  Future<void> _updateWalletBalance(
    DatabaseExecutor txn,
    int walletId,
    double amount,
    models.TransactionType type,
  ) async {
    // Get wallet from transaction context
    final maps = await txn.query(
      DatabaseHelper.tableWallets,
      where: 'id = ?',
      whereArgs: [walletId],
    );
    if (maps.isEmpty) {
      throw Exception('Wallet not found');
    }
    final currentBalance = maps.first['balance'] as double;

    // Calculate new balance
    // Credit = add to wallet, Debit = subtract from wallet
    final newBalance = type == models.TransactionType.CREDIT
        ? currentBalance + amount
        : currentBalance - amount;

    // Update wallet balance
    await txn.update(
      DatabaseHelper.tableWallets,
      {'balance': newBalance},
      where: 'id = ?',
      whereArgs: [walletId],
    );
  }

  /// Update monthly summary within a transaction
  Future<void> _updateMonthlySummary(
    DatabaseExecutor txn, {
    required String monthKey,
    required double amount,
    required bool isDebit,
    required double accountOpeningBalance,
  }) async {
    // Get existing summary
    final maps = await txn.query(
      DatabaseHelper.tableMonthlySummary,
      where: 'month_key = ?',
      whereArgs: [monthKey],
    );

    if (maps.isEmpty) {
      // Create new summary
      // Get previous month's closing balance
      final previousMaps = await txn.query(
        DatabaseHelper.tableMonthlySummary,
        where: 'month_key < ?',
        whereArgs: [monthKey],
        orderBy: 'month_key DESC',
        limit: 1,
      );

      final openingBalance = previousMaps.isNotEmpty
          ? previousMaps.first['closing_balance'] as double
          : accountOpeningBalance;

      final totalCredit = isDebit ? 0.0 : amount;
      final totalDebit = isDebit ? amount : 0.0;
      final closingBalance = openingBalance + totalCredit - totalDebit;

      await txn.insert(
        DatabaseHelper.tableMonthlySummary,
        {
          'month_key': monthKey,
          'opening_balance': openingBalance,
          'total_credit': totalCredit,
          'total_debit': totalDebit,
          'closing_balance': closingBalance,
        },
      );
    } else {
      // Update existing summary
      final existingSummary = maps.first;
      final newTotalCredit = (existingSummary['total_credit'] as double) +
          (isDebit ? 0.0 : amount);
      final newTotalDebit = (existingSummary['total_debit'] as double) +
          (isDebit ? amount : 0.0);
      final openingBalance = existingSummary['opening_balance'] as double;
      final newClosingBalance = openingBalance + newTotalCredit - newTotalDebit;

      await txn.update(
        DatabaseHelper.tableMonthlySummary,
        {
          'total_credit': newTotalCredit,
          'total_debit': newTotalDebit,
          'closing_balance': newClosingBalance,
        },
        where: 'month_key = ?',
        whereArgs: [monthKey],
      );
    }
  }

  /// Initialize the app with default data on first run
  Future<void> initializeDefaultData() async {
    final db = await _dbHelper.database;

    try {
      await db.transaction((txn) async {
        // Check if account already exists
        final accountMaps = await txn.query(DatabaseHelper.tableAccounts, limit: 1);
        if (accountMaps.isNotEmpty) {
          return; // Already initialized
        }

        // Create main account
        final accountId = await txn.insert(
          DatabaseHelper.tableAccounts,
          {
            'name': 'Main Account',
            'opening_balance': 0.0,
            'current_balance': 0.0,
            'created_at': DateTime.now().millisecondsSinceEpoch,
          },
        );

        print('Created main account with ID: $accountId');

        // Create default payment modes
        final paymentModes = [
          {'name': 'GPay', 'type': 'ACCOUNT'},
          {'name': 'PhonePe', 'type': 'ACCOUNT'},
          {'name': 'Debit Card', 'type': 'ACCOUNT'},
          {'name': 'Cash', 'type': 'CASH'},
          {'name': 'GPay Lite', 'type': 'WALLET'},
          {'name': 'PhonePe Lite', 'type': 'WALLET'},
        ];

        for (var mode in paymentModes) {
          await txn.insert(DatabaseHelper.tablePaymentModes, mode);
        }

        print('Created default payment modes');

        // Create default wallets for wallet-type payment modes
        final wallets = [
          {'name': 'GPay Lite Wallet', 'balance': 0.0},
          {'name': 'PhonePe Lite Wallet', 'balance': 0.0},
        ];

        for (var wallet in wallets) {
          await txn.insert(
            DatabaseHelper.tableWallets,
            {
              ...wallet,
              'created_at': DateTime.now().millisecondsSinceEpoch,
            },
          );
        }

        print('Created default wallets');
      });
    } catch (e) {
      print('Error initializing default data: $e');
      rethrow;
    }
  }
}
