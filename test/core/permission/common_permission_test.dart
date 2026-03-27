import 'package:doodleland/core/permission/common_permission.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  final mapper = PermissionResultMapper();

  test('granted status becomes successful result', () async {
    final result = mapper.fromStatus(PermissionStatus.granted, permissionName: 'camera');

    expect(result.isGranted, isTrue);
    expect(result.failure, isNull);
  });

  test('denied status becomes retryable failure', () async {
    final result = mapper.fromStatus(PermissionStatus.denied, permissionName: 'camera');

    expect(result.isGranted, isFalse);
    expect(result.failure?.type, PermissionFailureType.denied);
    expect(result.failure?.canRetry, isTrue);
  });

  test('permanently denied status requests user settings route', () async {
    final result = mapper.fromStatus(
      PermissionStatus.permanentlyDenied,
      permissionName: 'gallery',
    );

    expect(result.isGranted, isFalse);
    expect(result.failure?.type, PermissionFailureType.deniedPermanently);
    expect(result.failure?.canRetry, isFalse);
  });
}
