-- +goose Up
-- +goose StatementBegin
CREATE TABLE setting (
	id 		TEXT PRIMARY KEY NOT NULL,
	key 	TEXT UNIQUE NOT NULL,
	value TEXT DEFAULT NULL
);
CREATE INDEX idx_setting_key ON setting (key);
INSERT INTO setting (id, key, value) VALUES 
('fkzjyd1p4z866mj', 'installed', 0),
('j3j2kaq67n0v9op', 'domain', ''),
('vlr2rtp82fewd1o', 'email', ''),
('zg7kdyrm9c9ivi5', 'password', ''),
('0oh908z9r28133g', 'jwt_secret', 'secret'),
('o9h0oh90b2qt8c2', 'jwt_secret_expire_hours', '48'),
('6o20io9hb27n0v9', 'currency', 'USD'),
('2r59p9nudtykndd', 'stripe_secret_key', ''),
('hzmhlamxdwo6ca3', 'stripe_webhook_secret_key', '');

CREATE TABLE session (
	key 		TEXT UNIQUE NOT NULL,
	value 	TEXT DEFAULT NULL,
	expires INTEGER
);
CREATE INDEX idx_session_key ON session (key);

CREATE TABLE subdomain (
	id 		TEXT PRIMARY KEY NOT NULL,
	name 	TEXT UNIQUE NOT NULL,
	desc 	TEXT DEFAULT NULL
);
CREATE INDEX idx_subdomain_name ON subdomain (name);

CREATE TABLE page (
	id 				TEXT PRIMARY KEY NOT NULL,
	name 			TEXT NOT NULL,
	url 			TEXT UNIQUE NOT NULL,
	content 	TEXT DEFAULT NULL,
	type 		  TEXT NOT NULL CHECK (type == 'header' OR type == 'footer'),
	active    BOOLEAN DEFAULT TRUE NOT NULL,
	created 	TIMESTAMP DEFAULT (datetime('now')),
	updated 	TIMESTAMP
);
CREATE INDEX idx_page_name ON page (name);
CREATE INDEX idx_page_url ON page (url);
CREATE INDEX idx_page_group ON page (type);

INSERT INTO page (id, name, url, type, content) VALUES 
('ig9jpCixAgAu31f', 'Terms & Conditions', 'terms', 'footer', ''),
('sdH0wGM54e3mZC2', 'Privacy Policy', 'privacy', 'footer', ''),
('kFCjBnL25hNTRHk', 'Cookies', 'cookies', 'footer', '');

CREATE TABLE product (
	id 				TEXT PRIMARY KEY NOT NULL,
	name 			TEXT NOT NULL,
	desc 			TEXT NOT NULL,
	url 			TEXT UNIQUE NOT NULL,
	amount    NUMERC NOT NULL,
	metadata 	JSON DEFAULT '{}' NOT NULL,
	attribute JSON DEFAULT '[]' NOT NULL,
	active    BOOLEAN DEFAULT TRUE NOT NULL,
	deleted   BOOLEAN DEFAULT FALSE NOT NULL,
	created 	TIMESTAMP DEFAULT (datetime('now')),
	updated 	TIMESTAMP
);
CREATE INDEX idx_product_id ON product (id);
CREATE INDEX idx_product_name ON product (name);
CREATE INDEX idx_product_url ON product (url);

CREATE TABLE product_image (
	id 						TEXT PRIMARY KEY NOT NULL,
	product_id 		TEXT NOT NULL,
	name 					TEXT NOT NULL,
	ext 					TEXT NOT NULL,
	FOREIGN KEY (product_id) REFERENCES product(id) ON UPDATE CASCADE ON DELETE CASCADE
);
CREATE INDEX idx_product_image_product_id ON product_image (product_id);


CREATE TABLE cart (
	id 				     TEXT PRIMARY KEY NOT NULL,
	email 		     TEXT DEFAULT NULL,
	name  		     TEXT DEFAULT NULL,
	amount_total   NUMERC NOT NULL,
	currency			 TEXT NOT NULL,
	payment_id     TEXT DEFAULT NULL,
	payment_status TEXT DEFAULT NULL,
	cart 			     JSON DEFAULT '[]' NOT NULL,
	created 	     TIMESTAMP DEFAULT (datetime('now')),
	updated        TIMESTAMP
);
-- +goose StatementEnd


-- +goose Down
-- +goose StatementBegin
DROP TABLE cart;
DROP TABLE product_image;
DROP TABLE product;
DROP TABLE page;
DROP TABLE subdomain;
DROP TABLE session;
DROP TABLE setting;
-- +goose StatementEnd
