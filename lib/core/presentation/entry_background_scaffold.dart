import 'package:flutter/material.dart';

import '../constants/app_asset_paths.dart';
import 'app_back_button.dart';

class EntryBackgroundScaffold extends StatelessWidget {
  const EntryBackgroundScaffold({
    super.key,
    required this.body,
    this.showBackButton = false,
    this.onBackPressed,
  });

  final Widget body;
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              AppAssetPaths.mainEntryBackground,
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Positioned.fill(child: body),
          if (showBackButton) AppBackButtonOverlay(onPressed: onBackPressed),
        ],
      ),
    );
  }
}
