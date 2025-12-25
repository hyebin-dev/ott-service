/* =========================================================
   ott-db-v1-schema.sql (MySQL executable DDL) - Portfolio
   - Based on v0, hardened constraints + auth refresh token storage
   - Engine: InnoDB
   - Charset: utf8mb4
   ========================================================= */
   
-- (DB 생성/USE는 실행 커맨드에서 통제)
-- ===== Database =====
-- CREATE DATABASE IF NOT EXISTS ott_service
--   DEFAULT CHARACTER SET utf8mb4
--   DEFAULT COLLATE utf8mb4_0900_ai_ci;

-- USE ott_service;

-- ===== 회원/인증 =====
CREATE TABLE IF NOT EXISTS users (
  user_id        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  email          VARCHAR(255) NOT NULL,
  password_hash  VARCHAR(255) NULL,
  name           VARCHAR(50)  NOT NULL,
  phone          VARCHAR(20)  NULL,
  birth_date     DATE         NULL,
  gender         ENUM('MALE','FEMALE','NONE') NOT NULL DEFAULT 'NONE',
  created_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at     DATETIME(3)  NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  status         ENUM('ACTIVE','DELETED') NOT NULL DEFAULT 'ACTIVE',
  PRIMARY KEY (user_id),
  UNIQUE KEY uq_users_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS social_accounts (
  social_id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id            BIGINT UNSIGNED NOT NULL,
  provider           ENUM('KAKAO','GOOGLE','NAVER') NOT NULL,
  provider_user_key  VARCHAR(255) NOT NULL,
  connected_at       DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (social_id),
  UNIQUE KEY uq_social_provider_user (provider, provider_user_key),
  UNIQUE KEY uq_social_user_provider (user_id, provider),
  CONSTRAINT fk_social_users
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS terms (
  term_code    ENUM('AGE14','SERVICE','PRIVACY','PAID','MARKETING') NOT NULL,
  name         VARCHAR(100) NOT NULL,
  is_required  BOOLEAN NOT NULL,
  created_at   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (term_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS user_terms_agreement (
  agreement_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id      BIGINT UNSIGNED NOT NULL,
  term_code    ENUM('AGE14','SERVICE','PRIVACY','PAID','MARKETING') NOT NULL,
  agreed_at    DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (agreement_id),
  UNIQUE KEY uq_user_term (user_id, term_code),
  CONSTRAINT fk_uta_users
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_uta_terms
    FOREIGN KEY (term_code) REFERENCES terms(term_code)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- [v1 추가] Refresh Token 서버 저장(원문 저장 금지: 해시 저장)
CREATE TABLE IF NOT EXISTS refresh_tokens (
  token_id         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id          BIGINT UNSIGNED NOT NULL,
  token_hash       CHAR(64) NOT NULL,
  issued_at        DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  expires_at       DATETIME(3) NOT NULL,
  revoked_at       DATETIME(3) NULL,
  replaced_by_id   BIGINT UNSIGNED NULL,
  user_agent       VARCHAR(255) NULL,
  ip_address       VARCHAR(45) NULL,
  PRIMARY KEY (token_id),
  UNIQUE KEY uq_refresh_token_hash (token_hash),
  KEY idx_rt_user_expires (user_id, expires_at),
  KEY idx_rt_user_revoked (user_id, revoked_at),
  CONSTRAINT fk_rt_users
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_rt_replaced_by
    FOREIGN KEY (replaced_by_id) REFERENCES refresh_tokens(token_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ===== 요금제/구독/결제 =====
CREATE TABLE IF NOT EXISTS plans (
  plan_id        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name           ENUM('BASIC','STANDARD','PREMIUM') NOT NULL,
  price_monthly  INT UNSIGNED NOT NULL,
  max_quality    ENUM('SD','HD','UHD') NOT NULL,
  max_screens    TINYINT UNSIGNED NOT NULL,
  description    VARCHAR(255) NULL,
  is_active      BOOLEAN NOT NULL DEFAULT 1,
  PRIMARY KEY (plan_id),
  UNIQUE KEY uq_plans_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS subscriptions (
  subscription_id        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id                BIGINT UNSIGNED NOT NULL,
  plan_id                BIGINT UNSIGNED NOT NULL,
  status                 ENUM('ACTIVE','CANCELED','EXPIRED') NOT NULL DEFAULT 'ACTIVE',
  start_date             DATE NOT NULL,
  next_billing_date      DATE NOT NULL,
  end_date               DATE NULL,
  canceled_at            DATETIME(3) NULL,
  billing_price_monthly  INT UNSIGNED NOT NULL,
  created_at             DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at             DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (subscription_id),
  KEY idx_subscriptions_user_status (user_id, status),
  CONSTRAINT fk_sub_users
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_sub_plans
    FOREIGN KEY (plan_id) REFERENCES plans(plan_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS promo_codes (
  promo_id        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  code            VARCHAR(50) NOT NULL,
  discount_type   ENUM('PERCENT','AMOUNT','FREE_TRIAL') NOT NULL,
  discount_value  INT UNSIGNED NOT NULL,
  expires_at      DATETIME(3) NOT NULL,
  is_active       BOOLEAN NOT NULL DEFAULT 1,
  created_at      DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (promo_id),
  UNIQUE KEY uq_promo_code (code),
  CONSTRAINT chk_promo_discount_value
    CHECK (
      (discount_type = 'PERCENT'     AND discount_value BETWEEN 0 AND 100)
      OR
      (discount_type = 'AMOUNT'      AND discount_value >= 0)
      OR
      (discount_type = 'FREE_TRIAL'  AND discount_value >= 1)
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS payments (
  payment_id       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  subscription_id  BIGINT UNSIGNED NOT NULL,
  method           ENUM('CARD','KAKAOPAY','TOSSPAY','NAVERPAY') NOT NULL,
  card_company     VARCHAR(30) NULL,
  card_holder_name VARCHAR(50) NULL,
  card_last4       CHAR(4) NULL,
  amount           INT UNSIGNED NOT NULL,
  promo_id         BIGINT UNSIGNED NULL,
  paid_at          DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  result           ENUM('SUCCESS','FAIL') NOT NULL,
  PRIMARY KEY (payment_id),
  KEY idx_payments_subscription_paidat (subscription_id, paid_at),
  CONSTRAINT fk_pay_subscriptions
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(subscription_id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_pay_promos
    FOREIGN KEY (promo_id) REFERENCES promo_codes(promo_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ===== 프로필 =====
CREATE TABLE IF NOT EXISTS profiles (
  profile_id    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id       BIGINT UNSIGNED NOT NULL,
  name          VARCHAR(20) NOT NULL,
  avatar_code   VARCHAR(30) NOT NULL DEFAULT 'DEFAULT_1',
  is_kids       BOOLEAN NOT NULL DEFAULT 0,
  pin_enabled   BOOLEAN NOT NULL DEFAULT 0,
  pin_hash      VARCHAR(255) NULL,
  created_at    DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  is_active     BOOLEAN NOT NULL DEFAULT 1,
  updated_at    DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (profile_id),
  CONSTRAINT fk_profiles_users
    FOREIGN KEY (user_id) REFERENCES users(user_id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS profile_settings (
  profile_id             BIGINT UNSIGNED NOT NULL,
  ui_lang                ENUM('ko','en') NOT NULL DEFAULT 'ko',
  subtitle_lang          ENUM('auto','ko','en','off') NOT NULL DEFAULT 'auto',
  audio_lang             ENUM('auto','ko','en') NOT NULL DEFAULT 'auto',
  autoplay_next          BOOLEAN NOT NULL DEFAULT 1,
  autoplay_preview       BOOLEAN NOT NULL DEFAULT 1,
  quality_mode           ENUM('auto','low','mid','high') NOT NULL DEFAULT 'auto',
  notify_new_episode     BOOLEAN NOT NULL DEFAULT 1,
  notify_recommendation  BOOLEAN NOT NULL DEFAULT 1,
  notify_continue        BOOLEAN NOT NULL DEFAULT 1,
  max_age_rating         ENUM('ALL','7','12','15','19') NOT NULL DEFAULT 'ALL',
  PRIMARY KEY (profile_id),
  CONSTRAINT fk_ps_profiles
    FOREIGN KEY (profile_id) REFERENCES profiles(profile_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS subtitle_style (
  profile_id        BIGINT UNSIGNED NOT NULL,
  font_family       VARCHAR(50) NOT NULL DEFAULT 'default',
  font_size         ENUM('small','medium','large') NOT NULL DEFAULT 'medium',
  font_color        CHAR(7) NOT NULL DEFAULT '#FFFFFF',
  shadow_enabled    BOOLEAN NOT NULL DEFAULT 1,
  shadow_color      CHAR(7) NULL,
  background_color  CHAR(7) NULL,
  window_color      CHAR(7) NULL,
  preset            ENUM('default','custom') NOT NULL DEFAULT 'default',
  PRIMARY KEY (profile_id),
  CONSTRAINT fk_ss_profiles
    FOREIGN KEY (profile_id) REFERENCES profiles(profile_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ===== 콘텐츠 =====
CREATE TABLE IF NOT EXISTS contents (
  content_id      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  title_kr        VARCHAR(200) NOT NULL,
  title_en        VARCHAR(200) NULL,
  type            ENUM('MOVIE','SERIES') NOT NULL,
  synopsis_short  VARCHAR(500) NOT NULL,
  synopsis_long   TEXT NULL,
  release_year    YEAR NOT NULL,
  country         VARCHAR(50) NOT NULL,
  age_rating      ENUM('ALL','7','12','15','19') NOT NULL,
  runtime_min     SMALLINT UNSIGNED NULL,
  poster_url      VARCHAR(500) NOT NULL,
  backdrop_url    VARCHAR(500) NULL,
  trailer_url     VARCHAR(500) NULL,
  created_at      DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  is_active       BOOLEAN NOT NULL DEFAULT 1,
  PRIMARY KEY (content_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS genres (
  genre_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name     VARCHAR(50) NOT NULL,
  PRIMARY KEY (genre_id),
  UNIQUE KEY uq_genres_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS content_genres (
  content_id BIGINT UNSIGNED NOT NULL,
  genre_id   BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (content_id, genre_id),
  CONSTRAINT fk_cg_contents
    FOREIGN KEY (content_id) REFERENCES contents(content_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_cg_genres
    FOREIGN KEY (genre_id) REFERENCES genres(genre_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS people (
  person_id   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  name        VARCHAR(100) NOT NULL,
  created_at  DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (person_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS content_people (
  content_id      BIGINT UNSIGNED NOT NULL,
  person_id       BIGINT UNSIGNED NOT NULL,
  role_detail     ENUM('ACTOR','DIRECTOR','PRODUCER') NOT NULL,
  character_name  VARCHAR(100) NULL,
  PRIMARY KEY (content_id, person_id, role_detail),
  CONSTRAINT fk_cp_contents
    FOREIGN KEY (content_id) REFERENCES contents(content_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_cp_people
    FOREIGN KEY (person_id) REFERENCES people(person_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ===== 시리즈 구조(시리즈만) =====
CREATE TABLE IF NOT EXISTS seasons (
  season_id      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  content_id     BIGINT UNSIGNED NOT NULL,
  season_number  SMALLINT UNSIGNED NOT NULL,
  release_date   DATE NOT NULL,
  PRIMARY KEY (season_id),
  UNIQUE KEY uq_season_content_number (content_id, season_number),
  CONSTRAINT fk_seasons_contents
    FOREIGN KEY (content_id) REFERENCES contents(content_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS episodes (
  episode_id      BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  season_id       BIGINT UNSIGNED NOT NULL,
  episode_number  SMALLINT UNSIGNED NOT NULL,
  title           VARCHAR(200) NOT NULL,
  synopsis        TEXT NULL,
  runtime_min     SMALLINT UNSIGNED NOT NULL,
  video_url       VARCHAR(500) NULL,
  release_date    DATE NOT NULL,
  PRIMARY KEY (episode_id),
  UNIQUE KEY uq_episode_season_number (season_id, episode_number),
  CONSTRAINT fk_episodes_seasons
    FOREIGN KEY (season_id) REFERENCES seasons(season_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ===== 사용자 행동 데이터 =====
CREATE TABLE IF NOT EXISTS wishlists (
  wishlist_id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  profile_id  BIGINT UNSIGNED NOT NULL,
  content_id  BIGINT UNSIGNED NOT NULL,
  created_at  DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (wishlist_id),
  UNIQUE KEY uq_wishlist_profile_content (profile_id, content_id),
  CONSTRAINT fk_wl_profiles
    FOREIGN KEY (profile_id) REFERENCES profiles(profile_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_wl_contents
    FOREIGN KEY (content_id) REFERENCES contents(content_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS watch_histories (
  history_id       BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  profile_id       BIGINT UNSIGNED NOT NULL,
  content_id       BIGINT UNSIGNED NOT NULL,
  episode_id       BIGINT UNSIGNED NULL,
  episode_key      BIGINT UNSIGNED
                   GENERATED ALWAYS AS (IFNULL(episode_id, 0)) STORED,
  progress_sec     INT UNSIGNED NOT NULL DEFAULT 0,
  duration_sec     INT UNSIGNED NOT NULL,
  is_finished      BOOLEAN NOT NULL DEFAULT 0,
  is_hidden        BOOLEAN NOT NULL DEFAULT 0,
  last_watched_at  DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  created_at       DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (history_id),
  UNIQUE KEY uq_wh_profile_content_episodekey (profile_id, content_id, episode_key),
  KEY idx_wh_profile_hidden_last (profile_id, is_hidden, last_watched_at),
  CONSTRAINT fk_wh_profiles
    FOREIGN KEY (profile_id) REFERENCES profiles(profile_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_wh_contents
    FOREIGN KEY (content_id) REFERENCES contents(content_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  -- CONSTRAINT fk_wh_episodes
  --   FOREIGN KEY (episode_id) REFERENCES episodes(episode_id)
  --   ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT chk_wh_progress_duration
    CHECK (progress_sec >= 0 AND duration_sec > 0 AND progress_sec <= duration_sec)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS watch_sessions (
  session_id   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  profile_id   BIGINT UNSIGNED NOT NULL,
  content_id   BIGINT UNSIGNED NOT NULL,
  episode_id   BIGINT UNSIGNED NULL,
  started_at   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  ended_at     DATETIME(3) NULL,
  watched_sec  INT UNSIGNED NOT NULL DEFAULT 0,
  device_type  ENUM('WEB','MOBILE','TV') NULL,
  PRIMARY KEY (session_id),
  KEY idx_ws_profile_started (profile_id, started_at),
  CONSTRAINT fk_ws_profiles
    FOREIGN KEY (profile_id) REFERENCES profiles(profile_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_ws_contents
    FOREIGN KEY (content_id) REFERENCES contents(content_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_ws_episodes
    FOREIGN KEY (episode_id) REFERENCES episodes(episode_id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT chk_ws_times
    CHECK (ended_at IS NULL OR ended_at >= started_at),
  CONSTRAINT chk_ws_watched_sec
    CHECK (watched_sec >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS reviews (
  review_id   BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  profile_id  BIGINT UNSIGNED NOT NULL,
  content_id  BIGINT UNSIGNED NOT NULL,
  rating      DECIMAL(2,1) NOT NULL,
  title       VARCHAR(100) NOT NULL,
  body        TEXT NOT NULL,
  spoiler     BOOLEAN NOT NULL DEFAULT 0,
  is_private  BOOLEAN NOT NULL DEFAULT 0,
  created_at  DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  updated_at  DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
  PRIMARY KEY (review_id),
  UNIQUE KEY uq_review_profile_content (profile_id, content_id),
  CONSTRAINT fk_reviews_profiles
    FOREIGN KEY (profile_id) REFERENCES profiles(profile_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_reviews_contents
    FOREIGN KEY (content_id) REFERENCES contents(content_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT chk_reviews_rating
    CHECK (rating >= 0.0 AND rating <= 5.0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS content_blocks (
  block_id    BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  profile_id  BIGINT UNSIGNED NOT NULL,
  content_id  BIGINT UNSIGNED NOT NULL,
  reason      VARCHAR(255) NULL,
  created_at  DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (block_id),
  UNIQUE KEY uq_cb_profile_content (profile_id, content_id),
  CONSTRAINT fk_cb_profiles
    FOREIGN KEY (profile_id) REFERENCES profiles(profile_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_cb_contents
    FOREIGN KEY (content_id) REFERENCES contents(content_id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ===== Watch Party (Phase2) =====
CREATE TABLE IF NOT EXISTS watch_party_rooms (
  room_id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  host_profile_id  BIGINT UNSIGNED NOT NULL,
  content_id       BIGINT UNSIGNED NOT NULL,
  episode_id       BIGINT UNSIGNED NULL,
  room_name        VARCHAR(100) NOT NULL,
  join_code        CHAR(8) NOT NULL,
  status           ENUM('OPEN','CLOSED') NOT NULL DEFAULT 'OPEN',
  created_at       DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (room_id),
  UNIQUE KEY uq_wpr_join_code (join_code),
  CONSTRAINT fk_wpr_profiles
    FOREIGN KEY (host_profile_id) REFERENCES profiles(profile_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_wpr_contents
    FOREIGN KEY (content_id) REFERENCES contents(content_id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_wpr_episodes
    FOREIGN KEY (episode_id) REFERENCES episodes(episode_id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS watch_party_members (
  room_id     BIGINT UNSIGNED NOT NULL,
  profile_id  BIGINT UNSIGNED NOT NULL,
  joined_at   DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (room_id, profile_id),
  -- CONSTRAINT fk_wpm_rooms
  --   FOREIGN KEY (room_id) REFERENCES watch_party_rooms(room_id)
  --   ON DELETE CASCADE ON UPDATE CASCADE,
  -- CONSTRAINT fk_wpm_messages_rooms
  -- FOREIGN KEY (room_id) REFERENCES watch_party_rooms(room_id)
  -- ON DELETE CASCADE ON UPDATE CASCADE,
  -- CONSTRAINT fk_wpm_profiles
  --   FOREIGN KEY (profile_id) REFERENCES profiles(profile_id)
  --   ON DELETE CASCADE ON UPDATE CASCADE
  CONSTRAINT fk_watch_party_members_room
  FOREIGN KEY (room_id) REFERENCES watch_party_rooms(room_id)
  ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_watch_party_members_profile
  FOREIGN KEY (profile_id) REFERENCES profiles(profile_id)
  ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS watch_party_messages (
  message_id  BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  room_id     BIGINT UNSIGNED NOT NULL,
  profile_id  BIGINT UNSIGNED NOT NULL,
  body        TEXT NOT NULL,
  sent_at     DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (message_id),
  KEY idx_wpm_room_sent (room_id, sent_at),
  -- CONSTRAINT fk_wpm_rooms
  --   FOREIGN KEY (room_id) REFERENCES watch_party_rooms(room_id)
  --   ON DELETE CASCADE ON UPDATE CASCADE,
  -- CONSTRAINT fk_wpm_profiles
  --   FOREIGN KEY (profile_id) REFERENCES profiles(profile_id)
  --   ON DELETE CASCADE ON UPDATE CASCADE
  CONSTRAINT fk_watch_party_messages_room
  FOREIGN KEY (room_id) REFERENCES watch_party_rooms(room_id)
  ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_watch_party_messages_profile
  FOREIGN KEY (profile_id) REFERENCES profiles(profile_id)
  ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- -- ===== FK 보강 (DDL 분리 생성) =====
-- ALTER TABLE watch_histories
--   ADD CONSTRAINT fk_wh_episodes
--     FOREIGN KEY (episode_id) REFERENCES episodes(episode_id)
--     ON DELETE SET NULL ON UPDATE CASCADE;

-- fk_wh_episodes 제거 (v1)
-- episode_id는 애플리케이션 로직에서만 유효성 보장
