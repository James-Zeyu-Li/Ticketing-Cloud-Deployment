-- 1. Insert venues (seed values correspond to PurchaseService/venues.yml)
INSERT INTO venue (venue_id, city) VALUES
	('Venue1', 'Vancouver'),
	('Venue2', 'Vancouver'),
	('Venue3', 'Vancouver'),
	('Venue4', 'Vancouver'),
	('Venue5', 'Vancouver')
ON DUPLICATE KEY UPDATE city=VALUES(city);

-- 2. Insert Zones for each venue (idempotent)
-- Venue1: 50 zones, 30 rows, 40 cols
INSERT INTO zone (venue_id, zone_id, ticket_price, row_count, col_count) VALUES
	('Venue1', 1, 100.00, 30, 40), ('Venue1', 2, 100.00, 30, 40), ('Venue1', 3, 100.00, 30, 40), ('Venue1', 4, 100.00, 30, 40), ('Venue1', 5, 100.00, 30, 40),
	('Venue1', 6, 100.00, 30, 40), ('Venue1', 7, 100.00, 30, 40), ('Venue1', 8, 100.00, 30, 40), ('Venue1', 9, 100.00, 30, 40), ('Venue1', 10, 100.00, 30, 40),
	('Venue1', 11, 100.00, 30, 40), ('Venue1', 12, 100.00, 30, 40), ('Venue1', 13, 100.00, 30, 40), ('Venue1', 14, 100.00, 30, 40), ('Venue1', 15, 100.00, 30, 40),
	('Venue1', 16, 100.00, 30, 40), ('Venue1', 17, 100.00, 30, 40), ('Venue1', 18, 100.00, 30, 40), ('Venue1', 19, 100.00, 30, 40), ('Venue1', 20, 100.00, 30, 40),
	('Venue1', 21, 100.00, 30, 40), ('Venue1', 22, 100.00, 30, 40), ('Venue1', 23, 100.00, 30, 40), ('Venue1', 24, 100.00, 30, 40), ('Venue1', 25, 100.00, 30, 40),
	('Venue1', 26, 100.00, 30, 40), ('Venue1', 27, 100.00, 30, 40), ('Venue1', 28, 100.00, 30, 40), ('Venue1', 29, 100.00, 30, 40), ('Venue1', 30, 100.00, 30, 40),
	('Venue1', 31, 100.00, 30, 40), ('Venue1', 32, 100.00, 30, 40), ('Venue1', 33, 100.00, 30, 40), ('Venue1', 34, 100.00, 30, 40), ('Venue1', 35, 100.00, 30, 40),
	('Venue1', 36, 100.00, 30, 40), ('Venue1', 37, 100.00, 30, 40), ('Venue1', 38, 100.00, 30, 40), ('Venue1', 39, 100.00, 30, 40), ('Venue1', 40, 100.00, 30, 40),
	('Venue1', 41, 100.00, 30, 40), ('Venue1', 42, 100.00, 30, 40), ('Venue1', 43, 100.00, 30, 40), ('Venue1', 44, 100.00, 30, 40), ('Venue1', 45, 100.00, 30, 40),
	('Venue1', 46, 100.00, 30, 40), ('Venue1', 47, 100.00, 30, 40), ('Venue1', 48, 100.00, 30, 40), ('Venue1', 49, 100.00, 30, 40), ('Venue1', 50, 100.00, 30, 40)
ON DUPLICATE KEY UPDATE ticket_price=VALUES(ticket_price), row_count=VALUES(row_count), col_count=VALUES(col_count);

-- Venue2: 20 zones, 25 rows, 35 cols
INSERT INTO zone (venue_id, zone_id, ticket_price, row_count, col_count) VALUES
	('Venue2', 1, 90.00, 25, 35), ('Venue2', 2, 90.00, 25, 35), ('Venue2', 3, 90.00, 25, 35), ('Venue2', 4, 90.00, 25, 35), ('Venue2', 5, 90.00, 25, 35),
	('Venue2', 6, 90.00, 25, 35), ('Venue2', 7, 90.00, 25, 35), ('Venue2', 8, 90.00, 25, 35), ('Venue2', 9, 90.00, 25, 35), ('Venue2', 10, 90.00, 25, 35),
	('Venue2', 11, 90.00, 25, 35), ('Venue2', 12, 90.00, 25, 35), ('Venue2', 13, 90.00, 25, 35), ('Venue2', 14, 90.00, 25, 35), ('Venue2', 15, 90.00, 25, 35),
	('Venue2', 16, 90.00, 25, 35), ('Venue2', 17, 90.00, 25, 35), ('Venue2', 18, 90.00, 25, 35), ('Venue2', 19, 90.00, 25, 35), ('Venue2', 20, 90.00, 25, 35)
ON DUPLICATE KEY UPDATE ticket_price=VALUES(ticket_price), row_count=VALUES(row_count), col_count=VALUES(col_count);

-- Venue3: 10 zones, 20 rows, 25 cols
INSERT INTO zone (venue_id, zone_id, ticket_price, row_count, col_count) VALUES
	('Venue3', 1, 80.00, 20, 25), ('Venue3', 2, 80.00, 20, 25), ('Venue3', 3, 80.00, 20, 25), ('Venue3', 4, 80.00, 20, 25), ('Venue3', 5, 80.00, 20, 25),
	('Venue3', 6, 80.00, 20, 25), ('Venue3', 7, 80.00, 20, 25), ('Venue3', 8, 80.00, 20, 25), ('Venue3', 9, 80.00, 20, 25), ('Venue3', 10, 80.00, 20, 25)
ON DUPLICATE KEY UPDATE ticket_price=VALUES(ticket_price), row_count=VALUES(row_count), col_count=VALUES(col_count);

-- Venue4: 5 zones, 15 rows, 30 cols
INSERT INTO zone (venue_id, zone_id, ticket_price, row_count, col_count) VALUES
	('Venue4', 1, 70.00, 15, 30), ('Venue4', 2, 70.00, 15, 30), ('Venue4', 3, 70.00, 15, 30), ('Venue4', 4, 70.00, 15, 30), ('Venue4', 5, 70.00, 15, 30)
ON DUPLICATE KEY UPDATE ticket_price=VALUES(ticket_price), row_count=VALUES(row_count), col_count=VALUES(col_count);

-- Venue5: 30 zones, 50 rows, 60 cols
INSERT INTO zone (venue_id, zone_id, ticket_price, row_count, col_count) VALUES
	('Venue5', 1, 120.00, 50, 60), ('Venue5', 2, 120.00, 50, 60), ('Venue5', 3, 120.00, 50, 60), ('Venue5', 4, 120.00, 50, 60), ('Venue5', 5, 120.00, 50, 60),
	('Venue5', 6, 120.00, 50, 60), ('Venue5', 7, 120.00, 50, 60), ('Venue5', 8, 120.00, 50, 60), ('Venue5', 9, 120.00, 50, 60), ('Venue5', 10, 120.00, 50, 60),
	('Venue5', 11, 120.00, 50, 60), ('Venue5', 12, 120.00, 50, 60), ('Venue5', 13, 120.00, 50, 60), ('Venue5', 14, 120.00, 50, 60), ('Venue5', 15, 120.00, 50, 60),
	('Venue5', 16, 120.00, 50, 60), ('Venue5', 17, 120.00, 50, 60), ('Venue5', 18, 120.00, 50, 60), ('Venue5', 19, 120.00, 50, 60), ('Venue5', 20, 120.00, 50, 60),
	('Venue5', 21, 120.00, 50, 60), ('Venue5', 22, 120.00, 50, 60), ('Venue5', 23, 120.00, 50, 60), ('Venue5', 24, 120.00, 50, 60), ('Venue5', 25, 120.00, 50, 60),
	('Venue5', 26, 120.00, 50, 60), ('Venue5', 27, 120.00, 50, 60), ('Venue5', 28, 120.00, 50, 60), ('Venue5', 29, 120.00, 50, 60), ('Venue5', 30, 120.00, 50, 60)
ON DUPLICATE KEY UPDATE ticket_price=VALUES(ticket_price), row_count=VALUES(row_count), col_count=VALUES(col_count);

-- 3. Insert Events (match PurchaseService/events.yml)
INSERT INTO event (event_id, venue_id, name, type, event_date) VALUES
	('Event1', 'Venue1', 'Event1', 'Sports', '2025-12-15'),
	('Event2', 'Venue1', 'Event2', 'Sports', '2025-11-20'),
	('Event3', 'Venue2', 'Event3', 'Concert', '2025-10-25'),
	('Event4', 'Venue2', 'Event4', 'Concert', '2025-11-05'),
	('Event5', 'Venue3', 'Event5', 'Theater', '2025-10-30'),
	('Event6', 'Venue4', 'Event6', 'Conference', '2025-11-10'),
	('Event7', 'Venue5', 'Event7', 'Festival', '2025-07-15')
ON DUPLICATE KEY UPDATE name=VALUES(name), type=VALUES(type), event_date=VALUES(event_date);