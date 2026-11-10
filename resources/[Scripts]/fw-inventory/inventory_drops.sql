-- Optional: fw-inventory creates this table itself on start when Config.PersistentDrops = true.
CREATE TABLE IF NOT EXISTS `inventory_drops` (
    `id` INT NOT NULL,
    `coords` LONGTEXT NOT NULL,
    `props` LONGTEXT NOT NULL,
    `updated_at` INT NOT NULL,
    PRIMARY KEY (`id`)
);
