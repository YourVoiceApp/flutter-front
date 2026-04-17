# Frontend API Spec

프론트 연동용으로 바로 사용할 수 있게 현재 백엔드 API를 정리한 문서입니다.

## 기본 정보

- Base URL
  - 로컬 기본값: `http://localhost:9090`
- Swagger UI
  - `GET /swagger-ui.html`
- OpenAPI JSON
  - `GET /v3/api-docs`
- 인증 방식
  - `/auth/**` 를 제외한 모든 API는 `Authorization: Bearer {accessToken}` 필요
- 응답 시간 필드 형식
  - `LocalDateTime` 은 ISO 형식 문자열로 내려갑니다.
  - 예: `"2026-04-17T13:40:00"`

## 공통 응답 규칙

### 성공

- 조회/생성/수정: 주로 `200 OK`
- 삭제/일부 인증 처리: `204 No Content`

### 에러

공통 에러 응답 형식:

```json
{
  "code": "INVALID_REQUEST",
  "message": "Invalid request"
}
```

대표 에러 코드 예시:

- `INVALID_REQUEST`
- `INVALID_CREDENTIALS`
- `INVALID_REFRESH_TOKEN`
- `USER_NOT_FOUND`
- `PAYMENT_ORDER_NOT_FOUND`
- `ROOM_NOT_FOUND`
- `VOICE_FOLDER_NOT_FOUND`
- `VOICE_ASSET_NOT_FOUND`
- `GENERATED_AUDIO_NOT_FOUND`
- `ROOM_VOICE_SHARE_NOT_FOUND`

## 인증/Auth

인증 관련 API는 모두 공개 API입니다.

### 1. 이메일 인증 코드 발송

- `POST /auth/email/send-verification`
- Auth: 불필요

Request:

```json
{
  "email": "user@example.com"
}
```

Response:

- `204 No Content`

### 2. 이메일 인증 코드 확인

- `POST /auth/email/verify`
- Auth: 불필요

Request:

```json
{
  "email": "user@example.com",
  "code": "123456"
}
```

Response:

- `204 No Content`

### 3. 이메일 회원가입

- `POST /auth/signup`
- Auth: 불필요

Request:

```json
{
  "nickName": "dongho",
  "email": "user@example.com",
  "password": "password1234",
  "deviceInfo": "web-chrome"
}
```

Response:

```json
{
  "accessToken": "jwt-access-token",
  "refreshToken": "jwt-refresh-token",
  "userId": 1,
  "email": "user@example.com"
}
```

### 4. 이메일 로그인

- `POST /auth/login`
- Auth: 불필요

Request:

```json
{
  "email": "user@example.com",
  "password": "password1234",
  "deviceInfo": "web-chrome"
}
```

Response:

```json
{
  "accessToken": "jwt-access-token",
  "refreshToken": "jwt-refresh-token",
  "userId": 1,
  "email": "user@example.com"
}
```

### 5. 구글 로그인

- `POST /auth/google`
- Auth: 불필요

Request:

```json
{
  "idToken": "google-id-token",
  "deviceInfo": "web-chrome"
}
```

Response:

```json
{
  "accessToken": "jwt-access-token",
  "refreshToken": "jwt-refresh-token",
  "userId": 1,
  "email": "user@example.com"
}
```

### 6. 카카오 로그인

- `POST /auth/kakao`
- Auth: 불필요

Request:

```json
{
  "accessToken": "kakao-access-token",
  "deviceInfo": "web-chrome"
}
```

Response:

```json
{
  "accessToken": "jwt-access-token",
  "refreshToken": "jwt-refresh-token",
  "userId": 1,
  "email": "user@example.com"
}
```

### 7. 액세스 토큰 재발급

- `POST /auth/refresh`
- Auth: 불필요

Request:

```json
{
  "refreshToken": "jwt-refresh-token"
}
```

Response:

```json
{
  "accessToken": "new-jwt-access-token",
  "refreshToken": "jwt-refresh-token",
  "userId": 1,
  "email": "user@example.com"
}
```

### 8. 로그아웃

- `POST /auth/logout`
- Auth: 불필요

Request:

```json
{
  "refreshToken": "jwt-refresh-token"
}
```

Response:

- `204 No Content`

## 내 정보/Me

모든 API에 Bearer 토큰 필요

### 1. 내 정보 조회

- `GET /me`

Response:

```json
{
  "id": 1,
  "nickName": "dongho",
  "email": "user@example.com",
  "hasPassword": true,
  "adsFree": false
}
```

### 2. 프로필 수정

- `PATCH /me/profile`

Request:

```json
{
  "nickName": "new-name"
}
```

Response:

```json
{
  "id": 1,
  "nickName": "new-name",
  "email": "user@example.com",
  "hasPassword": true,
  "adsFree": false
}
```

### 3. 비밀번호 변경

- `PATCH /me/password`

Request:

```json
{
  "currentPassword": "old-password",
  "newPassword": "new-password-1234"
}
```

참고:

- 소셜 로그인 계정처럼 기존 비밀번호가 없으면 `currentPassword` 없이도 변경 가능할 수 있으나, 프론트에서는 사용자 계정 상태에 따라 분기하는 것이 안전합니다.

Response:

- `204 No Content`

### 4. 연결된 소셜 계정 조회

- `GET /me/social-accounts`

Response:

```json
[
  {
    "provider": "GOOGLE",
    "email": "user@example.com"
  }
]
```

### 5. 회원 탈퇴

- `DELETE /me`

Response:

- `204 No Content`

## 결제/Billing

모든 API에 Bearer 토큰 필요

광고 제거 상품은 현재 `ads_removal` 고정입니다.

### 1. 광고 제거 상태 조회

- `GET /billing/ads-removal/status`

Response:

```json
{
  "adsFree": false,
  "productId": "ads_removal",
  "purchasedAt": null
}
```

구매 완료 상태 예시:

```json
{
  "adsFree": true,
  "productId": "ads_removal",
  "purchasedAt": "2026-04-17T13:40:00"
}
```

### 2. 광고 제거 주문 생성

- `POST /billing/ads-removal/orders`

Request:

- body 없음

Response:

```json
{
  "orderId": 10,
  "productId": "ads_removal",
  "status": "CREATED",
  "adsFree": false,
  "confirmedAt": null
}
```

### 3. 광고 제거 결제 확인

- `POST /billing/ads-removal/confirm`

Request:

```json
{
  "orderId": 10,
  "purchaseToken": "google-play-purchase-token"
}
```

Response:

```json
{
  "orderId": 10,
  "productId": "ads_removal",
  "status": "PAID",
  "adsFree": true,
  "confirmedAt": "2026-04-17T13:45:00"
}
```

참고:

- 이미 광고 제거 상태면 주문 생성 API에서 에러가 납니다.
- 같은 `purchaseToken` 재사용 시 에러가 납니다.

## 음성 폴더/Voice Folders

모든 API에 Bearer 토큰 필요

### 1. 폴더 생성

- `POST /voice-folders`

Request:

```json
{
  "name": "내 폴더",
  "parentFolderId": null
}
```

하위 폴더 예시:

```json
{
  "name": "하위 폴더",
  "parentFolderId": 1
}
```

Response:

```json
{
  "id": 1,
  "parentFolderId": null,
  "name": "내 폴더",
  "voiceCount": 0,
  "createdAt": "2026-04-17T13:40:00",
  "updatedAt": "2026-04-17T13:40:00"
}
```

### 2. 폴더 내용 조회

- `GET /voice-folders/contents`
- Query
  - `parentId`: optional
  - 없으면 루트 폴더 기준 조회

예:

- `GET /voice-folders/contents`
- `GET /voice-folders/contents?parentId=1`

Response:

```json
{
  "totalVoiceCount": 3,
  "folders": [
    {
      "id": 1,
      "parentFolderId": null,
      "name": "내 폴더",
      "voiceCount": 2,
      "createdAt": "2026-04-17T13:40:00",
      "updatedAt": "2026-04-17T13:40:00"
    }
  ],
  "voices": [
    {
      "voiceKey": "voice_abc",
      "title": "나의 목소리",
      "folderId": 1,
      "acquiredBy": "CREATED",
      "acquiredAt": "2026-04-17T13:40:00"
    }
  ]
}
```

### 3. 폴더 수정

- `PUT /voice-folders/{folderId}`

Request:

```json
{
  "name": "이름 변경",
  "parentFolderId": null
}
```

Response:

```json
{
  "id": 1,
  "parentFolderId": null,
  "name": "이름 변경",
  "voiceCount": 2,
  "createdAt": "2026-04-17T13:40:00",
  "updatedAt": "2026-04-17T13:50:00"
}
```

### 4. 폴더 삭제

- `DELETE /voice-folders/{folderId}`

Response:

- `204 No Content`

## 음성/Voices

모든 API에 Bearer 토큰 필요

### 1. 내 음성 목록 조회

- `GET /voices`
- Query
  - `folderId`: optional

예:

- `GET /voices`
- `GET /voices?folderId=1`

Response:

```json
[
  {
    "voiceKey": "voice_abc",
    "title": "나의 목소리",
    "folderId": 1,
    "acquiredBy": "CREATED",
    "acquiredAt": "2026-04-17T13:40:00"
  }
]
```

### 2. 미분류 음성 목록 조회

- `GET /voices/unassigned`

Response:

```json
[
  {
    "voiceKey": "voice_xyz",
    "title": "미분류 음성",
    "folderId": null,
    "acquiredBy": "ROOM_SHARED",
    "acquiredAt": "2026-04-17T13:40:00"
  }
]
```

### 3. 음성 폴더 이동

- `PATCH /voices/folder`

Request:

```json
{
  "externalVoiceIds": ["voice_abc", "voice_xyz"],
  "folderId": 1
}
```

미분류로 이동:

```json
{
  "externalVoiceIds": ["voice_abc", "voice_xyz"],
  "folderId": null
}
```

Response:

```json
[
  {
    "voiceKey": "voice_abc",
    "title": "나의 목소리",
    "folderId": 1,
    "acquiredBy": "CREATED",
    "acquiredAt": "2026-04-17T13:40:00"
  }
]
```

주의:

- `externalVoiceIds` 중복은 허용되지 않습니다.
- 목록 중 하나라도 내 소유 음성이 아니면 전체 요청이 실패합니다.

### 4. 클론 보이스 생성

- `POST /voices/cloned-voice`
- Content-Type: `multipart/form-data`

Form data:

- `files`: 파일 1개
- `name`: string
- `description`: optional string

예시:

- `files`: `sample.mp3`
- `name`: `동호 목소리`
- `description`: `밝은 톤`

Response:

```json
{
  "voiceKey": "external_voice_id_123",
  "externalVoiceId": "external_voice_id_123",
  "title": "동호 목소리"
}
```

주의:

- 파트 이름이 `file` 이 아니라 `files` 입니다.
- 실제로는 파일 1개만 받습니다.
- 지원 확장자: `.wav`, `.mp3`
- 최대 크기: 3MB

### 5. TTS 생성

- `POST /voices/{ownershipId}/text-to-speech`

Request:

```json
{
  "text": "안녕하세요. 테스트 음성입니다."
}
```

Response:

```json
{
  "speechRequestId": 1,
  "generatedAudioId": 20,
  "streamUrl": "/voices/generated-audios/20/stream",
  "downloadUrl": "/voices/generated-audios/20/download"
}
```

주의:

- `ownershipId` 는 `voiceKey` 가 아니라 사용자의 소유 레코드 ID입니다.
- 현재 음성 목록 응답에는 `ownershipId` 가 내려오지 않으므로, 프론트에서 이 API를 바로 쓰려면 백엔드 보완이 필요할 수 있습니다.

### 6. 생성 오디오 스트리밍

- `GET /voices/generated-audios/{generatedAudioId}/stream`
- Response Content-Type: `audio/mpeg`

Response:

- 바이너리 mp3 스트림

### 7. 생성 오디오 다운로드

- `GET /voices/generated-audios/{generatedAudioId}/download`
- Response Content-Type: `audio/mpeg`

Response:

- 바이너리 mp3 파일 다운로드

## 방/Room

모든 API에 Bearer 토큰 필요

### enum 값

- `joinPolicy`
  - `INVITE_CODE_ONLY`
  - `INVITE_CODE_WITH_PASSWORD`

### 1. 방 생성

- `POST /room`

Request:

```json
{
  "title": "보이스룸 1",
  "joinPolicy": "INVITE_CODE_ONLY",
  "maxParticipants": 10,
  "password": null
}
```

비밀번호가 필요한 방 예시:

```json
{
  "title": "보이스룸 2",
  "joinPolicy": "INVITE_CODE_WITH_PASSWORD",
  "maxParticipants": 10,
  "password": "1234"
}
```

Response:

```json
{
  "id": 1,
  "ownerId": 1,
  "name": "보이스룸 1",
  "inviteCode": 123456,
  "joinPolicy": "INVITE_CODE_ONLY",
  "maxParticipants": 10,
  "createdAt": "2026-04-17T13:40:00",
  "updatedAt": "2026-04-17T13:40:00"
}
```

주의:

- 요청 필드는 `title` 인데 응답 필드는 `name` 입니다.

### 2. 내 방 목록 조회

- `GET /room`

Response:

```json
[
  {
    "id": 1,
    "ownerId": 1,
    "name": "보이스룸 1",
    "inviteCode": 123456,
    "joinPolicy": "INVITE_CODE_ONLY",
    "maxParticipants": 10,
    "createdAt": "2026-04-17T13:40:00",
    "updatedAt": "2026-04-17T13:40:00"
  }
]
```

### 3. 내 방 상세 조회

- `GET /room/{roomId}`

Response:

```json
{
  "id": 1,
  "ownerId": 1,
  "name": "보이스룸 1",
  "inviteCode": 123456,
  "joinPolicy": "INVITE_CODE_ONLY",
  "maxParticipants": 10,
  "createdAt": "2026-04-17T13:40:00",
  "updatedAt": "2026-04-17T13:40:00"
}
```

### 4. 방 수정

- `PUT /room/{roomId}`

Request:

```json
{
  "title": "수정된 방 제목",
  "joinPolicy": "INVITE_CODE_WITH_PASSWORD",
  "maxParticipants": 20,
  "password": "9999"
}
```

Response:

```json
{
  "id": 1,
  "ownerId": 1,
  "name": "수정된 방 제목",
  "inviteCode": 123456,
  "joinPolicy": "INVITE_CODE_WITH_PASSWORD",
  "maxParticipants": 20,
  "createdAt": "2026-04-17T13:40:00",
  "updatedAt": "2026-04-17T14:00:00"
}
```

### 5. 방 삭제

- `DELETE /room/{roomId}`

Response:

- `204 No Content`

## 방 음성 공유/Room Voice Shares

모든 API에 Bearer 토큰 필요

Path prefix:

- `/room/{roomId}/voice-shares`

### enum 값

- `accessScope`
  - `LISTEN_ONLY`
  - `SYNTHESIS_ALLOWED`
  - `DOWNLOAD_ALLOWED`

### 1. 방에 음성 공유

- `POST /room/{roomId}/voice-shares`

Request:

```json
{
  "externalVoiceIds": ["voice_abc", "voice_xyz"],
  "accessScope": "LISTEN_ONLY"
}
```

Response:

```json
[
  {
    "id": 1,
    "roomId": 1,
    "voiceKey": "voice_abc",
    "externalVoiceId": "voice_abc",
    "voiceTitle": "나의 목소리",
    "accessScope": "LISTEN_ONLY",
    "sharedAt": "2026-04-17T13:40:00"
  }
]
```

주의:

- 현재 응답에서는 `voiceKey` 와 `externalVoiceId` 가 동일한 값으로 내려옵니다.

### 2. 방 공유 음성 목록 조회

- `GET /room/{roomId}/voice-shares`

Response:

```json
[
  {
    "id": 1,
    "roomId": 1,
    "voiceKey": "voice_abc",
    "externalVoiceId": "voice_abc",
    "voiceTitle": "나의 목소리",
    "accessScope": "LISTEN_ONLY",
    "sharedAt": "2026-04-17T13:40:00"
  }
]
```

### 3. 방 공유 음성 상세 조회

- `GET /room/{roomId}/voice-shares/{shareId}`

Response:

```json
{
  "id": 1,
  "roomId": 1,
  "voiceKey": "voice_abc",
  "externalVoiceId": "voice_abc",
  "voiceTitle": "나의 목소리",
  "accessScope": "LISTEN_ONLY",
  "sharedAt": "2026-04-17T13:40:00"
}
```

### 4. 접근 범위 수정

- `PUT /room/{roomId}/voice-shares/{shareId}`

Request:

```json
{
  "accessScope": "DOWNLOAD_ALLOWED"
}
```

Response:

```json
{
  "id": 1,
  "roomId": 1,
  "voiceKey": "voice_abc",
  "externalVoiceId": "voice_abc",
  "voiceTitle": "나의 목소리",
  "accessScope": "DOWNLOAD_ALLOWED",
  "sharedAt": "2026-04-17T13:40:00"
}
```

### 5. 공유 음성 삭제

- `DELETE /room/{roomId}/voice-shares/{shareId}`

Response:

- `204 No Content`

## 프론트 구현 시 꼭 체크할 점

### 1. 인증 헤더

보호 API 호출 시 항상 아래 형식 사용:

```http
Authorization: Bearer {accessToken}
```

### 2. 토큰 재발급 흐름

- 액세스 토큰 만료 시 `POST /auth/refresh`
- 성공하면 새 `accessToken` 으로 재시도

### 3. TTS API 주의

- 경로 변수는 `voiceKey` 가 아니라 `ownershipId`
- 현재 음성 목록 응답에서는 `ownershipId` 를 받지 못함
- 프론트 연결 전에 이 부분은 백엔드 추가 수정 또는 별도 조회 API가 필요할 가능성이 높음

### 4. 방 API 필드명 차이

- 요청: `title`
- 응답: `name`

프론트 모델 변환 시 주의 필요

### 5. 클론 보이스 업로드 필드명

- multipart 파트 이름: `files`
- 단일 파일 업로드

