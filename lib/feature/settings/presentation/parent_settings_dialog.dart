import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/presentation/settings_viewmodel.dart';

Future<void> showParentSettings(BuildContext context) => showDialog<void>(
  context: context,
  builder: (_) => const ParentSettingsDialog(),
);

class ParentSettingsDialog extends ConsumerWidget {
  const ParentSettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsViewModelProvider);
    final model = ref.watch(settingsViewModelProvider.notifier);
    final settings = state.settings;
    return AlertDialog(
      title: const Text('부모 설정'),
      scrollable: true,
      content: SizedBox(
        width: 440,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('배경 음악'),
              value: settings.musicEnabled,
              onChanged: model.setMusicEnabled,
            ),
            SwitchListTile(
              title: const Text('효과음'),
              value: settings.effectsEnabled,
              onChanged: model.setEffectsEnabled,
            ),
            SwitchListTile(
              title: const Text('안내 음성'),
              subtitle: const Text('홈 인사와 버튼의 말소리를 켜요.'),
              value: settings.voiceEnabled,
              onChanged: model.setVoiceEnabled,
            ),
            SwitchListTile(
              title: const Text('효과 줄이기'),
              subtitle: const Text('장식 효과를 줄여요. 그림의 움직임과 놀이 반응은 그대로예요.'),
              value: settings.reduceEffects,
              onChanged: model.setReduceEffects,
            ),
            if (state.isSaving) const Text('저장 중…', semanticsLabel: '설정 저장 중'),
            if (state.restoreError != null)
              const Text('이전 설정을 불러오지 못해 기본 설정으로 시작했어요.'),
            if (state.saveError != null)
              const Text('지금은 적용됐지만 다음 실행을 위해 저장하지 못했어요.'),
            if (state.saveError != null || state.restoreError != null)
              TextButton(
                onPressed: model.retrySave,
                child: const Text('다시 저장'),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    );
  }
}
