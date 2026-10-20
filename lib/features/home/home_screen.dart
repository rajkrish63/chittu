import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants.dart';
import '../../core/utils.dart';
import '../../data/database/database_helper.dart';
import '../../data/models/chit_group.dart';
import '../../data/models/chit_round.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/round_repository.dart';
import '../group/group_detail_screen.dart';
import '../group/new_chit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GroupRepository _groupRepo = GroupRepository();
  final RoundRepository _roundRepo = RoundRepository();
  bool _loading = true;
  List<ChitGroup> _groups = [];
  final Map<int, List<ChitRound>> _groupRounds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
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
        _groupRounds.addAll(roundsMap);
        _loading = false;
      });
    }
  }

  Future<void> _exportBackup() async {
    try {
      final json = await DatabaseHelper.instance.exportJson();
      await Share.share(
        json,
        subject: 'Chit Notebook Backup - ${DateTime.now().toIso8601String().substring(0, 10)}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup export தயார்!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup பிழை: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('என் சீட்கள்', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'JSON Backup',
            icon: const Icon(Icons.cloud_download_outlined),
            onPressed: _exportBackup,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const NewChitScreen()),
          );
          if (created == true) {
            _loadData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('புதிய சீட்டு'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadData,
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
            const Text(
              'முதல் சீட்டை உருவாக்குங்க',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'உங்கள் குடும்பம் மற்றும் நண்பர்கள் சீட்டு கணக்கை எளிய முறையில் குறித்து வையுங்கள்.',
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
                  _loadData();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('சீட்டு தொடங்கு'),
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
                'மொத்த சீட்கள்',
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
                'செயலில் உள்ளவை',
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

    final periodTamil = Labels.periods[group.period] ?? group.period;
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
          _loadData();
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
                          ? Colors.green.withOpacity(0.12)
                          : Colors.grey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      group.status == 'active' ? 'செயலில் உள்ளது' : 'முடிந்தது',
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
                    '$amountFormatted / $periodTamil',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'மொத்தம்: ${rounds.length} ரவுண்டுகள்',
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
                          'ரவுண்டு ${activeRound.seqNo} / ${rounds.length}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Text(
                      'தவணை: ${formatDate(activeRound.dueDate)}',
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
