# My Page API

`마이페이지` 화면 기준 문서입니다.

## 현재 상태

- 서버 연동 가능
  - 내 정보 조회
  - 프로필 수정
  - 비밀번호 변경
  - 연결된 소셜 계정 조회
  - 회원 탈퇴
- 부분 연동 또는 추가 확인 필요
  - 보유 음성 통계 카운트는 현재 여러 API 조합 필요
  - 음성 카드의 TTS 액션은 `ownershipId` blocker 존재
  - 음성 삭제 액션은 서버 API 없음

모든 API에 Bearer 토큰 필요

## 이 화면에서 주로 쓰는 API

- `GET /me`
- `PATCH /me/profile`
- `PATCH /me/password`
- `GET /me/social-accounts`
- `DELETE /me`
- 보유 음성 관련 보조 API
  - `GET /voices`
  - `GET /voices/unassigned`
  - `GET /voice-folders/contents`

## 1. 내 정보 조회

- `GET /me`

Response:

```json
{
  "id": 1,
  "nickName": "게스트",
  "email": "user@example.com",
  "hasPassword": true,
  "adsFree": false
}
```

화면 적용 포인트:

- `nickName` 을 프로필 카드 이름에 표시
- `hasPassword` 로 비밀번호 변경 UI 노출 여부 판단 가능
- `adsFree` 로 광고 제거 상태 표시 가능

## 2. 프로필 수정

- `PATCH /me/profile`

Request:

```json
{
  "nickName": "동호"
}
```

Response:

```json
{
  "id": 1,
  "nickName": "동호",
  "email": "user@example.com",
  "hasPassword": true,
  "adsFree": false
}
```

## 3. 비밀번호 변경

- `PATCH /me/password`

Request:

```json
{
  "currentPassword": "old-password",
  "newPassword": "new-password-1234"
}
```

Response:

- `204 No Content`

주의:

- 소셜 로그인 계정처럼 비밀번호가 없는 계정은 `currentPassword` 없이 변경 가능한 케이스가 있을 수 있음
- 프론트에서는 `hasPassword` 와 로그인 방식 기준으로 UI 분기 권장

## 4. 연결된 소셜 계정 조회

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

## 5. 회원 탈퇴

- `DELETE /me`

Response:

- `204 No Content`

## 6. 보유 음성 카드 데이터 구성

마이페이지 화면의 보유 음성 카드/개수는 단일 전용 API가 아니라, 아래 API를 조합해야 할 수 있습니다.

### 전체 음성

- `GET /voices`

### 미분류 음성

- `GET /voices/unassigned`

### 폴더별/루트 기준 구조

- `GET /voice-folders/contents`

현재 주의사항:

- `내 업로드`, `공유방`, `구매` 같은 분류 카운트를 정확히 한 번에 내려주는 전용 API는 없음
- 프론트에서 `acquiredBy` 또는 다른 기준으로 임시 계산이 필요할 수 있음
- `구매` 여부를 음성 데이터만으로 완전히 식별 가능한지 추가 확인 필요

## 7. 음성 카드 액션 관련 상태

### TTS

- API는 존재: `POST /voices/{ownershipId}/text-to-speech`
- 하지만 목록 응답에 `ownershipId` 없음
- 따라서 마이페이지 카드에서 바로 TTS 연결은 현재 어려움

### 삭제

- 서버 삭제 API 없음
- 로그인 상태 기준 진짜 삭제는 아직 구현 불가

## 프론트 구현 메모

- 프로필 영역은 `GET /me` 하나로 대부분 해결 가능
- 음성 카드 영역은 현재 완전한 전용 API가 없어서 일부는 데모 또는 계산 로직 필요
- 실제 서비스 연결 기준으로는 `마이페이지` 와 `음성` 탭이 같은 음성 데이터 소스를 공유하는 편이 자연스러움
