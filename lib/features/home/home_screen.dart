import 'package:flutter/material.dart';
import '../../core/locale_controller.dart';
import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../data/models/chit_group.dart';
import '../../data/models/chit_round.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/round_repository.dart';
import '../group/group_detail_screen.dart';
import '../group/new_chit_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<_ChitsListTabState> _chitsListKey = GlobalKey<_ChitsListTabState>();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLocaleController.instance,
      builder: (context, _) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: [
              ChitsListTab(key: _chitsListKey),
              const SettingsScreen(),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() => _currentIndex = index);
              if (index == 0) {
                _chitsListKey.currentState?.loadData();
              }
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: const Icon(Icons.account_balance_wallet),
                label: S.myChits,
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: S.settings,
              ),
            ],
          ),
        );
      },
    );
  }
}

class ChitsListTab extends StatefulWidget {
  const ChitsListTab({super.key});

  @override
  State<ChitsListTab> createState() => _ChitsListTabState();
}

class _ChitsListTabState extends State<ChitsListTab> {
  final GroupRepository _groupRepo = GroupRepository();
  final RoundRepository _roundRepo = RoundRepository();
  bool _loading = true;
  List<ChitGroup> _groups = [];
  final Map<int, List<ChitRound>> _groupRounds = {};

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => _loading = true);
    final groups = await _groupRepo.getAll();
    final Map<int, List<ChitRound>> roundsMap = {};
    for (final g in groups) {
      if (g.id != null) {
        roundsMap[g.id!] = await _roundRepo.getForGroup(g.id!);
      }
    }
    if (mounted) {
      setState(() {
        _groups = groups;
        _groupRounds.clear();
        _groupRounds.addAll(roundsMap);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.myChits, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const NewChitScreen()),
          );
          if (created == true) {
            loadData();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(S.newChit),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: loadData,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: 16),
                      for (final group in _groups) _buildGroupCard(group),
                      const SizedBox(height: 72),
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_rounded, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              S.createFirstChit,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              S.emptyChitsSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                final created = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const NewChitScreen()),
                );
                if (created == true) {
                  loadData();
                }
              },
              icon: const Icon(Icons.add),
              label: Text(S.startChit),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final activeCount = _groups.where((g) => g.status == 'active').length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              Text(
                S.totalChits,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              Text(
                '${_groups.length}',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Container(width: 1, height: 36, color: Colors.grey.shade400),
          Column(
            children: [
              Text(
                S.activeCountLabel,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 4),
              Text(
                '$activeCount',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(ChitGroup group) {
    final rounds = _groupRounds[group.id] ?? [];
    ChitRound? activeRound;
    for (final r in rounds) {
      if (r.status != 'paid_out') {
        activeRound = r;
        break;
      }
    }
    activeRound ??= rounds.isNotEmpty ? rounds.last : null;

    final periodLabel = S.period(group.period);
    final amountFormatted = formatMoney(group.currency, group.contributionAmount);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GroupDetailScreen(groupId: group.id!),
            ),
          );
          loadData();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      group.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: group.status == 'active'
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      group.status == 'active' ? S.active : S.completed,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: group.status == 'active' ? Colors.green.shade800 : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '$amountFormatted / $periodLabel',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    S.totalRounds(rounds.length),
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
              if (activeRound != null) ...[
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.sync_rounded, size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          S.roundProgress(activeRound.seqNo, rounds.length),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Text(
                      S.dueDate(formatDate(activeRound.dueDate)),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
