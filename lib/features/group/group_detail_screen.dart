import 'package:flutter/material.dart';
import '../../core/locale_controller.dart';
import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../data/models/chit_group.dart';
import '../../data/models/chit_round.dart';
import '../../data/models/member.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/member_repository.dart';
import '../../data/repositories/round_repository.dart';
import '../member/member_ledger_screen.dart';
import '../round/round_detail_screen.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({super.key, required this.groupId});
  final int groupId;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> with SingleTickerProviderStateMixin {
  final GroupRepository _groupRepo = GroupRepository();
  final RoundRepository _roundRepo = RoundRepository();
  final MemberRepository _memberRepo = MemberRepository();

  late TabController _tabController;
  bool _loading = true;
  ChitGroup? _group;
  List<ChitRound> _rounds = [];
  List<Member> _members = [];
  final Map<int, Member> _memberMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final group = await _groupRepo.getById(widget.groupId);
    final rounds = await _roundRepo.getForGroup(widget.groupId);
    final members = await _memberRepo.getForGroup(widget.groupId);

    final map = <int, Member>{};
    for (final m in members) {
      if (m.id != null) map[m.id!] = m;
    }

    if (mounted) {
      setState(() {
        _group = group;
        _rounds = rounds;
        _members = members;
        _memberMap.clear();
        _memberMap.addAll(map);
        _loading = false;
      });
    }
  }

  Future<void> _handleDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.deleteChitPrompt),
        content: Text(S.deleteChitWarning),
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

    if (confirm != true) return;

    try {
      await _groupRepo.deleteIfEmpty(widget.groupId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.chitDeleted)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(S.cannotDelete),
            content: Text(e.toString().replaceAll('StateError: ', '')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.ok)),
            ],
          ),
        );
      }
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

        if (_group == null) {
          return Scaffold(
            appBar: AppBar(title: Text(S.myChits)),
            body: Center(child: Text(S.groupDetailsNotFound)),
          );
        }

        final group = _group!;
        ChitRound? activeRound;
        for (final r in _rounds) {
          if (r.status != 'paid_out') {
            activeRound = r;
            break;
          }
        }
        activeRound ??= _rounds.isNotEmpty ? _rounds.last : null;

        final potAmount = group.contributionAmount * _members.length;

        return Scaffold(
          appBar: AppBar(
            title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: S.deleteChitTooltip,
                onPressed: _handleDelete,
              ),
            ],
          ),
          body: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Round Card
                      if (activeRound != null) _buildActiveRoundHero(activeRound, potAmount),
                      const SizedBox(height: 16),
                      // Group metadata chip row
                      _buildMetadataChips(group, potAmount),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: S.membersTab(_members.length)),
                      Tab(text: S.roundsTab(_rounds.length)),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildMembersTab(),
                _buildRoundsTab(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveRoundHero(ChitRound round, double potAmount) {
    final recipient = _memberMap[round.recipientMemberId];
    final accountable = _memberMap[round.accountableMemberId];
    final statusLabel = S.roundStatus(round.status);

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.currentRoundProgress(round.seqNo, _rounds.length),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: round.status == 'paid_out' ? Colors.green : Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.recipientLabel, style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                      const SizedBox(height: 2),
                      Text(
                        recipient?.name ?? S.notAssigned,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(S.potAmountLabel, style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                      const SizedBox(height: 2),
                      Text(
                        formatMoney(_group!.currency, potAmount),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  S.accountableLabel(accountable?.name),
                  style: const TextStyle(fontSize: 12),
                ),
                const Spacer(),
                Text(
                  S.dueDate(formatDate(round.dueDate)),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RoundDetailScreen(roundId: round.id!),
                    ),
                  );
                  _loadData();
                },
                icon: const Icon(Icons.arrow_forward_rounded),
                label: Text(S.viewRoundDetails),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataChips(ChitGroup group, double potAmount) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          avatar: const Icon(Icons.payments_outlined, size: 16),
          label: Text(S.contributionChip(formatMoney(group.currency, group.contributionAmount))),
        ),
        Chip(
          avatar: const Icon(Icons.event_repeat_rounded, size: 16),
          label: Text(S.period(group.period)),
        ),
        Chip(
          avatar: const Icon(Icons.percent_rounded, size: 16),
          label: Text(S.interestChip(group.interestRatePct, group.interestMode)),
        ),
      ],
    );
  }

  Widget _buildMembersTab() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _members.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final member = _members[index];
        return ListTile(
          leading: CircleAvatar(
            child: Text('${member.payoutOrder}'),
          ),
          title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(member.phone ?? S.noPhone),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MemberLedgerScreen(
                  memberId: member.id!,
                  groupId: widget.groupId,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoundsTab() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _rounds.length,
      itemBuilder: (context, index) {
        final round = _rounds[index];
        final recipient = _memberMap[round.recipientMemberId];
        final statusLabel = S.roundStatus(round.status);

        Color badgeColor = Colors.blue.shade100;
        Color textColor = Colors.blue.shade900;
        if (round.status == 'collected') {
          badgeColor = Colors.orange.shade100;
          textColor = Colors.orange.shade900;
        } else if (round.status == 'paid_out') {
          badgeColor = Colors.green.shade100;
          textColor = Colors.green.shade900;
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: badgeColor,
              child: Text(
                '${round.seqNo}',
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
              ),
            ),
            title: Text(
              S.roundTitleItem(round.seqNo, recipient?.name ?? S.noRecipient),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(S.dueDateItem(formatDate(round.dueDate))),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor),
              ),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RoundDetailScreen(roundId: round.id!),
                ),
              );
              _loadData();
            },
          ),
        );
      },
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this.tabBar);
  final TabBar tabBar;

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
