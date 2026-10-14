import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../widgets/bottom_nav_bar.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      extendBody: navigationShell.currentIndex == 2,
      body: navigationShell,
      bottomNavigationBar: BottomNavBar(
        currentIndex: navigationShell.currentIndex,
        casesLabel: navigationShell.currentIndex == 2 ? 'Cases' : 'Reports',
        onTap: (index) {
          navigationShell.goBranch(index);
        },
      ),
    );
    if (navigationShell.currentIndex != 2) return scaffold;
    // Scope system-bar styling to Home, including the fixed bottom navigation.
    // Edge-to-edge Android paints the background from the widgets underneath.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFF8F8F8),
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarContrastEnforced: false,
      ),
      child: scaffold,
    );
  }
}
