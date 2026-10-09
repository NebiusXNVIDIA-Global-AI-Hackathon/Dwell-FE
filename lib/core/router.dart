import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/assistant/assistant_page.dart';
import '../features/home/home_page.dart';
import '../features/my_page/my_page.dart';
import '../features/my_place/my_place_page.dart';
import '../features/cases/pages/cases_page.dart';
import '../features/splash/splash_page.dart';
import '../features/cases/pages/case_creation_page.dart';
import 'layouts/main_layout.dart';

// 화면 추가 시 여기 GoRoute 도 추가
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    // 하단바 확인을 위해 홈에서 시작
    initialLocation: '/home',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/home'),

      // 하단바 없이 표시할 페이지
      GoRoute(path: '/splash', builder: (context, state) => const SplashPage()),
      // 케이스 등록 페이지
      GoRoute(
        path: '/cases/new',
        name: 'case-creation',
        builder: (context, state) => const CaseCreationPage(),
      ),

      // 공통 레이아웃과 하단바를 사용하는 페이지
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my-place',
                builder: (context, state) => const MyPlacePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cases',
                name: 'cases',
                builder: (context, state) => const CasesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/assistant',
                builder: (context, state) => const AssistantPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my-page',
                builder: (context, state) => const MyPage(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text('페이지를 찾을 수 없음\n${state.uri}', textAlign: TextAlign.center),
      ),
    ),
  );

  ref.onDispose(router.dispose);

  return router;
});
