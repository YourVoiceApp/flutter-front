# Voice Screen API

하단 탭 `음성` 화면 기준 문서입니다.

## 현재 상태

- 서버 연동 가능
  - 폴더 목록/내용 조회
  - 내 음성 목록 조회
  - 미분류 음성 조회
  - 음성 폴더 이동
  - 클론 보이스 생성
- 아직 바로 연동 어려움
  - TTS API: `ownershipId` 가 프론트에 없음
  - 생성 오디오 stream/download: TTS 응답과 이어져야 해서 현재 미연결
  - 음성 삭제: 서버 삭제 API 없음

## 이 화면에서 쓰는 API 묶음

### 폴더 API

- `POST /voice-folders`
- `GET /voice-folders/contents`
- `PUT /voice-folders/{folderId}`
- `DELETE /voice-folders/{folderId}`

### 음성 API

- `GET /voices`
- `GET /voices/unassigned`
- `PATCH /voices/folder`
- `POST /voices/cloned-voice`
- `POST /voices/{ownershipId}/text-to-speech`
- `GET /voices/generated-audios/{generatedAudioId}/stream`
- `GET /voices/generated-audios/{generatedAudioId}/download`

모든 API에 Bearer 토큰 필요

## 1. 화면 첫 진입

보통 아래 두 API 중 하나로 시작하면 됩니다.

### 루트 폴더 화면 조회

- `GET /voice-folders/contents`

Response:

```json
{
  "totalVoiceCount": 3,
  "folders": [
    {
      "id": 1,
      "parentFolderId": null,
      "name": "동물",
      "voiceCount": 1,
      "createdAt": "2026-04-17T13:40:00",
      "updatedAt": "2026-04-17T13:40:00"
    }
  ],
  "voices": [
    {
      "voiceKey": "voice_abc",
      "title": "엄마.안내_01.m4a",
      "folderId": null,
      "acquiredBy": "CREATED",
      "acquiredAt": "2026-04-17T13:40:00"
    }
  ]
}
```

### 특정 폴더 진입

- `GET /voice-folders/contents?parentId=1`

## 2. 폴더 생성

- `POST /voice-folders`

Request:

```json
{
  "name": "친구",
  "parentFolderId": null
}
```

하위 폴더 생성:

```json
{
  "name": "학교 친구",
  "parentFolderId": 1
}
```

Response:

```json
{
  "id": 3,
  "parentFolderId": null,
  "name": "친구",
  "voiceCount": 0,
  "createdAt": "2026-04-17T13:40:00",
  "updatedAt": "2026-04-17T13:40:00"
}
```

## 3. 폴더 수정

- `PUT /voice-folders/{folderId}`

Request:

```json
{
  "name": "친한 친구",
  "parentFolderId": null
}
```

## 4. 폴더 삭제

- `DELETE /voice-folders/{folderId}`

Response:

- `204 No Content`

## 5. 내 음성 목록 조회

- `GET /voices`
- optional query: `folderId`

예:

- `GET /voices`
- `GET /voices?folderId=1`

Response:

```json
[
  {
    "voiceKey": "voice_abc",
    "title": "엄마.안내_01.m4a",
    "folderId": 1,
    "acquiredBy": "CREATED",
    "acquiredAt": "2026-04-17T13:40:00"
  }
]
```

`acquiredBy` 값:

- `CREATED`
- `ROOM_SHARED`
- `ADMIN_GRANTED`

## 6. 미분류 음성 조회

- `GET /voices/unassigned`

Response:

```json
[
  {
    "voiceKey": "voice_xyz",
    "title": "새녹음_clip.aac",
    "folderId": null,
    "acquiredBy": "ROOM_SHARED",
    "acquiredAt": "2026-04-17T13:40:00"
  }
]
```

## 7. 음성 폴더 이동

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
    "title": "엄마.안내_01.m4a",
    "folderId": 1,
    "acquiredBy": "CREATED",
    "acquiredAt": "2026-04-17T13:40:00"
  }
]
```

주의:

- `externalVoiceIds` 중복 불가
- 하나라도 내 소유 음성이 아니면 전체 실패

## 8. 클론 보이스 생성

- `POST /voices/cloned-voice`
- Content-Type: `multipart/form-data`

Form data:

- `files`: 파일 1개
- `name`: string
- `description`: optional string

Response:

```json
{
  "voiceKey": "external_voice_id_123",
  "externalVoiceId": "external_voice_id_123",
  "title": "동호 목소리"
}
```

주의:

- 파트 이름은 `files`
- 실제로는 단일 파일
- 지원 확장자: `.wav`, `.mp3`
- 최대 크기: 3MB

## 9. TTS 생성

- `POST /voices/{ownershipId}/text-to-speech`

Request:

```json
{
  "text": "안녕하세요. 테스트 음성입니다."
}
```

성공 응답 예시:

```json
{
  "speechRequestId": 1,
  "generatedAudioId": 20,
  "streamUrl": "/voices/generated-audios/20/stream",
  "downloadUrl": "/voices/generated-audios/20/download"
}
```

현재 blocker:

- 경로 변수는 `voiceKey` 가 아니라 `ownershipId`
- 현재 음성 목록 응답에는 `ownershipId` 가 없음
- 그래서 프론트가 지금 응답만으로는 이 API를 직접 호출하기 어려움

## 10. 생성 오디오 재생/다운로드

### 스트리밍

- `GET /voices/generated-audios/{generatedAudioId}/stream`
- Response Content-Type: `audio/mpeg`

### 다운로드

- `GET /voices/generated-audios/{generatedAudioId}/download`
- Response Content-Type: `audio/mpeg`

현재 상태:

- 위 두 API 자체는 존재
- 하지만 `generatedAudioId` 는 TTS 응답을 통해 받아야 하므로, TTS 미연결 상태에서는 같이 미연결

## 11. 음성 삭제

현재 상태:

- 서버 기준 음성 삭제 API 없음
- 프론트에서 로그인 상태 삭제 기능은 완전한 서버 연동 불가

## 프론트 구현 메모

- 폴더 화면은 `GET /voice-folders/contents` 중심으로 구성하는 게 가장 편함
- 미분류 전용 영역은 `GET /voices/unassigned`
- TTS 버튼은 백엔드가 `ownershipId` 를 내려주기 전까지 비활성 또는 데모 처리 권장
- 삭제 버튼은 서버 API 추가 전까지 로컬 상태 변경만으로 처리하면 실제 데이터와 불일치 가능
