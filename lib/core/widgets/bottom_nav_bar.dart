import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_ui/material_ui.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80 + MediaQuery.paddingOf(context).bottom,
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Colors.white,
        elevation: 0,
        selectedItemColor: const Color(0xFF243B53),
        unselectedItemColor: const Color(0xFFA8A8A8),
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        showUnselectedLabels: true,
        items: [
          _buildItem(label: 'My place', assetName: 'my_place'),
          _buildItem(label: 'Cases', assetName: 'cases'),
          _buildItem(label: 'Home', assetName: 'home'),
          _buildItem(label: 'Assistant', assetName: 'assistant'),
          _buildItem(label: 'My Page', assetName: 'my_page'),
        ],
      ),
    );
  }

  // 각 탭의 기본·선택 아이콘 연결
  BottomNavigationBarItem _buildItem({
    required String label,
    required String assetName,
  }) {
    return BottomNavigationBarItem(
      icon: SvgPicture.asset(
        'assets/icons/bottom_nav/${assetName}_unselected.svg',
        width: 28,
        height: 28,
      ),
      activeIcon: SvgPicture.asset(
        'assets/icons/bottom_nav/${assetName}_selected.svg',
        width: 28,
        height: 28,
      ),
      label: label,
    );
  }
}
