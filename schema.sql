
CREATE TABLE users (
  id              integer PRIMARY KEY,
  username        varchar(32)  NOT NULL UNIQUE,
  realname        varchar(64)  DEFAULT '',
  openid          varchar(256) NOT NULL,

  created_time    datetime NOT NULL /* DEFAULT datetime('now') */,
  last_login_time datetime, /* null means invited and not logged in? */
  verified_time   datetime, /* null means not verified */

  birthday        date NOT NULL,
  timezone_id     integer NOT NULL DEFAULT 1 REFERENCES timezones (id)
);

CREATE TABLE gift (
  id              integer PRIMARY KEY,
  wish_id         integer NOT NULL REFERENCES wishes (id),
  user_id         integer NOT NULL REFERENCES users (id),
  quantity        integer NOT NULL default 1,
  created_time    datetime NOT NULL, /* DEFAULT datetime('now') */
  comments        text
);

CREATE TABLE groups (
  id              integer PRIMARY KEY,
  brief           varchar(32) NOT NULL UNIQUE,
  created_time    datetime NOT NULL /* DEFAULT datetime('now') */
);

CREATE TABLE group_memberships (
  group_id        integer NOT NULL REFERENCES groups (id),
  user_id         integer NOT NULL REFERENCES users (id),
  created_time    datetime NOT NULL /* DEFAULT datetime('now') */,
  PRIMARY KEY (user_id, group_id)
);

CREATE TABLE timezones (
  id              integer PRIMARY KEY,
  tz_name         varchar(32) NOT NULL
);

CREATE TABLE resource (
  id              integer PRIMARY KEY,
  owner_id        integer NOT NULL REFERENCES users (id),
  created_time    datetime NOT NULL /* DEFAULT datetime('now') */,
  modified_time   datetime NOT NULL
);

CREATE TABLE wishlist_attributes (
  id              integer PRIMARY KEY REFERENCES resource (id),
  brief           varchar(32) NOT NULL
);

CREATE VIEW wishlists AS
  SELECT r.id, r.owner_id, r.created_time, r.modified_time, wa.brief
  FROM wishlist_attributes wa
  JOIN resource r ON wa.id = r.id
;

CREATE TABLE wishes (
  id              integer PRIMARY KEY,
  wishlist_id     integer NOT NULL REFERENCES wishlists (id),
  brief           varchar(128) NOT NULL,
  summary         text,
  unit_cost       decimal(8,2), /* null means unknown */
  quantity        integer NOT NULL default 1,
  created_time    datetime NOT NULL /* DEFAULT datetime('now') */
);
