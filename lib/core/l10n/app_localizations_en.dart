// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Chit Notebook';

  @override
  String get myChits => 'My Chits';

  @override
  String get newChit => 'New Chit';

  @override
  String get startChit => 'Start Chit';

  @override
  String get createFirstChit => 'Create your first chit';

  @override
  String get emptyChitsSubtitle =>
      'Offline ledger for family & friends rotating savings funds.';

  @override
  String get paidSoFar => 'Paid so far';

  @override
  String get receivedSoFar => 'Received so far';

  @override
  String get stillToReceive => 'Still to receive';

  @override
  String get stillToPay => 'Still to pay';

  @override
  String get arrears => 'Arrears';

  @override
  String get prized => 'Prized (Winner)';

  @override
  String get notPrized => 'Pending Payout';

  @override
  String get postPrizeOutstanding => 'Post-prize commitment';

  @override
  String get guarantorNote => 'Guarantor / Security Note';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get disclaimerText =>
      'Chit Notebook is an offline digital ledger for organizers. It is NOT a payment app and NOT a regulated chit fund. Settlements occur outside the app.';
}
