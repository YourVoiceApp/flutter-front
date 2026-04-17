# Frontend API Docs

프론트에서 화면 단위로 보기 쉽게 API 문서를 분리한 인덱스입니다.

## 기본 정보

- Base URL: `http://43.202.13.147:9090`
- Swagger UI: `GET /swagger-ui.html`
- OpenAPI JSON: `GET /v3/api-docs`
- 인증: `/auth/**` 제외 전부 `Authorization: Bearer {accessToken}`
- 시간 형식: ISO 문자열
  - 예: `"2026-04-17T13:40:00"`

## 문서 목록

- `auth.md`
  - 로그인, 회원가입, 토큰 재발급
- `voice-screen.md`
  - 음성 화면, 폴더, 보유 음성, 클론 보이스, TTS 관련
- `rooms-screen.md`
  - 함께 화면, 방 생성/조회/수정/삭제, 방 음성 공유
- `market-screen.md`
  - 마켓 화면, 광고 제거 결제, 아직 데모인 마켓플레이스 영역
- `mypage-screen.md`
  - 마이페이지, 내 정보, 소셜 계정, 비밀번호 변경, 음성 카드와 관련된 연동 상태

## 공통 응답 규칙

### 성공

- 조회/생성/수정: 주로 `200 OK`
- 삭제/일부 인증 처리: `204 No Content`

### 공통 에러 형식

```json
{
  "code": "INVALID_REQUEST",
  "message": "Invalid request"
}
```

### 자주 보게 될 에러 코드

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

## 화면별 현재 상태 요약

### 음성 화면

- 폴더/음성 목록/폴더 이동/클론 보이스 생성은 서버 연동 가능
- TTS는 `ownershipId` 부재 때문에 현재 바로 연결 어려움
- 음성 삭제는 서버 API 없음

### 함께 화면

- 방 API 전체와 방 음성 공유 API 전체 사용 가능
- 기존 프론트는 데모 데이터 기반이었지만 서버 연동 대상 API는 준비됨

### 마켓 화면

- 광고 제거 결제 API는 사용 가능
- 마켓플레이스 목록/검색/정렬/내 판매는 아직 서버 명세 없음

### 마이페이지 화면

- 내 정보, 프로필 수정, 비밀번호 변경, 소셜 계정 조회, 회원 탈퇴 가능
- 보유 음성 카드 중 삭제/TTS처럼 추가 API가 필요한 항목은 일부 미연결
