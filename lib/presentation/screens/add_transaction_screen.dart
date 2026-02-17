import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/payment_mode.dart';
import '../../data/models/wallet.dart';
import '../../data/models/transaction.dart' as models;
import '../../data/repositories/payment_mode_repository.dart';
import '../../data/repositories/wallet_repository.dart';
import '../../domain/transaction_service.dart';

/// Screen for adding a new transaction.
/// Includes amount input, debit/credit toggle, payment mode selection,
/// wallet selection (if needed), purpose, and date picker.
class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final PaymentModeRepository _paymentModeRepo = PaymentModeRepository();
  final WalletRepository _walletRepo = WalletRepository();
  final TransactionService _transactionService = TransactionService();

  models.TransactionType _transactionType = models.TransactionType.DEBIT;
  List<PaymentMode> _paymentModes = [];
  PaymentMode? _selectedPaymentMode;
  List<Wallet> _wallets = [];
  Wallet? _selectedWallet;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  /// Load payment modes and wallets
  Future<void> _loadData() async {
    try {
      final paymentModes = await _paymentModeRepo.getAllPaymentModes();
      final wallets = await _walletRepo.getAllWallets();

      setState(() {
        _paymentModes = paymentModes;
        _wallets = wallets;
        _selectedPaymentMode = paymentModes.isNotEmpty ? paymentModes.first : null;
        _isLoadingData = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() => _isLoadingData = false);
    }
  }

  /// Submit the transaction
  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedPaymentMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment mode')),
      );
      return;
    }

    // Validate wallet selection if required
    if (_selectedPaymentMode!.requiresWallet() && _selectedWallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a wallet')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final amount = double.parse(_amountController.text);
      
      await _transactionService.addTransaction(
        amount: amount,
        type: _transactionType,
        paymentModeId: _selectedPaymentMode!.id!,
        walletId: _selectedWallet?.id,
        purpose: _purposeController.text,
        transactionDate: _selectedDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction added successfully')),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      print('Error adding transaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Show date picker
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Transaction Type Toggle
                    _buildTransactionTypeToggle(),
                    const SizedBox(height: 24),

                    // Amount Input
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        if (double.parse(value) <= 0) {
                          return 'Amount must be greater than 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Payment Mode Dropdown
                    DropdownButtonFormField<PaymentMode>(
                      value: _selectedPaymentMode,
                      decoration: const InputDecoration(
                        labelText: 'Payment Mode',
                        border: OutlineInputBorder(),
                      ),
                      items: _paymentModes.map((mode) {
                        return DropdownMenuItem(
                          value: mode,
                          child: Text(mode.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPaymentMode = value;
                          // Reset wallet selection when payment mode changes
                          if (value?.requiresWallet() == false) {
                            _selectedWallet = null;
                          }
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a payment mode';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Wallet Dropdown (only show if payment mode requires wallet)
                    if (_selectedPaymentMode?.requiresWallet() == true) ...[
                      DropdownButtonFormField<Wallet>(
                        value: _selectedWallet,
                        decoration: const InputDecoration(
                          labelText: 'Wallet',
                          border: OutlineInputBorder(),
                        ),
                        items: _wallets.map((wallet) {
                          return DropdownMenuItem(
                            value: wallet,
                            child: Text(wallet.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedWallet = value);
                        },
                        validator: (value) {
                          if (_selectedPaymentMode?.requiresWallet() == true &&
                              value == null) {
                            return 'Please select a wallet';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Purpose Input
                    TextFormField(
                      controller: _purposeController,
                      decoration: const InputDecoration(
                        labelText: 'Purpose/Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a purpose';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Date Picker
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Transaction Date',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('dd MMM yyyy').format(_selectedDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitTransaction,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Add Transaction',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  /// Build transaction type toggle (Debit/Credit)
  Widget _buildTransactionTypeToggle() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTypeButton(
                    label: 'Expense',
                    icon: Icons.arrow_downward,
                    type: models.TransactionType.DEBIT,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeButton(
                    label: 'Income',
                    icon: Icons.arrow_upward,
                    type: models.TransactionType.CREDIT,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual type button
  Widget _buildTypeButton({
    required String label,
    required IconData icon,
    required models.TransactionType type,
    required Color color,
  }) {
    final isSelected = _transactionType == type;

    return InkWell(
      onTap: () {
        setState(() => _transactionType = type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha((0.1 * 255).round()) : Colors.grey[100],
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey[600],
              size: 32,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
