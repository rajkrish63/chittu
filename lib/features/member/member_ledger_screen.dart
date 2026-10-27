import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/locale_controller.dart';
import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../data/models/chit_group.dart';
import '../../data/models/ledger_txn.dart';
import '../../data/models/member.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/member_repository.dart';

class MemberLedgerScreen extends StatefulWidget {
  const MemberLedgerScreen({
    super.key,
    required this.memberId,
    required this.groupId,
  });

  final int memberId;
  final int groupId;

  @override
  State<MemberLedgerScreen> createState() => _MemberLedgerScreenState();
}

class _MemberLedgerScreenState extends State<MemberLedgerScreen> {
  final MemberRepository _memberRepo = MemberRepository();
  final GroupRepository _groupRepo = GroupRepository();

  bool _loading = true;
  Member? _member;
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
    final members = await _memberRepo.getForGroup(widget.groupId);
    final member = members.firstWhere((m) => m.id == widget.memberId);
    final balance = await _memberRepo.balance(widget.groupId, widget.memberId);
    final txns = await _memberRepo.transactionsFor(widget.memberId);

    if (mounted) {
      setState(() {
        _group = group;
        _member = member;
        _balance = balance;
        _transactions = txns;
        _loading = false;
      });
    }
  }

  Future<void> _shareStatement() async {
    if (_member == null || _group == null || _balance == null) return;
    final b = _balance!;
    final statement = S.generateStatement(
      chitName: _group!.name,
      memberName: _member!.name,
      phone: _member!.phone,
      dateFormatted: formatDate(DateTime.now()),
      currency: _group!.currency,
      contributed: b.contributed,
      taken: b.taken,
      interestPaid: b.interestPaid,
      dividends: b.dividends,
      arrears: b.arrears,
      net: b.net,
      formatMoneyFn: formatMoney,
    );

    await Share.share(statement, subject: '${_member!.name} - Statement');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocaleController.instance,
      builder: (context, _) {
        if (_loading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (_member == null || _group == null || _balance == null) {
          return Scaffold(
            appBar: AppBar(title: Text(S.accountDetails)),
            body: Center(child: Text(S.detailsNotFound)),
          );
        }

        final m = _member!;
        final g = _group!;
        final b = _balance!;
        final isNetPositive = b.net >= 0;

        return Scaffold(
          appBar: AppBar(
            title: Text(m.name),
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
              // Net position card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        S.netPosition,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${isNetPositive ? "+" : ""}${formatMoney(g.currency, b.net)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isNetPositive ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isNetPositive ? S.netGain : S.netDue,
                        style: TextStyle(
                          fontSize: 12,
                          color: isNetPositive ? Colors.green.shade800 : Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Balance breakdown grid
              _buildBreakdownGrid(b, g.currency),
              const SizedBox(height: 24),

              // Transactions timeline
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
                for (final txn in _transactions) _buildTxnRow(txn, g.currency),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBreakdownGrid(MemberBalance b, String currency) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricTile(S.metricPaid, formatMoney(currency, b.contributed), Colors.blue)),
            const SizedBox(width: 8),
            Expanded(child: _buildMetricTile(S.metricTaken, formatMoney(currency, b.taken), Colors.green)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildMetricTile(S.metricInterest, formatMoney(currency, b.interestPaid), Colors.orange)),
            const SizedBox(width: 8),
            Expanded(child: _buildMetricTile(S.metricDividend, formatMoney(currency, b.dividends), Colors.purple)),
          ],
        ),
        if (b.arrears > 0) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(S.currentArrears, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                Text(
                  formatMoney(currency, b.arrears),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildTxnRow(LedgerTxn txn, String currency) {
    final typeText = S.txnType(txn.type);
    IconData icon = Icons.receipt_long;
    Color iconColor = Colors.grey;

    if (txn.type == 'contribution') {
      icon = Icons.check_circle_outline;
      iconColor = Colors.blue;
    } else if (txn.type == 'payout') {
      icon = Icons.account_balance_wallet_outlined;
      iconColor = Colors.green;
    } else if (txn.type == 'interest') {
      icon = Icons.trending_up;
      iconColor = Colors.orange;
    } else if (txn.type == 'dividend') {
      icon = Icons.volunteer_activism_outlined;
      iconColor = Colors.purple;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.12),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(typeText, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              formatMoney(currency, txn.amount),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        subtitle: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(txn.note ?? '', style: const TextStyle(fontSize: 12)),
            Text(formatDate(txn.createdAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
