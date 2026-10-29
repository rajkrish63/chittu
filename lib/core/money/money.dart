/// Pure-Dart integer-paise representation of currency.
/// Never uses floating-point numbers for money storage or calculation.
/// 1 INR = 100 Paise.
class Money implements Comparable<Money> {
  final int paise;

  const Money.fromPaise(this.paise);

  factory Money.fromRupees(num rupees) {
    return Money.fromPaise((rupees * 100).round());
  }

  static const Money zero = Money.fromPaise(0);

  /// Safely attempts to parse user text input into a [Money] instance, returning null if invalid.
  static Money? tryParse(String? input) {
    if (input == null) return null;
    final cleaned = input.replaceAll('₹', '').replaceAll(',', '').trim();
    if (cleaned.isEmpty) return null;
    try {
      return Money.parse(cleaned);
    } catch (_) {
      return null;
    }
  }

  /// Parses user text input like "5000", "₹5,000", "5,000.50", "10000" into integer paise.
  factory Money.parse(String input) {
    var cleaned = input.replaceAll('₹', '').replaceAll(',', '').trim();
    if (cleaned.isEmpty) return Money.zero;

    final parts = cleaned.split('.');
    final rupees = int.tryParse(parts[0]) ?? 0;
    int paise = 0;
    if (parts.length > 1) {
      var paiseStr = parts[1];
      if (paiseStr.length == 1) paiseStr += '0';
      if (paiseStr.length > 2) paiseStr = paiseStr.substring(0, 2);
      paise = int.tryParse(paiseStr) ?? 0;
    }
    final sign = cleaned.startsWith('-') ? -1 : 1;
    final total = (rupees.abs() * 100 + paise) * sign;
    return Money.fromPaise(total);
  }

  int get inPaise => paise;
  double get inRupees => paise / 100.0;
  bool get isZero => paise == 0;
  bool get isPositive => paise > 0;
  bool get isNegative => paise < 0;

  Money operator +(Money other) => Money.fromPaise(paise + other.paise);
  Money operator -(Money other) => Money.fromPaise(paise - other.paise);
  Money operator *(num multiplier) => Money.fromPaise((paise * multiplier).round());
  Money operator ~/(int divisor) => Money.fromPaise(paise ~/ divisor);
  Money abs() => Money.fromPaise(paise.abs());

  @override
  int compareTo(Money other) => paise.compareTo(other.paise);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Money && runtimeType == other.runtimeType && paise == other.paise;

  @override
  int get hashCode => paise.hashCode;

  /// Formats according to Indian numbering system (e.g. ₹1,00,000 or ₹5,000)
  String format({String currency = '₹', bool includePaise = false}) {
    final isNeg = paise < 0;
    final absPaise = paise.abs();
    final wholeRupees = absPaise ~/ 100;
    final remPaise = absPaise % 100;

    final formattedWhole = _formatIndian(wholeRupees);
    final sign = isNeg ? '-' : '';

    if (includePaise && remPaise > 0) {
      final paiseStr = remPaise.toString().padLeft(2, '0');
      return '$sign$currency$formattedWhole.$paiseStr';
    }
    return '$sign$currency$formattedWhole';
  }

  /// Indian Lakhs and Crores grouping: ##,##,###
  static String _formatIndian(int n) {
    if (n < 1000) return n.toString();
    final s = n.toString();
    final lastThree = s.substring(s.length - 3);
    var remaining = s.substring(0, s.length - 3);

    final parts = <String>[];
    while (remaining.length > 2) {
      parts.insert(0, remaining.substring(remaining.length - 2));
      remaining = remaining.substring(0, remaining.length - 2);
    }
    if (remaining.isNotEmpty) {
      parts.insert(0, remaining);
    }
    return '${parts.join(',')},$lastThree';
  }

  @override
  String toString() => format();
}
