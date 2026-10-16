import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'profile_menu.dart';
import '../../features/auth/providers/session_provider.dart';
import '../../features/auth/providers/profile_provider.dart';

/// Home and Reports share geometry; system space is applied by the page once.
class AppScreenHeader extends ConsumerWidget {
  const AppScreenHeader({
    super.key,
    required this.title,
    this.webTopPadding = webTopGap,
    this.onLogout,
    this.nickname,
  });
  final Widget title;
  final double webTopPadding;
  final Future<void> Function()? onLogout;
  final String? nickname;
  // Web has no native status-bar area. Reserve its design space here;
  // native pages already apply their real system inset outside this header.
  static const webTopGap = 50.0;
  static const nativeTopGap = 22.0;
  static const topGap = kIsWeb ? webTopGap : nativeTopGap;
  static const horizontalPadding = 22.0;
  static const height = 48.0;

  static double systemTopInset(BuildContext context) =>
      kIsWeb ? 0 : MediaQuery.paddingOf(context).top;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 590),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          kIsWeb ? webTopPadding : nativeTopGap,
          horizontalPadding,
          0,
        ),
        child: SizedBox(
          height: height,
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: title,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ProfileMenu(
                nickname: ref.watch(sessionProvider) == SessionMode.demo
                    ? 'SJ'
                    : nickname ?? ref.watch(profileNicknameProvider) ?? 'SJ',
                size: 42,
                onLogout: onLogout,
                onDemoLogout: ref.watch(sessionProvider) == SessionMode.demo
                    ? () => ref.read(sessionProvider.notifier).endDemo()
                    : null,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
