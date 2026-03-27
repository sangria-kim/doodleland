import 'package:go_router/go_router.dart';

import '../feature/capture/presentation/capture_screen.dart';
import '../feature/capture/presentation/crop_screen.dart';
import '../feature/capture/presentation/preview_screen.dart';
import '../feature/home/presentation/home_screen.dart';
import '../feature/stage/presentation/background_select_screen.dart';
import '../feature/stage/presentation/stage_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/capture',
        builder: (context, state) => const CaptureScreen(),
      ),
      GoRoute(
        path: '/capture/crop',
        builder: (context, state) {
          final sourceImagePath =
              state.extra is String ? state.extra as String : '';
          return CropScreen(sourceImagePath: sourceImagePath);
        },
      ),
      GoRoute(
        path: '/capture/preview',
        builder: (context, state) {
          final previewImagePath = state.extra is String ? state.extra as String : '';
          return PreviewScreen(previewImagePath: previewImagePath);
        },
      ),
      GoRoute(
        path: '/stage/background',
        builder: (context, state) => const BackgroundSelectScreen(),
      ),
      GoRoute(
        path: '/stage',
        builder: (context, state) => const StageScreen(),
      ),
    ],
  );
}
