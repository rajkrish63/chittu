import 'package:go_router/go_router.dart';
import '../../features/home/home_screen.dart';
import '../../features/group/new_chit_screen.dart';
import '../../features/group/group_detail_screen.dart';
import '../../features/round/round_detail_screen.dart';
import '../../features/member/member_ledger_screen.dart';
import '../../features/settings/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/new-group',
      builder: (context, state) => const NewChitScreen(),
    ),
    GoRoute(
      path: '/group/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return GroupDetailScreen(groupId: id);
      },
    ),
    GoRoute(
      path: '/round/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return RoundDetailScreen(roundId: id);
      },
    ),
    GoRoute(
      path: '/member/:groupId/:membershipId',
      builder: (context, state) {
        final groupId = int.parse(state.pathParameters['groupId']!);
        final membershipId = int.parse(state.pathParameters['membershipId']!);
        return MemberLedgerScreen(groupId: groupId, membershipId: membershipId);
      },
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
