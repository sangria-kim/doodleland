import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/stage_audio_controller.dart';
import '../../../core/presentation/menu_action_button.dart';
import '../../../router/app_router.dart';
import '../../library/presentation/library_viewmodel.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  static const int _totalAnimationMillis = 1380;

  late final AnimationController _controller;
  late final Animation<double> _foregroundOffsetY;
  late final Animation<double> _foregroundOpacity;
  late final Animation<double> _carsOffsetX;
  late final Animation<double> _carsOpacity;
  late final Animation<double> _titleScale;
  late final Animation<double> _titleOpacity;
  PageRoute<dynamic>? _subscribedRoute;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalAnimationMillis),
    );

    _foregroundOffsetY = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          200 / _totalAnimationMillis,
          620 / _totalAnimationMillis,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
    _foregroundOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          200 / _totalAnimationMillis,
          620 / _totalAnimationMillis,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _carsOffsetX = Tween<double>(begin: -10, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          500 / _totalAnimationMillis,
          880 / _totalAnimationMillis,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
    _carsOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          500 / _totalAnimationMillis,
          880 / _totalAnimationMillis,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _titleScale = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          900 / _totalAnimationMillis,
          1380 / _totalAnimationMillis,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
    _titleOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          900 / _totalAnimationMillis,
          1380 / _totalAnimationMillis,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    _controller.forward();
    unawaited(ref.read(stageAudioControllerProvider).playHomeEntryVoice());
  }

  @override
  void dispose() {
    if (_subscribedRoute != null) {
      AppRouter.homeRouteObserver.unsubscribe(this);
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute && route != _subscribedRoute) {
      if (_subscribedRoute != null) {
        AppRouter.homeRouteObserver.unsubscribe(this);
      }
      _subscribedRoute = route;
      AppRouter.homeRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    _controller.forward(from: 0);
    unawaited(ref.read(stageAudioControllerProvider).playHomeEntryVoice());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final buttonHeight = _responsiveButtonHeight(constraints.maxHeight);
          final buttonWidth = _responsiveButtonWidth(
            constraints.maxWidth.clamp(0.0, 1080.0),
          );
          final buttonGap = _responsiveButtonGap(constraints.maxWidth);
          final buttonFont = _responsiveButtonFont(constraints.maxHeight);
          final buttonIconSize = _responsiveIconSize(constraints.maxHeight);
          final buttonYOffset = _responsiveButtonYOffset(constraints.maxHeight);

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      'assets/backgrounds/main/bg_main_background.png',
                      key: const Key('home-bg-base'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: _foregroundOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _foregroundOffsetY.value),
                        child: Image.asset(
                          'assets/backgrounds/main/bg_main_foreground.png',
                          key: const Key('home-bg-foreground'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: _carsOpacity.value,
                      child: Transform.translate(
                        offset: Offset(_carsOffsetX.value, 0),
                        child: Image.asset(
                          'assets/backgrounds/main/bg_main_cars.png',
                          key: const Key('home-bg-cars'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: _titleOpacity.value,
                      child: Transform.scale(
                        scale: _titleScale.value,
                        child: Image.asset(
                          'assets/backgrounds/main/bg_main_title.png',
                          key: const Key('home-bg-title'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Center(
                      child: Transform.translate(
                        offset: Offset(0, buttonYOffset),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1080),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: buttonWidth,
                                height: buttonHeight,
                                child: MenuActionButton(
                                  label: '그림 만들기',
                                  icon: Icons.edit,
                                  buttonFontSize: buttonFont,
                                  buttonIconSize: buttonIconSize,
                                  onPressed: () => _startCreate(context),
                                ),
                              ),
                              SizedBox(width: buttonGap),
                              SizedBox(
                                width: buttonWidth,
                                height: buttonHeight,
                                child: MenuActionButton(
                                  label: '내 그림',
                                  icon: Icons.photo_library_outlined,
                                  buttonFontSize: buttonFont,
                                  buttonIconSize: buttonIconSize,
                                  onPressed: () => _openLibrary(context),
                                ),
                              ),
                              SizedBox(width: buttonGap),
                              SizedBox(
                                width: buttonWidth,
                                height: buttonHeight,
                                child: MenuActionButton(
                                  label: '놀이 시작',
                                  icon: Icons.play_arrow,
                                  backgroundColor: const Color(0xFFFF6F00),
                                  buttonFontSize: buttonFont,
                                  buttonIconSize: buttonIconSize,
                                  onPressed: () => _startStage(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  double _uiDensity(double screenHeight) {
    return (screenHeight / 640).clamp(0.62, 1.0);
  }

  double _responsiveButtonHeight(double screenHeight) {
    return screenHeight * 0.20;
  }

  double _responsiveButtonWidth(double screenWidth) {
    return screenWidth * 0.25;
  }

  double _responsiveButtonGap(double screenWidth) {
    return screenWidth * 0.02;
  }

  double _responsiveButtonFont(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (32 * density).clamp(19.0, 32.0);
  }

  double _responsiveIconSize(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (36 * density).clamp(21.0, 36.0);
  }

  double _responsiveButtonYOffset(double screenHeight) {
    return (screenHeight * 0.08).clamp(28.0, 64.0);
  }

  Future<void> _startStage(BuildContext context) async {
    unawaited(ref.read(stageAudioControllerProvider).playHomePlayButtonSfx());

    final viewModel = ref.read(libraryViewModelProvider.notifier);
    await viewModel.loadCharacters();

    final characters = ref.read(libraryViewModelProvider).characters;
    if (!context.mounted) {
      return;
    }

    if (characters.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('그림이 없어요. 먼저 그림을 만들어보세요.')));
      GoRouter.of(context).push('/capture');
      return;
    }

    GoRouter.of(context).push('/stage/background');
  }

  Future<void> _startCreate(BuildContext context) async {
    unawaited(ref.read(stageAudioControllerProvider).playHomeCreateButtonSfx());

    if (!context.mounted) {
      return;
    }

    context.push('/capture');
  }

  void _openLibrary(BuildContext context) {
    if (!context.mounted) {
      return;
    }

    context.push('/library');
  }
}
