# OTT API v1 요약 명세 (Summary)

> 본 문서는 OTT 서비스 API v1의 **핵심 규칙과 주요 엔드포인트만 요약**한 문서입니다.
> 상세 설계 및 Request/Response 예시는
> 👉 `docs/api/ott-api-v1.md` 를 참고하세요.

---

## 1. 공통 규칙

* **Base URL**: `/api/v1`
* **Auth**

  * `Authorization: Bearer {access_token}`
  * 예외(토큰 불필요): `POST /auth/signup`, `POST /auth/login`, `POST /auth/refresh`
* **Profile Context**

  * 프로필 기준 동작이 필요한 API는 `X-Profile-Id: {profile_id}` 헤더 사용
* **Request / Response**

  * JSON, `snake_case`
* **Time / Date**

  * **DATETIME/TIMESTAMP**: ISO 8601 UTC(Z) 문자열
    예: `2025-12-10T12:34:56.789Z`
  * **DATE**: `"YYYY-MM-DD"` 문자열
    예: `2026-01-01`

### v1 고정 정책(DB 매핑 핵심)

* **Watch Histories 매핑**

  * API `last_position_sec` ↔ DB `watch_histories.progress_sec`
  * API `total_duration_sec` ↔ DB `watch_histories.duration_sec`
* **Contents 이미지**

  * v1에서는 `thumbnail_url`을 분리하지 않고 **`thumbnail_url = poster_url`** 로 동일 값 사용 가능
* **Contents synopsis**

  * v1 상세 응답은 DB 구조와 통일: **`synopsis_short`, `synopsis_long`**
* **Rating(별점)**

  * v1에서 `my_state.my_rating`은 **리뷰의 `rating`과 동일**(리뷰 없으면 null)
    (리뷰 없는 별점 단독 저장은 v2)

### 공통 응답 Envelope

```json
{
  "success": true,
  "data": {},
  "error": null
}
```

---

## 2. 인증 / 계정 (Auth & Users)

| Method | Endpoint        | Description |
| ------ | --------------- | ----------- |
| POST   | `/auth/signup`  | 회원가입        |
| POST   | `/auth/login`   | 로그인         |
| POST   | `/auth/refresh` | 토큰 재발급      |
| GET    | `/users/me`     | 내 계정 정보 조회  |

---

## 3. 프로필 (Profiles)

| Method | Endpoint                 | Description |
| ------ | ------------------------ | ----------- |
| GET    | `/profiles`              | 프로필 목록      |
| POST   | `/profiles`              | 프로필 생성      |
| PATCH  | `/profiles/{profile_id}` | 프로필 수정      |
| DELETE | `/profiles/{profile_id}` | 프로필 삭제      |

* 계정당 **최대 5개**
* 최소 1개 프로필은 유지(정책 적용 시)
* `max_age_rating`은 `profile_settings.max_age_rating` 기반 (`ALL|7|12|15|19`)

---

## 4. 콘텐츠 (Contents)

| Method | Endpoint                          | Description       |
| ------ | --------------------------------- | ----------------- |
| GET    | `/contents`                       | 콘텐츠 목록            |
| GET    | `/contents/{content_id}`          | 콘텐츠 상세(프로필 상태 포함) |
| GET    | `/contents/{content_id}/episodes` | 회차 목록(시리즈)        |

* 영화/시리즈 통합 모델
* 연령 제한은 **프로필 기준 필터링**(서버 정책)

---

## 5. 시청 기록 / 이어보기

### Watch Histories

| Method | Endpoint           | Description   |
| ------ | ------------------ | ------------- |
| GET    | `/watch-histories` | 시청 기록/이어보기 목록 |
| PUT    | `/watch-histories` | 시청 위치 업데이트    |

* `X-Profile-Id` 필수
* 영화: `episode_id = null`
* 시리즈: 실제 `episode_id`

### Watch Sessions (선택)

| Method | Endpoint          | Description     |
| ------ | ----------------- | --------------- |
| GET    | `/watch-sessions` | 시청 세션 로그 조회(선택) |

---

## 6. 찜 (Wishlist)

| Method | Endpoint                 | Description |
| ------ | ------------------------ | ----------- |
| GET    | `/wishlist`              | 찜 목록        |
| POST   | `/wishlist`              | 찜 추가        |
| DELETE | `/wishlist/{content_id}` | 찜 제거        |

* 프로필 기준 (`X-Profile-Id`)
* 중복 찜 불가(프로필+콘텐츠 UNIQUE)

---

## 7. 리뷰 (Reviews)

| Method | Endpoint                         | Description |
| ------ | -------------------------------- | ----------- |
| GET    | `/contents/{content_id}/reviews` | 작품 리뷰 목록    |
| POST   | `/contents/{content_id}/reviews` | 리뷰 작성       |
| PATCH  | `/reviews/{review_id}`           | 리뷰 수정       |
| DELETE | `/reviews/{review_id}`           | 리뷰 삭제       |

* **30% 이상 시청한 경우에만 작성 가능**
* 프로필당 작품 1개 리뷰 제한(프로필+콘텐츠 UNIQUE)

---

## 8. 보안 / 디바이스 (향후)

> v1에서는 디바이스 테이블이 없어 **설계만 정의**(향후 확장)

| Method | Endpoint                               | Description  |
| ------ | -------------------------------------- | ------------ |
| GET    | `/security/devices`                    | 최근 접속 기기 목록  |
| POST   | `/security/devices/{device_id}/logout` | 특정 디바이스 로그아웃 |
| POST   | `/security/devices/logout-all`         | 전체 디바이스 로그아웃 |

---

## 9. 향후 확장

* 멤버십/결제 API → v2 분리 예정
* 소셜 로그인 `/auth/{provider}` 확장 가능
* 관리자 API `/admin/api/v1/...` 별도 네임스페이스
* Watch Party(Phase2) 문서 분리 가능

