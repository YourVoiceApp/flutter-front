# Rooms Screen API

하단 탭 `함께` 화면 기준 문서입니다.

## 현재 상태

- 서버 연동 대상 API는 준비되어 있음
- 방 API 전체
  - `/room`
  - `/room/{roomId}`
- 방 음성 공유 API 전체
  - `/room/{roomId}/voice-shares/*`
- 현재 프론트는 데모 데이터 기반이지만, 이 문서 기준으로 서버 연결 가능

모든 API에 Bearer 토큰 필요

## 이 화면에서 쓰는 API

### 방 API

- `POST /room`
- `GET /room`
- `GET /room/{roomId}`
- `PUT /room/{roomId}`
- `DELETE /room/{roomId}`

### 방 음성 공유 API

- `POST /room/{roomId}/voice-shares`
- `GET /room/{roomId}/voice-shares`
- `GET /room/{roomId}/voice-shares/{shareId}`
- `PUT /room/{roomId}/voice-shares/{shareId}`
- `DELETE /room/{roomId}/voice-shares/{shareId}`

## enum 값

### `joinPolicy`

- `INVITE_CODE_ONLY`
- `INVITE_CODE_WITH_PASSWORD`

### `accessScope`

- `LISTEN_ONLY`
- `SYNTHESIS_ALLOWED`
- `DOWNLOAD_ALLOWED`

## 1. 참여 중인 방 목록 조회

- `GET /room`

Response:

```json
[
  {
    "id": 1,
    "ownerId": 1,
    "name": "우리 가족 방",
    "inviteCode": 720341,
    "joinPolicy": "INVITE_CODE_ONLY",
    "maxParticipants": 3,
    "createdAt": "2026-04-17T13:40:00",
    "updatedAt": "2026-04-17T13:40:00"
  },
  {
    "id": 2,
    "ownerId": 1,
    "name": "사촌 모임",
    "inviteCode": 981203,
    "joinPolicy": "INVITE_CODE_WITH_PASSWORD",
    "maxParticipants": 3,
    "createdAt": "2026-04-17T13:40:00",
    "updatedAt": "2026-04-17T13:40:00"
  }
]
```

주의:

- 현재 API 설명상 "내가 만든 방" 기준입니다.
- 프론트 문구가 "참여 중인 방" 이라면 실제 요구사항과 API 의미가 맞는지 한 번 더 확인 필요합니다.

## 2. 방 생성

- `POST /room`

Request:

```json
{
  "title": "우리 가족 방",
  "joinPolicy": "INVITE_CODE_ONLY",
  "maxParticipants": 3,
  "password": null
}
```

비밀번호 방 예시:

```json
{
  "title": "사촌 모임",
  "joinPolicy": "INVITE_CODE_WITH_PASSWORD",
  "maxParticipants": 3,
  "password": "1234"
}
```

Response:

```json
{
  "id": 1,
  "ownerId": 1,
  "name": "우리 가족 방",
  "inviteCode": 720341,
  "joinPolicy": "INVITE_CODE_ONLY",
  "maxParticipants": 3,
  "createdAt": "2026-04-17T13:40:00",
  "updatedAt": "2026-04-17T13:40:00"
}
```

주의:

- 요청 필드는 `title`
- 응답 필드는 `name`

## 3. 방 상세 조회

- `GET /room/{roomId}`

Response:

```json
{
  "id": 1,
  "ownerId": 1,
  "name": "우리 가족 방",
  "inviteCode": 720341,
  "joinPolicy": "INVITE_CODE_ONLY",
  "maxParticipants": 3,
  "createdAt": "2026-04-17T13:40:00",
  "updatedAt": "2026-04-17T13:40:00"
}
```

## 4. 방 수정

- `PUT /room/{roomId}`

Request:

```json
{
  "title": "우리 가족 방 수정",
  "joinPolicy": "INVITE_CODE_WITH_PASSWORD",
  "maxParticipants": 4,
  "password": "9999"
}
```

Response:

```json
{
  "id": 1,
  "ownerId": 1,
  "name": "우리 가족 방 수정",
  "inviteCode": 720341,
  "joinPolicy": "INVITE_CODE_WITH_PASSWORD",
  "maxParticipants": 4,
  "createdAt": "2026-04-17T13:40:00",
  "updatedAt": "2026-04-17T14:00:00"
}
```

## 5. 방 삭제

- `DELETE /room/{roomId}`

Response:

- `204 No Content`

## 6. 방에 음성 공유

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
    "voiceTitle": "엄마.안내_01.m4a",
    "accessScope": "LISTEN_ONLY",
    "sharedAt": "2026-04-17T13:40:00"
  }
]
```

## 7. 공유 음성 목록 조회

- `GET /room/{roomId}/voice-shares`

Response:

```json
[
  {
    "id": 1,
    "roomId": 1,
    "voiceKey": "voice_abc",
    "externalVoiceId": "voice_abc",
    "voiceTitle": "엄마.안내_01.m4a",
    "accessScope": "LISTEN_ONLY",
    "sharedAt": "2026-04-17T13:40:00"
  }
]
```

## 8. 공유 음성 상세 조회

- `GET /room/{roomId}/voice-shares/{shareId}`

Response:

```json
{
  "id": 1,
  "roomId": 1,
  "voiceKey": "voice_abc",
  "externalVoiceId": "voice_abc",
  "voiceTitle": "엄마.안내_01.m4a",
  "accessScope": "LISTEN_ONLY",
  "sharedAt": "2026-04-17T13:40:00"
}
```

## 9. 공유 음성 접근 범위 수정

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
  "voiceTitle": "엄마.안내_01.m4a",
  "accessScope": "DOWNLOAD_ALLOWED",
  "sharedAt": "2026-04-17T13:40:00"
}
```

## 10. 공유 음성 삭제

- `DELETE /room/{roomId}/voice-shares/{shareId}`

Response:

- `204 No Content`

## 프론트 구현 메모

- 목록 화면은 `GET /room`
- 상세 진입 후 공유 음성 영역은 `GET /room/{roomId}/voice-shares`
- 방 생성/수정 시 프론트 모델은 `title`, 화면 표시 모델은 `name` 으로 매핑 필요
- `voiceKey` 와 `externalVoiceId` 는 현재 동일 값으로 내려옵니다
