import 'package:flutter/material.dart';
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
  final _nameController = TextEditingController(text: 'குடும்ப சீட்டு');
  final _amountController = TextEditingController(text: '5000');
  String _period = 'monthly';
  DateTime _startDate = DateTime.now();
  int _dueDay = 5;

  // Interest Settings
  final _rateController = TextEditingController(text: '2.0');
  String _interestMode = 'late_fee';

  // Members list
  final List<Map<String, String>> _members = [
    {'name': 'குமார் (Kumar)', 'phone': '9876543210'},
    {'name': 'செல்வி (Selvi)', 'phone': '9876543211'},
    {'name': 'ராஜா (Raja)', 'phone': '9876543212'},
    {'name': 'கார்த்திக் (Karthik)', 'phone': '9876543213'},
    {'name': 'மீனா (Meena)', 'phone': '9876543214'},
  ];

  final _newMemberNameController = TextEditingController();
  final _newMemberPhoneController = TextEditingController();

  bool _saving = false;

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
        const SnackBar(content: Text('குறைந்தது ஒரு உறுப்பினர் தேவை')),
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
        const SnackBar(content: Text('உறுப்பினர்களை சேர்க்கவும்')),
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
          const SnackBar(content: Text('சீட்டு வெற்றிகரமாக உருவாக்கப்பட்டது!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('பிழை: $e')),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('புதிய சீட்டு உருவாக்குதல்'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Section 1: Basic
            _buildSectionHeader('1. அடிப்படை விவரங்கள் (Basic Details)'),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'சீட்டு பெயர் (Chit Name)',
                hintText: 'எ.கா. குடும்ப சீட்டு 2026',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'பெயர் தேவை' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'தவணை தொகை (Contribution ₹)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      final n = double.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'சரியான தொகை தேவை';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _period,
                    decoration: const InputDecoration(
                      labelText: 'கால இடைவெளி (Period)',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'monthly', child: Text('மாதம் (Monthly)')),
                      DropdownMenuItem(value: 'weekly', child: Text('வாரம் (Weekly)')),
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
                    label: Text('தொடக்க நாள்: ${formatDate(_startDate)}'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 100,
                  child: TextFormField(
                    initialValue: '$_dueDay',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'தவணை நாள்',
                      hintText: '5',
                      border: OutlineInputBorder(),
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
            _buildSectionHeader('2. வட்டி முறை (Interest Mode)'),
            TextFormField(
              controller: _rateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'வட்டி விகிதம் (Interest Rate %)',
                suffixText: '%',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            RadioListTile<String>(
              value: 'late_fee',
              groupValue: _interestMode,
              title: const Text('தாமத வட்டி (Late-fee)'),
              subtitle: const Text('தாமதமாக கட்டுபவர் மட்டும் வட்டி செலுத்துவார்'),
              onChanged: (v) => setState(() => _interestMode = v!),
            ),
            RadioListTile<String>(
              value: 'recipient_pays',
              groupValue: _interestMode,
              title: const Text('பிடித்தவர் வட்டி கட்டுவது (Recipient-pays)'),
              subtitle: const Text('பணம் எடுப்பவர் வட்டி கட்டுவார், மற்றவர்களுக்கு பகிர்ந்தளிக்கப்படும்'),
              onChanged: (v) => setState(() => _interestMode = v!),
            ),
            const SizedBox(height: 24),

            // Section 3: Members & Payout Order
            _buildSectionHeader('3. உறுப்பினர்கள் மற்றும் முறை (Members & Payout Order)'),
            Text(
              'வரிசை எண்தான் பணம் எடுக்கும் முறை (Rotation Order):',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _members.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) newIndex -= 1;
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
                    decoration: const InputDecoration(
                      labelText: 'உறுப்பினர் பெயர்',
                      hintText: 'பெயர்',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _newMemberPhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'போன் எண்',
                      hintText: '9876543210',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _addMember,
                  icon: const Icon(Icons.add),
                  tooltip: 'சேர்',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Section 4: Summary & Submit
            _buildSectionHeader('4. முன்னோட்டம் (Preview & Summary)'),
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
                      const Text('மொத்த உறுப்பினர்கள்:'),
                      Text('${_members.length} பேர்', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('மொத்த ரவுண்டுகள்:'),
                      Text('${_members.length} தவணைகள்', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ஒவ்வொரு ரவுண்டு Pot தொகை:'),
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
                  : const Text('சீட்டை உருவாக்கு (Create Chit)', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 32),
          ],
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
