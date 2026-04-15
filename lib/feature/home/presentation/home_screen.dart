import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/stage_audio_controller.dart';
import '../../../core/theme/app_theme.dart';
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final gap = _responsiveGap(constraints.maxHeight);
          final buttonHeight = _responsiveButtonHeight(constraints.maxHeight);
          final buttonWidth = _responsiveButtonWidth(constraints.maxWidth, gap);
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
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              _HomeActionButtonFrame(
                                width: buttonWidth,
                                height: buttonHeight,
                                child: _HomeActionButton(
                                  label: '그림 만들기',
                                  icon: Icons.edit,
                                  buttonFontSize: buttonFont,
                                  iconSize: buttonIconSize,
                                  onPressed: () => _startCreate(context),
                                ),
                              ),
                              _HomeActionButtonFrame(
                                width: buttonWidth,
                                height: buttonHeight,
                                child: _HomeActionButton(
                                  label: '놀이 시작',
                                  icon: Icons.play_arrow,
                                  tonal: true,
                                  buttonFontSize: buttonFont,
                                  iconSize: buttonIconSize,
                                  onPressed: () => _startStage(context),
                                ),
                              ),
                              _HomeActionButtonFrame(
                                width: buttonWidth,
                                height: buttonHeight,
                                child: _HomeActionButton(
                                  label: '내 그림',
                                  icon: Icons.photo_library_outlined,
                                  tonal: true,
                                  backgroundColor: const Color(0xFF6A9FC7),
                                  buttonFontSize: buttonFont,
                                  iconSize: buttonIconSize,
                                  onPressed: () => _openLibrary(context),
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

  double _responsiveGap(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (16 * density).clamp(10.0, 18.0);
  }

  double _responsiveButtonHeight(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (126 * density).clamp(110.0, 144.0);
  }

  double _responsiveButtonWidth(double screenWidth, double gap) {
    final available = screenWidth - (gap * 2);
    return (available / 3).clamp(170.0, 280.0);
  }

  double _responsiveButtonFont(double screenHeight) {
    final density = _uiDensity(screenHeight);
    return (30 * density).clamp(18.0, 30.0);
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

class _HomeActionButtonFrame extends StatelessWidget {
  const _HomeActionButtonFrame({
    required this.width,
    required this.height,
    required this.child,
  });

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, height: height, child: child);
  }
}

class _HomeActionButton extends StatelessWidget {
  const _HomeActionButton({
    required this.label,
    required this.icon,
    required this.buttonFontSize,
    required this.iconSize,
    this.onPressed,
    this.tonal = false,
    this.backgroundColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool tonal;
  final Color? backgroundColor;
  final double buttonFontSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final isPrimary = !tonal;
    final borderRadius = BorderRadius.circular(30);
    final baseBackground =
        backgroundColor ??
        (isPrimary ? AppPalette.primary : const Color(0xFF53B4A0));
    final buttonBackground = baseBackground.withValues(alpha: 0.6);
    final buttonForeground = AppPalette.onPrimary;
    final disabledBackground = isPrimary
        ? const Color(0xFFC8CDD2)
        : const Color(0xFFDDE3E6);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: borderRadius,
        splashColor: AppPalette.primary.withValues(alpha: 0.16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            color: isEnabled ? buttonBackground : disabledBackground,
            border: Border.all(
              color: isPrimary
                  ? Colors.white.withValues(alpha: 0.26)
                  : Colors.white.withValues(alpha: 0.30),
              width: isPrimary ? 1.5 : 1.2,
            ),
            boxShadow: isEnabled
                ? [
                    BoxShadow(
                      color:
                          (isPrimary
                                  ? AppPalette.primary
                                  : AppPalette.textSecondary)
                              .withValues(alpha: 0.26),
                      blurRadius: 14,
                      spreadRadius: 0,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: SizedBox.expand(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _HomeActionButtonContent(
                icon: icon,
                label: label,
                buttonFontSize: buttonFontSize,
                iconSize: iconSize,
                color: buttonForeground.withValues(alpha: isEnabled ? 1 : 0.55),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeActionButtonContent extends StatelessWidget {
  const _HomeActionButtonContent({
    required this.icon,
    required this.label,
    required this.buttonFontSize,
    required this.iconSize,
    required this.color,
  });

  final IconData icon;
  final String label;
  final double buttonFontSize;
  final double iconSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: iconSize, color: color),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: buttonFontSize,
              fontWeight: FontWeight.w700,
              height: 1.2,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}
