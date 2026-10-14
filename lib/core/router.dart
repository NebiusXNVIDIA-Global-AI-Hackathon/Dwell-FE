import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/assistant/assistant_page.dart';
import '../features/home/home_page.dart';
import '../features/my_page/my_page.dart';
import '../features/my_place/my_place_page.dart';
import '../features/assistant/pages/bring_in_case_page.dart';
import '../features/assistant/pages/chat_page.dart';
import '../features/cases/pages/cases_page.dart';
import '../features/splash/splash_page.dart';
import '../features/cases/pages/case_creation_page.dart';
import '../features/cases/pages/analyzing_evidence_page.dart';
import '../features/cases/models/evidence_analysis_input.dart';
import '../features/cases/models/case_creation_result.dart';
import '../features/cases/pages/case_created_page.dart';
import '../features/cases/controllers/mock_evidence_check_controller.dart'
    show mockEvidenceCheckPolicy;
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
        builder: (context, state) => CaseCreationPage(
          onComplete: (draft, evidence) async {
            await context.pushNamed<void>(
              'case-analysis',
              extra: EvidenceAnalysisInput(draft, evidence),
            );
          },
        ),
        // Nested route keeps the creation page (and its evidence owner) mounted.
        routes: [
          GoRoute(
            path: 'analyzing',
            name: 'case-analysis',
            redirect: (context, state) =>
                state.extra is EvidenceAnalysisInput &&
                    (state.extra! as EvidenceAnalysisInput).isAvailable
                ? null
                : '/cases/new',
            builder: (context, state) {
              final input = state.extra! as EvidenceAnalysisInput;
              var navigating = false;
              return AnalyzingEvidencePage(
                input: input,
                onMockCompleted: () {
                  if (navigating ||
                      !context.mounted ||
                      !mockEvidenceCheckPolicy.enabled) {
                    return;
                  }
                  navigating = true;
                  context.pushReplacementNamed(
                    'case-created',
                    extra: CaseCreationResult.demo(input),
                  );
                },
              );
            },
          ),
          GoRoute(
            path: 'created',
            name: 'case-created',
            redirect: (_, state) =>
                state.extra is CaseCreationResult &&
                    (state.extra! as CaseCreationResult).input.isAvailable &&
                    (!(state.extra! as CaseCreationResult).isDemo ||
                        mockEvidenceCheckPolicy.enabled)
                ? null
                : '/cases/new',
            builder: (_, state) =>
                CaseCreatedPage(result: state.extra! as CaseCreationResult),
          ),
        ],
      ),
      // Bring in a case — 하단바 없음
      GoRoute(
        path: '/assistant/bring-in-case',
        name: 'assistant-bring-in-case',
        builder: (context, state) => const BringInCasePage(),
      ),
      // 케이스 채팅 — intent 로 시작 시나리오 결정
      GoRoute(
        path: '/assistant/chat/:caseNo',
        name: 'assistant-chat',
        builder: (context, state) => ChatPage(
          caseNo: state.pathParameters['caseNo']!,
          intent: state.uri.queryParameters['intent'],
        ),
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
