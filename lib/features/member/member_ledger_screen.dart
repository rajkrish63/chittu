import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/locale_controller.dart';
import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../data/models/chit_group.dart';
import '../../data/models/ledger_txn.dart';
import '../../data/models/membership.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/ledger_repository.dart';
import '../../domain/models/member_balance.dart';

class MemberLedgerScreen extends StatefulWidget {
  const MemberLedgerScreen({
    super.key,
    required this.membershipId,
    required this.groupId,
  });

  final int membershipId;
  final int groupId;

  @override
  State<MemberLedgerScreen> createState() => _MemberLedgerScreenState();
}

class _MemberLedgerScreenState extends State<MemberLedgerScreen> {
  final LedgerRepository _ledgerRepo = LedgerRepository();
  final GroupRepository _groupRepo = GroupRepository();

  bool _loading = true;
  Membership? _membership;
  ChitGroup? _group;
  MemberBalance? _balance;
  List<LedgerTxn> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final group = await _groupRepo.getById(widget.groupId);
    final memberships = await _groupRepo.getMemberships(widget.groupId);
    final membership = memberships.where((m) => m.id == widget.membershipId).firstOrNull;

    if (group != null && membership != null) {
      final balance = await _ledgerRepo.getMemberBalance(
        groupId: widget.groupId,
        membershipId: widget.membershipId,
      );
      final txns = await _ledgerRepo.getTransactionsForMembership(widget.membershipId);

      if (mounted) {
        setState(() {
          _group = group;
          _membership = membership;
          _balance = balance;
          _transactions = txns;
          _loading = false;
        });
        return;
      }
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _shareStatement() async {
    if (_membership == null || _group == null || _balance == null) return;
    final b = _balance!;
    final contact = _membership!.contact;

    final statement = S.generateStatement(
      chitName: _group!.name,
      memberName: contact?.name ?? 'Member',
      phone: contact?.phone,
      dateFormatted: formatDate(DateTime.now()),
      currency: _group!.currency,
      paidSoFarFormatted: b.paidSoFar.format(),
      receivedSoFarFormatted: b.receivedSoFar.format(),
      arrearsFormatted: b.arrears.format(),
      balanceFormatted: b.netBalance.abs().format(),
      isReceivedMore: b.netBalance.isPositive,
      isPrized: b.isPrized,
    );

    await Share.share(statement, subject: '${contact?.name ?? "Member"} - Chit Statement');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocaleController.instance,
      builder: (context, _) {
        if (_loading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (_membership == null || _group == null || _balance == null) {
          return Scaffold(
            appBar: AppBar(title: Text(S.accountDetails)),
            body: Center(child: Text(S.detailsNotFound)),
          );
        }

        final m = _membership!;
        final b = _balance!;
        final contact = m.contact;
        final isNetPositive = b.netBalance.isPositive;

        return Scaffold(
          appBar: AppBar(
            title: Text(contact?.name ?? S.accountDetails),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: S.shareStatementTooltip,
                onPressed: _shareStatement,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Plain-Language Summary Hero Card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: b.isPrized ? Colors.purple.shade50 : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: b.isPrized ? Colors.purple.shade200 : Colors.blue.shade200,
                              ),
                            ),
                            child: Text(
                              b.isPrized ? S.prizedStatusBadge : S.unprizedStatusBadge,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: b.isPrized ? Colors.purple.shade800 : Colors.blue.shade800,
                              ),
                            ),
                          ),
                          Text(
                            'Rotation #${m.payoutOrder}',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isNetPositive ? S.receivedSoFarLabel : S.paidSoFarLabel,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        b.netBalance.abs().format(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isNetPositive ? Colors.green.shade700 : Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isNetPositive
                            ? '(${S.receivedSoFarLabel} > ${S.paidSoFarLabel})'
                            : '(${S.paidSoFarLabel} > ${S.receivedSoFarLabel})',
                        style: TextStyle(
                          fontSize: 12,
                          color: isNetPositive ? Colors.green.shade800 : Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Breakdown Metrics Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      S.paidSoFarLabel,
                      b.paidSoFar.format(),
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      S.receivedSoFarLabel,
                      b.receivedSoFar.format(),
                      Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (b.hasArrears) ...[
                _buildMetricTile(
                  S.arrearsLabel,
                  b.arrears.format(),
                  Colors.red,
                  isWarning: true,
                ),
                const SizedBox(height: 8),
              ],

              if (b.isPrized && b.postPrizeOutstanding.isPositive) ...[
                _buildMetricTile(
                  S.postPrizeOutstandingLabel,
                  b.postPrizeOutstanding.format(),
                  Colors.purple,
                ),
                const SizedBox(height: 8),
              ],

              if (m.guarantorNote != null && m.guarantorNote!.isNotEmpty) ...[
                Card(
                  elevation: 0,
                  color: Colors.amber.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.amber.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined, size: 20, color: Colors.amber),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                S.guarantorNoteLabel,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                m.guarantorNote!,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Transactions Timeline
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    S.timelineTitle,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    S.recordCount(_transactions.length),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_transactions.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      S.noTransactions,
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ),
                )
              else
                for (final txn in _transactions) _buildTxnRow(txn),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricTile(String label, String value, MaterialColor color, {bool isWarning = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWarning ? Colors.red.shade50 : color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isWarning ? Colors.red.shade200 : color.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isWarning ? Colors.red.shade900 : color.shade900,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isWarning ? Colors.red.shade900 : color.shade900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTxnRow(LedgerTxn txn) {
    final isCredit = txn.type.value == 'payout' || txn.type.value == 'dividend';
    final sign = isCredit ? '+' : '-';
    final color = isCredit ? Colors.green.shade700 : Colors.blueGrey.shade800;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: txn.isReversal ? Colors.red.shade200 : Colors.grey.shade300,
        ),
      ),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: txn.isReversal ? Colors.red.shade50 : color.withValues(alpha: 0.1),
          child: Icon(
            txn.isReversal
                ? Icons.undo_rounded
                : isCredit
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
            size: 16,
            color: txn.isReversal ? Colors.red : color,
          ),
        ),
        title: Row(
          children: [
            Text(
              S.txnType(txn.type.value),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration: txn.isReversal ? TextDecoration.lineThrough : null,
              ),
            ),
            if (txn.isReversal) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Reversal', style: TextStyle(fontSize: 10, color: Colors.red)),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${formatDate(txn.createdAt)} ${txn.note != null ? "• ${txn.note}" : ""}',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Text(
          '$sign${txn.amount.format()}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: txn.isReversal ? Colors.red : color,
            fontSize: 14,
            decoration: txn.isReversal ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}
