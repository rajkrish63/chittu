import 'locale_controller.dart';

class S {
  static bool get _ta => AppLocaleController.instance.isTamil;

  // App & Common
  static String get appTitle => _ta ? 'சீட்டு நோட்புக்' : 'Chit Notebook';
  static String get myChits => _ta ? 'என் சீட்கள்' : 'My Chits';
  static String get settings => _ta ? 'அமைப்புகள்' : 'Settings';
  static String get cancel => _ta ? 'ரத்து' : 'Cancel';
  static String get delete => _ta ? 'நீக்கு' : 'Delete';
  static String get ok => _ta ? 'சரி' : 'OK';
  static String get save => _ta ? 'சேமி' : 'Save';
  static String get done => _ta ? 'முடிந்தது' : 'Done';
  static String get warning => _ta ? 'எச்சரிக்கை' : 'Warning';
  static String get error => _ta ? 'பிழை' : 'Error';
  static String get active => _ta ? 'செயலில் உள்ளது' : 'Active';
  static String get completed => _ta ? 'முடிந்தது' : 'Completed';
  static String get noPhone => _ta ? 'எண் இல்லை' : 'No phone';

  // Home Screen
  static String get newChit => _ta ? 'புதிய சீட்டு' : 'New Chit';
  static String get startChit => _ta ? 'சீட்டு தொடங்கு' : 'Start Chit';
  static String get createFirstChit => _ta ? 'உங்கள் முதல் சீட்டை உருவாக்குங்கள்' : 'Create your first chit';
  static String get emptyChitsSubtitle => _ta
      ? 'குடும்பம் மற்றும் நண்பர்களுக்கான சீட்டு நிதிகளை எளிதாகக் கண்காணித்து நிர்வகிக்கலாம்.'
      : 'Easily track and manage chit funds for family and friends.';
  static String get totalChits => _ta ? 'மொத்த சீட்கள்' : 'Total Chits';
  static String get activeCountLabel => _ta ? 'செயலில்' : 'Active';
  static String totalRounds(int count) => _ta ? 'மொத்தம்: $count தவணைகள்' : 'Total: $count rounds';
  static String roundProgress(int current, int total) => _ta ? 'ரவுண்டு $current / $total' : 'Round $current / $total';
  static String dueDate(String date) => _ta ? 'கடைசி நாள்: $date' : 'Due: $date';

  // Settings Screen
  static String get language => _ta ? 'மொழி (Language)' : 'Language';
  static String get languageSubtitle => _ta ? 'பயன்பாட்டின் மொழியை தேர்வு செய்க' : 'Select app display language';
  static String get english => 'English';
  static String get tamil => 'தமிழ் (Tamil)';
  static String get backupAndData => _ta ? 'காப்புநகல் & தரவு' : 'Backup & Data';
  static String get exportBackup => _ta ? 'காப்புநகல் ஏற்றுமதி (JSON Backup)' : 'Export JSON Backup';
  static String get exportBackupSubtitle => _ta ? 'எல்லா சீட்டு தரவுகளையும் பகிர் அல்லது சேமி' : 'Share or save all chit fund data';
  static String get backupReady => _ta ? 'காப்புநகல் தயாராக உள்ளது!' : 'Backup export ready!';
  static String get aboutApp => _ta ? 'செயலியை பற்றி' : 'About App';
  static String get appVersion => _ta ? 'பதிப்பு 0.1.0 (Family & Friends ROSCA Tracker)' : 'Version 0.1.0 (Family & Friends ROSCA Tracker)';
  static String get privacyNotice => _ta ? 'தரவு அனைத்தும் உங்கள் மொபைலில் மட்டுமே சேமிக்கப்படுகிறது (Offline-first).' : 'All data stays entirely on your device (Offline-first).';

  // New Chit Screen
  static String get createChitTitle => _ta ? 'புதிய சீட்டு உருவாக்குதல்' : 'Create New Chit';
  static String get basicDetailsSection => _ta ? '1. அடிப்படை விவரங்கள்' : '1. Basic Details';
  static String get chitNameLabel => _ta ? 'சீட்டு பெயர்' : 'Chit Name';
  static String get chitNameHint => _ta ? 'எ.கா. குடும்ப சீட்டு 2026' : 'e.g. Family Chit 2026';
  static String get defaultChitName => _ta ? 'குடும்ப சீட்டு' : 'Family Chit';
  static String get nameRequired => _ta ? 'பெயர் தேவை' : 'Name is required';
  static String get contributionLabel => _ta ? 'தவணை தொகை (Contribution ₹)' : 'Contribution Amount (₹)';
  static String get validAmountRequired => _ta ? 'சரியான தொகை தேவை' : 'Valid amount required';
  static String get periodLabel => _ta ? 'கால இடைவெளி (Period)' : 'Period';
  static String get monthly => _ta ? 'மாதம் (Monthly)' : 'Monthly';
  static String get weekly => _ta ? 'வாரம் (Weekly)' : 'Weekly';
  static String startDateLabel(String date) => _ta ? 'தொடக்க நாள்: $date' : 'Start Date: $date';
  static String get dueDayLabel => _ta ? 'தவணை நாள்' : 'Due Day';
  static String get interestModeSection => _ta ? '2. வட்டி முறை' : '2. Interest Mode';
  static String get interestRateLabel => _ta ? 'வட்டி விகிதம் (Interest Rate %)' : 'Interest Rate (%)';
  static String get lateFeeTitle => _ta ? 'தாமத வட்டி (Late-fee)' : 'Late fee';
  static String get lateFeeSubtitle => _ta ? 'தாமதமாக கட்டுபவர் மட்டும் வட்டி செலுத்துவார்' : 'Only members who pay late pay interest';
  static String get recipientPaysTitle => _ta ? 'பிடித்தவர் வட்டி கட்டுவது (Recipient-pays)' : 'Recipient pays';
  static String get recipientPaysSubtitle => _ta ? 'பணம் எடுப்பவர் வட்டி கட்டுவார், மற்றவர்களுக்கு பகிர்ந்தளிக்கப்படும்' : 'The member taking the pot pays interest; distributed as dividend';
  static String get membersOrderSection => _ta ? '3. உறுப்பினர்கள் மற்றும் முறை' : '3. Members & Payout Order';
  static String get rotationOrderSubtitle => _ta ? 'வரிசை எண்தான் பணம் எடுக்கும் முறை (Rotation Order):' : 'List order determines the payout rotation sequence:';
  static String get memberNameLabel => _ta ? 'உறுப்பினர் பெயர்' : 'Member Name';
  static String get memberNameHint => _ta ? 'பெயர்' : 'Name';
  static String get phoneLabel => _ta ? 'போன் எண்' : 'Phone Number';
  static String get addMemberTooltip => _ta ? 'உறுப்பினர் சேர்' : 'Add Member';
  static String get summaryPreviewSection => _ta ? '4. முன்னோட்டம் & சுருக்கம்' : '4. Preview & Summary';
  static String get totalMembers => _ta ? 'மொத்த உறுப்பினர்கள்:' : 'Total Members:';
  static String membersCount(int count) => _ta ? '$count பேர்' : '$count members';
  static String get totalRoundsLabel => _ta ? 'மொத்த ரவுண்டுகள்:' : 'Total Rounds:';
  static String roundsCount(int count) => _ta ? '$count தவணைகள்' : '$count rounds';
  static String get potPerRound => _ta ? 'ஒவ்வொரு ரவுண்டு Pot தொகை:' : 'Pot per Round:';
  static String get createChitButton => _ta ? 'சீட்டை உருவாக்கு' : 'Create Chit';
  static String get atLeastOneMember => _ta ? 'குறைந்தது ஒரு உறுப்பினர் தேவை' : 'At least one member is required';
  static String get addMembersAlert => _ta ? 'உறுப்பினர்களை சேர்க்கவும்' : 'Please add members';
  static String get chitCreatedSuccess => _ta ? 'சீட்டு வெற்றிகரமாக உருவாக்கப்பட்டது!' : 'Chit created successfully!';

  // Group Detail Screen
  static String get groupDetailsNotFound => _ta ? 'சீட்டு விவரம் கிடைக்கவில்லை' : 'Chit details not found';
  static String get deleteChitPrompt => _ta ? 'சீட்டை நீக்க வேண்டுமா?' : 'Delete this chit?';
  static String get deleteChitWarning => _ta ? 'பரிவர்த்தனைகள் எதுவும் இல்லை என்றால் மட்டுமே நீக்க முடியும்.' : 'Can only be deleted if there are no recorded transactions.';
  static String get chitDeleted => _ta ? 'சீட்டு நீக்கப்பட்டது' : 'Chit deleted';
  static String get cannotDelete => _ta ? 'நீக்க இயலவில்லை' : 'Cannot delete';
  static String get deleteChitTooltip => _ta ? 'சீட்டை நீக்கு' : 'Delete Chit';
  static String membersTab(int count) => _ta ? 'உறுப்பினர்கள் ($count)' : 'Members ($count)';
  static String roundsTab(int count) => _ta ? 'ரவுண்டுகள் ($count)' : 'Rounds ($count)';
  static String currentRoundProgress(int current, int total) => _ta ? 'நடப்பு ரவுண்டு $current / $total' : 'Current Round $current / $total';
  static String get recipientLabel => _ta ? 'பணம் எடுப்பவர் (Recipient):' : 'Recipient:';
  static String get notAssigned => _ta ? 'குறிக்கப்படவில்லை' : 'Not assigned';
  static String get potAmountLabel => _ta ? 'Pot தொகை:' : 'Pot Amount:';
  static String accountableLabel(String? name) => _ta ? 'பொறுப்பாளர்: ${name ?? "இல்லை"}' : 'Organizer: ${name ?? "None"}';
  static String get viewRoundDetails => _ta ? 'வசூல் குறி / விவரம் பார்' : 'View Collections / Details';
  static String contributionChip(String amount) => _ta ? 'தவணை: $amount' : 'Contribution: $amount';
  static String interestChip(double rate, String mode) => _ta
      ? 'வட்டி: $rate% (${mode == "late_fee" ? "Late fee" : "Recipient pays"})'
      : 'Interest: $rate% (${mode == "late_fee" ? "Late fee" : "Recipient pays"})';
  static String roundTitleItem(int seq, String recipientName) => _ta ? 'ரவுண்டு $seq — $recipientName' : 'Round $seq — $recipientName';
  static String dueDateItem(String date) => _ta ? 'தவணை நாள்: $date' : 'Due date: $date';

  // Round Detail Screen
  static String roundTitle(int seq) => _ta ? 'ரவுண்டு $seq' : 'Round $seq';
  static String get roundDetailsNotFound => _ta ? 'ரவுண்டு விவரம் கிடைக்கவில்லை' : 'Round details not found';
  static String get changeRecipientTooltip => _ta ? 'பணம் எடுப்பவரை மாற்று' : 'Change Recipient';
  static String get cannotModifyPaidOut => _ta ? 'இந்த ரவுண்டுக்கு Payout முடிந்துவிட்டது. மாற்ற இயலாது.' : 'Payout is completed for this round. Cannot modify.';
  static String get cancelCollectionPrompt => _ta ? 'வசூலை ரத்து செய்யவா?' : 'Cancel collection entry?';
  static String cancelCollectionContent(String memberName) => _ta
      ? '$memberName அவர்களின் தவணை பதிவை நீக்க வேண்டுமா?'
      : 'Remove contribution record for $memberName?';
  static String get lateFeeDialogTitle => _ta ? 'தாமத வட்டி (Late Fee)' : 'Late Fee Confirmation';
  static String lateFeeDialogContent(String dueDate, String lateFee) => _ta
      ? 'தவணை தேதி முடிந்துவிட்டது ($dueDate).\n\n$lateFee தாமத வட்டி கணக்கிடப்படும்.\nதாமதக் கட்டணமாக குறிக்கவா?'
      : 'Due date has passed ($dueDate).\n\nLate fee of $lateFee applies.\nMark as late payment?';
  static String get onTimeNoFee => _ta ? 'வட்டி வேண்டாம் (On-time)' : 'On-time (No fee)';
  static String get markLate => _ta ? 'தாமதம் (Late)' : 'Mark Late';
  static String get noPhoneForMember => _ta ? 'இந்த உறுப்பினருக்கு போன் எண் இல்லை' : 'No phone number for this member';
  static String get allPaidNotice => _ta ? 'அனைவரும் செலுத்திவிட்டனர்!' : 'All members have paid!';
  static String unpaidCountNotice(int count) => _ta ? '$count நபர்கள் இன்னும் செலுத்தவில்லை' : '$count members have not paid yet';
  static String get payoutConfirmationTitle => _ta ? 'Payout உறுதிப்படுத்தல்' : 'Payout Confirmation';
  static String get payoutRecipient => _ta ? 'பணம் பெறுபவர்:' : 'Recipient:';
  static String get unknownRecipient => _ta ? 'தெரியவில்லை' : 'Unknown';
  static String get totalPotAmount => _ta ? 'மொத்த Pot தொகை:' : 'Total Pot Amount:';
  static String recipientInterestLabel(double rate) => _ta ? 'பிடித்தவர் வட்டி ($rate%):' : 'Recipient Interest ($rate%):';
  static String get dividendPerMemberLabel => _ta ? 'மற்றவர்களுக்கு பங்கு (Dividend/member):' : 'Dividend per member:';
  static String arrearsWarning(int count) => _ta
      ? '$count நபர்கள் இன்னும் கட்டவில்லை. அவர்களுக்கு நிலுவை (Arrears) என்று பதிவாகும்.'
      : '$count member(s) have not paid. Arrears will be recorded for them.';
  static String get payoutSuccess => _ta ? 'Payout வெற்றிகரமாக பதிவு செய்யப்பட்டது!' : 'Payout recorded successfully!';
  static String get confirmPayoutButton => _ta ? 'Payout செய் (Confirm & Close Round)' : 'Confirm Payout & Close Round';
  static String get changeRecipientDialogTitle => _ta ? 'பணம் எடுப்பவரை மாற்றுதல்' : 'Change Pot Recipient';
  static String get newRecipientLabel => _ta ? 'புதிய நபர்' : 'New Recipient';
  static String get reasonLabel => _ta ? 'காரணம் (Reason - Mandatory)' : 'Reason (Mandatory)';
  static String get reasonHint => _ta ? 'எ.கா. அவசர தேவைக்காக மாற்றப்பட்டது' : 'e.g. Swapped for family emergency';
  static String get memberCollectionProgress => _ta ? 'உறுப்பினர்கள் வசூல் விவரம்' : 'Member Collections';
  static String progressCount(int paid, int total) => _ta ? '$paid / $total முடிந்தது' : '$paid / $total completed';
  static String get recipientBadge => _ta ? 'பணம் பெறுபவர் (Recipient)' : 'Recipient';
  static String get noRecipient => _ta ? 'யாரும் இல்லை' : 'None';
  static String get paidStatus => _ta ? 'செலுத்தப்பட்டது (Paid)' : 'Paid';
  static String get pendingStatus => _ta ? 'பாக்கி (Pending)' : 'Pending';
  static String get markPaid => _ta ? 'Mark Paid' : 'Mark Paid';
  static String get paidCheck => _ta ? 'Paid ✓' : 'Paid ✓';
  static String allPaidCountMessage(int pendingCount) => pendingCount == 0
      ? (_ta ? 'அனைவரும் கட்டினர்' : 'All members paid')
      : (_ta ? '$pendingCount பேர் பாக்கி' : '$pendingCount pending');
  static String get remindButton => _ta ? 'நினைவூட்டு' : 'Remind';
  static String get payoutButton => _ta ? 'Payout →' : 'Payout →';

  // Member Ledger Screen
  static String get accountDetails => _ta ? 'கணக்கு விவரம்' : 'Account Details';
  static String get detailsNotFound => _ta ? 'விவரங்கள் கிடைக்கவில்லை' : 'Details not found';
  static String get shareStatementTooltip => _ta ? 'அறிக்கையை பகிர்' : 'Share Statement';
  static String get netPosition => _ta ? 'நிகர நிலை (Net Position)' : 'Net Position';
  static String get netGain => _ta ? '(பெற்ற தொகை அதிகம் / Net Gain)' : '(Net Gain / Received More)';
  static String get netDue => _ta ? '(செலுத்த வேண்டிய தொகை / Net Due)' : '(Net Due / Owed)';
  static String get timelineTitle => _ta ? 'பரிவர்த்தனை வரலாறு (Timeline)' : 'Transaction Timeline';
  static String recordCount(int count) => _ta ? '$count பதிவுகள்' : '$count records';
  static String get noTransactions => _ta ? 'பரிவர்த்தனைகள் எதுவும் இல்லை' : 'No transactions recorded yet';
  static String get metricPaid => _ta ? 'வசூல் (Paid)' : 'Paid';
  static String get metricTaken => _ta ? 'எடுத்தது (Taken)' : 'Taken';
  static String get metricInterest => _ta ? 'வட்டி (Interest)' : 'Interest';
  static String get metricDividend => _ta ? 'பங்கு (Dividend)' : 'Dividend';
  static String get currentArrears => _ta ? 'தற்போதைய பாக்கி (Arrears):' : 'Current Arrears:';

  // Transaction types localized
  static String txnType(String type) {
    if (_ta) {
      switch (type) {
        case 'contribution': return 'தவணை செலுத்தியது (Contribution)';
        case 'payout': return 'சீட்டு எடுத்தது (Payout)';
        case 'interest': return 'வட்டி செலுத்தியது (Interest)';
        case 'penalty': return 'தாமதக் கட்டணம் (Late fee)';
        case 'dividend': return 'பங்கு தொகை (Dividend)';
        default: return type;
      }
    } else {
      switch (type) {
        case 'contribution': return 'Contribution';
        case 'payout': return 'Pot Payout';
        case 'interest': return 'Interest Paid';
        case 'penalty': return 'Late Fee';
        case 'dividend': return 'Dividend Earned';
        default: return type;
      }
    }
  }

  // Round status localized
  static String roundStatus(String status) {
    if (_ta) {
      switch (status) {
        case 'open': return 'திறந்துள்ளது';
        case 'collected': return 'வசூலானது';
        case 'paid_out': return 'முடிந்தது';
        default: return status;
      }
    } else {
      switch (status) {
        case 'open': return 'Open';
        case 'collected': return 'Collected';
        case 'paid_out': return 'Paid Out';
        default: return status;
      }
    }
  }

  // Periods localized
  static String period(String p) {
    if (_ta) {
      return p == 'weekly' ? 'வாரம்' : 'மாதம்';
    } else {
      return p == 'weekly' ? 'Weekly' : 'Monthly';
    }
  }

  // Statement text builder
  static String generateStatement({
    required String chitName,
    required String memberName,
    required String? phone,
    required String dateFormatted,
    required String currency,
    required double contributed,
    required double taken,
    required double interestPaid,
    required double dividends,
    required double arrears,
    required double net,
    required String Function(String currency, double amount) formatMoneyFn,
  }) {
    final netSign = net >= 0 ? '+' : '';
    if (_ta) {
      return '''
📄 *சீட்டு கணக்கு அறிக்கை (Statement)*
--------------------------------
சீட்டு: $chitName
உறுப்பினர்: $memberName
போன்: ${phone ?? '-'}
தேதி: $dateFormatted

*கணக்கு சுருக்கம் (Summary):*
• வசூல் செலுத்தியது: ${formatMoneyFn(currency, contributed)}
• சீட்டு எடுத்தது: ${formatMoneyFn(currency, taken)}
• வட்டி செலுத்தியது: ${formatMoneyFn(currency, interestPaid)}
• பங்கு பெற்றது: ${formatMoneyFn(currency, dividends)}
• நிலுவை (Arrears): ${formatMoneyFn(currency, arrears)}
--------------------------------
*நிகர நிலை (Net Position):* $netSign${formatMoneyFn(currency, net)}
--------------------------------
_Chit Notebook வழியாக பகிரப்பட்டது_
''';
    } else {
      return '''
📄 *Chit Fund Account Statement*
--------------------------------
Chit: $chitName
Member: $memberName
Phone: ${phone ?? '-'}
Date: $dateFormatted

*Account Summary:*
• Total Contributed: ${formatMoneyFn(currency, contributed)}
• Total Pot Received: ${formatMoneyFn(currency, taken)}
• Interest Paid: ${formatMoneyFn(currency, interestPaid)}
• Dividend Received: ${formatMoneyFn(currency, dividends)}
• Pending Arrears: ${formatMoneyFn(currency, arrears)}
--------------------------------
*Net Position:* $netSign${formatMoneyFn(currency, net)}
--------------------------------
_Shared via Chit Notebook_
''';
    }
  }
}
