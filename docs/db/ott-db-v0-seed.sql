/* =========================================================
   ott-db-v0-seed.sql (Demo seed data) - Portfolio
   - Purpose: Minimal data to quickly verify schema & relations
   - Notes:
     * IDs are inserted explicitly so 관계(FK) 확인이 쉬움
     * 실행 전: ott-db-v0-schema.sql 을 먼저 실행해야 함
   ========================================================= */

USE ott_service;

-- ---------- plans ----------
INSERT INTO plans (plan_id, name, price_monthly, max_quality, max_screens, description, is_active)
VALUES
  (1, 'BASIC',    9500,  'HD', 1, '기본 요금제', 1),
  (2, 'STANDARD', 13500, 'HD', 2, '스탠다드 요금제', 1),
  (3, 'PREMIUM',  17000, 'UHD', 4, '프리미엄 요금제', 1);

-- ---------- terms ----------
INSERT INTO terms (term_code, name, is_required, created_at)
VALUES
  ('AGE14',    '만 14세 이상 확인', 1, CURRENT_TIMESTAMP(3)),
  ('SERVICE',  '서비스 이용약관',   1, CURRENT_TIMESTAMP(3)),
  ('PRIVACY',  '개인정보 처리방침', 1, CURRENT_TIMESTAMP(3)),
  ('PAID',     '유료 결제 약관',    1, CURRENT_TIMESTAMP(3)),
  ('MARKETING','마케팅 수신 동의',  0, CURRENT_TIMESTAMP(3));

-- ---------- users ----------
INSERT INTO users (user_id, email, password_hash, name, phone, birth_date, gender, status, created_at, updated_at)
VALUES
  (1, 'demo1@example.com', '$2a$10$demo.hash.value.1', '데모유저1', '010-1111-2222', '1999-01-01', 'NONE', 'ACTIVE', CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
  (2, 'demo2@example.com', '$2a$10$demo.hash.value.2', '데모유저2', NULL,            NULL,         'NONE', 'ACTIVE', CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3));

-- ---------- social_accounts (optional demo) ----------
INSERT INTO social_accounts (social_id, user_id, provider, provider_user_key, connected_at)
VALUES
  (1, 1, 'GOOGLE', 'google-demo-user-1', CURRENT_TIMESTAMP(3));

-- ---------- user_terms_agreement ----------
INSERT INTO user_terms_agreement (agreement_id, user_id, term_code, agreed_at)
VALUES
  (1, 1, 'AGE14', CURRENT_TIMESTAMP(3)),
  (2, 1, 'SERVICE', CURRENT_TIMESTAMP(3)),
  (3, 1, 'PRIVACY', CURRENT_TIMESTAMP(3)),
  (4, 1, 'PAID', CURRENT_TIMESTAMP(3)),
  (5, 1, 'MARKETING', CURRENT_TIMESTAMP(3)),
  (6, 2, 'AGE14', CURRENT_TIMESTAMP(3)),
  (7, 2, 'SERVICE', CURRENT_TIMESTAMP(3)),
  (8, 2, 'PRIVACY', CURRENT_TIMESTAMP(3));

-- ---------- profiles ----------
INSERT INTO profiles (profile_id, user_id, name, avatar_code, is_kids, pin_enabled, pin_hash, is_active, created_at, updated_at)
VALUES
  (1, 1, '하이빈', 'DEFAULT_1', 0, 0, NULL, 1, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
  (2, 1, '키즈',   'DEFAULT_2', 1, 0, NULL, 1, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
  (3, 2, '게스트', 'DEFAULT_1', 0, 0, NULL, 1, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3));

-- ---------- profile_settings ----------
INSERT INTO profile_settings (
  profile_id, ui_lang, subtitle_lang, audio_lang,
  autoplay_next, autoplay_preview, quality_mode,
  notify_new_episode, notify_recommendation, notify_continue, max_age_rating
)
VALUES
  (1, 'ko', 'auto', 'auto', 1, 1, 'auto', 1, 1, 1, '19'),
  (2, 'ko', 'ko',   'ko',   1, 1, 'mid',  1, 0, 1, '7'),
  (3, 'en', 'en',   'en',   1, 0, 'high', 0, 1, 1, '19');

-- ---------- subtitle_style ----------
INSERT INTO subtitle_style (
  profile_id, font_family, font_size, font_color,
  shadow_enabled, shadow_color, background_color, window_color, preset
)
VALUES
  (1, 'default', 'medium', '#FFFFFF', 1, '#000000', NULL, NULL, 'default'),
  (2, 'default', 'large',  '#FFFF00', 1, '#000000', NULL, NULL, 'custom'),
  (3, 'default', 'small',  '#FFFFFF', 1, '#000000', NULL, NULL, 'default');

-- ---------- contents ----------
INSERT INTO contents (
  content_id, title_kr, title_en, type,
  synopsis_short, synopsis_long, release_year, country, age_rating,
  runtime_min, poster_url, backdrop_url, trailer_url, is_active, created_at
)
VALUES
  (1, '도시의 밤', 'Night in the City', 'MOVIE',
   '도시에서 벌어지는 미스터리 사건.', NULL, 2024, 'KR', '15',
   112, 'https://example.com/posters/1.jpg', 'https://example.com/backdrops/1.jpg', NULL, 1, CURRENT_TIMESTAMP(3)),
  (2, '스프링의 계절', 'Season of Spring', 'SERIES',
   '새로운 팀에서 성장하는 개발자의 이야기.', NULL, 2025, 'KR', '12',
   NULL, 'https://example.com/posters/2.jpg', 'https://example.com/backdrops/2.jpg', NULL, 1, CURRENT_TIMESTAMP(3));

-- ---------- seasons / episodes (for SERIES content_id=2) ----------
INSERT INTO seasons (season_id, content_id, season_number, release_date)
VALUES
  (1, 2, 1, '2025-01-01');

INSERT INTO episodes (episode_id, season_id, episode_number, title, synopsis, runtime_min, video_url, release_date)
VALUES
  (1, 1, 1, '첫 배포', '첫 번째 배포를 준비한다.', 45, 'https://example.com/videos/ep1.mp4', '2025-01-01'),
  (2, 1, 2, '장애 대응', '예상치 못한 장애가 발생한다.', 48, 'https://example.com/videos/ep2.mp4', '2025-01-08');

-- ---------- genres / content_genres ----------
INSERT INTO genres (genre_id, name)
VALUES
  (1, '드라마'),
  (2, '미스터리'),
  (3, '코미디');

INSERT INTO content_genres (content_id, genre_id)
VALUES
  (1, 2),
  (2, 1),
  (2, 3);

-- ---------- people / content_people ----------
INSERT INTO people (person_id, name, created_at)
VALUES
  (1, '김감독', CURRENT_TIMESTAMP(3)),
  (2, '이배우', CURRENT_TIMESTAMP(3)),
  (3, '박배우', CURRENT_TIMESTAMP(3));

INSERT INTO content_people (content_id, person_id, role_detail, character_name)
VALUES
  (1, 1, 'DIRECTOR', NULL),
  (1, 2, 'ACTOR', '정하늘'),
  (2, 1, 'PRODUCER', NULL),
  (2, 3, 'ACTOR', '민수');

-- ---------- subscriptions / payments ----------
INSERT INTO subscriptions (
  subscription_id, user_id, plan_id, status,
  start_date, next_billing_date, end_date, canceled_at,
  billing_price_monthly, created_at, updated_at
)
VALUES
  (1, 1, 2, 'ACTIVE', '2025-12-01', '2026-01-01', NULL, NULL, 13500, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3));

INSERT INTO payments (
  payment_id, subscription_id, promo_id, method,
  card_company, card_holder_name, card_last4,
  amount, paid_at, result
)
VALUES
  (1, 1, NULL, 'CARD', 'SAMSUNG', '데모유저1', '1234', 13500, CURRENT_TIMESTAMP(3), 'SUCCESS');

-- ---------- wishlists ----------
INSERT INTO wishlists (wishlist_id, profile_id, content_id, created_at)
VALUES
  (1, 1, 1, CURRENT_TIMESTAMP(3)),
  (2, 1, 2, CURRENT_TIMESTAMP(3)),
  (3, 3, 2, CURRENT_TIMESTAMP(3));

-- ---------- watch_histories ----------
-- MOVIE: episode_id = NULL
INSERT INTO watch_histories (
  history_id, profile_id, content_id, episode_id,
  progress_sec, duration_sec, is_finished, is_hidden,
  last_watched_at, created_at
)
VALUES
  (1, 1, 1, NULL, 1800, 6720, 0, 0, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3)),
  (2, 1, 2, 2,    1200, 2880, 0, 0, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3));

-- ---------- watch_sessions ----------
INSERT INTO watch_sessions (
  session_id, profile_id, content_id, episode_id,
  started_at, ended_at, watched_sec, device_type
)
VALUES
  (1, 1, 1, NULL, CURRENT_TIMESTAMP(3), NULL, 1800, 'WEB'),
  (2, 1, 2, 2,    CURRENT_TIMESTAMP(3), NULL, 1200, 'MOBILE');

-- ---------- reviews ----------
INSERT INTO reviews (
  review_id, profile_id, content_id, rating, title, body,
  spoiler, is_private, created_at, updated_at
)
VALUES
  (1, 1, 1, 4.5, '분위기가 좋아요', '연출과 음악이 인상적이었어요.', 0, 0, CURRENT_TIMESTAMP(3), CURRENT_TIMESTAMP(3));

-- ---------- content_blocks ----------
INSERT INTO content_blocks (block_id, profile_id, content_id, reason, created_at)
VALUES
  (1, 2, 1, '키즈 프로필에서는 제외', CURRENT_TIMESTAMP(3));

-- ---------- watch_party (Phase2 demo) ----------
INSERT INTO watch_party_rooms (
  room_id, host_profile_id, content_id, episode_id,
  room_name, join_code, status, created_at
)
VALUES
  (1, 1, 2, 1, '1화 같이보기', 'AB12CD34', 'OPEN', CURRENT_TIMESTAMP(3));

INSERT INTO watch_party_members (room_id, profile_id, joined_at)
VALUES
  (1, 1, CURRENT_TIMESTAMP(3)),
  (1, 3, CURRENT_TIMESTAMP(3));

INSERT INTO watch_party_messages (message_id, room_id, profile_id, body, sent_at)
VALUES
  (1, 1, 1, '시작해볼까?', CURRENT_TIMESTAMP(3)),
  (2, 1, 3, '좋아요!', CURRENT_TIMESTAMP(3));
