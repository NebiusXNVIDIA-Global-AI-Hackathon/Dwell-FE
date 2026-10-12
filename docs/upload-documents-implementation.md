# Step 5 Upload Documents 구현 결과

제공된 빈 상태·파일 선택 상태 UI를 기준으로 `Upload Document` 화면을 구현했습니다. 시스템 상태 표시줄은 앱에서 그리지 않고 SafeArea로 처리합니다.

## 사용 흐름

`Add Evidence → + → Upload Documents → Choose files → Selected File 목록 → Upload → 기존 Evidence 목록`

- 점선 파일 선택 영역, 선택 파일 수, 파일명·형식·크기, 삭제 X, 하단 Upload 버튼을 적용했습니다.
- Android는 `Choose files`, Web은 `Choose files or drag and drop`을 표시합니다.
- Upload 전 파일은 업로드 화면이 소유합니다. 선택 취소는 기존 선택을 유지하고, Back·화면 종료는 임시 선택을 정리합니다.
- Upload는 파일을 기존 EvidenceController에 전달합니다. 서버 업로드 API를 호출하지 않습니다.
- 기존 Evidence 썸네일 72×72 크기, 둥근 모서리, 선택 테두리, 삭제 버튼을 재사용했습니다.
- PDF·Word는 아이콘과 파일 정보 미리보기, JPG·PNG는 작은 이미지 썸네일을 제공합니다. PDF·Word 전체 렌더러나 외부 앱 열기는 추가하지 않았습니다.
- Check 버튼은 비활성 상태를 유지합니다.

## 패키지

- `file_picker 13.1.0`: Android/Web 다중 시스템 파일 선택, 원본 표시 이름, 크기 조회, 스트림 읽기.
- `archive 4.0.9`: DOCX ZIP 디렉터리와 필수 XML 항목 검증.
- `crypto 3.0.7`: SHA-256 내용 해시로 같은 파일의 중복 첨부 차단. 기존 전이 의존성을 직접 선언했습니다.
- Flutter `dart:ui`와 기존 `web 1.1.1`, `path_provider 2.1.6`, Lucide 아이콘을 재사용했습니다.

파일 선택기 API와 지원 플랫폼은 [file_picker 공식 문서](https://pub.dev/packages/file_picker)를 확인했고, 설치된 Android/Web 구현 소스도 확인했습니다.

## 형식·용량 검증

기본 PDF·DOC·DOCX에 더해 제공된 디자인에 명시된 JPG/JPEG·PNG를 지원합니다.

| 형식 | 검사 |
| --- | --- |
| PDF | PDF 버전 헤더 및 파일 끝의 EOF 표식 |
| DOC | OLE/CFB 시그니처, FAT·디렉터리 구조, WordDocument 스트림 |
| DOCX | ZIP 필수 항목, Word 콘텐츠 타입·XML 네임스페이스·문서 요소, XML 길이·CRC |
| JPG/PNG | 확장자와 이미지 시그니처 일치, 실제 Flutter 이미지 디코딩 |

- 파일당 최대 `10 × 1024 × 1024 = 10,485,760`바이트이며 UI에는 10MB로 표시합니다.
- 가능한 경우 읽기 전에 크기를 거부하고, 크기가 불명확해도 스트림을 읽으며 상한을 검사합니다.
- 한 번 읽은 바이트로 검증·해시·저장을 수행합니다. DOCX는 필요한 XML만 출력 크기를 제한해 디코딩합니다.
- 빈 파일, 읽기 실패, 보고된 크기와 실제 크기 불일치, 미지원 형식, 명백한 확장자 불일치를 거부합니다.
- 일부 파일 실패는 정상 파일을 유지하며 SnackBar로 안내합니다. 안내가 Upload 버튼을 가리지 않도록 배치했습니다.
- 원본 표시 이름을 유지하면서 경로 성분·제어 문자·방향 제어 문자를 제거합니다. 실제 캐시 파일 경로에는 표시 이름을 직접 사용하지 않습니다.

## 플랫폼과 소유권

- Android: 파일 선택기는 Storage Access Framework를 사용합니다. 전체 저장소 권한을 추가하지 않았습니다. 선택기가 반환한 임시 복사본을 읽고, 검증된 파일은 앱의 독립된 `dwell-document-` 캐시에 저장합니다. 선택기 복사본은 확인된 앱 `file_picker` 캐시 경로 내부에서만 제거합니다.
- Web: 브라우저 파일 선택과 드롭 영역을 지원합니다. 기존 플랫폼 서비스로 독립된 Blob을 만들고 원본 선택 Blob을 해제합니다. Web 구현에는 dart:io 파일 접근을 추가하지 않았습니다.
- EvidenceModel에 document 타입, 표시 이름, 크기, 내용 해시, 이미지 썸네일과 정리 콜백을 추가했습니다. 삭제·취소·페이지 종료는 소유 파일/Blob과 미리보기 캐시를 정리합니다.
- 새 화면으로 이동한 뒤 늦게 도착하는 선택 결과는 첨부하지 않고 폐기합니다. 연속 터치는 화면과 서비스 양쪽에서 차단합니다.
- 영구 복원은 구현하지 않았습니다. 기존 녹음·영상 캐시 및 Web 재생 경로는 유지합니다.

## 추가·수정 파일

### 제품 코드

- `lib/features/cases/pages/evidence/evidence_documents_page.dart`
- `lib/features/cases/widgets/creation/evidence/evidence_document_preview.dart`
- `lib/features/cases/services/evidence_documents.dart`
- `lib/features/cases/services/evidence_document_format.dart`
- `lib/features/cases/services/evidence_document_drop.dart`
- `lib/features/cases/services/evidence_document_drop_native.dart`
- `lib/features/cases/services/evidence_document_drop_web.dart`
- `lib/features/cases/services/evidence_media_native.dart`
- `lib/features/cases/services/evidence_media_web.dart`
- `lib/features/cases/models/evidence_model.dart`
- `lib/features/cases/controllers/evidence_controller.dart`
- `lib/features/cases/pages/case_creation_page.dart`
- `lib/features/cases/widgets/creation/steps/evidence_step.dart`
- `pubspec.yaml`, `pubspec.lock`

### 테스트

- `test/evidence_documents_test.dart`
- `test/evidence_documents_flow_test.dart`
- `test/evidence_documents_visual_test.dart`
- `test/evidence_documents_browser_test.dart`
- `test/helpers/evidence_document_fixtures.dart`
- `test/helpers/evidence_documents_browser_checks.dart`
- `test/helpers/evidence_documents_browser_stub.dart`
- `test/helpers/case_creation_test_harness.dart`
- `test/evidence_step_test.dart`: 문서 메뉴에서 새 업로드 화면에 진입·취소하는 동작으로 기존 회귀 검증을 갱신했습니다.

## 검증

- 문서 서비스: 형식, 다중 선택, 10MB 경계값, 빈 파일·미지원·읽기 실패, 부분 성공, 중복, 취소, 캐시 삭제, 드롭 입력의 공통 검증.
- 화면 흐름: Upload 전 기존 Evidence 보존, 선택 파일 삭제, Upload 후 첨부·선택·삭제, 취소와 늦은 결과 정리.
- 레이아웃: 320×568 및 393×844에서 긴 이름과 글자 1.5배 확대, 기존 여러 화면 크기의 메뉴 회귀 검증.
- 빈 상태·선택 상태를 `build/document-previews/empty.png`, `build/document-previews/selected.png`로 렌더링해 확인했습니다.

| 명령 | 최종 결과 |
| --- | --- |
| `flutter analyze` | 통과, 오류·경고 없음 |
| `flutter test` | 320개 통과, Chrome 전용 2개는 VM 실행에서 제외 |
| `flutter build apk --debug` | 통과 |
| `flutter build web` | 통과, Wasm dry run도 성공 |

Chrome 전용 자동화는 테스트 로드 단계에서 진행되지 않아 중단했습니다. 따라서 실제 브라우저의 시스템 파일 선택·드롭 성공을 확인한 것으로 보고하지 않습니다. Android 실기기 시스템 선택기도 수동 검증하지 않았습니다.

실기기에서는 PDF·DOC·DOCX·JPG·PNG 다중 선택, 선택 취소, 클라우드 제공자 파일, 10MB 초과·권한 거부, 재선택 중복, Upload 후 선택·삭제를 확인해야 합니다. Chrome에서는 드롭 영역 위치·파일 드롭·화면 종료 후 Blob 정리를, Android에서는 시스템 Back과 임시 파일 정리를 추가 확인해야 합니다.

Git commit과 push는 진행하지 않았습니다.
