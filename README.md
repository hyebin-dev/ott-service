# ott-service

구독 기반 OTT 영상 스트리밍 웹 서비스  
**Tech Stack:** Spring Boot + React + MySQL

> 와이어프레임 → DB/ERD → API 설계 → 백엔드/프론트엔드 구현까지  
> OTT 서비스를 처음부터 끝까지 직접 설계·구현하는 개인 포트폴리오 프로젝트입니다.

---

## 1. 프로젝트 개요

`ott-service`는 **한 계정에 여러 프로필을 두고**,  
프로필별로 시청 경험·기록·추천·설정을 분리 관리하는  
**구독 기반 OTT 영상 스트리밍 웹 서비스**를 목표로 합니다.

현재 레포지토리는 **구현 직전 단계까지의 설계 자산(UX/DB/API 계약)** 을 정리해두었으며,  
이후 단계에서 Spring Boot / React 구현이 순차적으로 추가됩니다.

현재까지 정리된 내용:

- 데스크톱 웹 기준 **UX 와이어프레임**
- **OTT 서비스 DB 설계(v0/v1)** (ERD + MySQL DDL + Seed)
- **REST API 설계 문서(v1)** (요약본 + 상세본)

이후 단계에서 추가될 내용:

- Spring Boot 기반 **백엔드 API 구현**
- React 기반 **프론트엔드 웹 애플리케이션**
- 샘플 데이터 기반 **데모 & 배포**

---

## 2. 주요 기능(설계)

### 2-1. 계정 · 멤버십

- 이메일 회원가입 / 로그인
- 멤버십 플랜 선택 (BASIC / STANDARD / PREMIUM)
- 결제 수단 등록, 결제 내역 및 다음 결제일 확인
- 멤버십 변경 및 해지 플로우
- 계정 정보 수정 전 **비밀번호 재확인**

### 2-2. 프로필 · 자녀 보호

- 계정당 최대 5개의 프로필 생성
- 프로필 이미지, 이름, PIN 잠금 설정
- 프로필별 시청 기록 / 추천 / 설정 완전 분리
- 자녀 보호 기능
  - 관람 등급 제한 (ALL / 7 / 12 / 15 / 19)
  - 특정 작품 개별 차단

### 2-3. 콘텐츠 탐색

- 홈 화면
  - 오늘의 TOP 콘텐츠
  - 신규 콘텐츠
  - 회원 맞춤 추천
  - 장르별 섹션
- 영화 / 시리즈 / 찜 탭 분리
- 작품 상세
  - 시놉시스, 장르, 국가, 러닝타임/시즌 정보
  - 출연/제작 정보
  - 관련 콘텐츠 추천

### 2-4. 시청 경험

- 웹 플레이어 UI
- 이어보기 / 시청 기록 관리
- 시리즈 자동 다음 회차 재생
- 재생 종료 후 리뷰 유도 플로우

### 2-5. 리뷰 · 평가

- 별점 + 리뷰 제목 + 본문 작성
- 스포일러 여부 설정
- 작품 상세 내 리뷰 목록
- “내가 작성한 리뷰” 관리
- 리뷰 Empty State 화면 설계

### 2-6. 보안 (설계)

- 최근 접속 기기(디바이스) 목록
- 디바이스별 로그아웃
- 모든 기기에서 로그아웃
- 의심 접속 시 비밀번호 변경 유도 플로우
- Refresh Token 로테이션 + 서버 저장(해시) + 로그아웃 폐기

---

## 3. UX & 와이어프레임

현재 와이어프레임은 **데스크톱 웹 기준**으로 다음 흐름을 포함합니다.

- 회원가입 3단계
  1. 이메일 입력
  2. 비밀번호 설정
  3. 기본 정보 및 약관 동의
- 로그인 / 비밀번호 찾기
- 프로필 선택 및 관리 (PIN 잠금 포함)
- 홈 / 영화 / 시리즈 / 찜 탭
- 작품 상세 (영화/시리즈, 회차 목록)
- 리뷰 작성 / 목록
- 시청 기록 / 찜 목록 (존재/빈 상태)
- 계정 설정 (멤버십, 계정 정보, 자녀 보호, 보안)
- 프로필별 재생/화면/자막 설정

### 와이어프레임 & DB 설계 파일 경로

```text
docs/
├─ wireframes/
│  └─ desktop/
│     *.png                    # OTT 데스크톱 웹 와이어프레임
├─ db/
│  ├─ README.md                 # DB/ERD 설계 상세 문서(v1 기준)
│  ├─ ott-db-v0.png             # OTT DB ERD (v0)
│  ├─ ott-db-v0-schema.sql      # MySQL DDL (v0)
│  ├─ ott-db-v0-seed.sql        # Demo Seed Data (v0)
│  ├─ ott-db-v1-schema.sql      # MySQL DDL (v1)
│  └─ ott-db-v1-seed.sql        # Demo Seed Data (v1, 재실행 안전)
└─ api/
   ├─ ott-api-summary.md        # API 요약 명세
   └─ ott-api-v1.md             # API 상세 명세
````

> 파일명 규칙: `wf-<영역>-<상태>.png`
> Git 히스토리만 보아도 화면 목적을 유추할 수 있도록 네이밍했습니다.

---

## 4. API 설계 문서(v1)

본 프로젝트는 **구현 이전에 API 계약을 명확히 정의**하는 것을 목표로 합니다.

* **API 요약본**
  👉 `docs/api/ott-api-summary.md`
  (엔드포인트/헤더/공통 규칙을 빠르게 파악하기 위한 문서)

* **API 상세본 (v1)**
  👉 `docs/api/ott-api-v1.md`
  (Request/Response, 에러 코드, 설계 의도까지 포함한 계약 문서)

주요 설계 포인트:

* 프로필 컨텍스트 분리를 위한 `X-Profile-Id` 헤더 정책
* 영화/시리즈 통합 모델
  (영화: `episode_id = null`, 시리즈: 실제 `episode_id`)
* 공통 Response Envelope 구조
* ISO 8601 시간 표준화(UTC 기반)
* v1 / v2 단계적 확장 전략

---

## 5. DB 실행(로컬) - v1 권장

> v1은 v0 기반으로 제약/정합성 보강 및 Refresh Token 저장 전략을 포함한 버전입니다.
> 기본 개발/검증은 v1을 기준으로 진행합니다. (v0는 비교/재현 용도로 유지)

### 5-1. DB 생성(선택)

```bash
mysql -u root -p -e "CREATE DATABASE IF NOT EXISTS ott_service DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_0900_ai_ci;"
```

### 5-2. 스키마 적용(v1)

```bash
mysql -u root -p ott_service < docs/db/ott-db-v1-schema.sql
```

### 5-3. 데모 Seed 적용(v1, catalog-only)

> GitHub 공개를 전제로 **catalog-only(public-safe)** 데이터만 포함합니다.
> users/profiles/subscriptions/payments/watch/review 등 사용자 데이터는 포함하지 않습니다.

```bash
mysql -u root -p ott_service < docs/db/ott-db-v1-seed.sql
```

---

## 6. 기술 스택

### Backend (구현 예정)

* Java 17+
* Spring Boot
* Spring MVC, Spring Security
* JPA / Hibernate
* MySQL

### Frontend (구현 예정)

* React
* JavaScript (TypeScript 도입 검토)

### Tools

* Git / GitHub
* ERD Cloud (DB 설계)
* Figma (와이어프레임 디자인)

---

## 7. Roadmap

본 프로젝트는 **설계 → 계약(API) → 구현** 흐름으로 단계적으로 진행됩니다.

* [x] 서비스 화면 흐름 및 핵심 기능 러프 정의
* [x] 데스크톱 웹 와이어프레임(Figma) 설계
* [x] ERD 설계 및 MySQL DB 스키마 구현 (v0)
* [x] REST API v1 설계 (요약본 + 상세 명세)
* [x] DB/ERD v1 보완(제약 하드닝, Refresh Token 저장 전략 포함)
* [ ] 백엔드(Spring Boot) 구현
* [ ] 프론트엔드(React) 구현
* [ ] 샘플 데이터 기반 데모 & 배포

---

## 8. Notes

* 본 레포지토리는 **학습 및 포트폴리오 목적**의 개인 프로젝트입니다.
* 설계 → 구현 → 개선의 전 과정을 Git 커밋 히스토리로 남겨
  **“서비스를 어떻게 구조화하고 확장하는지”** 를 보여주는 것을 목표로 합니다.
