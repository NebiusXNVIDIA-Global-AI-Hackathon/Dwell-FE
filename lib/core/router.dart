import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/assistant/assistant_page.dart';
import '../features/home/home_page.dart';
import '../features/my_page/my_page.dart';
import '../features/my_place/my_place_page.dart';
import '../features/my_place/pages/building_insights_page.dart';
import '../features/my_place/pages/building_signals_list_page.dart';
import '../features/my_place/pages/hpd_history_page.dart';
import '../features/my_place/pages/landlord_posts_page.dart';
import '../features/my_place/pages/owner_buildings_page.dart';
import '../features/my_place/pages/building_signals_page.dart';
import '../features/my_place/pages/community_search_page.dart';
import '../features/my_place/pages/neighbor_community_page.dart';
import '../features/my_place/pages/post_detail_page.dart';
import '../features/my_place/pages/post_editor_page.dart';
import '../features/my_place/pages/tag_posts_page.dart';
import '../features/my_place/pages/check_my_unit_page.dart';
import '../features/assistant/pages/bring_in_case_page.dart';
import '../features/assistant/pages/chat_page.dart';
import '../features/cases/pages/cases_page.dart';
import '../features/splash/splash_page.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/providers/session_provider.dart';
import '../features/auth/providers/sign_up_provider.dart';
import '../features/auth/pages/sign_up_page.dart';
import '../features/auth/pages/sign_up_address_page.dart';
import '../features/cases/pages/case_creation_page.dart';
import '../features/cases/pages/analyzing_evidence_page.dart';
import '../features/cases/models/evidence_analysis_input.dart';
import '../features/cases/models/case_creation_result.dart';
import '../features/cases/models/reports_creation_notice.dart';
import '../features/cases/pages/case_created_page.dart';
import '../features/cases/controllers/mock_evidence_check_controller.dart'
    show mockEvidenceCheckPolicy;
import 'layouts/main_layout.dart';

// 화면 추가 시 여기 GoRoute 도 추가
// Optional future startup/auth check, in addition to the minimum Splash duration.
final splashCompletionProvider = Provider<Future<void>?>((ref) => null);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(ref.read(sessionProvider));
  ref.listen(sessionProvider, (_, next) => refresh.value = next);
  final router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: refresh,
    redirect: (_, state) {
      final mode = ref.read(sessionProvider);
      final hasAccess =
          mode == SessionMode.demo || mode == SessionMode.authenticated;
      final path = state.uri.path;
      final isSignUp = path == '/sign-up' || path == '/sign-up/address';
      final isPublic =
          path == '/' || path == '/splash' || path == '/login' || isSignUp;
      if (!hasAccess && !isPublic) return '/login';
      // A previous browser entry for Login must not interrupt an active demo.
      if (hasAccess && (path == '/login' || isSignUp)) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/splash'),

      // 하단바 없이 표시할 페이지
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => SplashPage(
          ready: ref.read(splashCompletionProvider),
          onCompleted: () => context.go(
            ref.read(sessionProvider) == SessionMode.unauthenticated
                ? '/login'
                : '/home',
          ),
        ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => LoginPage(
          onSignUp: () => context.goNamed('sign-up'),
          onDemo: () async {
            ref.read(sessionProvider.notifier).enterDemo();
            // The refreshed route guard owns the single transition to Home.
          },
        ),
      ),
      GoRoute(
        path: '/sign-up',
        name: 'sign-up',
        builder: (_, _) => const SignUpPage(),
        routes: [
          GoRoute(
            path: 'address',
            name: 'sign-up-address',
            redirect: (_, _) =>
                ref.read(signUpProvider).canContinue ? null : '/sign-up',
            builder: (_, _) => const SignUpAddressPage(),
          ),
        ],
      ),
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
      // 커뮤니티 — 하단바 없음
      GoRoute(
        path: '/my-place/community',
        builder: (context, state) => const NeighborCommunityPage(),
      ),
      GoRoute(
        path: '/my-place/community/search',
        builder: (context, state) => const CommunitySearchPage(),
      ),
      GoRoute(
        path: '/my-place/community/new',
        builder: (context, state) => const PostEditorPage(),
      ),
      GoRoute(
        path: '/my-place/community/tags/:tag',
        builder: (context, state) =>
            TagPostsPage(tag: state.pathParameters['tag'] ?? ''),
      ),
      GoRoute(
        path: '/my-place/community/post/:postId',
        builder: (context, state) => PostDetailPage(
          postId: int.tryParse(state.pathParameters['postId'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/my-place/community/post/:postId/edit',
        builder: (context, state) => PostEditorPage(
          postId: int.tryParse(state.pathParameters['postId'] ?? '') ?? 0,
        ),
      ),
      // 시그널 목록 · 상세 · 내 집 확인 — 하단바 없음
      GoRoute(
        path: '/my-place/insights/hpd',
        builder: (context, state) => const HpdHistoryPage(),
      ),
      GoRoute(
        path: '/my-place/insights/owner-buildings',
        builder: (context, state) => const OwnerBuildingsPage(),
      ),
      GoRoute(
        path: '/my-place/insights/landlord-posts',
        builder: (context, state) => const LandlordPostsPage(),
      ),
      GoRoute(
        path: '/my-place/insights',
        builder: (context, state) => const BuildingInsightsPage(),
      ),
      GoRoute(
        path: '/my-place/signals',
        builder: (context, state) => const BuildingSignalsListPage(),
      ),
      GoRoute(
        path: '/my-place/signals/:signalId',
        builder: (context, state) => BuildingSignalsPage(
          signalId: int.tryParse(state.pathParameters['signalId'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '/my-place/check-unit/:signalId',
        builder: (context, state) => CheckMyUnitPage(
          signalId: int.tryParse(state.pathParameters['signalId'] ?? '') ?? 0,
        ),
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
                builder: (context, state) => CasesPage(
                  creationNotice: state.extra is ReportsCreationNotice
                      ? state.extra! as ReportsCreationNotice
                      : null,
                ),
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

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });

  return router;
});
