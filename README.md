# 🏠 Dwell-Frontend

Nebius × NVIDIA Global AI Hackathon을 위한 Dwell Frontend 프로젝트입니다.
이 문서는 Flutter 개발 환경, 프로젝트 구조 및 협업 규칙을 정리합니다.

---

# 🛠 Tech Stack

| Category | Stack |
| --- | --- |
| Framework | Flutter |
| Language | Dart |
| Target Platform | Android, Web |
| UI | Material UI (`material_ui`) |
| Routing | go_router |
| State Management | flutter_riverpod |
| Server State | fquery, fquery_core |
| Hooks | flutter_hooks |
| HTTP Client | Dio |
| Local Storage | shared_preferences |
| Secure Storage | flutter_secure_storage |
| Font | Pretendard Variable |
| Font Package | google_fonts |
| SVG | flutter_svg |
| Image Cache | cached_network_image |
| Date / Number Formatting | intl |
| Code Quality | flutter_lints, Dart Formatter |
| Testing | flutter_test |

> 패키지 목록은 `pubspec.yaml`을 기준으로 합니다. 설치된 패키지와 기능 연동 완료 여부는 별개입니다.

---

# ⚙️ Project Setup

## 개발 환경

- 팀 기준 환경: **Flutter 3.47.6 / Dart 3.13.5**
- Dart SDK 범위: `>=3.13.5 <4.0.0` (`pubspec.yaml` 기준)
- 개발 대상: **Android, Web**
- 권장 에디터: VS Code + Flutter / Dart 확장

팀원 간 SDK 차이로 인한 충돌을 줄이기 위해 동일한 Flutter 버전을 사용합니다.
의존성의 실제 설치 버전은 저장소에 포함된 `pubspec.lock`을 기준으로 맞춥니다.

## 공통 설정

- `ProviderScope`를 통한 Riverpod 설정
- `CacheProvider`와 `QueryCache`를 통한 fquery 캐시 설정
- `MaterialApp.router`와 go_router를 통한 라우팅
- `MainLayout`을 통한 공통 화면 레이아웃
- `BottomNavBar`를 통한 하단 네비게이션
- Pretendard Variable 전역 폰트
- 시스템 설정을 따르는 라이트 / 다크 테마
- `Gap` 상수를 통한 공통 간격 관리
- 공통 로딩 / 에러 / 빈 화면 위젯
- GitHub Issue / Pull Request 템플릿

현재 각 페이지는 기본 화면 틀로 구성되어 있으며, 상세 UI와 API 연동은 이후 개발합니다.

---

# 📁 Folder Structure

```text
FE/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   └── PULL_REQUEST_TEMPLATE.md
├── assets/
│   ├── fonts/
│   │   └── PretendardVariable.ttf
│   ├── icons/
│   │   └── bottom_nav/
│   └── images/
├── lib/
│   ├── core/
│   │   ├── layouts/
│   │   │   └── main_layout.dart
│   │   ├── widgets/
│   │   │   └── bottom_nav_bar.dart
│   │   ├── router.dart
│   │   └── theme.dart
│   ├── features/
│   │   ├── assistant/
│   │   │   └── assistant_page.dart
│   │   ├── home/
│   │   │   └── home_page.dart
│   │   ├── my_page/
│   │   │   └── my_page.dart
│   │   ├── my_place/
│   │   │   └── my_place_page.dart
│   │   ├── cases/
│   │   │   └── pages/cases_page.dart
│   │   └── splash/
│   │       └── splash_page.dart
│   ├── shared/
│   │   └── widgets/
│   │       └── state_views.dart
│   ├── app.dart
│   └── main.dart
├── android/
├── ios/
├── web/
├── test/
├── analysis_options.yaml
├── pubspec.yaml
└── pubspec.lock
```

| Path | 역할 |
| --- | --- |
| `lib/main.dart` | 앱 실행 및 전역 Provider 초기화 |
| `lib/app.dart` | 앱 이름, 라우터, 테마 설정 |
| `lib/core/` | 라우터, 테마, 공통 레이아웃 등 앱 기반 설정 |
| `lib/features/` | 기능별 페이지 및 해당 기능에 필요한 코드 |
| `lib/shared/widgets/` | 여러 기능에서 재사용하는 공통 UI |
| `assets/` | 이미지, SVG 아이콘, 폰트 |
| `test/` | 테스트 코드 |
| `pubspec.yaml` | 패키지, SDK 범위, 에셋 및 폰트 등록 |
| `pubspec.lock` | 실제 설치된 의존성 버전 |

`ios/`는 생성된 플랫폼 폴더이며, 현재 개발 대상은 Android와 Web입니다.
기능 내부 폴더는 필요한 시점에 추가합니다. 특정 페이지에서만 사용하는 위젯은 해당 기능 폴더에 둡니다.

---

# 🗺 Routing

라우팅은 `lib/core/router.dart`에서 관리합니다.

| Page | Route | 하단 네비게이션 |
| --- | --- | --- |
| Splash | `/splash` | 미표시 |
| My place | `/my-place` | 표시 |
| Cases | `/cases` | 표시 |
| Home | `/home` | 표시 |
| Assistant | `/assistant` | 표시 |
| My Page | `/my-page` | 표시 |

- 현재 시작 경로는 `/home`입니다.
- `/`에 접근하면 `/home`으로 이동합니다.
- 메인 탭은 `StatefulShellRoute.indexedStack` 하위에 구성합니다.
- 공통 화면 틀은 `MainLayout`, 하단바 UI는 `BottomNavBar`에서 관리합니다.
- 탭 순서는 **My place → Cases → Home → Assistant → My Page**입니다.
- 하단바 없는 화면은 공통 탭 라우트 밖에 추가합니다.

---

# 🌿 Branch Convention

작업 종류에 따라 `feat`, `ui`, `api` 브랜치를 사용합니다.

| Branch | 역할 |
| --- | --- |
| `main` | 배포 가능한 코드를 관리하는 브랜치 |
| `develop` | 다음 버전을 위한 개발 통합 브랜치 |
| `feat/#이슈번호/명칭` | 새로운 기능 및 사용자 흐름 구현 |
| `ui/#이슈번호/명칭` | 화면 UI 구현 및 스타일링 작업 |
| `api/#이슈번호/명칭` | 데이터 통신, API 연동 및 비즈니스 로직 작업 |

## 예시

```text
feat/#10/login
feat/#11/case-registration
ui/#12/login-form
ui/#13/home-page
ui/#14/bottom-navigation
api/#45/fetch-user-profile
api/#46/case-api
```

## 작성 규칙

- 작업 브랜치는 최신 `develop`에서 생성합니다.
- 새로운 기능이나 UI와 API를 함께 포함하는 기능 단위 작업은 `feat`를 사용합니다.
- 화면 UI 작업은 `ui`, API 연동 및 데이터 처리 작업은 `api`를 사용합니다.
- 기존 형식에 따라 이슈 번호 앞에 `#`을 포함합니다.
- 작업 명칭은 영문 소문자와 하이픈 `-`을 사용합니다.
- 하나의 브랜치는 하나의 이슈를 기준으로 관리합니다.
- `main`, `develop`으로의 병합은 Pull Request를 통해 진행합니다.

---

# 📝 Commit Convention

커밋 메시지는 아래 형식으로 작성합니다.

```text
이모지 Type: 작업 내용
```

| 이모지 | Type | 설명 |
| --- | --- | --- |
| 🎉 | `Start` | 프로젝트 생성 및 초기 설정 |
| ✨ | `Feat` | 새로운 기능 추가 |
| 🐛 | `Fix` | 버그 수정 |
| 🎨 | `Design` | 화면 UI 및 디자인 변경 |
| ♻️ | `Refactor` | 코드 리팩토링 |
| 🔧 | `Settings` | 개발 환경 및 설정 파일 변경 |
| 🗃️ | `Comment` | 주석 추가 및 변경 |
| ➕ | `Dependency/Plugin` | 패키지 및 플러그인 추가 |
| 📝 | `Docs` | 문서 추가 및 수정 |
| 🔀 | `Merge` | 브랜치 병합 |
| 🚀 | `Deploy` | 배포 관련 작업 |
| 🚚 | `Rename` | 파일 및 폴더 이름 변경 또는 이동 |
| 🔥 | `Remove` | 파일 및 코드 삭제 |
| ⏪️ | `Revert` | 이전 버전으로 복구 |

## 예시

| 한국어 | English |
| --- | --- |
| `🎉 Start: Flutter 프로젝트 초기 설정` | `🎉 Start: Initialize Flutter project` |
| `✨ Feat: 하단 네비게이션 및 탭 라우팅 구현` | `✨ Feat: Implement bottom navigation and tab routing` |
| `🐛 Fix: 하단 네비게이션 선택 상태 오류 수정` | `🐛 Fix: Correct bottom navigation selection state` |
| `🎨 Design: 홈 화면 레이아웃 구현` | `🎨 Design: Build home page layout` |
| `♻️ Refactor: 공통 레이아웃 위젯 분리` | `♻️ Refactor: Extract shared layout widget` |
| `🔧 Settings: Pretendard 전역 폰트 설정` | `🔧 Settings: Configure global Pretendard font` |
| `➕ Dependency/Plugin: flutter_svg 추가` | `➕ Dependency/Plugin: Add flutter_svg` |
| `📝 Docs: README 개발 및 협업 규칙 작성` | `📝 Docs: Document development and collaboration guidelines` |

## 작성 규칙

- `Type`은 표에 정의된 영문 표기와 대소문자를 사용합니다.
- 작업 내용은 한국어 또는 영어로 작성합니다.
- 제목 끝에 마침표를 붙이지 않습니다.
- 한 커밋에는 하나의 논리적 변경을 포함합니다.
- `수정`, `작업`, `변경`만 적지 않고 변경 대상을 명시합니다.
- 기능 구현과 디자인 변경은 가능하면 분리합니다.

---

# 🔀 Workflow

1. 작업할 Issue를 생성합니다.
2. `develop` 브랜치를 최신화합니다.
3. 작업 종류에 맞는 브랜치를 생성합니다.
4. 작업 후 코드 검사와 실행 확인을 진행합니다.
5. Commit Convention에 맞게 커밋하고 Push합니다.
6. `develop`을 대상으로 Pull Request를 생성합니다.
7. 팀원에게 리뷰를 요청합니다.
8. 리뷰한 팀원이 `develop`으로 병합합니다.
9. 병합 후 작업자가 작업 브랜치를 삭제합니다.

## Pull Request 작성

저장소의 PR 템플릿을 사용합니다.

- **Related Issue**: `close #이슈번호` 형식으로 연결합니다.
- **Work Description**: 구현 내용과 변경 사항을 작성합니다.
- **Notices**: 의존성 추가, 공통 파일 변경, 확인 사항 등을 작성합니다.
- **ScreenShot**: 화면 변경이 있다면 스크린샷을 첨부합니다.

공통 라우터, 테마, 레이아웃 또는 `pubspec.yaml`을 수정할 때는 PR에 변경 내용을 명시합니다.
충돌이 발생하면 PR 작성자가 해결하고, 변경 사항을 다시 확인합니다.

---

# 🎨 Widget & UI Convention

프로젝트는 **Flutter Widget + Material UI**를 사용합니다.

## 기본 규칙

- 파일 및 폴더 이름은 `snake_case`를 사용합니다.
- 클래스 및 위젯 이름은 `UpperCamelCase`를 사용합니다.
- 변수 및 함수 이름은 `lowerCamelCase`를 사용합니다.
- 변경되지 않는 위젯과 값에는 가능한 경우 `const`를 사용합니다.
- 반복되는 UI는 위젯으로 분리합니다.
- 페이지는 `lib/features/`, 공통 레이아웃은 `lib/core/layouts/`에서 관리합니다.
- 재사용하는 로딩 / 에러 / 빈 화면은 공통 상태 위젯을 사용합니다.
- 네트워크 요청과 복잡한 비즈니스 로직을 `build()` 안에 직접 작성하지 않습니다.

## 테마 및 간격

공통 스타일은 `lib/core/theme.dart`에서 관리합니다.

| 항목 | 현재 설정 |
| --- | --- |
| 전역 폰트 | `Pretendard Variable` |
| 테마 기준색 | `#243B53` |
| 라이트 모드 페이지 배경 | `#F8F8F8` |
| 테마 모드 | 시스템 설정 사용 |

간격은 가능한 경우 `Gap` 상수를 사용합니다.

| Token | Value |
| --- | --- |
| `Gap.xs` | `4.0` |
| `Gap.sm` | `8.0` |
| `Gap.md` | `16.0` |
| `Gap.lg` | `24.0` |
| `Gap.xl` | `40.0` |

글자 스타일은 `Theme.of(context).textTheme`, 공통 색상은 `Theme.of(context).colorScheme`을 우선 사용합니다.
Android와 Web에서 화면 크기 변화, 스크롤, 입력창 및 하단바 동작을 확인합니다.

## Assets

- 이미지: `assets/images/`
- 아이콘: `assets/icons/`
- 하단바 SVG: `assets/icons/bottom_nav/`
- 폰트: `assets/fonts/`
- 새로운 에셋 하위 폴더를 추가하면 `pubspec.yaml`의 `flutter.assets`에도 등록합니다.
- 폰트는 `flutter.fonts`에 등록합니다.
- 하단바 아이콘은 `{탭명}_selected.svg`, `{탭명}_unselected.svg` 형식을 사용합니다.

---

# 🔗 API & State Convention

| 구분 | 사용 도구 |
| --- | --- |
| HTTP 요청 | Dio |
| 서버 데이터 및 캐시 | fquery, fquery_core |
| 클라이언트 전역 상태 | Riverpod |
| 위젯 내부 상태 및 생명주기 보조 | flutter_hooks |
| 일반 로컬 설정 저장 | shared_preferences |
| 인증 정보 저장 | flutter_secure_storage |

현재 API 관련 패키지와 fquery 캐시 초기화가 준비되어 있으며, 실제 백엔드 연동은 이후 구현합니다.

## API 연동 시 적용할 규칙

- 공통 Dio 클라이언트에서 Base URL과 공통 요청 설정을 관리합니다.
- 페이지 UI와 API 요청 코드를 분리합니다.
- 로딩, 성공, 에러 및 빈 데이터 상태를 구분합니다.
- 서버에서 받아온 데이터는 fquery의 캐시와 조회 흐름을 통해 관리합니다.
- 화면 간 공유하는 클라이언트 상태는 Riverpod으로 관리합니다.
- 인증 정보와 일반 설정 값을 구분해 저장합니다.
- 환경별 API 주소와 설정 주입 방식은 백엔드 연동 시 정합니다.

---

# 💻 Getting Started

## Repository Clone

```bash
git clone https://github.com/NebiusXNVIDIA-Global-AI-Hackathon/FE.git
cd FE
git switch develop
```

## 개발 환경 확인

```bash
flutter --version
flutter doctor
```

Android 실행 시 Android SDK와 에뮬레이터 또는 연결된 기기가 필요합니다.
Web 실행 시 Chrome을 준비합니다.

## Package Install

```bash
flutter pub get
```

## Web 실행

```bash
flutter run -d chrome
```

## Android 실행

실행 가능한 기기 목록을 확인한 후 사용할 기기를 선택합니다.

```bash
flutter devices
flutter run -d <device-id>
```

`<device-id>`는 `flutter devices`에서 확인한 실제 기기 ID로 바꿉니다.

---

# 🧹 Code Check

Pull Request를 생성하기 전에 변경한 코드를 검사하고 실행 결과를 확인합니다.

## Format 검사

```bash
dart format --output=none --set-exit-if-changed lib test
```

필요한 경우 자동 포맷을 적용합니다.

```bash
dart format lib test
```

## 정적 분석

```bash
flutter analyze
```

## 테스트

```bash
flutter test
```

## Web Build

```bash
flutter build web
```

Android 설정이나 Android 전용 기능을 변경한 경우 Android 빌드도 확인합니다.

```bash
flutter build apk --debug
```

`pubspec.yaml`을 변경한 경우 `flutter pub get`을 실행하고, 변경된 `pubspec.lock`도 함께 커밋합니다.

---

# 🤝 Collaboration Notes

- 개발 시작 전에 최신 `develop`과 팀 SDK 버전을 확인합니다.
- 패키지 버전 변경은 필요한 작업 범위에서 진행하고 팀원에게 공유합니다.
- 작업에 필요한 플랫폼 설정만 수정합니다.
- 공통 파일 변경은 팀원과 공유하여 충돌을 줄입니다.
- 자동 생성된 빌드 파일과 로컬 환경 파일은 커밋하지 않습니다.
- Issue와 PR은 저장소에 등록된 템플릿을 사용합니다.
- UI 변경은 실행 화면을 확인하고 PR에 스크린샷을 첨부합니다.
