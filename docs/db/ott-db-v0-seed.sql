/* =========================================================
   ott-db-v0-seed.sql (Public demo seed data) - Portfolio
   - Purpose: Safe/minimal seed for GitHub (catalog-only)
   - Notes:
     * NO users/profiles/subscriptions/payments/watch data
     * Only catalog: plans/terms/genres/contents/seasons/episodes/people/mappings
     * Execute AFTER: ott-db-v0-schema.sql
   ========================================================= */

USE ott_service;

-- ---------- plans ----------
INSERT INTO plans (plan_id, name, price_monthly, max_quality, max_screens, description, is_active)
VALUES
  (1, 'BASIC',    9500,  'HD', 1, '기본 요금제', 1),
  (2, 'STANDARD', 13500, 'HD', 2, '스탠다드 요금제', 1),
  (3, 'PREMIUM',  17000, 'UHD', 4, '프리미엄 요금제', 1)
ON DUPLICATE KEY UPDATE
  price_monthly = VALUES(price_monthly),
  max_quality   = VALUES(max_quality),
  max_screens   = VALUES(max_screens),
  description   = VALUES(description),
  is_active     = VALUES(is_active);

-- ---------- terms ----------
INSERT INTO terms (term_code, name, is_required, created_at)
VALUES
  ('AGE14',     '만 14세 이상 확인', 1, CURRENT_TIMESTAMP(3)),
  ('SERVICE',   '서비스 이용약관',   1, CURRENT_TIMESTAMP(3)),
  ('PRIVACY',   '개인정보 처리방침', 1, CURRENT_TIMESTAMP(3)),
  ('PAID',      '유료 결제 약관',    1, CURRENT_TIMESTAMP(3)),
  ('MARKETING', '마케팅 수신 동의',  0, CURRENT_TIMESTAMP(3))
ON DUPLICATE KEY UPDATE
  name        = VALUES(name),
  is_required = VALUES(is_required);

-- ---------- genres ----------
INSERT INTO genres (genre_id, name)
VALUES
  (1, 'SF'),
  (2, '액션'),
  (3, '어드벤처'),
  (4, '리얼리티'),
  (5, '예능'),
  (6, '요리')
ON DUPLICATE KEY UPDATE
  name = VALUES(name);

-- ---------- contents ----------
-- MOVIE: 아바타: 불과 재
-- SERIES: 흑백요리사 (시즌 1/2는 seasons에)
INSERT INTO contents (
  content_id, title_kr, title_en, type,
  synopsis_short, synopsis_long,
  release_year, country, age_rating,
  runtime_min, poster_url, backdrop_url, trailer_url,
  is_active, created_at
)
VALUES
  (
    1, '아바타: 불과 재', 'Avatar: Fire and Ash', 'MOVIE',
    '판도라에서 다시 시작되는 거대한 전쟁과 선택의 이야기.',
    NULL,
    2025, 'US', '12',
    190,
    'https://example.com/posters/avatar_fire_ash.jpg',
    'https://example.com/backdrops/avatar_fire_ash.jpg',
    'https://example.com/trailers/avatar_fire_ash.mp4',
    1, CURRENT_TIMESTAMP(3)
  ),
  (
    2, '흑백요리사', 'Culinary Class Wars', 'SERIES',
    '흑과 백, 서로 다른 철학의 셰프들이 한 무대에서 맞붙는다.',
    NULL,
    2024, 'KR', '12',
    NULL,
    'https://example.com/posters/culinary_class_wars.jpg',
    'https://example.com/backdrops/culinary_class_wars.jpg',
    NULL,
    1, CURRENT_TIMESTAMP(3)
  )
ON DUPLICATE KEY UPDATE
  title_kr       = VALUES(title_kr),
  title_en       = VALUES(title_en),
  type           = VALUES(type),
  synopsis_short = VALUES(synopsis_short),
  synopsis_long  = VALUES(synopsis_long),
  release_year   = VALUES(release_year),
  country        = VALUES(country),
  age_rating     = VALUES(age_rating),
  runtime_min    = VALUES(runtime_min),
  poster_url     = VALUES(poster_url),
  backdrop_url   = VALUES(backdrop_url),
  trailer_url    = VALUES(trailer_url),
  is_active      = VALUES(is_active);

-- ---------- seasons ----------
INSERT INTO seasons (season_id, content_id, season_number, release_date)
VALUES
  (1, 2, 1, '2024-09-01'),
  (2, 2, 2, '2025-03-01')
ON DUPLICATE KEY UPDATE
  content_id    = VALUES(content_id),
  season_number = VALUES(season_number),
  release_date  = VALUES(release_date);

-- ---------- episodes ----------
-- (예시) 시즌1 2화, 시즌2 2화만 넣음
INSERT INTO episodes (
  episode_id, season_id, episode_number,
  title, synopsis, runtime_min, video_url, release_date
)
VALUES
  (1, 1, 1, '1화: 첫 대결', '첫 미션에서 셰프들의 철학이 정면충돌한다.', 55, 'https://example.com/videos/ccw_s1e1.mp4', '2024-09-01'),
  (2, 1, 2, '2화: 불의 균형', '불과 칼, 시간과 온도의 싸움이 시작된다.',     57, 'https://example.com/videos/ccw_s1e2.mp4', '2024-09-08'),
  (3, 2, 1, '시즌2 1화: 리매치', '더 강해진 규칙, 더 강해진 참가자들이 돌아온다.', 58, 'https://example.com/videos/ccw_s2e1.mp4', '2025-03-01'),
  (4, 2, 2, '시즌2 2화: 팀 미션', '협업 속에서 진짜 실력이 드러난다.',             60, 'https://example.com/videos/ccw_s2e2.mp4', '2025-03-08')
ON DUPLICATE KEY UPDATE
  season_id     = VALUES(season_id),
  episode_number= VALUES(episode_number),
  title         = VALUES(title),
  synopsis      = VALUES(synopsis),
  runtime_min   = VALUES(runtime_min),
  video_url     = VALUES(video_url),
  release_date  = VALUES(release_date);

-- ---------- content_genres ----------
INSERT INTO content_genres (content_id, genre_id)
VALUES
  (1, 1), -- Avatar: SF
  (1, 2), -- Avatar: Action
  (1, 3), -- Avatar: Adventure
  (2, 4), -- 흑백요리사: Reality
  (2, 5), -- 흑백요리사: Variety
  (2, 6)  -- 흑백요리사: Cooking
ON DUPLICATE KEY UPDATE
  content_id = content_id;

-- ---------- people ----------
INSERT INTO people (person_id, name, created_at)
VALUES
  (1, '제임스 카메론', CURRENT_TIMESTAMP(3)),
  (2, '샘 워딩턴',     CURRENT_TIMESTAMP(3)),
  (3, '조 샐다나',     CURRENT_TIMESTAMP(3)),
  (4, '연출(흑백요리사)', CURRENT_TIMESTAMP(3)),
  (5, '출연(흑백요리사)', CURRENT_TIMESTAMP(3))
ON DUPLICATE KEY UPDATE
  name = VALUES(name);

-- ---------- content_people ----------
INSERT INTO content_people (content_id, person_id, role_detail, character_name)
VALUES
  (1, 1, 'DIRECTOR', NULL),
  (1, 2, 'ACTOR',    '제이크 설리'),
  (1, 3, 'ACTOR',    '네이티리'),
  (2, 4, 'PRODUCER', NULL),
  (2, 5, 'ACTOR',    NULL)
ON DUPLICATE KEY UPDATE
  character_name = VALUES(character_name);
