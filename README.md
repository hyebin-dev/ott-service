# ott-service

구독 기반 OTT 영상 스트리밍 웹 서비스  
**Tech Stack 예정:** Spring Boot + React + MySQL

> 와이어프레임 → DB 설계 → 백엔드/프론트엔드 구현까지  
> OTT 서비스를 처음부터 끝까지 직접 설계·구현하는 개인 프로젝트입니다.

---

## 1. 프로젝트 개요

`ott-service`는 한 계정에 여러 프로필을 두고, 프로필별 시청 경험을 분리해서 관리하는 **구독 기반 OTT 웹 서비스**를 목표로 합니다.

현재 레포에는 **데스크톱 웹 기준 와이어프레임**과 **OTT DB 설계 v0(ERD + SQL DDL)** 가 정리되어 있으며,  
이후 다음 항목들이 순차적으로 추가될 예정입니다.

- MySQL 기반 **DB/ERD 설계 고도화**
- Spring Boot 기반 **백엔드 API**
- React 기반 **프론트엔드 웹 애플리케이션**

---

## 2. 주요 기능 설계

### 2-1. 계정 · 멤버십

- 이메일 회원가입 / 로그인
- 멤버십 플랜 선택(광고형, 스탠다드, 프리미엄 등)
- 결제 수단 등록, 결제 내역 및 다음 결제일 확인
- 멤버십 변경 및 해지 플로우
- 계정 정보 수정 전 **비밀번호 재확인**

### 2-2. 프로필 · 자녀 보호

- 계정당 최대 5개의 프로필 생성  
- 프로필 이미지, 이름, PIN 잠금 설정
- 프로필별 시청 기록 / 추천 / 설정 분리
- 자녀 보호 기능
  - 관람 등급(ALL / 7+ / 12+ / 19+) 슬라이더로 제한
  - 등급과 무관하게 특정 작품 개별 차단

### 2-3. 콘텐츠 탐색

- 홈(메인) 화면
  - 오늘의 TOP 20, 신규 콘텐츠, 회원 맞춤 추천, 장르별 섹션 등
- **영화 / 시리즈 / 찜** 탭 분리
- 작품 상세
  - 시놉시스, 장르, 국가, 러닝타임/시즌 정보
  - 출연/제작 정보, 관련 콘텐츠 추천

### 2-4. 시청 경험

- 웹 플레이어 UI (재생/일시정지, 구간 이동, 음량, 전체 화면 등)
- **이어보기 / 시청 기록** 관리
- 회차 자동 재생(시리즈) 및 재생 종료 후 다음 회차 안내

### 2-5. 리뷰 · 평가

- 별점 + 리뷰 제목 + 한줄평 작성
- 스포일러 포함 여부 체크
- 작품 상세 내 리뷰 목록(정렬: 최신순 등)
- “내가 작성한 리뷰” 목록 / 수정 / 삭제
- 리뷰가 없을 때의 **빈 상태(Empty State)** 화면까지 설계

### 2-6. 보안

- 최근 접속 기기(디바이스) 목록
- 디바이스별 로그인 이력 확인 및 **모든 기기에서 로그아웃**
- 의심스러운 접속이 있을 때 비밀번호 변경을 유도하는 플로우 설계

---

## 3. UX & 와이어프레임

현재 와이어프레임은 **데스크톱 웹 기준**으로, 다음과 같은 플로우를 포함합니다.

- 회원가입 3단계
  1. 이메일 입력
  2. 비밀번호 설정
  3. 이름/휴대폰/생년월일 및 약관 동의
- 로그인, 비밀번호 찾기, 카카오 로그인 버튼
- 프로필 선택 → 프로필 관리 → 프로필 수정(PIN 잠금 포함)
- 홈 / 영화 / 시리즈 / 찜 탭
- 작품 상세 (영화/시리즈, 회차 목록, 관련 콘텐츠)
- 리뷰 작성/목록, 재생 종료 후 간단 리뷰 팝업
- 시청 기록 / 찜 목록 (있을 때, 없을 때 화면)
- 계정 설정(멤버십, 계정 정보, 자녀 보호, 보안)
- 프로필별 화면 설정(자막, 화질/데이터, 자동재생, 알림)

와이어프레임/DB 설계 파일은 다음 경로에서 확인할 수 있습니다.

```text
ott-streaming-wireframes/
└─ docs/
   ├─ wireframes/
   │  └─ desktop/
   │     wf-auth-login.png                     # 로그인
   │     wf-signup-step1-email.png             # 회원가입 1단계 – 이메일
   │     wf-signup-step2-password.png          # 회원가입 2단계 – 비밀번호
   │     wf-signup-step3-profile-info.png      # 회원가입 3단계 – 기본 정보
   │     wf-home-main.png                      # 메인 홈
   │     wf-home-profile-dropdown.png          # 홈 – 프로필 메뉴
   │     wf-movie-list.png                     # 영화 탭
   │     wf-series-list.png                    # 시리즈 탭
   │     wf-movie-detail.png                   # 작품 상세 – 기본
   │     wf-movie-detail-episodes.png          # 작품 상세 – 회차
   │     wf-movie-detail-reviews.png           # 작품 상세 – 리뷰
   │     wf-my-reviews-list.png                # 내 리뷰 목록
   │     wf-my-reviews-empty.png               # 내 리뷰 – 비어 있을 때
   │     wf-watch-history-list.png             # 시청 기록
   │     wf-watch-history-empty.png            # 시청 기록 – 비어 있을 때
   │     wf-wishlist-list.png                  # 찜 목록
   │     wf-wishlist-empty.png                 # 찜 목록 – 비어 있을 때
   │     wf-membership-plan-select.png         # 멤버십 선택
   │     wf-payment-method-card.png            # 결제 수단 선택(카드)
   │     wf-payment-complete.png               # 결제 완료
   │     wf-account-info-edit.png              # 계정 정보 수정
   │     wf-account-membership-manage.png      # 멤버십 관리
   │     wf-account-membership-cancel.png      # 멤버십 해지
   │     wf-account-parental-profile.png       # 자녀 보호 – 프로필 선택
   │     wf-account-parental-rating-limit.png  # 자녀 보호 – 관람 등급 제한
   │     wf-account-security-devices.png       # 보안 – 디바이스 관리
   │     wf-account-verify-before-edit.png     # 정보 변경 전 본인 확인
   │     wf-profile-select.png                 # 프로필 선택
   │     wf-profile-manage.png                 # 프로필 관리
   │     wf-profile-edit.png                   # 프로필 수정
   │     wf-profile-settings.png               # 프로필별 화면 설정
   │     wf-player-default.png                 # 플레이어 기본 화면
   │     wf-player-postplay-review.png         # 재생 종료 후 리뷰 팝업
   │     wf-review-create.png                  # 리뷰 작성 모달
   │     ...
   └─ db/
      ott-db-v0.png                            # OTT 전체 ERD 다이어그램 (v0)
      ott-db-v0.sql                            # MySQL DDL 스키마 (v0)
````

> 와이어프레임 파일명 규칙: `wf-<영역>-<상태>.png`
> DB 설계 파일명 규칙: `ott-db-v<버전>.{png,sql}` 형식으로 버전별 히스토리를 관리합니다.

---

## 4. 기술 스택 (예정)

**Backend**

* Java 17+
* Spring Boot
* Spring MVC, Spring Security
* JPA/Hibernate
* MySQL

**Frontend**

* React
* JavaScript (또는 TypeScript 도입 검토)

**Infra & Tools**

* Git / GitHub
* ERD Cloud (DB 설계)
* 디자인 레퍼런스용 와이어프레임 툴

---

## 5. 디렉터리 구조

> 코드 베이스는 점진적으로 추가될 예정이며, 현재는 설계/와이어프레임/DB 중심 구조입니다.

```text
ott-service/
├─ LICENSE
├─ README.md
├─ .gitignore
└─ ott-streaming-wireframes/
   └─ docs/
      ├─ wireframes/
      │  └─ desktop/
      │     *.png        # OTT 데스크톱 웹 와이어프레임
      └─ db/
         ott-db-v0.png   # OTT DB ERD (v0)
         ott-db-v0.sql   # OTT DB 스키마 DDL (v0)
```

향후 계획:

```text
ott-service/
├─ backend/     # Spring Boot 프로젝트 (예정)
├─ frontend/    # React 프로젝트 (예정)
└─ docs/        # ERD, API 명세 등 설계 문서 (예정)
```

---

## 6. Roadmap

* [x] 데스크톱 웹 와이어프레임 정리 및 업로드
* [x] OTT DB 1차 설계(ERD + SQL DDL, `ott-db-v0`) 업로드
* [ ] DB/ERD 설계 보완 및 문서화
* [ ] 백엔드(Spring Boot) 프로젝트 생성 및 기본 도메인/엔티티 구현
* [ ] 프론트엔드(React) 프로젝트 생성 및 기본 레이아웃 구현
* [ ] 시청/리뷰/찜/자녀 보호 등 핵심 기능 API 및 UI 구현
* [ ] 샘플 데이터 기반 데모 & 배포

---

## 7. Notes

* 이 레포는 **실무용이 아닌 학습 및 포트폴리오 목적**의 개인 프로젝트입니다.
* 설계/구현 과정 전체를 Git 커밋 히스토리로 남겨,
  “서비스를 어떻게 구조화하고 발전시키는지”를 보여주는 것을 목표로 합니다.
