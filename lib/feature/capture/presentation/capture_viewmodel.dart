import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/permission/common_permission.dart';
import '../domain/save_character_usecase.dart';

class CaptureState {
  const CaptureState({
    this.isBusy = false,
    this.selectedImagePath,
    this.feedbackMessage,
    this.lastSavedId,
  });

  final bool isBusy;
  final String? selectedImagePath;
  final String? feedbackMessage;
  final int? lastSavedId;

  CaptureState copyWith({
    bool? isBusy,
    String? selectedImagePath,
    String? feedbackMessage,
    int? lastSavedId,
  }) {
    return CaptureState(
      isBusy: isBusy ?? this.isBusy,
      selectedImagePath: selectedImagePath ?? this.selectedImagePath,
      feedbackMessage: feedbackMessage,
      lastSavedId: lastSavedId ?? this.lastSavedId,
    );
  }

  bool get hasFeedback => feedbackMessage != null;
}

enum CaptureImageSource {
  camera,
  gallery,
}

class CaptureViewModel extends StateNotifier<CaptureState> {
  CaptureViewModel({
    required ImagePicker imagePicker,
    required PermissionResultMapper permissionResultMapper,
    required SaveCharacterUseCase saveCharacterUseCase,
  })  : _imagePicker = imagePicker,
        _permissionResultMapper = permissionResultMapper,
        _saveCharacterUseCase = saveCharacterUseCase,
        super(const CaptureState());

  final ImagePicker _imagePicker;
  final PermissionResultMapper _permissionResultMapper;
  final SaveCharacterUseCase _saveCharacterUseCase;

  Future<String?> pickImage(CaptureImageSource source) async {
    if (state.isBusy) return null;

    state = state.copyWith(isBusy: true, feedbackMessage: null);

    final permission = switch (source) {
      CaptureImageSource.camera => Permission.camera,
      CaptureImageSource.gallery => Permission.photos,
    };
    final permissionResult = await _permissionResultMapper.ensureGranted(permission);
    if (!permissionResult.isGranted) {
      state = state.copyWith(
        isBusy: false,
        feedbackMessage: permissionResult.failure?.message,
      );
      return null;
    }

    final imageSource = switch (source) {
      CaptureImageSource.camera => ImageSource.camera,
      CaptureImageSource.gallery => ImageSource.gallery,
    };
    final pickedFile = await _imagePicker.pickImage(
      source: imageSource,
      maxWidth: 1920,
      imageQuality: 90,
    );
    if (pickedFile == null) {
      state = state.copyWith(
        isBusy: false,
        feedbackMessage: '이미지 선택이 취소되었습니다.',
      );
      return null;
    }

    state = state.copyWith(
      isBusy: false,
      selectedImagePath: pickedFile.path,
      feedbackMessage: null,
    );
    return pickedFile.path;
  }

  Future<SaveCharacterResult?> saveCurrentImage(String imagePath) async {
    if (state.isBusy) return null;

    state = state.copyWith(isBusy: true, feedbackMessage: null);
    try {
      final result = await _saveCharacterUseCase(sourceImagePath: imagePath);
      state = state.copyWith(
        isBusy: false,
        selectedImagePath: imagePath,
        lastSavedId: result.characterId,
        feedbackMessage: result.qualityWarningMessage,
      );
      return result;
    } catch (error) {
      state = state.copyWith(
        isBusy: false,
        feedbackMessage: '저장 중 오류가 발생했습니다: $error',
      );
      return null;
    }
  }

  void clearFeedback() {
    state = state.copyWith(feedbackMessage: null);
  }
}

final imagePickerProvider = Provider<ImagePicker>((_) => ImagePicker());

final captureViewModelProvider =
    StateNotifierProvider<CaptureViewModel, CaptureState>(
  (ref) => CaptureViewModel(
    imagePicker: ref.watch(imagePickerProvider),
    permissionResultMapper: const PermissionResultMapper(),
    saveCharacterUseCase: ref.watch(saveCharacterUseCaseProvider),
  ),
);
