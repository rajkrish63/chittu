import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ta')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Chit Notebook'**
  String get appTitle;

  /// No description provided for @myChits.
  ///
  /// In en, this message translates to:
  /// **'My Chits'**
  String get myChits;

  /// No description provided for @newChit.
  ///
  /// In en, this message translates to:
  /// **'New Chit'**
  String get newChit;

  /// No description provided for @startChit.
  ///
  /// In en, this message translates to:
  /// **'Start Chit'**
  String get startChit;

  /// No description provided for @createFirstChit.
  ///
  /// In en, this message translates to:
  /// **'Create your first chit'**
  String get createFirstChit;

  /// No description provided for @emptyChitsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offline ledger for family & friends rotating savings funds.'**
  String get emptyChitsSubtitle;

  /// No description provided for @paidSoFar.
  ///
  /// In en, this message translates to:
  /// **'Paid so far'**
  String get paidSoFar;

  /// No description provided for @receivedSoFar.
  ///
  /// In en, this message translates to:
  /// **'Received so far'**
  String get receivedSoFar;

  /// No description provided for @stillToReceive.
  ///
  /// In en, this message translates to:
  /// **'Still to receive'**
  String get stillToReceive;

  /// No description provided for @stillToPay.
  ///
  /// In en, this message translates to:
  /// **'Still to pay'**
  String get stillToPay;

  /// No description provided for @arrears.
  ///
  /// In en, this message translates to:
  /// **'Arrears'**
  String get arrears;

  /// No description provided for @prized.
  ///
  /// In en, this message translates to:
  /// **'Prized (Winner)'**
  String get prized;

  /// No description provided for @notPrized.
  ///
  /// In en, this message translates to:
  /// **'Pending Payout'**
  String get notPrized;

  /// No description provided for @postPrizeOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Post-prize commitment'**
  String get postPrizeOutstanding;

  /// No description provided for @guarantorNote.
  ///
  /// In en, this message translates to:
  /// **'Guarantor / Security Note'**
  String get guarantorNote;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @disclaimerText.
  ///
  /// In en, this message translates to:
  /// **'Chit Notebook is an offline digital ledger for organizers. It is NOT a payment app and NOT a regulated chit fund. Settlements occur outside the app.'**
  String get disclaimerText;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
