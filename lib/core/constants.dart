/// UI labels (Tamil first, per v1 decision). Keys stored in DB are english_snake.
class Labels {
  static const txnTypes = {
    'contribution': 'வசூல்',
    'payout': 'பணம் எடுப்பு',
    'interest': 'வட்டி',
    'penalty': 'அபராதம்',
    'dividend': 'பங்கு',
  };

  static const roundStatuses = {
    'open': 'தொடங்கியது',
    'collected': 'வசூல் முடிஞ்சிடுச்சு',
    'paid_out': 'payout முடிஞ்சிடுச்சு',
  };

  static const interestModes = {
    'late_fee': 'தாமத வட்டி (late-fee)',
    'recipient_pays': 'பிடித்தவர் வட்டி கட்டுவது (recipient-pays)',
  };

  static const periods = {'weekly': 'வாரம்', 'monthly': 'மாதம்'};
}
