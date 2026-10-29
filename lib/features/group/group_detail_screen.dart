import 'package:flutter/material.dart';
import '../../core/locale_controller.dart';
import '../../core/money/money.dart';
import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../data/models/chit_group.dart';
import '../../data/models/chit_round.dart';
import '../../data/models/membership.dart';
import '../../data/repositories/group_repository.dart';
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

  late TabController _tabController;
  bool _loading = true;
  ChitGroup? _group;
  List<ChitRound> _rounds = [];
  List<Membership> _memberships = [];
  final Map<int, Membership> _membershipMap = {};

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
    final memberships = await _groupRepo.getMemberships(widget.groupId);

    final map = <int, Membership>{};
    for (final m in memberships) {
      if (m.id != null) map[m.id!] = m;
    }

    if (mounted) {
      setState(() {
        _group = group;
        _rounds = rounds;
        _memberships = memberships;
        _membershipMap.clear();
        _membershipMap.addAll(map);
        _loading = false;
      });
    }
  }

  Future<void> _handleDelete() async {
    if (_group == null) return;
    final groupName = _group!.name;
    final textController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isMatch = textController.text.trim() == groupName.trim();
          return AlertDialog(
            title: Text(S.deleteChitPrompt),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.deleteChitWarning),
                const SizedBox(height: 16),
                Text(
                  S.typeChitNameToConfirm(groupName),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: textController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: S.enterChitNameHint,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (_) => setDialogState(() {}),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.cancel)),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: isMatch ? () => Navigator.pop(ctx, true) : null,
                child: Text(S.delete),
              ),
            ],
          );
        },
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
          if (!r.isPaidOut) {
            activeRound = r;
            break;
          }
        }
        activeRound ??= _rounds.isNotEmpty ? _rounds.last : null;

        final pot = Money.fromPaise(group.installmentPaise * _memberships.length);

        return Scaffold(
          appBar: AppBar(
            title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'More options',
                onSelected: (val) {
                  if (val == 'delete') _handleDelete();
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text(S.deleteChitTooltip, style: const TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
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
                      if (activeRound != null) _buildActiveRoundHero(activeRound, pot),
                      const SizedBox(height: 16),
                      _buildMetadataChips(group),
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
                      Tab(text: S.membersTab(_memberships.length)),
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

  Widget _buildActiveRoundHero(ChitRound round, Money pot) {
    final recipient = _membershipMap[round.recipientMembershipId];
    final statusLabel = S.roundStatus(round.status.value);

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
                      color: round.isPaidOut ? Colors.green : Colors.blue.shade900,
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
                      Text(S.recipientLabel,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                      const SizedBox(height: 2),
                      Text(
                        recipient?.contact?.name ?? S.notAssigned,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(S.potAmountLabel,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
                      const SizedBox(height: 2),
                      Text(
                        pot.format(),
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

  Widget _buildMetadataChips(ChitGroup group) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        Chip(
          avatar: const Icon(Icons.payments_outlined, size: 16),
          label: Text(S.contributionChip(group.installment.format())),
        ),
        Chip(
          avatar: const Icon(Icons.event_repeat_rounded, size: 16),
          label: Text(S.period(group.period)),
        ),
        if (group.rateBps > 0)
          Chip(
            avatar: const Icon(Icons.percent_rounded, size: 16),
            label: Text(S.interestChip(group.ratePct, group.penaltyMode.value)),
          ),
      ],
    );
  }

  Widget _buildMembersTab() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _memberships.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final m = _memberships[index];
        final contact = m.contact;
        return ListTile(
          leading: CircleAvatar(
            child: Text('${m.payoutOrder}'),
          ),
          title: Row(
            children: [
              Text(contact?.name ?? 'Member', style: const TextStyle(fontWeight: FontWeight.w600)),
              if (m.prized) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.purple.shade200),
                  ),
                  child: Text(
                    S.prizedStatusBadge,
                    style: TextStyle(fontSize: 10, color: Colors.purple.shade800, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(contact?.phone ?? S.noPhone),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MemberLedgerScreen(
                  groupId: widget.groupId,
                  membershipId: m.id!,
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
        final recipient = _membershipMap[round.recipientMembershipId];
        final statusLabel = S.roundStatus(round.status.value);

        Color badgeColor = Colors.blue.shade100;
        Color textColor = Colors.blue.shade900;
        if (round.isCollected) {
          badgeColor = Colors.orange.shade100;
          textColor = Colors.orange.shade900;
        } else if (round.isPaidOut) {
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
              S.roundTitleItem(round.seqNo, recipient?.contact?.name ?? S.noRecipient),
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
