
CREATE TABLE users (
  id              integer PRIMARY KEY,
  username        varchar(32) NOT NULL UNIQUE,
  realname        varchar(64) DEFAULT '',
  pw_digest       varchar(32) NOT NULL,

  created_time    datetime NOT NULL /* DEFAULT datetime('now') */,
  last_login_time datetime, /* null means invited and not logged in? */
  verified_time   datetime, /* null means not verified */

  birthday        date NOT NULL,
  timezone_id     integer NOT NULL DEFAULT 1 REFERENCES timezones (id)
);

CREATE TABLE timezones (
  id              integer PRIMARY KEY,
  tz_name         varchar(32) NOT NULL
);

CREATE TABLE groups (
  id              integer PRIMARY KEY,
  brief           varchar(32) NOT NULL UNIQUE
);

CREATE TABLE group_users (
  user_id         integer NOT NULL REFERENCES users (id),
  group_id        integer NOT NULL REFERENCES groups (id),
  PRIMARY KEY (user_id, group_id)
);

CREATE TABLE wishlists (
  id              integer PRIMARY KEY,
  user_id         integer NOT NULL REFERENCES users (id),
  brief           varchar(32) NOT NULL,
  created_time    datetime NOT NULL,
  modified_time   datetime NOT NULL
);

CREATE TABLE wish (
  id              integer PRIMARY KEY,
  wishlist_id     integer NOT NULL REFERENCES wishlists (id),
  brief           varchar(128) NOT NULL,
  cost            decimal(8,2), /* null means unknown */
  created_time    datetime NOT NULL
);
