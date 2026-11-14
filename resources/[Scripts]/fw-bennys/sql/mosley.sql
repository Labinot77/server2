-- Mosley's Dealership: business, bank account, catalog (15 test cars) and the computer monitor.

INSERT INTO `phone_businesses` (`business_owner`, `business_name`, `business_account`, `business_employees`, `business_ranks`) VALUES
	('1001', 'Mosley''s Dealership', '64829173', '[]', '[]');

INSERT INTO `player_financials` (`citizenid`, `name`, `accountid`, `balance`, `type`, `authorized`, `active`, `monitored`) VALUES
	('1001', 'Mosley''s Dealership', '64829173', 0, 'Bedrijfsrekening', '[]', 1, 0);

INSERT INTO `server_vehicles` (`shop`, `vehicle`, `stock`, `preset`) VALUES
	('mosley', 'asea', 9, '[]'),
	('mosley', 'blista', 7, '[]'),
	('mosley', 'emperor', 5, '[]'),
	('mosley', 'glendale', 3, '[]'),
	('mosley', 'ingot', 3, '[]'),
	('mosley', 'intruder', 5, '[]'),
	('mosley', 'issi2', 5, '[]'),
	('mosley', 'manana', 4, '[]'),
	('mosley', 'picador', 3, '[]'),
	('mosley', 'premier', 8, '[]'),
	('mosley', 'primo', 8, '[]'),
	('mosley', 'sadler', 2, '[]'),
	('mosley', 'stanier', 9, '[]'),
	('mosley', 'tornado', 5, '[]'),
	('mosley', 'washington', 6, '[]');

-- Monitor (fw-admin placed prop, the Dealership/Management computer). Fine-tune it in the admin panel if needed.
INSERT INTO `placed_props` (`model`, `coords`, `rotation`, `frozen`, `collision`, `placed_by`) VALUES
	('v_res_lest_monitor', '{"x":-31.25,"y":-1664.87,"z":30.29}', '{"x":0.0,"y":0.0,"z":340.15}', 1, 1, 'sql');
