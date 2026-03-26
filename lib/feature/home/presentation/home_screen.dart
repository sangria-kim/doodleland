import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '그림놀이터',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  '안드로이드 우선 초기 설정이 완료된 홈 화면입니다.',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 80,
                  width: 240,
                  child: FilledButton(
                    onPressed: () => context.push('/capture'),
                    child: const Text('그림 만들기', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 80,
                  width: 240,
                  child: FilledButton.tonal(
                    onPressed: () => context.push('/stage/background'),
                    child: const Text('놀이 시작', style: TextStyle(fontSize: 22)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
