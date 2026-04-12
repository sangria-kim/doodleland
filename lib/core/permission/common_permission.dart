import 'package:permission_handler/permission_handler.dart';

enum PermissionFailureType {
  denied,
  deniedPermanently,
  limited,
  restricted,
  unknown,
}

class PermissionFailure {
  const PermissionFailure({required this.type, required this.message});

  final PermissionFailureType type;
  final String message;

  bool get canRetry => type == PermissionFailureType.denied;
}

class PermissionResult {
  const PermissionResult({required this.isGranted, this.failure});

  final bool isGranted;
  final PermissionFailure? failure;

  factory PermissionResult.granted() {
    return const PermissionResult(isGranted: true);
  }

  factory PermissionResult.denied(PermissionFailure failure) {
    return PermissionResult(isGranted: false, failure: failure);
  }
}

class PermissionResultMapper {
  const PermissionResultMapper();

  PermissionResult fromStatus(
    PermissionStatus status, {
    String? permissionName,
  }) {
    if (status.isGranted) {
      return PermissionResult.granted();
    }
    if (status.isLimited) {
      return PermissionResult.denied(
        PermissionFailure(
          type: PermissionFailureType.limited,
          message: '${permissionName ?? 'permission'} 제한 모드입니다.',
        ),
      );
    }
    if (status.isPermanentlyDenied) {
      return PermissionResult.denied(
        PermissionFailure(
          type: PermissionFailureType.deniedPermanently,
          message:
              '${permissionName ?? 'permission'} 권한이 영구적으로 거부되었습니다. 설정에서 허용해 주세요.',
        ),
      );
    }
    if (status.isRestricted) {
      return PermissionResult.denied(
        PermissionFailure(
          type: PermissionFailureType.restricted,
          message: '${permissionName ?? 'permission'} 접근이 기기 정책에 의해 제한됩니다.',
        ),
      );
    }
    if (status.isDenied) {
      return PermissionResult.denied(
        PermissionFailure(
          type: PermissionFailureType.denied,
          message: '${permissionName ?? 'permission'}이(가) 거부되어 기능을 사용할 수 없습니다.',
        ),
      );
    }
    return PermissionResult.denied(
      PermissionFailure(
        type: PermissionFailureType.unknown,
        message: '${permissionName ?? 'permission'} 상태를 판별할 수 없습니다.',
      ),
    );
  }

  Future<PermissionResult> ensureGranted(Permission permission) async {
    final status = await permission.request();
    return fromStatus(status, permissionName: permission.toString());
  }
}
