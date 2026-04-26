# Backend Business Domains

현재 프론트 UI를 기준으로 백엔드에서 분리해야 할 비즈니스 도메인을 정리한 문서다.
이 문서는 "화면 기준 기능 목록"이 아니라, 실제 서버 구현을 위한 bounded context, 핵심 엔티티, 주요 유스케이스, 도메인 간 의존 관계를 정의하는 데 목적이 있다.

## 1. 프론트 기준 핵심 사용자 흐름

현재 UI에서 확인되는 사용자 흐름은 아래 5개 축으로 요약된다.

1. 인증과 계정 관리
2. 음성 업로드, 폴더 관리, 학습 상태 확인
3. 학습 완료 음성으로 듣기와 재생
4. 가족/지인과 공유 방 생성 및 참여
5. 마켓 판매, 구매, 광고 제거 결제

즉 백엔드는 최소한 아래 도메인들을 가져야 한다.

1. `Identity`
2. `Account`
3. `Voice Library`
4. `Voice Training Pipeline`
5. `Voice Inference`
6. `Room Collaboration`
7. `Marketplace`
8. `Billing / Entitlement`
9. `Support / Notification`

## 2. 권장 Bounded Context

### 2.1 `Identity`

역할:
- 회원가입, 로그인, 소셜 로그인, 토큰 발급/재발급/로그아웃 처리
- 디바이스 정보와 세션 관리
- 이메일 인증과 인증 코드 검증

Aggregate:
- `IdentityAccount`
- `AuthSession`
- `EmailVerification`
- `SocialIdentityLink`

핵심 엔티티:
- `IdentityAccount`
  - `accountId`
  - `email`
  - `passwordHash`
  - `status`
  - `hasPassword`
  - `createdAt`
- `AuthSession`
  - `sessionId`
  - `accountId`
  - `refreshTokenId`
  - `deviceInfo`
  - `issuedAt`
  - `expiresAt`
  - `revokedAt`
- `EmailVerification`
  - `email`
  - `code`
  - `purpose`
  - `verifiedAt`
  - `expiresAt`
- `SocialIdentityLink`
  - `accountId`
  - `provider`
  - `providerUserId`
  - `providerEmail`
  - `linkedAt`

주요 유스케이스:
- 이메일 회원가입
- 이메일 로그인
- 구글 로그인 토큰 교환
- 카카오 로그인 토큰 교환
- 액세스 토큰 재발급
- 로그아웃
- 이메일 인증번호 발송
- 이메일 인증번호 검증

프론트와 바로 연결되는 API:
- `POST /auth/signup`
- `POST /auth/login`
- `POST /auth/google`
- `POST /auth/kakao`
- `POST /auth/refresh`
- `POST /auth/logout`
- `POST /auth/email/send-verification`
- `POST /auth/email/verify`

### 2.2 `Account`

역할:
- 로그인 이후 사용자의 프로필과 계정 설정 관리
- 닉네임 수정, 비밀번호 변경, 소셜 계정 연결 조회, 회원 탈퇴 처리

Aggregate:
- `UserProfile`
- `AccountSecurityPolicy`

핵심 엔티티:
- `UserProfile`
  - `accountId`
  - `nickname`
  - `statusMessage`
  - `profileImageUrl`
  - `createdAt`
  - `updatedAt`
- `AccountSecurityPolicy`
  - `accountId`
  - `hasPassword`
  - `lastPasswordChangedAt`
  - `withdrawnAt`

주요 유스케이스:
- 내 정보 조회
- 프로필 수정
- 비밀번호 변경
- 연결된 소셜 계정 조회
- 회원 탈퇴

프론트와 바로 연결되는 API:
- `GET /me`
- `PATCH /me/profile`
- `PATCH /me/password`
- `GET /me/social-accounts`
- `DELETE /me`

### 2.3 `Voice Library`

역할:
- 사용자가 소유한 음성 자산 관리
- 음성 폴더 관리
- 음성 출처 구분(내 업로드, 공유방 획득, 마켓 구매)
- 목록, 검색, 이동, 삭제

Aggregate:
- `VoiceAsset`
- `VoiceFolder`
- `VoiceOwnership`

핵심 엔티티:
- `VoiceAsset`
  - `voiceId`
  - `ownerAccountId`
  - `title`
  - `originType`
  - `visibility`
  - `status`
  - `folderId`
  - `sampleAudioUrl`
  - `createdAt`
- `VoiceFolder`
  - `folderId`
  - `ownerAccountId`
  - `name`
  - `isSystemFolder`
  - `createdAt`
- `VoiceOwnership`
  - `voiceId`
  - `accountId`
  - `acquiredBy`
  - `acquiredAt`

값 객체:
- `VoiceOriginType`: `UPLOADED`, `ROOM_SHARED`, `MARKET_PURCHASED`
- `VoiceVisibility`: `PRIVATE`, `ROOM_SHARED`, `MARKET_LISTED`

주요 유스케이스:
- 음성 폴더 생성/수정/삭제
- 내 음성 목록 조회
- 음성을 다른 폴더로 이동
- 음성 삭제
- 출처별 필터 조회

최소 API:
- `GET /voice-folders`
- `POST /voice-folders`
- `PATCH /voice-folders/{folderId}`
- `DELETE /voice-folders/{folderId}`
- `GET /voices`
- `PATCH /voices/{voiceId}/folder`
- `DELETE /voices/{voiceId}`

### 2.4 `Voice Training Pipeline`

역할:
- 원본 음성 업로드부터 학습 완료까지의 파이프라인 관리
- 업로드 상태, 학습 상태, 실패 사유, 모델 생성 결과 추적

Aggregate:
- `VoiceTrainingJob`
- `VoiceTrainingSource`
- `VoiceModelArtifact`

핵심 엔티티:
- `VoiceTrainingJob`
  - `jobId`
  - `accountId`
  - `sourceFileId`
  - `requestedFolderId`
  - `status`
  - `failureReason`
  - `requestedAt`
  - `startedAt`
  - `completedAt`
- `VoiceTrainingSource`
  - `fileId`
  - `storagePath`
  - `fileName`
  - `durationMs`
  - `contentType`
- `VoiceModelArtifact`
  - `modelId`
  - `jobId`
  - `voiceId`
  - `modelVersion`
  - `artifactPath`

상태 값:
- `UPLOADED`
- `VALIDATING`
- `TRAINING`
- `COMPLETED`
- `FAILED`

주요 유스케이스:
- 업로드 URL 발급
- 업로드 완료 통지
- 학습 작업 생성
- 학습 상태 조회
- 학습 완료 후 `VoiceAsset` 생성

최소 API:
- `POST /voice-training/uploads`
- `POST /voice-training/jobs`
- `GET /voice-training/jobs`
- `GET /voice-training/jobs/{jobId}`

도메인 이벤트:
- `VoiceUploadCompleted`
- `VoiceTrainingStarted`
- `VoiceTrainingFailed`
- `VoiceTrainingCompleted`
- `VoiceAssetCreated`

### 2.5 `Voice Inference`

역할:
- 학습 완료 음성으로 텍스트를 재생 가능한 음성으로 변환
- 미리듣기, TTS, 향후 STT/대화형 기능 확장

Aggregate:
- `SpeechSynthesisRequest`
- `GeneratedAudio`

핵심 엔티티:
- `SpeechSynthesisRequest`
  - `requestId`
  - `voiceId`
  - `requestedBy`
  - `text`
  - `purpose`
  - `status`
  - `createdAt`
- `GeneratedAudio`
  - `audioId`
  - `requestId`
  - `audioUrl`
  - `durationMs`
  - `expiresAt`

주요 유스케이스:
- 학습 완료 음성으로 듣기
- 마켓 미리듣기 생성
- 공유방 내 음성 사용

최소 API:
- `POST /voice-inference/speak`
- `GET /voice-inference/requests/{requestId}`

주의:
- 현재 프론트는 기기 TTS로 데모 중이지만, 실제 서비스에서는 반드시 서버의 `voiceId` 기반 추론 API가 필요하다.

### 2.6 `Room Collaboration`

역할:
- 가족/지인 중심의 초대형 공유 방
- 초대코드, 비밀번호 보호, 멤버십, 공유 음성 권한 제어

Aggregate:
- `VoiceRoom`
- `RoomMembership`
- `RoomVoiceShare`

핵심 엔티티:
- `VoiceRoom`
  - `roomId`
  - `ownerAccountId`
  - `name`
  - `inviteCode`
  - `passwordHash`
  - `joinPolicy`
  - `createdAt`
- `RoomMembership`
  - `roomId`
  - `accountId`
  - `role`
  - `joinedAt`
  - `status`
- `RoomVoiceShare`
  - `shareId`
  - `roomId`
  - `voiceId`
  - `sharedBy`
  - `sharedAt`
  - `accessScope`

주요 유스케이스:
- 방 생성
- 초대 코드로 방 입장
- 방 비밀번호 검증
- 방 멤버 목록 조회
- 방에 음성 공유
- 방에서 공유 해제
- 방 내 공유 음성 목록 조회

최소 API:
- `POST /rooms`
- `POST /rooms/join`
- `GET /rooms`
- `GET /rooms/{roomId}`
- `GET /rooms/{roomId}/members`
- `POST /rooms/{roomId}/shared-voices`
- `DELETE /rooms/{roomId}/shared-voices/{shareId}`

도메인 규칙:
- 방에 공유 가능한 음성은 `VoiceTrainingPipeline` 완료 상태여야 한다.
- 공유 해도 원본 소유권은 바뀌지 않는다.
- 방은 "접근 권한"만 제공하고 "소유권 이전"은 하지 않는다.

### 2.7 `Marketplace`

역할:
- 학습 완료 음성의 판매 등록, 탐색, 미리듣기, 구매 처리
- 구매 시 구매자 라이브러리로 음성 권한 부여

Aggregate:
- `VoiceListing`
- `VoicePurchase`
- `VoiceLicense`

핵심 엔티티:
- `VoiceListing`
  - `listingId`
  - `sellerAccountId`
  - `voiceId`
  - `title`
  - `price`
  - `previewScript`
  - `status`
  - `listedAt`
- `VoicePurchase`
  - `purchaseId`
  - `listingId`
  - `buyerAccountId`
  - `amount`
  - `paymentId`
  - `purchasedAt`
- `VoiceLicense`
  - `licenseId`
  - `voiceId`
  - `buyerAccountId`
  - `scope`
  - `issuedAt`

주요 유스케이스:
- 판매 등록
- 판매 목록 검색
- 최신순/인기순 정렬
- 미리듣기 재생
- 구매
- 내 판매 목록 조회

최소 API:
- `GET /market/listings`
- `POST /market/listings`
- `GET /market/listings/{listingId}`
- `POST /market/listings/{listingId}/preview`
- `POST /market/listings/{listingId}/purchase`
- `GET /market/my/listings`

도메인 규칙:
- 판매 등록 대상은 `ownerAccountId == sellerAccountId` 이고 `COMPLETED` 상태인 음성만 가능하다.
- 한 음성은 판매 가능하지만 구매 시에는 구매자 라이브러리에 별도 소유 권한이 생겨야 한다.
- 구매 수, 노출 수, 최근 등록일은 조회 모델에서 관리하는 것이 좋다.

### 2.8 `Billing / Entitlement`

역할:
- 광고 제거와 음성 구매 결제 처리
- 인앱결제 영수증 검증
- 사용자 entitlement 관리

Aggregate:
- `PaymentOrder`
- `PaymentTransaction`
- `Entitlement`

핵심 엔티티:
- `PaymentOrder`
  - `orderId`
  - `accountId`
  - `productType`
  - `productId`
  - `amount`
  - `status`
  - `createdAt`
- `PaymentTransaction`
  - `transactionId`
  - `orderId`
  - `provider`
  - `providerTransactionId`
  - `verifiedAt`
- `Entitlement`
  - `accountId`
  - `code`
  - `active`
  - `startedAt`
  - `expiredAt`

주요 유스케이스:
- 광고 제거 구매
- 마켓 음성 구매 결제
- 결제 검증
- 활성 entitlement 조회

최소 API:
- `POST /billing/orders`
- `POST /billing/transactions/confirm`
- `GET /billing/entitlements`

프론트 반영 포인트:
- 현재 `adsRemoved` 는 로컬 플래그지만 실제 서비스에서는 `Entitlement(code=ADS_FREE)` 로 치환해야 한다.

### 2.9 `Support / Notification`

역할:
- 고객센터, FAQ, 문의 접수
- 이메일/푸시/인앱 알림
- 비밀번호 재설정, 결제 완료, 학습 완료 알림

핵심 엔티티:
- `SupportTicket`
- `NotificationMessage`
- `NotificationPreference`

권장 유스케이스:
- 고객 문의 등록
- 자주 묻는 질문 조회
- 학습 완료 푸시
- 방 초대 알림
- 구매 완료 알림

## 3. 도메인 간 관계

핵심 관계는 아래와 같다.

1. `Identity` 는 로그인 가능한 주체를 만든다.
2. `Account` 는 로그인 주체의 프로필과 보안 설정을 관리한다.
3. `Voice Training Pipeline` 이 완료되면 `Voice Library` 의 `VoiceAsset` 이 생성된다.
4. `Room Collaboration` 은 `VoiceAsset` 의 접근 권한만 공유한다.
5. `Marketplace` 는 `VoiceAsset` 을 판매 가능한 `VoiceListing` 으로 노출한다.
6. `Billing / Entitlement` 가 결제를 확정하면 `Marketplace` 는 `VoiceLicense` 를 발급하고, `Voice Library` 는 구매 음성 소유권을 부여한다.
7. `Voice Inference` 는 `VoiceAsset` 또는 `VoiceListing` 기반 미리듣기에 사용된다.

## 4. 지금 프론트 기준으로 꼭 필요한 우선 구현 순서

현재 프론트에서 바로 살아 있어야 하는 우선순위는 아래 순서를 권장한다.

### Phase 1

1. `Identity`
2. `Account`
3. `Voice Library`
4. `Voice Training Pipeline`

이 단계가 되면:
- 회원가입/로그인
- 내 정보 관리
- 음성 업로드
- 폴더 관리
- 학습 상태 확인
- 완료 음성 조회

까지 실제 서비스로 연결된다.

### Phase 2

1. `Voice Inference`
2. `Room Collaboration`

이 단계가 되면:
- 완료 음성 듣기
- 방 생성/입장
- 방 내 음성 공유

가 가능해진다.

### Phase 3

1. `Marketplace`
2. `Billing / Entitlement`
3. `Support / Notification`

이 단계가 되면:
- 판매 등록
- 구매
- 광고 제거
- 고객센터/알림

까지 완성된다.

## 5. 백엔드 구현 시 추천 애그리거트 루트

너무 많은 엔티티를 한 번에 묶기보다 아래 루트를 기준으로 나누는 편이 안전하다.

- `IdentityAccount`
- `UserProfile`
- `VoiceTrainingJob`
- `VoiceAsset`
- `VoiceRoom`
- `VoiceListing`
- `PaymentOrder`

이렇게 나누면 "계정", "음성 생성", "음성 소유", "공유", "판매", "결제"가 서로 독립적으로 진화할 수 있다.

## 6. DB 테이블 초안

최소 테이블은 아래 정도가 필요하다.

- `identity_accounts`
- `auth_sessions`
- `email_verifications`
- `social_identity_links`
- `user_profiles`
- `voice_folders`
- `voice_assets`
- `voice_training_jobs`
- `voice_training_sources`
- `voice_model_artifacts`
- `voice_rooms`
- `room_memberships`
- `room_voice_shares`
- `voice_listings`
- `voice_purchases`
- `voice_licenses`
- `payment_orders`
- `payment_transactions`
- `entitlements`
- `support_tickets`
- `notifications`

## 7. 프론트 기능과 도메인 매핑

- 로그인, 회원가입, 소셜 로그인: `Identity`
- 마이페이지, 계정정보, 비밀번호 변경, 탈퇴: `Account`
- 음성 탭, 폴더 관리, 업로드, 목록, 이동, 삭제: `Voice Library`
- 업로드됨, 학습 중, 완료 상태: `Voice Training Pipeline`
- 듣기 화면, 미리듣기 재생: `Voice Inference`
- 함께 탭, 방 만들기, 입장하기, 공유 음성: `Room Collaboration`
- 마켓 둘러보기, 내 판매, 구매: `Marketplace`
- 광고 제거, 결제 검증: `Billing / Entitlement`
- 고객센터, 알림, 비밀번호 재설정: `Support / Notification`

## 8. 결론

현재 프론트 UI 기준으로 가장 중요한 백엔드 핵심 도메인은 다음 7개다.

1. `Identity`
2. `Account`
3. `Voice Library`
4. `Voice Training Pipeline`
5. `Voice Inference`
6. `Room Collaboration`
7. `Marketplace`

여기에 실제 서비스 운영을 위해 `Billing / Entitlement`, `Support / Notification` 을 붙이면 전체 제품 구조가 완성된다.

이미 프론트에는 인증/계정 API 계약의 방향이 보이기 때문에, 다음 단계는 `Voice`, `Room`, `Marketplace` 쪽 서버 계약을 동일한 수준으로 구체화하는 것이다.
