import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants.dart';
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
    final netSign = b.net >= 0 ? '+' : '';
    final statement = '''
📄 *சீட்டு கணக்கு அறிக்கை (Statement)*
--------------------------------
சீட்டு: ${_group!.name}
உறுப்பினர்: ${_member!.name}
போன்: ${_member!.phone ?? '-'}
தேதி: ${formatDate(DateTime.now())}

*கணக்கு சுருக்கம் (Summary):*
• வசூல் செலுத்தியது: ${formatMoney(_group!.currency, b.contributed)}
• சீட்டு எடுத்தது: ${formatMoney(_group!.currency, b.taken)}
• வட்டி செலுத்தியது: ${formatMoney(_group!.currency, b.interestPaid)}
• பங்கு பெற்றது: ${formatMoney(_group!.currency, b.dividends)}
• நிலுவை (Arrears): ${formatMoney(_group!.currency, b.arrears)}
--------------------------------
*நிகர நிலை (Net Position):* $netSign${formatMoney(_group!.currency, b.net)}
--------------------------------
_Chit Notebook வழியாக பகிரப்பட்டது_
''';

    await Share.share(statement, subject: '${_member!.name} - Statement');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_member == null || _group == null || _balance == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('கணக்கு விவரம்')),
        body: const Center(child: Text('விவரங்கள் கிடைக்கவில்லை')),
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
            tooltip: 'அறிக்கையை பகிர்',
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
                    'நிகர நிலை (Net Position)',
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
                    isNetPositive
                        ? '(பெற்ற தொகை அதிகம் / Net Gain)'
                        : '(செலுத்த வேண்டிய தொகை / Net Due)',
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
              const Text(
                'பரிவர்த்தனை வரலாறு (Timeline)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_transactions.length} பதிவுகள்',
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
                  'பரிவர்த்தனைகள் எதுவும் இல்லை',
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
  }

  Widget _buildBreakdownGrid(MemberBalance b, String currency) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricTile('வசூல் (Paid)', formatMoney(currency, b.contributed), Colors.blue)),
            const SizedBox(width: 8),
            Expanded(child: _buildMetricTile('எடுத்தது (Taken)', formatMoney(currency, b.taken), Colors.green)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildMetricTile('வட்டி (Interest)', formatMoney(currency, b.interestPaid), Colors.orange)),
            const SizedBox(width: 8),
            Expanded(child: _buildMetricTile('பங்கு (Dividend)', formatMoney(currency, b.dividends), Colors.purple)),
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
                const Text('தற்போதைய பாக்கி (Arrears):', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
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
        color: color.withOpacity(0.08),
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
    final typeTamil = Labels.txnTypes[txn.type] ?? txn.type;
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
          backgroundColor: iconColor.withOpacity(0.12),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(typeTamil, style: const TextStyle(fontWeight: FontWeight.w600)),
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
