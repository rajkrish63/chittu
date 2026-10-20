import 'package:flutter/material.dart';
import '../../core/constants.dart';
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
        const SnackBar(content: Text('இந்த ரவுண்டுக்கு Payout முடிந்துவிட்டது. மாற்ற இயலாது.')),
      );
      return;
    }

    final isPaid = _paidMemberIds.contains(member.id);

    if (isPaid) {
      // Unmark confirmation
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('வசூலை ரத்து செய்யவா?'),
          content: Text('${member.name} அவர்களின் தவணை பதிவை நீக்க வேண்டுமா?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('இல்லை')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('ரத்து செய்'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await _roundRepo.unmarkContribution(_round!.id!, member.id!);
        _loadData();
      }
    } else {
      // Check if late
      bool isLate = DateTime.now().isAfter(_round!.dueDate);
      if (isLate && _group!.interestMode == 'late_fee' && _group!.interestRatePct > 0) {
        final lateFee = _group!.contributionAmount * _group!.interestRatePct / 100;
        final lateConfirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('தாமத வட்டி (Late Fee)'),
            content: Text(
              'தவணை தேதி முடிந்துவிட்டது (${formatDate(_round!.dueDate)}).\n\n'
              '${formatMoney(_group!.currency, lateFee)} தாமத வட்டி கணக்கிடப்படும்.\n'
              'தாமதக் கட்டணமாக குறிக்கவா?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('வட்டி வேண்டாம் (On-time)'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('தாமதம் (Late)'),
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
        const SnackBar(content: Text('இந்த உறுப்பினருக்கு போன் எண் இல்லை')),
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
        const SnackBar(content: Text('அனைவரும் செலுத்திவிட்டனர்!')),
      );
      return;
    }

    // Remind first pending member or show list
    final first = pending.first;
    if (first.phone != null && first.phone!.isNotEmpty) {
      await _sendWhatsAppReminder(first);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${pending.length} நபர்கள் இன்னும் செலுத்தவில்லை')),
      );
    }
  }

  Future<void> _showPayoutSheet() async {
    if (_round == null || _group == null) return;
    final recipient = _memberMap[_round!.recipientMemberId];
    final pot = _group!.contributionAmount * _members.length;
    final unpaidCount = _members.length - _paidMemberIds.length;

    double interest = 0;
    double dividend = 0;
    if (_group!.interestMode == 'recipient_pays' && _group!.interestRatePct > 0) {
      interest = pot * _group!.interestRatePct / 100;
      final othersCount = _members.length - 1;
      dividend = othersCount > 0 ? interest / othersCount : 0;
    }

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
                const Text(
                  'Payout உறுதிப்படுத்தல்',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('பணம் பெறுபவர்:'),
                Text(recipient?.name ?? 'தெரியவில்லை', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('மொத்த Pot தொகை:'),
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
                  Text('பிடித்தவர் வட்டி (${_group!.interestRatePct}%):'),
                  Text(formatMoney(_group!.currency, interest), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('மற்றவர்களுக்கு பங்கு (Dividend/member):'),
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
                        '$unpaidCount நபர்கள் இன்னும் கட்டவில்லை. அவர்களுக்கு நிலுவை (Arrears) என்று பதிவாகும்.',
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
                      const SnackBar(content: Text('Payout வெற்றிகரமாக பதிவு செய்யப்பட்டது!')),
                    );
                  }
                  _loadData();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Payout செய் (Confirm & Close Round)', style: TextStyle(fontSize: 16)),
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
          title: const Text('பணம் எடுப்பவரை மாற்றுதல்'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: selectedId,
                decoration: const InputDecoration(labelText: 'புதிய நபர்', border: OutlineInputBorder()),
                items: [
                  for (final m in _members)
                    DropdownMenuItem(value: m.id, child: Text(m.name)),
                ],
                onChanged: (v) => setDialogState(() => selectedId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'காரணம் (Reason - Mandatory)',
                  hintText: 'எ.கா. அவசர தேவைக்காக மாற்றப்பட்டது',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ரத்து')),
            FilledButton(
              onPressed: () {
                if (selectedId != null && reasonController.text.trim().isNotEmpty) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('மாற்று'),
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
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_round == null || _group == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ரவுண்டு')),
        body: const Center(child: Text('ரவுண்டு விவரம் கிடைக்கவில்லை')),
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
        title: Text('ரவுண்டு ${round.seqNo}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Recipient-ஐ மாற்று',
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
              const Text(
                'உறுப்பினர்கள் வசூல் விவரம்',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '$paidCount / $totalCount முடிந்தது',
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
  }

  Widget _buildHeaderCard(
    ChitRound round,
    ChitGroup group,
    Member? recipient,
    Member? accountable,
    int paidCount,
    int totalCount,
  ) {
    final statusLabel = Labels.roundStatuses[round.status] ?? round.status;
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
                      'பணம் பெறுபவர் (Recipient)',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      recipient?.name ?? 'யாரும் இல்லை',
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
                Text('தவணை: ${formatMoney(group.currency, group.contributionAmount)}', style: const TextStyle(fontSize: 13)),
                Text('கடைசி நாள்: ${formatDate(round.dueDate)}', style: const TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('பொறுப்பாளர்: ${accountable?.name ?? "இல்லை"}', style: const TextStyle(fontSize: 13)),
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
          isPaid ? 'செலுத்தப்பட்டது (Paid)' : (member.phone ?? 'பாக்கி (Pending)'),
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
              child: Text(isPaid ? 'Paid ✓' : 'Mark Paid'),
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
            color: Colors.black.withOpacity(0.08),
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
                    pendingCount == 0 ? 'அனைவரும் கட்டினர்' : '$pendingCount பேர் பாக்கி',
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
                label: const Text('Remind'),
              ),
              const SizedBox(width: 8),
            ],
            FilledButton(
              onPressed: isPaidOut ? null : _showPayoutSheet,
              style: FilledButton.styleFrom(
                backgroundColor: isPaidOut ? Colors.grey : Colors.green.shade700,
              ),
              child: Text(isPaidOut ? 'முடிந்தது' : 'Payout →'),
            ),
          ],
        ),
      ),
    );
  }
}
