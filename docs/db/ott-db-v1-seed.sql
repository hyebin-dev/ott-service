/* =========================================================
   ott-db-v1-seed.sql (MySQL executable seed) - Portfolio
   - Seed data for demo/dev (public-safe / catalog-only)
   - Notes:
     * NO users/profiles/subscriptions/payments/watch data
     * Safe to re-run (ON DUPLICATE KEY UPDATE / INSERT IGNORE / NOT EXISTS)
     * Execute AFTER: ott-db-v1-schema.sql
   - Engine: InnoDB / Charset: utf8mb4
   ========================================================= */

USE ott_service;

SET NAMES utf8mb4;
SET time_zone = '+09:00';

-- ---------------------------------------------------------
-- 1) terms (약관)
-- ---------------------------------------------------------
INSERT INTO terms (term_code, name, is_required)
VALUES
  ('AGE14',     '만 14세 이상 확인', 1),
  ('SERVICE',   '서비스 이용약관',   1),
  ('PRIVACY',   '개인정보 처리방침', 1),
  ('PAID',      '유료 서비스 약관',  1),
  ('MARKETING', '마케팅 정보 수신',  0)
ON DUPLICATE KEY UPDATE
  name        = VALUES(name),
  is_required = VALUES(is_required);

-- ---------------------------------------------------------
-- 2) plans (요금제)
-- ---------------------------------------------------------
INSERT INTO plans (name, price_monthly, max_quality, max_screens, description, is_active)
VALUES
  ('BASIC',    9500,  'HD',  1, '1인 스트리밍 / HD',  1),
  ('STANDARD', 13500, 'HD',  2, '동시 2명 / HD',      1),
  ('PREMIUM',  17000, 'UHD', 4, '동시 4명 / UHD',     1)
ON DUPLICATE KEY UPDATE
  price_monthly = VALUES(price_monthly),
  max_quality   = VALUES(max_quality),
  max_screens   = VALUES(max_screens),
  description   = VALUES(description),
  is_active     = VALUES(is_active);

-- ---------------------------------------------------------
-- 3) genres (장르)
-- ---------------------------------------------------------
INSERT INTO genres (name)
VALUES
  ('드라마'),
  ('다큐멘터리'),
  ('예능'),
  ('액션'),
  ('SF'),
  ('어드벤처')
ON DUPLICATE KEY UPDATE
  name = VALUES(name);

-- ---------------------------------------------------------
-- 4) people (출연/제작진) - 예시용 가명 데이터
-- ---------------------------------------------------------
INSERT INTO people (name)
SELECT '홍길동'
WHERE NOT EXISTS (SELECT 1 FROM people WHERE name='홍길동');

INSERT INTO people (name)
SELECT '김감독'
WHERE NOT EXISTS (SELECT 1 FROM people WHERE name='김감독');

INSERT INTO people (name)
SELECT '이셰프'
WHERE NOT EXISTS (SELECT 1 FROM people WHERE name='이셰프');

INSERT INTO people (name)
SELECT '박셰프'
WHERE NOT EXISTS (SELECT 1 FROM people WHERE name='박셰프');

-- ---------------------------------------------------------
-- 5) contents (영화/시리즈) - 예시 데이터
--    주의: 포트폴리오 시연용 "예시" 레코드
-- ---------------------------------------------------------

-- 영화: 아바타: 불과 재
INSERT INTO contents
  (title_kr, title_en, type, synopsis_short, synopsis_long, release_year, country, age_rating,
   runtime_min, poster_url, backdrop_url, trailer_url, is_active)
SELECT
  '아바타: 불과 재', 'Avatar: Fire and Ash', 'MOVIE',
  '새로운 위협 속에서 선택을 강요받는 서사.',
  '세계관 확장 속에서 갈등과 연대가 교차하며, 각 인물의 선택이 이야기를 밀어붙인다. (포트폴리오 예시 데이터)',
  2025, 'US', '12',
  175,
  'https://example.com/posters/avatar-fire-ash.jpg',
  'https://example.com/backdrops/avatar-fire-ash.jpg',
  'https://example.com/trailers/avatar-fire-ash.mp4',
  1
WHERE NOT EXISTS (
  SELECT 1
  FROM contents
  WHERE title_kr='아바타: 불과 재' AND type='MOVIE'
);

-- 시리즈: 흑백요리사 1
INSERT INTO contents
  (title_kr, title_en, type, synopsis_short, synopsis_long, release_year, country, age_rating,
   runtime_min, poster_url, backdrop_url, trailer_url, is_active)
SELECT
  '흑백요리사 1', 'Culinary Duel S1', 'SERIES',
  '서로 다른 스타일의 요리사들이 미션으로 승부한다.',
  '미션/평가/탈락 구조를 통해 캐릭터와 서사를 쌓아가는 구성. (포트폴리오 예시 데이터)',
  2024, 'KR', '12',
  NULL,
  'https://example.com/posters/chef-bw-s1.jpg',
  'https://example.com/backdrops/chef-bw-s1.jpg',
  'https://example.com/trailers/chef-bw-s1.mp4',
  1
WHERE NOT EXISTS (
  SELECT 1
  FROM contents
  WHERE title_kr='흑백요리사 1' AND type='SERIES'
);

-- 시리즈: 흑백요리사 2
INSERT INTO contents
  (title_kr, title_en, type, synopsis_short, synopsis_long, release_year, country, age_rating,
   runtime_min, poster_url, backdrop_url, trailer_url, is_active)
SELECT
  '흑백요리사 2', 'Culinary Duel S2', 'SERIES',
  '룰이 강화된 시즌, 더 어려워진 미션과 팀전.',
  '경쟁 구조가 진화하며 관계/전략 요소가 커지는 시즌. (포트폴리오 예시 데이터)',
  2025, 'KR', '12',
  NULL,
  'https://example.com/posters/chef-bw-s2.jpg',
  'https://example.com/backdrops/chef-bw-s2.jpg',
  'https://example.com/trailers/chef-bw-s2.mp4',
  1
WHERE NOT EXISTS (
  SELECT 1
  FROM contents
  WHERE title_kr='흑백요리사 2' AND type='SERIES'
);

-- ---------------------------------------------------------
-- 6) content_genres (콘텐츠-장르 매핑)
-- ---------------------------------------------------------

-- 아바타: 불과 재 → SF/액션/어드벤처
INSERT IGNORE INTO content_genres (content_id, genre_id)
SELECT c.content_id, g.genre_id
FROM contents c
JOIN genres g ON g.name IN ('SF','액션','어드벤처')
WHERE c.title_kr='아바타: 불과 재' AND c.type='MOVIE';

-- 흑백요리사 1 → 예능/다큐멘터리(예시)
INSERT IGNORE INTO content_genres (content_id, genre_id)
SELECT c.content_id, g.genre_id
FROM contents c
JOIN genres g ON g.name IN ('예능','다큐멘터리')
WHERE c.title_kr='흑백요리사 1' AND c.type='SERIES';

-- 흑백요리사 2 → 예능/다큐멘터리(예시)
INSERT IGNORE INTO content_genres (content_id, genre_id)
SELECT c.content_id, g.genre_id
FROM contents c
JOIN genres g ON g.name IN ('예능','다큐멘터리')
WHERE c.title_kr='흑백요리사 2' AND c.type='SERIES';

-- ---------------------------------------------------------
-- 7) content_people (콘텐츠-인물 매핑) - 예시용
-- ---------------------------------------------------------

-- 아바타: 불과 재 → 감독(김감독), 배우(홍길동)
INSERT IGNORE INTO content_people (content_id, person_id, role_detail, character_name)
SELECT c.content_id, p.person_id, 'DIRECTOR', NULL
FROM contents c
JOIN people p ON p.name='김감독'
WHERE c.title_kr='아바타: 불과 재' AND c.type='MOVIE';

INSERT IGNORE INTO content_people (content_id, person_id, role_detail, character_name)
SELECT c.content_id, p.person_id, 'ACTOR', '주인공'
FROM contents c
JOIN people p ON p.name='홍길동'
WHERE c.title_kr='아바타: 불과 재' AND c.type='MOVIE';

-- 흑백요리사 1 → 출연(이셰프/박셰프)
INSERT IGNORE INTO content_people (content_id, person_id, role_detail, character_name)
SELECT c.content_id, p.person_id, 'ACTOR', '참가자'
FROM contents c
JOIN people p ON p.name='이셰프'
WHERE c.title_kr='흑백요리사 1' AND c.type='SERIES';

INSERT IGNORE INTO content_people (content_id, person_id, role_detail, character_name)
SELECT c.content_id, p.person_id, 'ACTOR', '참가자'
FROM contents c
JOIN people p ON p.name='박셰프'
WHERE c.title_kr='흑백요리사 1' AND c.type='SERIES';

-- 흑백요리사 2 → 출연(이셰프/박셰프)
INSERT IGNORE INTO content_people (content_id, person_id, role_detail, character_name)
SELECT c.content_id, p.person_id, 'ACTOR', '참가자'
FROM contents c
JOIN people p ON p.name='이셰프'
WHERE c.title_kr='흑백요리사 2' AND c.type='SERIES';

INSERT IGNORE INTO content_people (content_id, person_id, role_detail, character_name)
SELECT c.content_id, p.person_id, 'ACTOR', '참가자'
FROM contents c
JOIN people p ON p.name='박셰프'
WHERE c.title_kr='흑백요리사 2' AND c.type='SERIES';

-- ---------------------------------------------------------
-- 8) seasons / episodes (시리즈 구조)
--    흑백요리사 1 = 시즌1 (content 기준)
--    흑백요리사 2 = 시즌1 (content 기준)
-- ---------------------------------------------------------

-- 흑백요리사 1 → 시즌 1
INSERT INTO seasons (content_id, season_number, release_date)
SELECT c.content_id, 1, '2024-09-01'
FROM contents c
WHERE c.title_kr='흑백요리사 1' AND c.type='SERIES'
ON DUPLICATE KEY UPDATE
  release_date = VALUES(release_date);

-- 흑백요리사 1 → E1~E3
INSERT INTO episodes (season_id, episode_number, title, synopsis, runtime_min, video_url, release_date)
SELECT s.season_id, 1, '1화: 첫 미션', '첫 대결이 시작된다. (예시)', 62,
       'https://example.com/videos/bwchef1-e1.mp4', '2024-09-01'
FROM seasons s
JOIN contents c ON c.content_id=s.content_id
WHERE c.title_kr='흑백요리사 1' AND s.season_number=1
ON DUPLICATE KEY UPDATE
  title       = VALUES(title),
  synopsis    = VALUES(synopsis),
  runtime_min = VALUES(runtime_min),
  video_url   = VALUES(video_url),
  release_date= VALUES(release_date);

INSERT INTO episodes (season_id, episode_number, title, synopsis, runtime_min, video_url, release_date)
SELECT s.season_id, 2, '2화: 제한 시간', '시간 압박 속 전략이 갈린다. (예시)', 64,
       'https://example.com/videos/bwchef1-e2.mp4', '2024-09-08'
FROM seasons s
JOIN contents c ON c.content_id=s.content_id
WHERE c.title_kr='흑백요리사 1' AND s.season_number=1
ON DUPLICATE KEY UPDATE
  title       = VALUES(title),
  synopsis    = VALUES(synopsis),
  runtime_min = VALUES(runtime_min),
  video_url   = VALUES(video_url),
  release_date= VALUES(release_date);

INSERT INTO episodes (season_id, episode_number, title, synopsis, runtime_min, video_url, release_date)
SELECT s.season_id, 3, '3화: 팀전', '협업이 곧 실력이다. (예시)', 66,
       'https://example.com/videos/bwchef1-e3.mp4', '2024-09-15'
FROM seasons s
JOIN contents c ON c.content_id=s.content_id
WHERE c.title_kr='흑백요리사 1' AND s.season_number=1
ON DUPLICATE KEY UPDATE
  title       = VALUES(title),
  synopsis    = VALUES(synopsis),
  runtime_min = VALUES(runtime_min),
  video_url   = VALUES(video_url),
  release_date= VALUES(release_date);

-- 흑백요리사 2 → 시즌 1 (별도 content라서 season_number는 1로 시작)
INSERT INTO seasons (content_id, season_number, release_date)
SELECT c.content_id, 1, '2025-09-01'
FROM contents c
WHERE c.title_kr='흑백요리사 2' AND c.type='SERIES'
ON DUPLICATE KEY UPDATE
  release_date = VALUES(release_date);

-- 흑백요리사 2 → E1~E3
INSERT INTO episodes (season_id, episode_number, title, synopsis, runtime_min, video_url, release_date)
SELECT s.season_id, 1, '1화: 룰 변경', '새 시즌, 새 규칙. (예시)', 63,
       'https://example.com/videos/bwchef2-e1.mp4', '2025-09-01'
FROM seasons s
JOIN contents c ON c.content_id=s.content_id
WHERE c.title_kr='흑백요리사 2' AND s.season_number=1
ON DUPLICATE KEY UPDATE
  title       = VALUES(title),
  synopsis    = VALUES(synopsis),
  runtime_min = VALUES(runtime_min),
  video_url   = VALUES(video_url),
  release_date= VALUES(release_date);

INSERT INTO episodes (season_id, episode_number, title, synopsis, runtime_min, video_url, release_date)
SELECT s.season_id, 2, '2화: 난이도 상승', '미션 난도가 한 단계 올라간다. (예시)', 65,
       'https://example.com/videos/bwchef2-e2.mp4', '2025-09-08'
FROM seasons s
JOIN contents c ON c.content_id=s.content_id
WHERE c.title_kr='흑백요리사 2' AND s.season_number=1
ON DUPLICATE KEY UPDATE
  title       = VALUES(title),
  synopsis    = VALUES(synopsis),
  runtime_min = VALUES(runtime_min),
  video_url   = VALUES(video_url),
  release_date= VALUES(release_date);

INSERT INTO episodes (season_id, episode_number, title, synopsis, runtime_min, video_url, release_date)
SELECT s.season_id, 3, '3화: 탈락전', '결정적인 승부가 이어진다. (예시)', 67,
       'https://example.com/videos/bwchef2-e3.mp4', '2025-09-15'
FROM seasons s
JOIN contents c ON c.content_id=s.content_id
WHERE c.title_kr='흑백요리사 2' AND s.season_number=1
ON DUPLICATE KEY UPDATE
  title       = VALUES(title),
  synopsis    = VALUES(synopsis),
  runtime_min = VALUES(runtime_min),
  video_url   = VALUES(video_url),
  release_date= VALUES(release_date);

-- ---------------------------------------------------------
-- 9) promo_codes (프로모션) - Optional demo data
-- ---------------------------------------------------------
INSERT INTO promo_codes (code, discount_type, discount_value, expires_at, is_active)
VALUES
  ('WELCOME10', 'PERCENT', 10, DATE_ADD(NOW(3), INTERVAL 180 DAY), 1),
  ('NEW5000',   'AMOUNT',  5000, DATE_ADD(NOW(3), INTERVAL 90 DAY), 1),
  ('TRIAL7',    'FREE_TRIAL', 7, DATE_ADD(NOW(3), INTERVAL 365 DAY), 1)
ON DUPLICATE KEY UPDATE
  discount_type  = VALUES(discount_type),
  discount_value = VALUES(discount_value),
  expires_at     = VALUES(expires_at),
  is_active      = VALUES(is_active);
