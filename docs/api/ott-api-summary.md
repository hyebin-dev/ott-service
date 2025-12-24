# OTT API v1 요약 명세 (Summary)

> 본 문서는 OTT 서비스 API v1의 **핵심 규칙과 주요 엔드포인트만 요약**한 문서입니다.
> 상세 설계 및 Request/Response 예시는
> 👉 `docs/api/ott-api-v1.md` 를 참고하세요.

---

## 1. 공통 규칙

* **Base URL**: `/api/v1`
* **Auth**

  * `Authorization: Bearer {access_token}`
* **Profile Context**

  * 프로필 기준 동작이 필요한 API는
    `X-Profile-Id: {profile_id}` 헤더 사용
* **Request / Response**

  * JSON, `snake_case`
* **Time**

  * ISO 8601 UTC(Z) 문자열
    예: `2025-12-10T12:34:56.789Z`

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
* 최소 1개 프로필은 유지

---

## 4. 콘텐츠 (Contents)

| Method | Endpoint                          | Description |
| ------ | --------------------------------- | ----------- |
| GET    | `/contents`                       | 콘텐츠 목록      |
| GET    | `/contents/{content_id}`          | 콘텐츠 상세      |
| GET    | `/contents/{content_id}/episodes` | 회차 목록(시리즈)  |

* 영화/시리즈 통합 모델
* 연령 제한은 **프로필 기준 필터링**

---

## 5. 시청 기록 / 이어보기

### Watch Histories

| Method | Endpoint           |
| ------ | ------------------ |
| GET    | `/watch-histories` |
| PUT    | `/watch-histories` |

* `X-Profile-Id` 필수
* 영화: `episode_id = null`
* 시리즈: 실제 `episode_id`

### Watch Sessions

| Method | Endpoint          |
| ------ | ----------------- |
| GET    | `/watch-sessions` |

---

## 6. 찜 (Wishlist)

| Method | Endpoint                 |
| ------ | ------------------------ |
| GET    | `/wishlist`              |
| POST   | `/wishlist`              |
| DELETE | `/wishlist/{content_id}` |

* 프로필 기준
* 중복 찜 불가

---

## 7. 리뷰 (Reviews)

| Method | Endpoint                         |
| ------ | -------------------------------- |
| GET    | `/contents/{content_id}/reviews` |
| POST   | `/contents/{content_id}/reviews` |
| PATCH  | `/reviews/{review_id}`           |
| DELETE | `/reviews/{review_id}`           |

* **30% 이상 시청한 경우에만 작성 가능**
* 프로필당 작품 1개 리뷰 제한

---

## 8. 보안 / 디바이스 (향후)

> v0 DB에는 디바이스 테이블이 없어 **설계만 정의**

| Method | Endpoint                               |
| ------ | -------------------------------------- |
| GET    | `/security/devices`                    |
| POST   | `/security/devices/{device_id}/logout` |
| POST   | `/security/devices/logout-all`         |

---

## 9. 향후 확장

* 멤버십/결제 API → v2 분리 예정
* 소셜 로그인 `/auth/{provider}` 확장 가능
* 관리자 API `/admin/api/v1/...` 별도 네임스페이스
* Watch Party(Phase2) 문서 분리 가능

