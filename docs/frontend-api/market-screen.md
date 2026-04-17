# Market Screen API

하단 탭 `마켓` 화면 기준 문서입니다.

## 현재 상태

- 서버 연동 가능
  - 광고 제거 결제 API
- 아직 데모 상태
  - 마켓플레이스 목록
  - 검색
  - 정렬
  - 내 판매
  - 음성 상품 상세/구매 관련 기능

이유:

- 현재 백엔드 명세서에는 마켓플레이스 관련 API 섹션이 없음
- 그래서 화면 대부분은 아직 로컬 데모 상태로 유지해야 함

모든 결제 API에 Bearer 토큰 필요

## 이 화면에서 실제로 쓸 수 있는 API

- `GET /billing/ads-removal/status`
- `POST /billing/ads-removal/orders`
- `POST /billing/ads-removal/confirm`

상품 ID는 현재 `ads_removal` 고정

## 1. 광고 제거 상태 조회

- `GET /billing/ads-removal/status`

Response:

```json
{
  "adsFree": false,
  "productId": "ads_removal",
  "purchasedAt": null
}
```

구매 완료 예시:

```json
{
  "adsFree": true,
  "productId": "ads_removal",
  "purchasedAt": "2026-04-17T13:40:00"
}
```

화면 적용 포인트:

- `adsFree: true` 이면 "듣기 화면 광고 끄기" 배너를 숨기거나 구매 완료 상태로 전환

## 2. 광고 제거 주문 생성

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

## 3. 광고 제거 결제 확인

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

주의:

- 이미 광고 제거 상태면 주문 생성 API에서 에러
- 같은 `purchaseToken` 재사용 시 에러

## 아직 없는 마켓 API

현재 백엔드 기준 미확인 또는 미제공:

- 음성 상품 목록 조회
- 인기순/최신순 정렬
- 검색어 기반 조회
- 내 판매 목록
- 상품 상세
- 상품 구매
- 미리듣기 정보 조회

## 프론트 구현 메모

- 현재 `마켓` 화면은 `광고 제거` 카드만 서버 연동 가능
- 나머지 리스트 UI는 계속 데모 데이터 유지 권장
- 나중에 마켓 API가 나오면 이 문서에 별도 섹션 추가하면 됨
