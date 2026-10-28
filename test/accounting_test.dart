import 'package:flutter_test/flutter_test.dart';
import 'package:chit_notebook/core/utils.dart';
import 'package:chit_notebook/data/models/chit_group.dart';
import 'package:chit_notebook/data/models/member.dart';
import 'package:chit_notebook/data/models/ledger_txn.dart';
import 'package:chit_notebook/data/repositories/member_repository.dart';

void main() {
  group('Utils & Financial Math', () {
    test('formatMoney handles positive, zero, and negative amounts', () {
      expect(formatMoney('₹', 5000), '₹5,000');
      expect(formatMoney('₹', 0), '₹0');
      expect(formatMoney('₹', -1500), '-₹1,500');
    });

    test('monthlyDueDate clamps properly for short months (e.g. Feb)', () {
      final start = DateTime(2026, 1, 15);
      // Next month is February 2026 (28 days)
      final febDue = monthlyDueDate(start, 31, 1);
      expect(febDue.year, 2026);
      expect(febDue.month, 2);
      expect(febDue.day, 28);
    });

    test('waUrl adds country code 91 for 10-digit Indian numbers', () {
      final url = waUrl('9876543210', 'Payment reminder');
      expect(url, contains('wa.me/919876543210'));
      expect(url, contains(Uri.encodeComponent('Payment reminder')));

      // Already has international country code (12 digits)
      final intlUrl = waUrl('+91 9876543210', 'Hello');
      expect(intlUrl, contains('wa.me/919876543210'));
    });
  });

  group('Chit Fund Closed-Loop Math', () {
    test('calculateRecipientPays distributes closed-loop dividends to other members', () {
      final calc = calculateRecipientPays(
        pot: 25000.0,
        interestRatePct: 2.0,
        totalMembers: 5,
      );

      expect(calc.interest, 500.0);
      expect(calc.dividend, 125.0);
      // Closed loop: 4 other members each receive 125 = 500 total
      expect(4 * calc.dividend, equals(calc.interest));
    });

    test('calculateRecipientPays handles edge cases (0% or single member)', () {
      final zeroRate = calculateRecipientPays(pot: 25000, interestRatePct: 0, totalMembers: 5);
      expect(zeroRate.interest, 0.0);
      expect(zeroRate.dividend, 0.0);

      final singleMember = calculateRecipientPays(pot: 5000, interestRatePct: 2.0, totalMembers: 1);
      expect(singleMember.interest, 0.0);
      expect(singleMember.dividend, 0.0);
    });

    test('MemberBalance computes net position correctly (received - paid)', () {
      const balance = MemberBalance(
        contributed: 15000,
        taken: 25000,
        interestPaid: 500,
        dividends: 250,
        arrears: 0,
      );

      // (25000 received + 250 dividend) - (15000 contributed + 500 interest) = 9750
      expect(balance.net, 9750.0);
    });
  });

  group('Model Serialization Tests', () {
    test('ChitGroup toMap and fromMap roundtrip', () {
      final now = DateTime(2026, 10, 28);
      final group = ChitGroup(
        id: 1,
        name: 'Family Chit',
        contributionAmount: 5000,
        currency: '₹',
        period: 'monthly',
        interestRatePct: 2.0,
        interestMode: 'late_fee',
        startDate: now,
        dueDay: 5,
        status: 'active',
        createdAt: now,
      );

      final map = group.toMap();
      final reconstructed = ChitGroup.fromMap(map);

      expect(reconstructed.name, group.name);
      expect(reconstructed.contributionAmount, 5000);
      expect(reconstructed.period, 'monthly');
      expect(reconstructed.dueDay, 5);
    });

    test('Member toMap and fromMap roundtrip', () {
      final now = DateTime(2026, 10, 28);
      final member = Member(
        id: 1,
        groupId: 10,
        name: 'Kumar',
        phone: '9876543210',
        payoutOrder: 1,
        role: 'admin',
        joinedAt: now,
      );

      final map = member.toMap();
      final reconstructed = Member.fromMap(map);

      expect(reconstructed.name, 'Kumar');
      expect(reconstructed.phone, '9876543210');
      expect(reconstructed.payoutOrder, 1);
      expect(reconstructed.role, 'admin');
    });

    test('LedgerTxn toMap and fromMap roundtrip', () {
      final now = DateTime(2026, 10, 28);
      final txn = LedgerTxn(
        id: 1,
        roundId: 2,
        memberId: 3,
        type: 'contribution',
        amount: 5000,
        isLate: false,
        note: 'On-time payment',
        createdAt: now,
      );

      final map = txn.toMap();
      final reconstructed = LedgerTxn.fromMap(map);

      expect(reconstructed.type, 'contribution');
      expect(reconstructed.amount, 5000);
      expect(reconstructed.isLate, isFalse);
    });
  });
}
