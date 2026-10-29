import 'package:flutter/material.dart';
import '../../core/locale_controller.dart';
import '../../core/money/money.dart';
import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../data/models/chit_group.dart';
import '../../data/models/chit_round.dart';
import '../../data/models/membership.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/ledger_repository.dart';
import '../../data/repositories/round_repository.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/late_fee_calculator.dart';

class RoundDetailScreen extends StatefulWidget {
  const RoundDetailScreen({super.key, required this.roundId});
  final int roundId;

  @override
  State<RoundDetailScreen> createState() => _RoundDetailScreenState();
}

class _RoundDetailScreenState extends State<RoundDetailScreen> {
  final RoundRepository _roundRepo = RoundRepository();
  final GroupRepository _groupRepo = GroupRepository();
  final LedgerRepository _ledgerRepo = LedgerRepository();

  bool _loading = true;
  ChitRound? _round;
  ChitGroup? _group;
  List<Membership> _memberships = [];
  final Set<int> _paidMembershipIds = {};
  final Map<int, Membership> _membershipMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final round = await _roundRepo.getById(widget.roundId);
    if (round == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final group = await _groupRepo.getById(round.groupId);
    final memberships = await _groupRepo.getMemberships(round.groupId);
    final paidIds = await _ledgerRepo.getPaidMembershipIdsForRound(round.id!);

    final map = <int, Membership>{};
    for (final m in memberships) {
      if (m.id != null) map[m.id!] = m;
    }

    if (mounted) {
      setState(() {
        _round = round;
        _group = group;
        _memberships = memberships;
        _paidMembershipIds.clear();
        _paidMembershipIds.addAll(paidIds);
        _membershipMap.clear();
        _membershipMap.addAll(map);
        _loading = false;
      });
    }
  }

  Future<void> _togglePaid(Membership membership) async {
    if (_round == null || _group == null || membership.id == null) return;

    final isPaid = _paidMembershipIds.contains(membership.id);
    final contactName = membership.contact?.name ?? 'Member';

    if (isPaid) {
      if (_round!.isPaidOut) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.cannotModifyPaidOut)),
        );
        return;
      }

      // Reversal confirmation
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(S.cancelCollectionPrompt),
          content: Text(S.cancelCollectionContent(contactName)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.cancel)),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(S.delete),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await _roundRepo.unmarkContribution(_round!.id!, membership.id!);
        _loadData();
      }
    } else {
      // Pending contribution: check if overdue with dynamic late fee breakdown
      final lateCalc = LateFeeCalculator.compute(
        installmentPaise: _group!.installmentPaise,
        rateBps: _group!.rateBps,
        dueDate: _round!.dueDate,
        graceDays: _group!.graceDays,
      );

      bool isLate = false;
      int? lateFeePaiseToApply;

      if (lateCalc.isOverdue &&
          _group!.penaltyMode == PenaltyMode.lateFee &&
          lateCalc.lateFee.isPositive) {
        final choice = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(S.lateFeeDialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.alarm_on, color: Colors.amber, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        S.daysOverdueCount(lateCalc.daysOverdue),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(S.baseInstallmentLabel),
                    Text(lateCalc.baseInstallment.format()),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(S.latePenaltyLabel),
                    Text(
                      '+${lateCalc.lateFee.format()}',
                      style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(S.totalPayableLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      lateCalc.totalDue.format(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'cancel'),
                child: Text(S.cancel),
              ),
              OutlinedButton(
                onPressed: () => Navigator.pop(ctx, 'waive'),
                child: Text(S.waiveLateFee),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, 'fee'),
                child: Text(S.collectWithFee),
              ),
            ],
          ),
        );

        if (choice == null || choice == 'cancel') return;
        if (choice == 'fee') {
          isLate = true;
          lateFeePaiseToApply = lateCalc.lateFee.inPaise;
        } else {
          isLate = false;
        }
      }

      await _roundRepo.markContribution(
        round: _round!,
        group: _group!,
        membershipId: membership.id!,
        isLate: isLate,
        lateFeePaise: lateFeePaiseToApply,
      );
      _loadData();
    }
  }

  Future<void> _sendWhatsAppReminder(Membership membership) async {
    if (_round == null || _group == null) return;
    final contact = membership.contact;
    if (contact?.phone == null || contact!.phone!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.noPhoneForMember)),
      );
      return;
    }

    final lateCalc = LateFeeCalculator.compute(
      installmentPaise: _group!.installmentPaise,
      rateBps: _group!.rateBps,
      dueDate: _round!.dueDate,
      graceDays: _group!.graceDays,
    );

    String message;
    if (lateCalc.isOverdue && lateCalc.lateFee.isPositive) {
      message = '${contact.name}, payment for Round ${_round!.seqNo} is overdue by ${lateCalc.daysOverdue} days.\n'
          '• Installment: ${lateCalc.baseInstallment.format()}\n'
          '• Late Fee: ${lateCalc.lateFee.format()}\n'
          '• Total Due: ${lateCalc.totalDue.format()}\n'
          'Please pay at your earliest convenience 🙏';
    } else {
      message = '${contact.name}, payment for Round ${_round!.seqNo} (${_group!.installment.format()}) is pending (due: ${formatDate(_round!.dueDate)}). '
          'Please pay at your earliest convenience 🙏';
    }

    await openWhatsApp(contact.phone!, message);
  }

  Future<void> _showPayoutSheet() async {
    if (_round == null || _group == null) return;
    final recipient = _membershipMap[_round!.recipientMembershipId];
    final pot = Money.fromPaise(_group!.installmentPaise * _memberships.length);
    final unpaidCount = _memberships.length - _paidMembershipIds.length;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.payoutConfirmationTitle,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(S.payoutRecipient),
                Text(
                  recipient?.contact?.name ?? S.unknownRecipient,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(S.totalPotAmount),
                Text(
                  pot.format(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            if (unpaidCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        S.arrearsWarning(unpaidCount),
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (_round!.recipientMembershipId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please assign a recipient before payout')),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  await _roundRepo.runPayout(
                    round: _round!,
                    group: _group!,
                    recipientMembershipId: _round!.recipientMembershipId!,
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(S.payoutSuccess)),
                    );
                  }
                  _loadData();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(S.confirmPayoutButton, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeRecipient() async {
    if (_round == null || _round!.isPaidOut) return;

    int? selectedId = _round!.recipientMembershipId;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(S.changeRecipientDialogTitle),
          content: DropdownButtonFormField<int>(
            initialValue: selectedId,
            decoration: InputDecoration(
              labelText: S.newRecipientLabel,
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final m in _memberships)
                DropdownMenuItem(
                  value: m.id,
                  child: Text('${m.payoutOrder}. ${m.contact?.name ?? "Member"}'),
                ),
            ],
            onChanged: (v) => setDialogState(() => selectedId = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.cancel)),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(S.ok),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedId != null) {
      await _roundRepo.setRecipient(widget.roundId, selectedId!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocaleController.instance,
      builder: (context, _) {
        if (_loading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (_round == null || _group == null) {
          return Scaffold(
            appBar: AppBar(title: Text(S.roundTitle(1))),
            body: Center(child: Text(S.roundDetailsNotFound)),
          );
        }

        final round = _round!;
        final group = _group!;
        final recipient = _membershipMap[round.recipientMembershipId];
        final paidCount = _paidMembershipIds.length;
        final totalCount = _memberships.length;
        final pendingCount = totalCount - paidCount;

        return Scaffold(
          appBar: AppBar(
            title: Text(S.roundTitle(round.seqNo)),
            actions: [
              IconButton(
                icon: const Icon(Icons.swap_horiz_rounded),
                tooltip: S.changeRecipientTooltip,
                onPressed: round.isPaidOut ? null : _changeRecipient,
              ),
            ],
          ),
          bottomNavigationBar: _buildStickyBottomBar(pendingCount, round.isPaidOut),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Card
              _buildHeaderCard(round, group, recipient, paidCount, totalCount),
              const SizedBox(height: 16),

              // Member Collections Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    S.memberCollectionProgress,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    S.progressCount(paidCount, totalCount),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: paidCount == totalCount ? Colors.green : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Membership Collection Checklist
              for (final membership in _memberships)
                _buildMemberRow(membership, round.isPaidOut),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(
    ChitRound round,
    ChitGroup group,
    Membership? recipient,
    int paidCount,
    int totalCount,
  ) {
    String statusLabel;
    Color statusBg;
    Color statusTextColor;

    if (round.isPaidOut) {
      if (paidCount < totalCount) {
        statusLabel = '${S.statusDisbursed} (${totalCount - paidCount} pending)';
        statusBg = Colors.amber.shade100;
        statusTextColor = Colors.amber.shade900;
      } else {
        statusLabel = S.statusDisbursed;
        statusBg = Colors.green.shade100;
        statusTextColor = Colors.green.shade900;
      }
    } else if (round.isCollected) {
      statusLabel = S.statusPotReady;
      statusBg = Colors.orange.shade100;
      statusTextColor = Colors.orange.shade900;
    } else {
      statusLabel = '${S.statusCollecting} ($paidCount/$totalCount)';
      statusBg = Colors.blue.shade100;
      statusTextColor = Colors.blue.shade900;
    }

    final pot = Money.fromPaise(group.installmentPaise * totalCount);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.recipientBadge,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      recipient?.contact?.name ?? S.noRecipient,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.contributionChip(group.installment.format()),
                  style: const TextStyle(fontSize: 13),
                ),
                Text(S.dueDate(formatDate(round.dueDate)), style: const TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pot: ${pot.format()}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: totalCount > 0 ? paidCount / totalCount : 0,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: paidCount == totalCount ? Colors.green : Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberRow(Membership membership, bool isPaidOut) {
    final isPaid = _paidMembershipIds.contains(membership.id);
    final contact = membership.contact;

    final lateCalc = isPaid
        ? null
        : LateFeeCalculator.compute(
            installmentPaise: _group!.installmentPaise,
            rateBps: _group!.rateBps,
            dueDate: _round!.dueDate,
            graceDays: _group!.graceDays,
          );

    String subtitleText;
    Color subtitleColor;

    if (isPaid) {
      subtitleText = S.paidStatus;
      subtitleColor = Colors.green.shade700;
    } else if (lateCalc != null && lateCalc.isOverdue) {
      subtitleText = '${contact?.phone ?? S.pendingStatus} • ${lateCalc.daysOverdue}d overdue';
      subtitleColor = Colors.red.shade700;
    } else {
      subtitleText = contact?.phone ?? S.pendingStatus;
      subtitleColor = Colors.grey.shade700;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPaid ? Colors.green.shade300 : Colors.grey.shade300,
          width: isPaid ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPaid ? Colors.green.shade100 : Colors.grey.shade200,
          child: Icon(
            isPaid ? Icons.check : Icons.person_outline,
            color: isPaid ? Colors.green.shade800 : Colors.grey.shade700,
          ),
        ),
        title: Text(contact?.name ?? 'Member', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          subtitleText,
          style: TextStyle(
            color: subtitleColor,
            fontSize: 12,
            fontWeight: isPaid || (lateCalc?.isOverdue ?? false)
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isPaid && contact?.phone != null && contact!.phone!.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.green),
                tooltip: 'WhatsApp Reminder',
                onPressed: () => _sendWhatsAppReminder(membership),
              ),
            FilledButton.tonal(
              onPressed: isPaid && isPaidOut ? null : () => _togglePaid(membership),
              style: FilledButton.styleFrom(
                backgroundColor: isPaid ? Colors.green.shade100 : null,
                foregroundColor: isPaid ? Colors.green.shade900 : null,
              ),
              child: Text(isPaid ? S.paidCheck : S.markPaid),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyBottomBar(int pendingCount, bool isPaidOut) {
    final pendingPaise = (_group?.installmentPaise ?? 0) * pendingCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.allPaidCountMessage(pendingCount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: pendingCount == 0 ? Colors.green : Colors.red.shade700,
                    ),
                  ),
                  if (pendingCount > 0)
                    Text(
                      Money.fromPaise(pendingPaise).format(),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
            FilledButton(
              onPressed: isPaidOut ? null : _showPayoutSheet,
              style: FilledButton.styleFrom(
                backgroundColor: isPaidOut
                    ? Colors.grey
                    : pendingCount == 0
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
              ),
              child: Text(
                isPaidOut
                    ? (pendingCount == 0 ? S.done : S.statusDisbursed)
                    : (pendingCount == 0 ? S.disbursePotButton : S.disburseEarlyButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
