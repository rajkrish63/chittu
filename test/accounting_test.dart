import 'package:flutter_test/flutter_test.dart';
import 'package:chit_notebook/core/money/money.dart';
import 'package:chit_notebook/core/utils.dart';
import 'package:chit_notebook/data/models/chit_group.dart';
import 'package:chit_notebook/data/models/contact.dart';
import 'package:chit_notebook/data/models/ledger_txn.dart';
import 'package:chit_notebook/data/models/membership.dart';
import 'package:chit_notebook/domain/models/enums.dart';
import 'package:chit_notebook/domain/models/member_balance.dart';
import 'package:chit_notebook/domain/services/late_fee_calculator.dart';
import 'package:chit_notebook/domain/services/rounds_generator.dart';

void main() {
  group('Utils & Financial Math', () {
    test('Money format handles positive, zero, and negative amounts in Indian Lakh format', () {
      expect(const Money.fromPaise(500000).format(), '₹5,000');
      expect(const Money.fromPaise(0).format(), '₹0');
      expect(const Money.fromPaise(-150000).format(), '-₹1,500');
      expect(const Money.fromPaise(10000000).format(), '₹1,00,000');
    });

    test('RoundsGenerator clamps monthly due dates properly for short months (e.g. Feb)', () {
      final schedule = RoundsGenerator.generateSchedule(
        startDate: DateTime(2026, 1, 31),
        dueDay: 31,
        totalMembers: 2,
        period: 'monthly',
        payoutMethod: PayoutMethod.fixedOrder,
      );
      expect(schedule.length, 2);
      expect(schedule[0].dueDate.month, 1);
      expect(schedule[0].dueDate.day, 31);
      // Next month is February 2026 (28 days)
      expect(schedule[1].dueDate.month, 2);
      expect(schedule[1].dueDate.day, 28);
    });

    test('waUrl adds country code 91 for 10-digit Indian numbers', () {
      final url = waUrl('9876543210', 'Payment reminder');
      expect(url, contains('wa.me/919876543210'));
      expect(url, contains(Uri.encodeComponent('Payment reminder')));

      // Already has international country code (12 digits)
      final intlUrl = waUrl('+91 9876543210', 'Hello');
      expect(intlUrl, contains('wa.me/919876543210'));
    });

    test('LateFeeCalculator computes prorated overdue fees accurately', () {
      final dueDate = DateTime(2026, 10, 10);
      final currentDate = DateTime(2026, 10, 25); // 15 days overdue
      final calc = LateFeeCalculator.compute(
        installmentPaise: 500000, // ₹5,000
        dueDate: dueDate,
        rateBps: 200, // 2% per month
        currentDate: currentDate,
      );

      expect(calc.isOverdue, isTrue);
      expect(calc.daysOverdue, 15);
      // 500000 * 200 * 15 / 300000 = 5000 paise (₹50)
      expect(calc.lateFee.inPaise, 5000);
      expect(calc.totalDue.inPaise, 505000);
    });

    test('LateFeeCalculator returns zero fee for on-time payments', () {
      final dueDate = DateTime(2026, 10, 25);
      final currentDate = DateTime(2026, 10, 20); // 5 days before due
      final calc = LateFeeCalculator.compute(
        installmentPaise: 500000,
        dueDate: dueDate,
        rateBps: 200,
        currentDate: currentDate,
      );

      expect(calc.isOverdue, isFalse);
      expect(calc.daysOverdue, 0);
      expect(calc.lateFee.inPaise, 0);
      expect(calc.totalDue.inPaise, 500000);
    });
  });

  group('Plain-Language Financial Balance', () {
    test('MemberBalance computes plain-language metrics correctly', () {
      const balance = MemberBalance(
        paidSoFar: Money.fromPaise(1500000), // ₹15,000 paid
        receivedSoFar: Money.fromPaise(2500000), // ₹25,000 received
        arrears: Money.zero,
        isPrized: true,
        postPrizeOutstanding: Money.fromPaise(1000000), // ₹10,000 to pay
      );

      // netBalance = received - paid = 25,000 - 15,000 = 10,000
      expect(balance.netBalance.inPaise, 1000000);
      expect(balance.isPrized, isTrue);
      expect(balance.postPrizeOutstanding.inPaise, 1000000);
    });
  });

  group('Model Serialization Tests', () {
    test('ChitGroup toMap and fromMap roundtrip', () {
      final now = DateTime(2026, 10, 28);
      final group = ChitGroup(
        id: 1,
        name: 'Family Chit',
        installmentPaise: 500000,
        currency: '₹',
        period: 'monthly',
        payoutMethod: PayoutMethod.fixedOrder,
        penaltyMode: PenaltyMode.lateFee,
        rateBps: 200,
        graceDays: 2,
        commissionBps: 0,
        status: 'active',
        createdAt: now,
      );

      final map = group.toMap();
      final reconstructed = ChitGroup.fromMap(map);

      expect(reconstructed.name, group.name);
      expect(reconstructed.installmentPaise, 500000);
      expect(reconstructed.period, 'monthly');
      expect(reconstructed.payoutMethod, PayoutMethod.fixedOrder);
      expect(reconstructed.rateBps, 200);
      expect(reconstructed.graceDays, 2);
    });

    test('Contact toMap and fromMap roundtrip', () {
      final now = DateTime(2026, 10, 28);
      final contact = Contact(
        id: 1,
        name: 'Kumar',
        phone: '9876543210',
        countryCode: '91',
        note: 'Guarantor: Raman',
        createdAt: now,
      );

      final map = contact.toMap();
      final reconstructed = Contact.fromMap(map);

      expect(reconstructed.name, 'Kumar');
      expect(reconstructed.phone, '9876543210');
      expect(reconstructed.note, 'Guarantor: Raman');
    });

    test('Membership toMap and fromMap roundtrip', () {
      final now = DateTime(2026, 10, 28);
      final contact = Contact(
        id: 1,
        name: 'Kumar',
        phone: '9876543210',
        createdAt: now,
      );

      final membership = Membership(
        id: 10,
        groupId: 1,
        contactId: 1,
        shareNo: 1,
        payoutOrder: 2,
        prized: true,
        guarantorNote: 'Raman backed',
        contact: contact,
      );

      final map = membership.toMap();
      final reconstructed = Membership.fromMap(map, contact);

      expect(reconstructed.groupId, 1);
      expect(reconstructed.contactId, 1);
      expect(reconstructed.payoutOrder, 2);
      expect(reconstructed.prized, isTrue);
      expect(reconstructed.guarantorNote, 'Raman backed');
    });

    test('LedgerTxn toMap and fromMap roundtrip', () {
      final now = DateTime(2026, 10, 28);
      final txn = LedgerTxn(
        id: 1,
        roundId: 2,
        membershipId: 3,
        type: TransactionType.contribution,
        amountPaise: 500000,
        isLate: false,
        note: 'On-time installment',
        createdAt: now,
      );

      final map = txn.toMap();
      final reconstructed = LedgerTxn.fromMap(map);

      expect(reconstructed.type, TransactionType.contribution);
      expect(reconstructed.amountPaise, 500000);
      expect(reconstructed.isLate, isFalse);
    });
  });
}
