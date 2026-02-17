import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/account.dart';
import '../../data/models/wallet.dart';
import '../../data/models/monthly_summary.dart';
import '../../data/models/transaction.dart' as models;
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../data/repositories/monthly_summary_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../domain/transaction_service.dart';
import 'add_transaction_screen.dart';

/// Home screen displaying account balances, wallet balances,
/// monthly summary, and recent transactions.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AccountRepository _accountRepo = AccountRepository();
  final WalletRepository _walletRepo = WalletRepository();
  final MonthlySummaryRepository _summaryRepo = MonthlySummaryRepository();
  final TransactionRepository _transactionRepo = TransactionRepository();
  final TransactionService _transactionService = TransactionService();

  Account? _mainAccount;
  List<Wallet> _wallets = [];
  MonthlySummary? _currentMonthSummary;
  List<models.Transaction> _recentTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeAndLoadData();
  }

  /// Initialize default data and load all information
  Future<void> _initializeAndLoadData() async {
    try {
      // Initialize default data on first run
      await _transactionService.initializeDefaultData();
      
      // Load data
      await _loadData();
    } catch (e) {
      print('Error initializing app: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  /// Load all data from database
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load main account
      final account = await _accountRepo.getMainAccount();
      
      // Load all wallets
      final wallets = await _walletRepo.getAllWallets();
      
      // Load current month summary
      final currentMonthKey = models.Transaction.generateMonthKey(DateTime.now());
      final summary = await _summaryRepo.getMonthlySummary(currentMonthKey);
      
      // Load recent transactions (last 20)
      final transactions = await _transactionRepo.getAllTransactions(limit: 20);

      setState(() {
        _mainAccount = account;
        _wallets = wallets;
        _currentMonthSummary = summary;
        _recentTransactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Navigate to add transaction screen
  Future<void> _navigateToAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
    );

    // Reload data if transaction was added
    if (result == true) {
      await _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Tracker'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main Account Balance Card
                    _buildAccountCard(),
                    const SizedBox(height: 16),
                    
                    // Wallets Section
                    if (_wallets.isNotEmpty) ...[
                      _buildWalletsSection(),
                      const SizedBox(height: 16),
                    ],
                    
                    // Monthly Summary
                    _buildMonthlySummaryCard(),
                    const SizedBox(height: 16),
                    
                    // Recent Transactions
                    _buildRecentTransactionsSection(),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddTransaction,
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// Build main account balance card
  Widget _buildAccountCard() {
    final balance = _mainAccount?.currentBalance ?? 0.0;
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _mainAccount?.name ?? 'Main Account',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currencyFormat.format(balance),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: balance >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build wallets section
  Widget _buildWalletsSection() {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Wallets',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ..._wallets.map((wallet) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: Text(wallet.name),
                trailing: Text(
                  currencyFormat.format(wallet.balance),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: wallet.balance >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ),
            )),
      ],
    );
  }

  /// Build monthly summary card
  Widget _buildMonthlySummaryCard() {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final monthFormat = DateFormat('MMMM yyyy');
    final currentMonth = monthFormat.format(DateTime.now());

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentMonth,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            if (_currentMonthSummary != null) ...[
              _buildSummaryRow(
                'Opening Balance',
                _currentMonthSummary!.openingBalance,
                currencyFormat,
              ),
              _buildSummaryRow(
                'Total Income',
                _currentMonthSummary!.totalCredit,
                currencyFormat,
                color: Colors.green,
              ),
              _buildSummaryRow(
                'Total Expenses',
                _currentMonthSummary!.totalDebit,
                currencyFormat,
                color: Colors.red,
              ),
              const Divider(height: 24),
              _buildSummaryRow(
                'Closing Balance',
                _currentMonthSummary!.closingBalance,
                currencyFormat,
                isBold: true,
              ),
            ] else
              const Text('No transactions this month'),
          ],
        ),
      ),
    );
  }

  /// Build a summary row
  Widget _buildSummaryRow(
    String label,
    double amount,
    NumberFormat format, {
    Color? color,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            format.format(amount),
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build recent transactions section
  Widget _buildRecentTransactionsSection() {
    final currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Transactions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_recentTransactions.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No transactions yet')),
            ),
          )
        else
          ..._recentTransactions.map((transaction) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    transaction.isDebit()
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: transaction.isDebit() ? Colors.red : Colors.green,
                  ),
                  title: Text(transaction.purpose),
                  subtitle: Text(dateFormat.format(transaction.transactionDate)),
                  trailing: Text(
                    '${transaction.isDebit() ? '-' : '+'}${currencyFormat.format(transaction.amount)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: transaction.isDebit() ? Colors.red : Colors.green,
                    ),
                  ),
                ),
              )),
      ],
    );
  }
}
