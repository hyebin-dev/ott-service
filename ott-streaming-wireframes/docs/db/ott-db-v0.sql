CREATE TABLE `contents` (
	`content_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'AI',
	`title_kr`	VARCHAR(200)	NOT NULL,
	`title_en`	VARCHAR(200)	NULL,
	`type`	ENUM('MOVIE','SERIES')	NOT NULL,
	`synopsis_short`	VARCHAR(500)	NOT NULL,
	`synopsis_long`	TEXT	NULL,
	`release_year`	YEAR	NOT NULL,
	`country`	VARCHAR(50)	NOT NULL,
	`age_rating`	ENUM('7','12','15','19')	NOT NULL,
	`runtime_min`	SMALLINT UNSIGNED	NULL,
	`poster_url`	VARCHAR(500)	NOT NULL,
	`backdrop_url`	VARCHAR(500)	NULL,
	`trailer_url`	VARCHAR(500)	NULL,
	`created_at`	DATETIME(3)	NOT NULL	DEFAULT CURRENT_TIMESTAMP(3),
	`is_active`	BOOLEAN	NOT NULL	DEFAULT 1
);

CREATE TABLE `subscriptions` (
	`subscription_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'AI',
	`user_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to users.user_id, ON DELETE RESTRICT',
	`plan_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to plans.plan_id, ON DELETE RESTRICT',
	`status`	ENUM('ACTIVE','CANCELED','EXPIRED')	NOT NULL	DEFAULT 'ACTIVE',
	`start_date`	DATE	NOT NULL,
	`next_billing_date`	DATE	NOT NULL,
	`end_date`	DATE	NULL,
	`canceled_at`	DATETIME(3)	NULL,
	`created_at`	DATETIME(3)	NOT NULL	DEFAULT CURRENT_TIMESTAMP(3),
	`updated_at`	DATETIME(3)	NOT NULL	DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3)
);

CREATE TABLE `reviews` (
	`review_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'AI',
	`profile_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to profiles.profile_id, ON DELETE CASCADE',
	`content_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to contents.content_id, ON DELETE CASCADE',
	`rating`	DECIMAL(2,1)	NOT NULL,
	`title`	VARCHAR(100)	NOT NULL,
	`body`	TEXT	NOT NULL,
	`spoiler`	BOOLEAN	NOT NULL	DEFAULT 0,
	`is_private`	BOOLEAN	NOT NULL	DEFAULT 0,
	`created_at`	DATETIME(3)	NOT NULL	DEFAULT CURRENT_TIMESTAMP(3),
	`updated_at`	DATETIME(3)	NOT NULL	DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3)
);

CREATE TABLE `subtitle_style` (
	`profile_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK (and PK) to profiles.profile_id, ON DELETE CASCADE',
	`font_family`	VARCHAR(50)	NOT NULL	DEFAULT 'default',
	`font_size`	ENUM('small','medium','large')	NOT NULL	DEFAULT 'medium',
	`font_color`	CHAR(7)	NOT NULL	DEFAULT '#FFFFFF',
	`shadow_enabled`	BOOLEAN	NOT NULL	DEFAULT 1,
	`shadow_color`	CHAR(7)	NULL,
	`background_color`	CHAR(7)	NULL,
	`window_color`	CHAR(7)	NULL,
	`preset`	ENUM('default','custom')	NOT NULL	DEFAULT 'default'
);

CREATE TABLE `terms` (
	`term_code`	ENUM('AGE14','SERVICE','PRIVACY','PAID','MARKETING')	NOT NULL,
	`name`	VARCHAR(100)	NOT NULL,
	`is_required`	BOOLEAN	NOT NULL,
	`created_at`	DATETIME(3)	NOT NULL	DEFAULT CURRENT_TIMESTAMP(3)
);

CREATE TABLE `content_blocks` (
	`block_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'AI',
	`profile_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to profiles.profile_id, ON DELETE CASCADE',
	`content_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to contents.content_id, ON DELETE CASCADE',
	`reason`	VARCHAR(255)	NULL,
	`created_at`	DATETIME(3)	NOT NULL	DEFAULT CURRENT_TIMESTAMP(3)
);

CREATE TABLE `wishlists` (
	`wishlist_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'AI',
	`profile_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to profiles.profile_id, ON DELETE CASCADE',
	`content_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to contents.content_id, ON DELETE CASCADE',
	`created_at`	DATETIME(3)	NOT NULL	DEFAULT CURRENT_TIMESTAMP(3)
);

CREATE TABLE `profile_settings` (
	`profile_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK (and PK) to profiles.profile_id, ON DELETE CASCADE',
	`ui_lang`	ENUM('ko','en')	NOT NULL	DEFAULT 'ko',
	`subtitle_lang`	ENUM('auto','ko','en','off')	NOT NULL	DEFAULT 'auto',
	`audio_lang`	ENUM('auto','ko','en')	NOT NULL	DEFAULT 'auto',
	`autoplay_next`	BOOLEAN	NOT NULL	DEFAULT 1,
	`autoplay_preview`	BOOLEAN	NOT NULL	DEFAULT 1,
	`quality_mode`	ENUM('auto','low','mid','high')	NOT NULL	DEFAULT 'auto',
	`notify_new_episode`	BOOLEAN	NOT NULL	DEFAULT 1,
	`notify_recommendation`	BOOLEAN	NOT NULL	DEFAULT 1,
	`notify_continue`	BOOLEAN	NOT NULL	DEFAULT 1,
	`max_age_rating`	ENUM('ALL','7','12','15','19')	NOT NULL	DEFAULT 'ALL'
);

CREATE TABLE `plans` (
	`plan_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'AI',
	`name`	ENUM('BASIC','STANDARD','PREMIUM')	NOT NULL,
	`price_monthly`	INT UNSIGNED	NOT NULL,
	`max_quality`	ENUM('SD','HD','UHD')	NOT NULL,
	`max_screens`	TINYINT UNSIGNED	NOT NULL,
	`description`	VARCHAR(255)	NULL,
	`is_active`	BOOLEAN	NOT NULL	DEFAULT 1
);

CREATE TABLE `people` (
	`person_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'AI',
	`name`	VARCHAR(100)	NOT NULL,
	`created_at`	DATETIME(3)	NOT NULL	DEFAULT CURRENT_TIMESTAMP(3)
);

CREATE TABLE `promo_codes` (
	`promo_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'AI',
	`code`	VARCHAR(50)	NOT NULL	COMMENT 'UNIQUE',
	`discount_type`	ENUM('PERCENT','AMOUNT','FREE_TRIAL')	NOT NULL,
	`discount_value`	INT UNSIGNED	NOT NULL,
	`expires_at`	DATETIME(3)	NOT NULL,
	`is_active`	BOOLEAN	NOT NULL	DEFAULT 1,
	`created_at`	DATETIME(3)	NOT NULL	DEFAULT CURRENT_TIMESTAMP(3)
);

CREATE TABLE `watch_party_members` (
	`room_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to watch_party_rooms.room_id, ON DELETE CASCADE',
	`profile_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to profiles.profile_id, ON DELETE CASCADE',
	`joined_at`	DATETIME(3)	NOT NULL	DEFAULT CURRENT_TIMESTAMP(3)
);

CREATE TABLE `watch_party_rooms` (
	`room_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'AI',
	`profile_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to profiles.profile_id, ON DELETE CASCADE',
	`content_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to contents.content_id, ON DELETE CASCADE',
	`episode_id`	BIGINT UNSIGNED	NULL	COMMENT 'FK to episodes.episode_id, ON DELETE CASCADE',
	`room_name`	VARCHAR(100)	NOT NULL,
	`join_code`	CHAR(8)	NOT NULL	COMMENT 'UNIQUE',
	`status`	ENUM('OPEN','CLOSED')	NOT NULL	DEFAULT 'OPEN',
	`created_at`	DATETIME(3)	NOT NULL	DEFAULT CURRENT_TIMESTAMP(3)
);

CREATE TABLE `users` (
	`user_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'AI',
	`email`	VARCHAR(255)	NOT NULL	COMMENT 'UNIQUE',
	`password_hash`	VARCHAR(255)	NULL,
	`name`	VARCHAR(50)	NOT NULL,
	`phone`	VARCHAR(20)	NULL,
	`birth_date`	DATE	NULL,
	`gender`	ENUM('MALE','FEMALE','NONE')	NULL	DEFAULT 'NONE',
	`created_at`	DATETIME(3)	NOT NULL	DEFAULT CURRENT_TIMESTAMP(3),
	`updated_at`	DATETIME(3)	NOT NULL	DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3),
	`status`	ENUM('ACTIVE','DELETED')	NOT NULL	DEFAULT 'ACTIVE'
);

CREATE TABLE `episodes` (
	`episode_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'AI',
	`season_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to seasons.season_id, ON DELETE CASCADE',
	`episode_number`	SMALLINT UNSIGNED	NOT NULL,
	`title`	VARCHAR(200)	NOT NULL,
	`synopsis`	TEXT	NULL,
	`runtime_min`	SMALLINT UNSIGNED	NOT NULL,
	`video_url`	VARCHAR(500)	NULL,
	`release_date`	DATE	NOT NULL
);

CREATE TABLE `payments` (
	`payment_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'AI',
	`subscription_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to subscriptions.subscription_id, ON DELETE RESTRICT',
	`promo_id`	BIGINT UNSIGNED	NULL	COMMENT 'FK to promo_codes.promo_id, ON DELETE RESTRICT',
	`method`	ENUM('CARD','KAKAOPAY','TOSSPAY','NAVERPAY')	NOT NULL,
	`card_company`	VARCHAR(30)	NULL,
	`card_holder_name`	VARCHAR(50)	NULL,
	`card_last4`	CHAR(4)	NULL,
	`amount`	INT UNSIGNED	NOT NULL,
	`paid_at`	DATETIME(3)	NOT NULL	DEFAULT CURRENT_TIMESTAMP(3),
	`result`	ENUM('SUCCESS','FAIL')	NOT NULL
);

CREATE TABLE `watch_histories` (
	`history_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'AI',
	`profile_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to profiles.profile_id, ON DELETE CASCADE',
	`content_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to contents.content_id, ON DELETE CASCADE',
	`episode_id`	BIGINT UNSIGNED	NULL	COMMENT 'FK to episodes.episode_id, ON DELETE CASCADE',
	`progress_sec`	INT UNSIGNED	NOT NULL	DEFAULT 0,
	`duration_sec`	INT UNSIGNED	NOT NULL,
	`is_finished`	BOOLEAN	NOT NULL	DEFAULT 0,
	`is_hidden`	BOOLEAN	NOT NULL	DEFAULT 0,
	`last_watched_at`	DATETIME(3)	NOT NULL	DEFAULT CURRENT_TIMESTAMP(3),
	`created_at`	DATETIME(3)	NOT NULL	DEFAULT CURRENT_TIMESTAMP(3)
);

CREATE TABLE `social_accounts` (
	`social_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'AI',
	`user_id2`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to users.user_id, ON DELETE RESTRICT',
	`provider`	ENUM('KAKAO','GOOGLE','NAVER')	NOT NULL,
	`provider_user_key`	VARCHAR(255)	NOT NULL,
	`connected_at`	DATETIME(3)	NOT NULL	DEFAULT CURRENT_TIMESTAMP(3)
);

CREATE TABLE `content_people` (
	`content_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to contents.content_id, ON DELETE CASCADE',
	`person_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to people.person_id, ON DELETE CASCADE',
	`role_detail`	ENUM('ACTOR','DIRECTOR','PRODUCER')	NOT NULL,
	`character_name`	VARCHAR(100)	NULL
);

CREATE TABLE `profiles` (
	`profile_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'AI',
	`user_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to users.user_id, ON DELETE RESTRICT',
	`name`	VARCHAR(20)	NOT NULL,
	`avatar_code`	VARCHAR(30)	NOT NULL	DEFAULT 'DEFAULT_1',
	`is_kids`	BOOLEAN	NOT NULL	DEFAULT 0,
	`pin_enabled`	BOOLEAN	NOT NULL	DEFAULT 0,
	`pin_hash`	VARCHAR(255)	NULL,
	`created_at`	DATETIME(3)	NOT NULL	DEFAULT CURRENT_TIMESTAMP(3),
	`is_active`	BOOLEAN	NOT NULL	DEFAULT 1,
	`updated_at`	DATETIME(3)	NOT NULL	DEFAULT CURRENT_TIMESTAMP(3) ON UPDATE CURRENT_TIMESTAMP(3)
);

CREATE TABLE `content_genres` (
	`content_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to contents.content_id, ON DELETE CASCADE',
	`genre_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to genres.genre_id, ON DELETE CASCADE'
);

CREATE TABLE `watch_sessions` (
	`session_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'AI',
	`profile_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to profiles.profile_id, ON DELETE CASCADE',
	`content_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to contents.content_id, ON DELETE CASCADE',
	`episode_id`	BIGINT UNSIGNED	NULL	COMMENT 'FK to episodes.episode_id, ON DELETE CASCADE',
	`started_at`	DATETIME(3)	NOT NULL	DEFAULT CURRENT_TIMESTAMP(3),
	`ended_at`	DATETIME(3)	NULL,
	`watched_sec`	INT UNSIGNED	NOT NULL	DEFAULT 0,
	`device_type`	ENUM('WEB','MOBILE','TV')	NULL
);

CREATE TABLE `seasons` (
	`season_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'AI',
	`content_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to contents.content_id, ON DELETE CASCADE',
	`season_number`	SMALLINT UNSIGNED	NOT NULL,
	`release_date`	DATE	NOT NULL
);

CREATE TABLE `user_terms_agreement` (
	`agreement_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'AI',
	`user_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to users.user_id, ON DELETE RESTRICT',
	`term_code`	ENUM('AGE14','SERVICE','PRIVACY','PAID','MARKETING')	NOT NULL	COMMENT 'FK to terms.term_code, ON DELETE RESTRICT',
	`agreed_at`	DATETIME(3)	NOT NULL	DEFAULT CURRENT_TIMESTAMP(3)
);

CREATE TABLE `watch_party_messages` (
	`message_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'AI',
	`room_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to watch_party_rooms.room_id, ON DELETE CASCADE',
	`profile_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'FK to profiles.profile_id, ON DELETE CASCADE',
	`body`	TEXT	NOT NULL,
	`sent_at`	DATETIME(3)	NOT NULL	DEFAULT CURRENT_TIMESTAMP(3)
);

CREATE TABLE `genres` (
	`genre_id`	BIGINT UNSIGNED	NOT NULL	COMMENT 'AI',
	`name`	VARCHAR(50)	NOT NULL	COMMENT 'UNIQUE'
);

ALTER TABLE `contents` ADD CONSTRAINT `PK_CONTENTS` PRIMARY KEY (
	`content_id`
);

ALTER TABLE `subscriptions` ADD CONSTRAINT `PK_SUBSCRIPTIONS` PRIMARY KEY (
	`subscription_id`
);

ALTER TABLE `reviews` ADD CONSTRAINT `PK_REVIEWS` PRIMARY KEY (
	`review_id`
);

ALTER TABLE `subtitle_style` ADD CONSTRAINT `PK_SUBTITLE_STYLE` PRIMARY KEY (
	`profile_id`
);

ALTER TABLE `terms` ADD CONSTRAINT `PK_TERMS` PRIMARY KEY (
	`term_code`
);

ALTER TABLE `content_blocks` ADD CONSTRAINT `PK_CONTENT_BLOCKS` PRIMARY KEY (
	`block_id`
);

ALTER TABLE `wishlists` ADD CONSTRAINT `PK_WISHLISTS` PRIMARY KEY (
	`wishlist_id`
);

ALTER TABLE `profile_settings` ADD CONSTRAINT `PK_PROFILE_SETTINGS` PRIMARY KEY (
	`profile_id`
);

ALTER TABLE `plans` ADD CONSTRAINT `PK_PLANS` PRIMARY KEY (
	`plan_id`
);

ALTER TABLE `people` ADD CONSTRAINT `PK_PEOPLE` PRIMARY KEY (
	`person_id`
);

ALTER TABLE `promo_codes` ADD CONSTRAINT `PK_PROMO_CODES` PRIMARY KEY (
	`promo_id`
);

ALTER TABLE `watch_party_rooms` ADD CONSTRAINT `PK_WATCH_PARTY_ROOMS` PRIMARY KEY (
	`room_id`
);

ALTER TABLE `users` ADD CONSTRAINT `PK_USERS` PRIMARY KEY (
	`user_id`
);

ALTER TABLE `episodes` ADD CONSTRAINT `PK_EPISODES` PRIMARY KEY (
	`episode_id`
);

ALTER TABLE `payments` ADD CONSTRAINT `PK_PAYMENTS` PRIMARY KEY (
	`payment_id`
);

ALTER TABLE `watch_histories` ADD CONSTRAINT `PK_WATCH_HISTORIES` PRIMARY KEY (
	`history_id`
);

ALTER TABLE `social_accounts` ADD CONSTRAINT `PK_SOCIAL_ACCOUNTS` PRIMARY KEY (
	`social_id`
);

ALTER TABLE `profiles` ADD CONSTRAINT `PK_PROFILES` PRIMARY KEY (
	`profile_id`
);

ALTER TABLE `watch_sessions` ADD CONSTRAINT `PK_WATCH_SESSIONS` PRIMARY KEY (
	`session_id`
);

ALTER TABLE `seasons` ADD CONSTRAINT `PK_SEASONS` PRIMARY KEY (
	`season_id`
);

ALTER TABLE `user_terms_agreement` ADD CONSTRAINT `PK_USER_TERMS_AGREEMENT` PRIMARY KEY (
	`agreement_id`
);

ALTER TABLE `watch_party_messages` ADD CONSTRAINT `PK_WATCH_PARTY_MESSAGES` PRIMARY KEY (
	`message_id`
);

ALTER TABLE `genres` ADD CONSTRAINT `PK_GENRES` PRIMARY KEY (
	`genre_id`
);

ALTER TABLE `subscriptions` ADD CONSTRAINT `FK_users_TO_subscriptions_1` FOREIGN KEY (
	`user_id`
)
REFERENCES `users` (
	`user_id`
);

ALTER TABLE `subscriptions` ADD CONSTRAINT `FK_plans_TO_subscriptions_1` FOREIGN KEY (
	`plan_id`
)
REFERENCES `plans` (
	`plan_id`
);

ALTER TABLE `reviews` ADD CONSTRAINT `FK_profiles_TO_reviews_1` FOREIGN KEY (
	`profile_id`
)
REFERENCES `profiles` (
	`profile_id`
);

ALTER TABLE `reviews` ADD CONSTRAINT `FK_contents_TO_reviews_1` FOREIGN KEY (
	`content_id`
)
REFERENCES `contents` (
	`content_id`
);

ALTER TABLE `subtitle_style` ADD CONSTRAINT `FK_profiles_TO_subtitle_style_1` FOREIGN KEY (
	`profile_id`
)
REFERENCES `profiles` (
	`profile_id`
);

ALTER TABLE `content_blocks` ADD CONSTRAINT `FK_profiles_TO_content_blocks_1` FOREIGN KEY (
	`profile_id`
)
REFERENCES `profiles` (
	`profile_id`
);

ALTER TABLE `content_blocks` ADD CONSTRAINT `FK_contents_TO_content_blocks_1` FOREIGN KEY (
	`content_id`
)
REFERENCES `contents` (
	`content_id`
);

ALTER TABLE `wishlists` ADD CONSTRAINT `FK_profiles_TO_wishlists_1` FOREIGN KEY (
	`profile_id`
)
REFERENCES `profiles` (
	`profile_id`
);

ALTER TABLE `wishlists` ADD CONSTRAINT `FK_contents_TO_wishlists_1` FOREIGN KEY (
	`content_id`
)
REFERENCES `contents` (
	`content_id`
);

ALTER TABLE `profile_settings` ADD CONSTRAINT `FK_profiles_TO_profile_settings_1` FOREIGN KEY (
	`profile_id`
)
REFERENCES `profiles` (
	`profile_id`
);

ALTER TABLE `watch_party_members` ADD CONSTRAINT `FK_watch_party_rooms_TO_watch_party_members_1` FOREIGN KEY (
	`room_id`
)
REFERENCES `watch_party_rooms` (
	`room_id`
);

ALTER TABLE `watch_party_members` ADD CONSTRAINT `FK_profiles_TO_watch_party_members_1` FOREIGN KEY (
	`profile_id`
)
REFERENCES `profiles` (
	`profile_id`
);

ALTER TABLE `watch_party_rooms` ADD CONSTRAINT `FK_profiles_TO_watch_party_rooms_1` FOREIGN KEY (
	`profile_id`
)
REFERENCES `profiles` (
	`profile_id`
);

ALTER TABLE `watch_party_rooms` ADD CONSTRAINT `FK_contents_TO_watch_party_rooms_1` FOREIGN KEY (
	`content_id`
)
REFERENCES `contents` (
	`content_id`
);

ALTER TABLE `watch_party_rooms` ADD CONSTRAINT `FK_episodes_TO_watch_party_rooms_1` FOREIGN KEY (
	`episode_id`
)
REFERENCES `episodes` (
	`episode_id`
);

ALTER TABLE `episodes` ADD CONSTRAINT `FK_seasons_TO_episodes_1` FOREIGN KEY (
	`season_id`
)
REFERENCES `seasons` (
	`season_id`
);

ALTER TABLE `payments` ADD CONSTRAINT `FK_subscriptions_TO_payments_1` FOREIGN KEY (
	`subscription_id`
)
REFERENCES `subscriptions` (
	`subscription_id`
);

ALTER TABLE `payments` ADD CONSTRAINT `FK_promo_codes_TO_payments_1` FOREIGN KEY (
	`promo_id`
)
REFERENCES `promo_codes` (
	`promo_id`
);

ALTER TABLE `watch_histories` ADD CONSTRAINT `FK_profiles_TO_watch_histories_1` FOREIGN KEY (
	`profile_id`
)
REFERENCES `profiles` (
	`profile_id`
);

ALTER TABLE `watch_histories` ADD CONSTRAINT `FK_contents_TO_watch_histories_1` FOREIGN KEY (
	`content_id`
)
REFERENCES `contents` (
	`content_id`
);

ALTER TABLE `watch_histories` ADD CONSTRAINT `FK_episodes_TO_watch_histories_1` FOREIGN KEY (
	`episode_id`
)
REFERENCES `episodes` (
	`episode_id`
);

ALTER TABLE `social_accounts` ADD CONSTRAINT `FK_users_TO_social_accounts_1` FOREIGN KEY (
	`user_id2`
)
REFERENCES `users` (
	`user_id`
);

ALTER TABLE `content_people` ADD CONSTRAINT `FK_contents_TO_content_people_1` FOREIGN KEY (
	`content_id`
)
REFERENCES `contents` (
	`content_id`
);

ALTER TABLE `content_people` ADD CONSTRAINT `FK_people_TO_content_people_1` FOREIGN KEY (
	`person_id`
)
REFERENCES `people` (
	`person_id`
);

ALTER TABLE `profiles` ADD CONSTRAINT `FK_users_TO_profiles_1` FOREIGN KEY (
	`user_id`
)
REFERENCES `users` (
	`user_id`
);

ALTER TABLE `content_genres` ADD CONSTRAINT `FK_contents_TO_content_genres_1` FOREIGN KEY (
	`content_id`
)
REFERENCES `contents` (
	`content_id`
);

ALTER TABLE `content_genres` ADD CONSTRAINT `FK_genres_TO_content_genres_1` FOREIGN KEY (
	`genre_id`
)
REFERENCES `genres` (
	`genre_id`
);

ALTER TABLE `watch_sessions` ADD CONSTRAINT `FK_profiles_TO_watch_sessions_1` FOREIGN KEY (
	`profile_id`
)
REFERENCES `profiles` (
	`profile_id`
);

ALTER TABLE `watch_sessions` ADD CONSTRAINT `FK_contents_TO_watch_sessions_1` FOREIGN KEY (
	`content_id`
)
REFERENCES `contents` (
	`content_id`
);

ALTER TABLE `watch_sessions` ADD CONSTRAINT `FK_episodes_TO_watch_sessions_1` FOREIGN KEY (
	`episode_id`
)
REFERENCES `episodes` (
	`episode_id`
);

ALTER TABLE `seasons` ADD CONSTRAINT `FK_contents_TO_seasons_1` FOREIGN KEY (
	`content_id`
)
REFERENCES `contents` (
	`content_id`
);

ALTER TABLE `user_terms_agreement` ADD CONSTRAINT `FK_users_TO_user_terms_agreement_1` FOREIGN KEY (
	`user_id`
)
REFERENCES `users` (
	`user_id`
);

ALTER TABLE `user_terms_agreement` ADD CONSTRAINT `FK_terms_TO_user_terms_agreement_1` FOREIGN KEY (
	`term_code`
)
REFERENCES `terms` (
	`term_code`
);

ALTER TABLE `watch_party_messages` ADD CONSTRAINT `FK_watch_party_rooms_TO_watch_party_messages_1` FOREIGN KEY (
	`room_id`
)
REFERENCES `watch_party_rooms` (
	`room_id`
);

ALTER TABLE `watch_party_messages` ADD CONSTRAINT `FK_profiles_TO_watch_party_messages_1` FOREIGN KEY (
	`profile_id`
)
REFERENCES `profiles` (
	`profile_id`
);

