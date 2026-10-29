import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/contact_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/ledger_repository.dart';
import '../../data/repositories/round_repository.dart';

final contactRepositoryProvider = Provider<ContactRepository>((ref) {
  return ContactRepository();
});

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository();
});

final roundRepositoryProvider = Provider<RoundRepository>((ref) {
  return RoundRepository();
});

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  return LedgerRepository();
});

