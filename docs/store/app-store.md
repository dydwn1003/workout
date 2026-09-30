# App Store (아이폰) 출시 준비

앱: **알아서핏** · 번들 ID `com.alasfit.app` · iPhone 전용, 세로 화면 · 1.0은 커뮤니티 없이
개인정보처리방침: https://dydwn1003.github.io/workout/privacy.html

맥이 없어도 GitHub Actions의 맥 서버(`.github/workflows/ios.yml`)가 빌드하고 App Store Connect에 올립니다.

## 1단계. App Store Connect에 앱 만들기

1. https://appstoreconnect.apple.com → **앱** → **＋** → **신규 앱**
   - 플랫폼: iOS
   - 이름: `알아서핏` (이미 쓰이는 이름이면 `알아서핏 - 칼로리 코치`처럼)
   - 기본 언어: 한국어
   - 번들 ID: 목록에 없으면 먼저 https://developer.apple.com/account/resources/identifiers 에서 **＋** → App IDs → App → 설명 `AlasFit`, Bundle ID(Explicit) `com.alasfit.app`, Capabilities에서 **Sign In with Apple** 체크 → 등록. 그다음 다시 신규 앱 화면에서 고릅니다.
   - SKU: `alasfit`
2. 만들어진 앱의 **앱 정보** 화면에 있는 **Apple ID**(숫자 10자리 정도)를 GitHub 저장소 Settings → Secrets and variables → Actions → **Variables**에 `IOS_APP_ID`로 넣습니다. 업데이트 안내와 별점 리뷰가 이 번호로 App Store를 엽니다.

## 2단계. 빌드용 키 4개 (GitHub Secrets)

1. App Store Connect → **사용자 및 액세스** → **통합** 탭 → **App Store Connect API** → 팀 키 **＋**
   - 이름: `GitHub Actions`, 액세스: **관리(Admin)**. 인증서와 프로비저닝 프로필을 자동으로 만들려면 관리 권한이 필요합니다.
   - 만든 뒤 **API 키 다운로드**. `AuthKey_XXXXXXXXXX.p8` 파일은 **한 번만** 받을 수 있으니 잘 보관합니다.
2. GitHub 저장소 Settings → Secrets and variables → Actions → **Secrets**에 넣습니다.
   - `ASC_KEY_ID`: 키 목록의 **키 ID** (10자리)
   - `ASC_ISSUER_ID`: 키 목록 위에 있는 **Issuer ID** (UUID 형태)
   - `ASC_KEY_P8`: .p8 파일을 메모장으로 열어 `-----BEGIN PRIVATE KEY-----`부터 `-----END PRIVATE KEY-----`까지 **전부**
   - `APPLE_TEAM_ID`: https://developer.apple.com/account → 멤버십 세부 사항의 **팀 ID** (10자리)

이 키들은 채팅이나 다른 곳에 붙여넣지 말고 GitHub Secrets에만 넣으세요.

## 3단계. 로그인 설정

- **Apple 로그인** (구글·카카오 로그인이 있으면 필수): Supabase → Authentication → Sign In / Providers → **Apple** 켜기 → **Client IDs**에 `com.alasfit.app` 입력 → 저장. 앱 안에서 바로 로그인하는 방식이라 Secret Key는 비워 둬도 됩니다.
- **Google 로그인**: Google Cloud Console → API 및 서비스 → 사용자 인증 정보 → **사용자 인증 정보 만들기 → OAuth 클라이언트 ID** → 유형 **iOS**, 번들 ID `com.alasfit.app` → 만들어진 **클라이언트 ID**(`…apps.googleusercontent.com`)를 GitHub **Variables**에 `GOOGLE_IOS_CLIENT_ID`로 넣습니다. 비밀값이 아니라서 Variables에 넣으면 됩니다. 없으면 아이폰 앱에서 구글 버튼이 숨겨집니다.
- **카카오 로그인**: https://developers.kakao.com → 내 애플리케이션 → 앱 설정 → 플랫폼 → **iOS 플랫폼 등록** → 번들 ID `com.alasfit.app`.

## 4단계. 빌드해서 TestFlight에 올리기

1. GitHub → Actions → **Build iOS for TestFlight** → Run workflow (약 15~25분)
2. 성공하면 10~30분 뒤 App Store Connect → 앱 → **TestFlight**에 빌드가 나타납니다.
3. TestFlight → 내부 테스트 그룹에 본인을 추가하면 아이폰의 **TestFlight 앱**으로 설치할 수 있습니다.
4. 빌드 번호는 커밋 수라서 새 커밋이 있어야 올라갑니다. 같은 커밋으로 다시 올리면 "이미 있는 빌드 번호"라고 거절됩니다.

## 5단계. 심사 제출 (앱 스토어 탭)

- **스크린샷**: 6.9인치(1320×2868) 또는 6.7인치(1290×2796) 아이폰 화면 3장 이상. iPhone 전용 앱이라 iPad 스크린샷은 필요 없습니다.
- **이름**: `알아서핏 - 칼로리 다이어트 코치` · **부제**: `매주 알아서 맞춰주는 목표 칼로리`
- **프로모션 텍스트**: 체중과 식사만 기록하세요. 실제로 쓰는 에너지를 계산해서 매주 목표 칼로리를 알아서 다시 맞춰 드려요. 로그인 없이 바로 시작할 수 있어요.
- **키워드** (이름·부제에 있는 단어는 빼도 검색됨): `식단,체중,감량,단백질,식단기록,체중관리,살빼기,벌크업,유지어터,헬스,운동기록,영양성분,탄단지,체지방,인바디,식사일기,린매스업,체중감량,칼로리계산,식단일지,건강`
- **설명**: google-play.md의 자세한 설명과 같습니다(1.0은 커뮤니티 문단 없이).
- **저작권**: `2026 이용주`
- **지원 URL**: https://dydwn1003.github.io/workout/ · **개인정보처리방침 URL**: 위 주소
- **카테고리**: 건강 및 피트니스 (보조: 음식 및 음료)
- **연령 등급**: 모든 항목 "없음" → 4+ (1.0은 커뮤니티가 없어서)
- **앱 개인정보 보호(영양 성분표)**
  - 수집함: 연락처 정보 › 이메일 주소(로그인 시), 건강 및 피트니스 › 피트니스·건강(체중, 체성분, 식단), 식별자 › 사용자 ID, 사용 데이터 › 제품 상호작용(앱 사용 통계)
  - 모두 "사용자에게 연결됨: 예", "추적: 아니요", 목적: 앱 기능(+ 사용 통계는 분석)
- **심사 정보(App Review) 메모** 예시:
  > 로그인 없이 바로 사용할 수 있습니다(첫 화면 "시작해볼까요?"). 로그인(Apple/Google/Kakao)은 기기 간 동기화용 선택 기능입니다. 계정 삭제: 로그인 후 설정 탭 맨 위 계정 영역 → 계정 삭제. 이 앱은 의학적 조언을 제공하지 않으며 첫 화면에 안내가 있습니다.
- **수출 규정**: Info.plist에 `ITSAppUsesNonExemptEncryption = false`가 들어 있어 따로 묻지 않습니다.

## 1.1(커뮤니티)을 올릴 때

- 빌드에 `COMMUNITY=true`를 더하고, 이용약관(EULA) 동의, 신고 처리(24시간 이내), 앱 안 연락처를 보강한 뒤 제출합니다(가이드라인 1.2).
- 연령 등급: "사용자 생성 콘텐츠/무제한 웹 접근" 질문에 맞게 다시 답합니다.
- 영양 성분표에 사진, 기타 사용자 콘텐츠(글·댓글)를 추가합니다.
