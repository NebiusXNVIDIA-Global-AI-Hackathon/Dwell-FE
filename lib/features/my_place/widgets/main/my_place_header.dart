import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/app_colors.dart';
import '../../../../core/theme.dart';
import '../../../../core/widgets/profile_menu.dart';

/// 네이비 헤더 — 아래가 타원으로 깎이고 카드가 경계에 걸친다
class MyPlaceHeader extends StatelessWidget {
  const MyPlaceHeader({
    super.key,
    required this.address,
    required this.nickname,
    required this.card,
  });

  final String address;
  final String nickname;

  /// Rising Issue 카드 또는 All clear 카드
  final Widget card;

  /// 카드가 곡선 아래로 내려오는 깊이
  static const _overhang = 52.0;

  /// 웹은 상태바가 없어 설계 여백만 잡는다
  static const _webTopGap = 50.0;

  @override
  Widget build(BuildContext context) {
    final topInset = kIsWeb ? _webTopGap : MediaQuery.paddingOf(context).top;

    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: _overhang,
          child: ClipPath(
            clipper: const _CurvedHeaderClipper(),
            child: const ColoredBox(color: AppColors.navy),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(top: topInset + 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  left: Gap.lg,
                  right: Gap.screenH,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Gap.md,
                  children: [
                    const Expanded(
                      child: Text(
                        'My Place',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.bg,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ),
                    ProfileMenu(nickname: nickname),
                  ],
                ),
              ),
              const SizedBox(height: Gap.card),
              // 와프는 두 줄로 끊어 쓴다 — 폭을 묶어 같은 자리에서 접히게 한다
              Padding(
                padding: const EdgeInsets.only(left: Gap.lg, right: Gap.lg),
                child: SizedBox(
                  width: 232,
                  child: Text(
                    address,
                    style: const TextStyle(
                      color: AppColors.headerAddress,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: _overhang),
              card,
            ],
          ),
        ),
      ],
    );
  }
}

/// 아래로 볼록한 곡선 — 가장자리보다 가운데가 72 더 내려온다
class _CurvedHeaderClipper extends CustomClipper<Path> {
  const _CurvedHeaderClipper();

  static const _bulge = 72.0;

  @override
  Path getClip(Size size) => Path()
    ..lineTo(0, size.height - _bulge)
    ..quadraticBezierTo(
      size.width / 2,
      size.height + _bulge,
      size.width,
      size.height - _bulge,
    )
    ..lineTo(size.width, 0)
    ..close();

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
