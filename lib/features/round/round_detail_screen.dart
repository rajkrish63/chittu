import 'package:flutter/material.dart';
import '../../core/locale_controller.dart';
import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/chit_group.dart';
import '../../data/models/chit_round.dart';
import '../../data/models/member.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/member_repository.dart';
import '../../data/repositories/round_repository.dart';

class RoundDetailScreen extends StatefulWidget {
  const RoundDetailScreen({super.key, required this.roundId});
  final int roundId;

  @override
  State<RoundDetailScreen> createState() => _RoundDetailScreenState();
}

class _RoundDetailScreenState extends State<RoundDetailScreen> {
  final RoundRepository _roundRepo = RoundRepository();
  final GroupRepository _groupRepo = GroupRepository();
  final MemberRepository _memberRepo = MemberRepository();

  bool _loading = true;
  ChitRound? _round;
  ChitGroup? _group;
  List<Member> _members = [];
  final Set<int> _paidMemberIds = {};
  final Map<int, Member> _memberMap = {};

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
    final members = await _memberRepo.getForGroup(round.groupId);

    final db = await DatabaseHelper.instance.database;
    final txns = await db.query(
      'transactions',
      where: 'round_id = ? AND type = ?',
      whereArgs: [round.id, 'contribution'],
    );
    final paid = txns.map((t) => t['member_id'] as int).toSet();

    final map = <int, Member>{};
    for (final m in members) {
      if (m.id != null) map[m.id!] = m;
    }

    if (mounted) {
      setState(() {
        _round = round;
        _group = group;
        _members = members;
        _paidMemberIds.clear();
        _paidMemberIds.addAll(paid);
        _memberMap.clear();
        _memberMap.addAll(map);
        _loading = false;
      });
    }
  }

  Future<void> _togglePaid(Member member) async {
    if (_round == null || _group == null || member.id == null) return;
    if (_round!.status == 'paid_out') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.cannotModifyPaidOut)),
      );
      return;
    }

    final isPaid = _paidMemberIds.contains(member.id);

    if (isPaid) {
      // Unmark confirmation
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(S.cancelCollectionPrompt),
          content: Text(S.cancelCollectionContent(member.name)),
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
        await _roundRepo.unmarkContribution(_round!.id!, member.id!);
        _loadData();
      }
    } else {
      // Check if late (only after the due date calendar day has passed)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dueCalendarDay = DateTime(_round!.dueDate.year, _round!.dueDate.month, _round!.dueDate.day);
      bool isLate = today.isAfter(dueCalendarDay);
      if (isLate && _group!.interestMode == 'late_fee' && _group!.interestRatePct > 0) {
        final lateFee = _group!.contributionAmount * _group!.interestRatePct / 100;
        final lateConfirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(S.lateFeeDialogTitle),
            content: Text(S.lateFeeDialogContent(
              formatDate(_round!.dueDate),
              formatMoney(_group!.currency, lateFee),
            )),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(S.onTimeNoFee),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(S.markLate),
              ),
            ],
          ),
        );
        if (lateConfirm != null) {
          isLate = lateConfirm;
        }
      }

      await _roundRepo.markContribution(
        round: _round!,
        group: _group!,
        memberId: member.id!,
        isLate: isLate,
      );
      _loadData();
    }
  }

  Future<void> _sendWhatsAppReminder(Member member) async {
    if (_round == null || _group == null) return;
    if (member.phone == null || member.phone!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.noPhoneForMember)),
      );
      return;
    }

    final msg = reminderMessage(
      memberName: member.name,
      roundNo: _round!.seqNo,
      amount: _group!.contributionAmount,
      currency: _group!.currency,
    );
    await openWhatsApp(member.phone!, msg);
  }

  Future<void> _remindAllPending() async {
    if (_round == null || _group == null) return;
    final pending = _members.where((m) => !_paidMemberIds.contains(m.id)).toList();
    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.allPaidNotice)),
      );
      return;
    }

    // Remind first pending member or show count
    final first = pending.first;
    if (first.phone != null && first.phone!.isNotEmpty) {
      await _sendWhatsAppReminder(first);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.unpaidCountNotice(pending.length))),
      );
    }
  }

  Future<void> _showPayoutSheet() async {
    if (_round == null || _group == null) return;
    final recipient = _memberMap[_round!.recipientMemberId];
    final pot = _group!.contributionAmount * _members.length;
    final unpaidCount = _members.length - _paidMemberIds.length;

    final calc = _group!.interestMode == 'recipient_pays'
        ? calculateRecipientPays(
            pot: pot,
            interestRatePct: _group!.interestRatePct,
            totalMembers: _members.length,
          )
        : (interest: 0.0, dividend: 0.0);
    final interest = calc.interest;
    final dividend = calc.dividend;

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
                Text(recipient?.name ?? S.unknownRecipient, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(S.totalPotAmount),
                Text(
                  formatMoney(_group!.currency, pot),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            if (_group!.interestMode == 'recipient_pays' && _group!.interestRatePct > 0) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(S.recipientInterestLabel(_group!.interestRatePct)),
                  Text(formatMoney(_group!.currency, interest), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(S.dividendPerMemberLabel),
                  Text(formatMoney(_group!.currency, dividend), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                ],
              ),
            ],
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
                  Navigator.pop(ctx);
                  await _roundRepo.runPayout(round: _round!, group: _group!);
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
    if (_round == null || _round!.status == 'paid_out') return;

    int? selectedId = _round!.recipientMemberId;
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(S.changeRecipientDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedId,
                decoration: InputDecoration(labelText: S.newRecipientLabel, border: const OutlineInputBorder()),
                items: [
                  for (final m in _members)
                    DropdownMenuItem(value: m.id, child: Text(m.name)),
                ],
                onChanged: (v) => setDialogState(() => selectedId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: S.reasonLabel,
                  hintText: S.reasonHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.cancel)),
            FilledButton(
              onPressed: () {
                if (selectedId != null && reasonController.text.trim().isNotEmpty) {
                  Navigator.pop(ctx, true);
                }
              },
              child: Text(S.ok),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedId != null) {
      await _roundRepo.setRecipient(
        widget.roundId,
        selectedId!,
        reason: reasonController.text.trim(),
      );
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
        final recipient = _memberMap[round.recipientMemberId];
        final accountable = _memberMap[round.accountableMemberId];
        final paidCount = _paidMemberIds.length;
        final totalCount = _members.length;
        final pendingCount = totalCount - paidCount;
        final isPaidOut = round.status == 'paid_out';

        return Scaffold(
          appBar: AppBar(
            title: Text(S.roundTitle(round.seqNo)),
            actions: [
              IconButton(
                icon: const Icon(Icons.swap_horiz_rounded),
                tooltip: S.changeRecipientTooltip,
                onPressed: isPaidOut ? null : _changeRecipient,
              ),
            ],
          ),
          bottomNavigationBar: _buildStickyBottomBar(pendingCount, isPaidOut),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header Card
              _buildHeaderCard(round, group, recipient, accountable, paidCount, totalCount),
              const SizedBox(height: 16),

              // Member collection list header
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

              // Member Rows
              for (final member in _members) _buildMemberRow(member, isPaidOut),
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
    Member? recipient,
    Member? accountable,
    int paidCount,
    int totalCount,
  ) {
    final statusLabel = S.roundStatus(round.status);
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
                      recipient?.name ?? S.noRecipient,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: round.status == 'paid_out'
                        ? Colors.green.shade100
                        : round.status == 'collected'
                            ? Colors.orange.shade100
                            : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: round.status == 'paid_out'
                          ? Colors.green.shade900
                          : round.status == 'collected'
                              ? Colors.orange.shade900
                              : Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(S.contributionChip(formatMoney(group.currency, group.contributionAmount)), style: const TextStyle(fontSize: 13)),
                Text(S.dueDate(formatDate(round.dueDate)), style: const TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(S.accountableLabel(accountable?.name), style: const TextStyle(fontSize: 13)),
                Text('Pot: ${formatMoney(group.currency, group.contributionAmount * totalCount)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
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

  Widget _buildMemberRow(Member member, bool isPaidOut) {
    final isPaid = _paidMemberIds.contains(member.id);

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
        title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          isPaid ? S.paidStatus : (member.phone ?? S.pendingStatus),
          style: TextStyle(
            color: isPaid ? Colors.green.shade700 : Colors.red.shade700,
            fontSize: 12,
            fontWeight: isPaid ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isPaid && member.phone != null && member.phone!.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.send_rounded, color: Colors.green),
                tooltip: 'WhatsApp Reminder',
                onPressed: () => _sendWhatsAppReminder(member),
              ),
            FilledButton.tonal(
              onPressed: isPaidOut ? null : () => _togglePaid(member),
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
    final pendingAmount = (_group?.contributionAmount ?? 0) * pendingCount;

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
                      formatMoney(_group?.currency ?? '₹', pendingAmount),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
            if (pendingCount > 0) ...[
              OutlinedButton.icon(
                onPressed: _remindAllPending,
                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                label: Text(S.remindButton),
              ),
              const SizedBox(width: 8),
            ],
            FilledButton(
              onPressed: isPaidOut ? null : _showPayoutSheet,
              style: FilledButton.styleFrom(
                backgroundColor: isPaidOut ? Colors.grey : Colors.green.shade700,
              ),
              child: Text(isPaidOut ? S.done : S.payoutButton),
            ),
          ],
        ),
      ),
    );
  }
}
