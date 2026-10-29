import 'package:flutter_test/flutter_test.dart';
import 'package:chit_notebook/core/money/money.dart';
import 'package:chit_notebook/domain/models/enums.dart';
import 'package:chit_notebook/domain/services/late_fee_calculator.dart';
import 'package:chit_notebook/domain/services/ledger_aggregator.dart';
import 'package:chit_notebook/domain/services/round_state_machine.dart';
import 'package:chit_notebook/domain/services/rounds_generator.dart';

void main() {
  group('Money Value Object', () {
    test('Stores and formats integer paise with Indian lakh-style separators', () {
      expect(const Money.fromPaise(500000).format(), '₹5,000');
      expect(const Money.fromPaise(10000000).format(), '₹1,00,000');
      expect(const Money.fromPaise(250000000).format(), '₹25,00,000');
      expect(const Money.fromPaise(0).format(), '₹0');
      expect(const Money.fromPaise(-150000).format(), '-₹1,500');
    });

    test('Parses string inputs safely into integer paise', () {
      expect(Money.parse('5000').inPaise, 500000);
      expect(Money.parse('₹5,000').inPaise, 500000);
      expect(Money.parse('1,00,000').inPaise, 10000000);
      expect(Money.parse('5000.50').inPaise, 500050);
      expect(Money.parse('').inPaise, 0);
    });

    test('Performs exact integer arithmetic without floating-point drift', () {
      const a = Money.fromPaise(100000); // ₹1,000
      const b = Money.fromPaise(250000); // ₹2,500
      expect((a + b).inPaise, 350000);
      expect((b - a).inPaise, 150000);
      expect((a * 3).inPaise, 300000);
      expect((b ~/ 2).inPaise, 125000);
    });
  });

  group('LateFeeCalculator Domain Service', () {
    test('Calculates prorated daily late fee with bps and stated rounding rule', () {
      final dueDate = DateTime(2026, 10, 1);
      final currentDate = DateTime(2026, 10, 16); // 15 days overdue
      final result = LateFeeCalculator.compute(
        installmentPaise: 500000, // ₹5,000
        rateBps: 200, // 2% per month
        dueDate: dueDate,
        currentDate: currentDate,
      );

      expect(result.isOverdue, isTrue);
      expect(result.daysOverdue, 15);
      // Fee = (500000 * 200 * 15) / 300000 = 5000 paise (₹50)
      expect(result.lateFee.inPaise, 5000);
      expect(result.totalDue.inPaise, 505000); // ₹5,050
    });

    test('Respects grace days cutoff', () {
      final dueDate = DateTime(2026, 10, 1);
      final currentDate = DateTime(2026, 10, 4); // 3 days past due
      final result = LateFeeCalculator.compute(
        installmentPaise: 500000,
        rateBps: 200,
        dueDate: dueDate,
        graceDays: 3, // 3 grace days
        currentDate: currentDate,
      );

      expect(result.isOverdue, isFalse);
      expect(result.daysOverdue, 0);
      expect(result.lateFee.inPaise, 0);
    });

    test('Returns zero fee when payment is on-time', () {
      final dueDate = DateTime(2026, 10, 15);
      final currentDate = DateTime(2026, 10, 10);
      final result = LateFeeCalculator.compute(
        installmentPaise: 500000,
        rateBps: 200,
        dueDate: dueDate,
        currentDate: currentDate,
      );

      expect(result.isOverdue, isFalse);
      expect(result.lateFee.inPaise, 0);
      expect(result.totalDue.inPaise, 500000);
    });
  });

  group('RoundStateMachine Domain Service', () {
    test('Transitions from open -> collected -> paid_out', () {
      // 0 paid of 5 -> open
      expect(RoundStateMachine.resolveStatus(totalMembers: 5, paidMembers: 0, isPaidOut: false), RoundStatus.open);
      // 4 paid of 5 -> open
      expect(RoundStateMachine.resolveStatus(totalMembers: 5, paidMembers: 4, isPaidOut: false), RoundStatus.open);
      // 5 paid of 5 -> collected
      expect(RoundStateMachine.resolveStatus(totalMembers: 5, paidMembers: 5, isPaidOut: false), RoundStatus.collected);
      // paid out -> paid_out
      expect(RoundStateMachine.resolveStatus(totalMembers: 5, paidMembers: 5, isPaidOut: true), RoundStatus.paidOut);
    });

    test('Allows early payout with arrears (no deadlock)', () {
      final evaluation = RoundStateMachine.evaluatePayoutEligibility(
        totalMembers: 5,
        paidMembers: 3,
        isPaidOut: false,
      );

      expect(evaluation.allowed, isTrue);
      expect(evaluation.hasArrears, isTrue);
      expect(evaluation.pendingCount, 2);

      // Late contributions can still be marked after payout
      expect(RoundStateMachine.canRecordContribution(isAlreadyPaid: false), isTrue);
    });
  });

  group('RoundsGenerator Domain Service', () {
    test('Clamps monthly due dates on short months (e.g. Feb 31st -> 28th)', () {
      final schedule = RoundsGenerator.generateSchedule(
        startDate: DateTime(2026, 1, 31),
        dueDay: 31,
        totalMembers: 3,
        period: 'monthly',
        payoutMethod: PayoutMethod.fixedOrder,
        payoutOrderToMembershipId: {1: 101, 2: 102, 3: 103},
      );

      expect(schedule.length, 3);
      // Month 1: Jan 31
      expect(schedule[0].dueDate.month, 1);
      expect(schedule[0].dueDate.day, 31);
      expect(schedule[0].recipientMembershipId, 101);

      // Month 2: Feb 2026 has 28 days -> clamped to 28
      expect(schedule[1].dueDate.month, 2);
      expect(schedule[1].dueDate.day, 28);
      expect(schedule[1].recipientMembershipId, 102);

      // Month 3: March 31
      expect(schedule[2].dueDate.month, 3);
      expect(schedule[2].dueDate.day, 31);
      expect(schedule[2].recipientMembershipId, 103);
    });
  });

  group('LedgerAggregator Domain Service', () {
    test('Handles immutable append-only reversals via reversesTxnId', () {
      final txns = [
        const RawTxnRecord(id: 1, roundId: 1, membershipId: 10, type: TransactionType.contribution, amountPaise: 500000),
        const RawTxnRecord(id: 2, roundId: 1, membershipId: 10, type: TransactionType.interest, amountPaise: 5000),
        // Reversal of transaction 2 (late fee waived by foreman)
        const RawTxnRecord(id: 3, roundId: 1, membershipId: 10, type: TransactionType.interest, amountPaise: 5000, reversesTxnId: 2),
      ];

      final active = LedgerAggregator.getActiveTransactions(txns);
      expect(active.length, 1);
      expect(active.first.id, 1); // Only transaction 1 remains active
    });

    test('Computes plain-language member balances accurately', () {
      final txns = [
        const RawTxnRecord(id: 1, roundId: 1, membershipId: 10, type: TransactionType.contribution, amountPaise: 500000),
        const RawTxnRecord(id: 2, roundId: 2, membershipId: 10, type: TransactionType.contribution, amountPaise: 500000),
        const RawTxnRecord(id: 3, roundId: 2, membershipId: 10, type: TransactionType.payout, amountPaise: 2500000), // Won round 2
      ];

      final balance = LedgerAggregator.aggregateMemberBalance(
        membershipId: 10,
        totalRounds: 5,
        installmentPaise: 500000,
        isPrized: true,
        memberTxns: txns,
        pastDueOrActiveRoundsCount: 2,
      );

      expect(balance.paidSoFar.inPaise, 1000000); // ₹10,000 paid
      expect(balance.receivedSoFar.inPaise, 2500000); // ₹25,000 received
      expect(balance.netBalance.inPaise, 1500000); // +₹15,000 (net received)
      expect(balance.arrears.inPaise, 0); // 2 paid of 2 past rounds -> 0 arrears
      expect(balance.postPrizeOutstanding.inPaise, 1500000); // 3 rounds remaining * ₹5,000 = ₹15,000
    });
  });
}
