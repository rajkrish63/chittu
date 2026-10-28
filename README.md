# Chit Notebook (சிட்டு நோட்புக்)

An offline-first, privacy-focused digital ledger for family, friends, and community chit funds (ROSCAs / Rotating Savings and Credit Associations). 

> **"Money moves outside the app; the app is the ledger."**  
> Designed for the chit organizer. Members receive clean, instant statements via WhatsApp.

---

## 🌟 Key Features

- **🔒 100% Offline & Private:** Built with SQLite on-device storage. No tracking, no external accounts, no cloud dependencies.
- **🌐 Bilingual (English & Tamil):** Default English interface with a seamless one-tap toggle to Tamil (தமிழ்). Preference is persisted automatically.
- **📐 Robust Closed-Loop Accounting:**
  - **Accurate Arrears Tracking:** Accurately distinguishes active and past-due unpaid rounds from future rounds, preserving defaults from closed rounds.
  - **Closed-Loop Interest & Dividends:** In `recipient_pays` mode, interest paid by the round recipient is automatically distributed as dividends to other members, strictly summing to zero across the group.
  - **Dynamic Balance Calculation:** Member balances (`net = (taken + dividends) - (contributed + interestPaid)`) are always derived from the immutable ledger transaction stream rather than stored as mutable state.
  - **Strict Calendar-Day Deadlines:** Late fee cutoffs respect full end-of-calendar-day deadlines.
- **📲 Instant WhatsApp Statements:** Pre-formats clean ledger statements with automatic Indian mobile number (`+91`) normalization and opens `wa.me` deep links directly.
- **💾 JSON Backup & Restore:** Single-tap JSON export and import for seamless phone-to-phone data migration or disaster recovery.
- **⚡ Lean & Fast (Ponytail Principles):** Zero bloat. Stripped of heavy, unused dependencies for instant startup and lightweight APK footprints.

---

## 📱 App Walkthrough & Screens

Chit Notebook is organized into a clean bottom-navigation layout:

| Tab / Screen | Description |
| :--- | :--- |
| **My Chits (`HomeScreen`)** | Overview of all active and completed chit groups with progress indicators and round counters. |
| **New Chit (`NewChitScreen`)** | Intuitive setup for chit groups: member names, pool amount, cycle interval, and interest model (`none`, `recipient_pays`, or `late_fee`). |
| **Group Details (`GroupDetailScreen`)** | Complete round-by-round rotation timeline, status chips, payout recipients, and member rosters. |
| **Round Operations (`RoundDetailScreen`)** | Real-time collection tracker, contribution checklist with late fee indicators, recipient picker, and pot payout execution. |
| **Member Ledger (`MemberLedgerScreen`)** | Comprehensive member financial statement: contributed vs. received breakdown, net position badge, full transaction timeline, and WhatsApp share button. |
| **Settings (`SettingsScreen`)** | Language selection (English / தமிழ்) and JSON database backup/restore utilities. |

---

## 🏗 Architecture

```
lib/
├── main.dart                      # Application bootstrap & SharedPreferences init
├── app.dart                       # MaterialApp configuration & theme setup
├── core/
│   ├── strings.dart               # Complete English & Tamil localization dictionary
│   ├── app_locale_controller.dart # Change-notifier for runtime language switching
│   └── utils.dart                 # Formatting, calendar-day math, WhatsApp deep links
├── data/
│   ├── database/
│   │   ├── schema.dart            # DDL schema definitions (indices & foreign keys)
│   │   └── database_helper.dart   # SQLite lifecycle, migrations, and JSON backup
│   ├── models/
│   │   ├── chit_group.dart        # Group configuration & cycle metadata
│   │   ├── member.dart            # Member profiles & derived balance models
│   │   ├── chit_round.dart        # Round state, dates, and pot values
│   │   └── ledger_txn.dart        # Immutable audit ledger entries
│   └── repositories/
│       ├── group_repository.dart  # Group generation & round-robin rotation setup
│       ├── round_repository.dart  # Contributions, closed-loop payouts & status updates
│       └── member_repository.dart # Dynamic financial statements & arrears queries
└── features/
    ├── home/                      # HomeScreen with bottom navigation bar
    ├── group/                     # Chit creation wizard & group details
    ├── round/                     # Round collection & payout management
    ├── ledger/                    # Member statement ledger & WhatsApp sharing
    └── settings/                  # Language selector & database backup/restore
```

---

## 🧮 Accounting & Financial Rules

1. **Transaction Integrity:** Every monetary movement (contribution, pot payout, interest payment, or dividend distribution) is stored as an immutable `ledger_txn` record.
2. **Referential Integrity:** SQLite foreign keys are explicitly enforced (`PRAGMA foreign_keys = ON`). Deleting a group cascades cleanly.
3. **Safe Deletion:** Groups can only be deleted if zero financial transactions have been posted.
4. **Closed-Loop Balance:**
   $$\text{Recipient Dividend} = \frac{\text{Pot} \times \text{Interest Rate}}{\text{Total Members} - 1}$$
   The pot recipient pays the interest, which is divided evenly and credited as dividends to all other active members.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.22.0 or higher recommended)
- Android Studio / VS Code / Antigravity IDE

### Installation

```bash
# Clone the repository
git clone https://github.com/rajkrish63/chittu.git
cd chittu

# Install dependencies
flutter pub get

# Run on connected device or emulator
flutter run
```

---

## 🧪 Testing & Code Quality

The project includes unit and widget tests covering financial math, closed-loop calculations, SQLite serialization, and dynamic localization:

```bash
# Run all unit and widget tests
flutter test

# Run static code analysis
flutter analyze
```

Both tests and analyzer pass with zero issues.

---

## 📄 License

This project is open-source under the MIT License. Feel free to adapt it for community, family, or self-help group financial tracking.
