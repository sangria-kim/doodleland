import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../feature/home/presentation/home_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/capture',
        builder: (context, state) => const _ComingSoonScreen(title: '그림 만들기'),
      ),
      GoRoute(
        path: '/capture/crop',
        builder: (context, state) => const _ComingSoonScreen(title: '크롭'),
      ),
      GoRoute(
        path: '/capture/preview',
        builder: (context, state) => const _ComingSoonScreen(title: '미리보기'),
      ),
      GoRoute(
        path: '/stage/background',
        builder: (context, state) => const _ComingSoonScreen(title: '배경 선택'),
      ),
      GoRoute(
        path: '/stage',
        builder: (context, state) => const _ComingSoonScreen(title: '무대 놀이'),
      ),
    ],
  );
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: const Center(child: Text('초기 설정이 완료되면 이 화면이 연결됩니다.')),
    );
  }
}
