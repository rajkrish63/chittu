import 'package:flutter/material.dart';
import '../../core/locale_controller.dart';
import '../../core/money/money.dart';
import '../../core/strings.dart';
import '../../core/utils.dart';
import '../../data/models/chit_group.dart';
import '../../data/models/contact.dart';
import '../../data/repositories/contact_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../domain/models/enums.dart';

class NewChitScreen extends StatefulWidget {
  const NewChitScreen({super.key});

  @override
  State<NewChitScreen> createState() => _NewChitScreenState();
}

class _NewChitScreenState extends State<NewChitScreen> {
  final _formKey = GlobalKey<FormState>();
  final GroupRepository _groupRepo = GroupRepository();
  final ContactRepository _contactRepo = ContactRepository();

  // Basic Details
  late final TextEditingController _nameController;
  final _amountController = TextEditingController(text: '5000');
  String _period = 'monthly';
  DateTime _startDate = DateTime.now();
  int _dueDay = 5;

  // Interest & Penalty Settings
  final _rateController = TextEditingController(text: '2.0');
  String _interestMode = 'late_fee';

  // Members list (name, phone, note)
  late final List<Map<String, String>> _members;

  final _newMemberNameController = TextEditingController();
  final _newMemberPhoneController = TextEditingController();
  final _newMemberNoteController = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final isTa = AppLocaleController.instance.isTamil;
    _nameController = TextEditingController(text: isTa ? 'குடும்ப சீட்டு' : 'Family Chit');
    _members = isTa
        ? [
            {'name': 'குமார் (Kumar)', 'phone': '9876543210', 'note': ''},
            {'name': 'செல்வி (Selvi)', 'phone': '9876543211', 'note': ''},
            {'name': 'ராஜா (Raja)', 'phone': '9876543212', 'note': ''},
            {'name': 'கார்த்திக் (Karthik)', 'phone': '9876543213', 'note': ''},
            {'name': 'மீனா (Meena)', 'phone': '9876543214', 'note': ''},
          ]
        : [
            {'name': 'Kumar', 'phone': '9876543210', 'note': ''},
            {'name': 'Selvi', 'phone': '9876543211', 'note': ''},
            {'name': 'Raja', 'phone': '9876543212', 'note': ''},
            {'name': 'Karthik', 'phone': '9876543213', 'note': ''},
            {'name': 'Meena', 'phone': '9876543214', 'note': ''},
          ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _rateController.dispose();
    _newMemberNameController.dispose();
    _newMemberPhoneController.dispose();
    _newMemberNoteController.dispose();
    super.dispose();
  }

  void _addMember() {
    final name = _newMemberNameController.text.trim();
    final phone = _newMemberPhoneController.text.trim();
    final note = _newMemberNoteController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _members.add({'name': name, 'phone': phone, 'note': note});
      _newMemberNameController.clear();
      _newMemberPhoneController.clear();
      _newMemberNoteController.clear();
    });
  }

  Future<void> _pickExistingContact() async {
    final existingContacts = await _contactRepo.getAllContacts();
    if (!mounted) return;

    if (existingContacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved contacts yet in notebook.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<Contact>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select from Notebook Contacts',
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: existingContacts.length,
                  itemBuilder: (ctx, i) {
                    final c = existingContacts[i];
                    return ListTile(
                      leading: CircleAvatar(child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?')),
                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(c.phone ?? 'No phone'),
                      onTap: () => Navigator.pop(ctx, c),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null) {
      setState(() {
        _newMemberNameController.text = selected.name;
        _newMemberPhoneController.text = selected.phone ?? '';
      });
    }
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
      final money = Money.tryParse(_amountController.text.trim()) ?? Money.zero;
      final rateBps = ((double.tryParse(_rateController.text.trim()) ?? 0.0) * 100).round();

      final group = ChitGroup(
        name: _nameController.text.trim(),
        installmentPaise: money.paise,
        currency: '₹',
        period: _period,
        payoutMethod: PayoutMethod.fixedOrder,
        penaltyMode: PenaltyMode.fromString(_interestMode),
        rateBps: rateBps,
        graceDays: 0,
        commissionBps: 0,
        status: 'active',
        createdAt: DateTime.now(),
      );

      final contacts = <Contact>[];
      final guarantorNotes = <String?>[];

      for (var i = 0; i < _members.length; i++) {
        final m = _members[i];
        contacts.add(Contact(
          name: m['name']!,
          phone: m['phone']?.isEmpty == true ? null : m['phone'],
          createdAt: DateTime.now(),
        ));
        guarantorNotes.add(m['note']?.isEmpty == true ? null : m['note']);
      }

      await _groupRepo.createGroupWithMembershipsAndRounds(
        group: group,
        contacts: contacts,
        startDate: _startDate,
        dueDay: _dueDay,
        guarantorNotes: guarantorNotes,
      );

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
    final money = Money.tryParse(_amountController.text.trim()) ?? Money.zero;
    final totalPot = money * _members.length;

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
              // Section 1: Basic Details
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
                        final m = Money.tryParse(v ?? '');
                        if (m == null || m.paise <= 0) return S.validAmountRequired;
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

              // Section 2: Interest & Penalty Settings
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
                      subtitle: Text(m['phone']?.isNotEmpty == true ? m['phone']! : 'No phone'),
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
              const SizedBox(height: 12),
              // Member input row with contact picker
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _newMemberNameController,
                      decoration: InputDecoration(
                        labelText: S.memberNameLabel,
                        hintText: S.memberNameHint,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.contacts_outlined),
                          tooltip: 'Pick from saved contacts',
                          onPressed: _pickExistingContact,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _newMemberPhoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        hintText: '9876543210',
                        border: OutlineInputBorder(),
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
                          totalPot.format(),
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
