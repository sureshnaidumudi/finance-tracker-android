# Finance Tracker - Personal Finance Management App

An offline-first, production-grade personal finance tracking Android application built with Flutter.

## Features

✅ **Offline-First**: All data stored locally in SQLite, no cloud dependency  
✅ **Low Storage**: Optimized for minimal storage usage (~500 MB total constraint)  
✅ **Clean Architecture**: Organized with data, domain, and presentation layers  
✅ **Fast Performance**: Pre-calculated monthly summaries for instant app startup  
✅ **Multiple Payment Modes**: GPay, PhonePe, Debit Card, Cash, Wallet support  
✅ **Atomic Transactions**: All balance updates happen safely in database transactions  
✅ **Monthly Accounting**: Automatic monthly summaries with opening/closing balances  

## Architecture

```
lib/
├── data/
│   ├── database/
│   │   └── database_helper.dart          # SQLite database management
│   ├── models/
│   │   ├── account.dart                  # Main bank account model
│   │   ├── wallet.dart                   # Wallet (GPay Lite, PhonePe Lite) model
│   │   ├── payment_mode.dart             # Payment methods model
│   │   ├── transaction.dart              # Transaction model
│   │   └── monthly_summary.dart          # Pre-calculated monthly summary
│   └── repositories/
│       ├── account_repository.dart
│       ├── wallet_repository.dart
│       ├── payment_mode_repository.dart
│       ├── transaction_repository.dart
│       └── monthly_summary_repository.dart
├── domain/
│   └── transaction_service.dart          # Business logic for transactions
└── presentation/
    └── screens/
        ├── home_screen.dart              # Main dashboard
        └── add_transaction_screen.dart   # Transaction entry form
```

## Database Schema

### Tables

- **accounts**: Main bank account with opening and current balance
- **wallets**: Independent wallet balances (GPay Lite, PhonePe Lite)
- **payment_modes**: Available payment methods (ACCOUNT, WALLET, CASH types)
- **transactions**: All financial transactions with indexed date and month fields
- **monthly_summary**: Pre-calculated monthly accounting summaries

### Transaction Rules

1. **ACCOUNT type payment modes** (GPay, PhonePe, Debit Card) affect the main account balance
2. **WALLET type payment modes** require wallet selection and affect wallet balance
3. **CASH type** only records transactions without balance impact
4. All balance updates are **atomic** using SQLite transactions

## Getting Started

### Prerequisites

- Flutter SDK (3.27.2 or higher)
- Android SDK (API level 34+)
- Java 17 or higher

### Installation

1. **Add Flutter to PATH** (add to ~/.bashrc or ~/.zshrc):
   ```bash
   export PATH="$HOME/flutter/bin:$PATH"
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Build the app**:
   ```bash
   # Debug build
   flutter build apk --debug
   
   # Release build
   flutter build apk --release
   ```

4. **Install on device**:
   ```bash
   # Connect Android device via USB and enable USB debugging
   flutter install
   
   # Or manually install the APK
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

### Running in Development

```bash
# Connect Android device or start emulator
flutter devices

# Run the app
flutter run
```

## Usage

### First Launch

On first launch, the app automatically creates:
- Main account with ₹0 balance
- Default payment modes (GPay, PhonePe, Debit Card, Cash, GPay Lite, PhonePe Lite)
- Default wallets (GPay Lite Wallet, PhonePe Lite Wallet)

### Adding Transactions

1. Tap the **"Add Transaction"** button
2. Select **Expense** or **Income**
3. Enter the **amount**
4. Choose a **payment mode**
5. If wallet payment mode, select the **wallet**
6. Enter a **purpose/description**
7. Pick a **date** (defaults to today)
8. Tap **"Add Transaction"**

### Home Screen

- **Main Account Balance**: Shows current bank account balance
- **Wallets**: Displays all wallet balances
- **Monthly Summary**: Current month's opening balance, income, expenses, and closing balance
- **Recent Transactions**: Last 20 transactions

## Technical Details

### Storage Optimization

- No images, videos, or binary data stored
- Text and numeric data only
- Paginated transaction queries
- Indexed database fields for fast lookups

### Performance

- Monthly summaries pre-calculated and stored
- No full transaction history recalculation on startup
- Atomic database transactions for consistency
- Efficient query patterns with proper indexing

### State Management

- Simple setState and ChangeNotifier pattern
- No heavy state management frameworks
- Clean separation of concerns

## Build Output

The release APK is located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

Size: ~21 MB (includes Flutter framework)

## Troubleshooting

### Build Issues

If you encounter Gradle/Java compatibility issues, the proper versions are already configured:
- Android Gradle Plugin: 8.3.0
- Gradle: 8.4
- Requires Java 17+

### Database Issues

To inspect the database during development, you can use Android Studio's Database Inspector or connect via `adb shell`.

## App Structure

- **Models**: Define data structures matching SQLite schema
- **Repositories**: Handle database CRUD operations
- **Services**: Contain business logic with atomic transaction handling
- **Screens**: Flutter UI components with minimal state management

## Future Enhancements (Not Implemented)

The following features are intentionally excluded per requirements:
- ❌ Cloud sync
- ❌ User authentication
- ❌ Charts and visualizations
- ❌ Export functionality
- ❌ Categories and tags
- ❌ Budget tracking
- ❌ Recurring transactions
- ❌ Background services
- ❌ Notifications

---

**Last Updated**: February 2, 2026  
**Flutter Version**: 3.27.2  
**Minimum Android SDK**: 21 (Android 5.0)  
**Target Android SDK**: 34 (Android 14)

