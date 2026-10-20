# Project Overview

## Purpose
**Chit Notebook** (`chit_notebook`) is a digital notebook for family & friends chit funds (ROSCA — Rotating Savings and Credit Association). 
- **Core Principle:** Money moves strictly outside the app (cash, UPI, bank transfer); the app functions purely as the single source of truth ledger.
- **Primary User:** The organizer who runs the chit.
- **Secondary Users:** Group members who participate passively. Members do not install an app, create an account, or log in; they receive updates, reminder deep links, and monthly statements via WhatsApp and PDF.
- **Privacy & Connectivity:** 100% offline-first, local-only SQLite storage, zero backend, zero analytics, zero external cloud dependency.

## Main technologies
- **Framework:** Flutter (Dart SDK `>=3.0.0 <4.0.0`)
- **Local Database:** `sqflite` (`^2.3.0`) with SQLite (DDL enforces foreign keys, check constraints, indexes)
- **Path Utilities:** `path` (`^1.8.3`), `path_provider` (`^2.1.1`)
- **Formatting & Localization:** `intl` (`^0.19.0`) for currency formatting (₹), date formatting, and Tamil-first UI
- **Deep Linking / Reminders:** `url_launcher` (`^6.2.2`) generating direct `wa.me` WhatsApp links
- **Sharing:** `share_plus` (`^10.0.0`) for sharing PDF statements and JSON database backups
- **State Management (Planned / In Pipeline):** `flutter_riverpod` (`^2.5`)
- **PDF Generation (Planned / In Pipeline):** `pdf` (`^3.11`)
- **Linter & Code Quality:** `flutter_lints` (`^4.0.0`)

## Entry points
- **Application Entry:** [`lib/main.dart`](file:///d:/codebase/chit-notebook/lib/main.dart) (`main()` executes `runApp(const ChitNotebookApp())`)
- **Root Widget & Theming:** [`lib/app.dart`](file:///d:/codebase/chit-notebook/lib/app.dart) (`ChitNotebookApp`, configured with Material 3, seed black theme, home screen root)
- **Database Schema Definition:** [`lib/data/database/schema.dart`](file:///d:/codebase/chit-notebook/lib/data/database/schema.dart)
- **Database Helper Singleton:** [`lib/data/database/database_helper.dart`](file:///d:/codebase/chit-notebook/lib/data/database/database_helper.dart)

## Important commands
- **Install dependencies:**
  ```bash
  flutter pub get
  ```
- **Run application:**
  ```bash
  flutter run
  ```
- **Run automated tests:**
  ```bash
  flutter test
  ```
- **Run linter / static analysis:**
  ```bash
  flutter analyze
  ```
- **Build release Android APK:**
  ```bash
  flutter build apk
  ```
