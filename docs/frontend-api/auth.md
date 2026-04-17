# Auth API

로그인 전후 공통으로 쓰는 인증 API 문서입니다.

## 현재 상태

- 전부 서버 연동 가능
- 모두 공개 API
- 액세스 토큰 만료 시 `POST /auth/refresh` 로 재발급

## 공통 응답

토큰 발급 응답은 아래 형식을 사용합니다.

```json
{
  "accessToken": "jwt-access-token",
  "refreshToken": "jwt-refresh-token",
  "userId": 1,
  "email": "user@example.com"
}
```

## 1. 이메일 인증 코드 발송

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

## 2. 이메일 인증 코드 확인

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

## 3. 이메일 회원가입

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

## 4. 이메일 로그인

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

## 5. 구글 로그인

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

## 6. 카카오 로그인

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

## 7. 액세스 토큰 재발급

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

## 8. 로그아웃

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

## 프론트 메모

- 보호 API 요청 시 헤더:

```http
Authorization: Bearer {accessToken}
```

- 토큰 만료 시 일반 흐름:
  - 보호 API 호출 실패
  - `POST /auth/refresh`
  - 새 `accessToken` 저장
  - 실패했던 요청 재시도
