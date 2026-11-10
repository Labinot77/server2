-- Optional: fw-housing adds this column automatically on start if it is missing.
ALTER TABLE `player_houses` ADD COLUMN `mlo` VARCHAR(64) NULL DEFAULT NULL;
