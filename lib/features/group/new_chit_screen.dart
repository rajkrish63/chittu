import 'package:flutter/material.dart';
import '../../core/locale_controller.dart';
import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../data/models/chit_group.dart';
import '../../data/models/member.dart';
import '../../data/repositories/group_repository.dart';

class NewChitScreen extends StatefulWidget {
  const NewChitScreen({super.key});

  @override
  State<NewChitScreen> createState() => _NewChitScreenState();
}

class _NewChitScreenState extends State<NewChitScreen> {
  final _formKey = GlobalKey<FormState>();
  final GroupRepository _groupRepo = GroupRepository();

  // Basic Details
  late final TextEditingController _nameController;
  final _amountController = TextEditingController(text: '5000');
  String _period = 'monthly';
  DateTime _startDate = DateTime.now();
  int _dueDay = 5;

  // Interest Settings
  final _rateController = TextEditingController(text: '2.0');
  String _interestMode = 'late_fee';

  // Members list
  late final List<Map<String, String>> _members;

  final _newMemberNameController = TextEditingController();
  final _newMemberPhoneController = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final isTa = AppLocaleController.instance.isTamil;
    _nameController = TextEditingController(text: isTa ? 'குடும்ப சீட்டு' : 'Family Chit');
    _members = isTa
        ? [
            {'name': 'குமார் (Kumar)', 'phone': '9876543210'},
            {'name': 'செல்வி (Selvi)', 'phone': '9876543211'},
            {'name': 'ராஜா (Raja)', 'phone': '9876543212'},
            {'name': 'கார்த்திக் (Karthik)', 'phone': '9876543213'},
            {'name': 'மீனா (Meena)', 'phone': '9876543214'},
          ]
        : [
            {'name': 'Kumar', 'phone': '9876543210'},
            {'name': 'Selvi', 'phone': '9876543211'},
            {'name': 'Raja', 'phone': '9876543212'},
            {'name': 'Karthik', 'phone': '9876543213'},
            {'name': 'Meena', 'phone': '9876543214'},
          ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _rateController.dispose();
    _newMemberNameController.dispose();
    _newMemberPhoneController.dispose();
    super.dispose();
  }

  void _addMember() {
    final name = _newMemberNameController.text.trim();
    final phone = _newMemberPhoneController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _members.add({'name': name, 'phone': phone});
      _newMemberNameController.clear();
      _newMemberPhoneController.clear();
    });
  }

  void _removeMember(int index) {
    if (_members.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.atLeastOneMember)),
      );
      return;
    }
    setState(() {
      _members.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_members.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.addMembersAlert)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final amount = double.tryParse(_amountController.text.trim()) ?? 0;
      final rate = double.tryParse(_rateController.text.trim()) ?? 0;

      final group = ChitGroup(
        name: _nameController.text.trim(),
        contributionAmount: amount,
        currency: '₹',
        period: _period,
        interestRatePct: rate,
        interestMode: _interestMode,
        startDate: _startDate,
        dueDay: _dueDay,
        status: 'active',
        createdAt: DateTime.now(),
      );

      final members = <Member>[];
      for (var i = 0; i < _members.length; i++) {
        members.add(Member(
          name: _members[i]['name']!,
          phone: _members[i]['phone'],
          payoutOrder: i + 1,
          role: i == 0 ? 'admin' : 'member',
          joinedAt: DateTime.now(),
        ));
      }

      await _groupRepo.createGroup(group, members);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.chitCreatedSuccess)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${S.error}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final totalPot = amount * _members.length;

    return ListenableBuilder(
      listenable: AppLocaleController.instance,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(S.createChitTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Section 1: Basic
              _buildSectionHeader(S.basicDetailsSection),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: S.chitNameLabel,
                  hintText: S.chitNameHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? S.nameRequired : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: S.contributionLabel,
                        prefixText: '₹ ',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final n = double.tryParse(v ?? '');
                        if (n == null || n <= 0) return S.validAmountRequired;
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _period,
                      decoration: InputDecoration(
                        labelText: S.periodLabel,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 'monthly', child: Text(S.monthly)),
                        DropdownMenuItem(value: 'weekly', child: Text(S.weekly)),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _period = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked;
                            _dueDay = picked.day;
                          });
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(S.startDateLabel(formatDate(_startDate))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 110,
                    child: TextFormField(
                      initialValue: '$_dueDay',
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: S.dueDayLabel,
                        hintText: '5',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        final n = int.tryParse(v);
                        if (n != null && n >= 1 && n <= 31) {
                          _dueDay = n;
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section 2: Interest
              _buildSectionHeader(S.interestModeSection),
              TextFormField(
                controller: _rateController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: S.interestRateLabel,
                  suffixText: '%',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              RadioGroup<String>(
                groupValue: _interestMode,
                onChanged: (v) {
                  if (v != null) setState(() => _interestMode = v);
                },
                child: Column(
                  children: [
                    RadioListTile<String>(
                      value: 'late_fee',
                      title: Text(S.lateFeeTitle),
                      subtitle: Text(S.lateFeeSubtitle),
                    ),
                    RadioListTile<String>(
                      value: 'recipient_pays',
                      title: Text(S.recipientPaysTitle),
                      subtitle: Text(S.recipientPaysSubtitle),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section 3: Members & Payout Order
              _buildSectionHeader(S.membersOrderSection),
              Text(
                S.rotationOrderSubtitle,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 8),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _members.length,
                onReorderItem: (oldIndex, newIndex) {
                  setState(() {
                    final item = _members.removeAt(oldIndex);
                    _members.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final m = _members[index];
                  return Card(
                    key: ValueKey(m['name']! + index.toString()),
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(m['name']!, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(m['phone'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _removeMember(index),
                          ),
                          const Icon(Icons.drag_handle),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _newMemberNameController,
                      decoration: InputDecoration(
                        labelText: S.memberNameLabel,
                        hintText: S.memberNameHint,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _newMemberPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: S.phoneLabel,
                        hintText: '9876543210',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addMember,
                    icon: const Icon(Icons.add),
                    tooltip: S.addMemberTooltip,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Section 4: Summary & Submit
              _buildSectionHeader(S.summaryPreviewSection),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(S.totalMembers),
                        Text(S.membersCount(_members.length), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(S.totalRoundsLabel),
                        Text(S.roundsCount(_members.length), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(S.potPerRound),
                        Text(
                          formatMoney('₹', totalPot),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(S.createChitButton, style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
