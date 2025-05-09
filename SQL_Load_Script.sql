-- ******************************************************
-- *  Data‑loading script for the corrected FIDE DB     *
-- *  Usage: $ sqlite3 fide.db < SQL_Load_Script.sql    *
-- ******************************************************

.headers off
.mode csv
.separator ","

PRAGMA foreign_keys = OFF;
BEGIN TRANSACTION;

-- ------------------------------------------------------
-- Players
-- ------------------------------------------------------
-- First import April (we assume it contains the freshest ratings).
.import --skip 1 /data/FIDE_Avril_2025.csv players

-- Import March into a temporary table, then merge with deduplication.
CREATE TEMP TABLE players_tmp (
    player_id      INTEGER,
    fide_id        INTEGER,
    name           TEXT,
    title          TEXT,
    gender         TEXT,
    country        TEXT,
    age            INTEGER,
    birth_year     INTEGER,
    elo_standard   INTEGER,
    elo_rapid      INTEGER,
    elo_blitz      INTEGER
);
.import --skip 1 /data/FIDE_Mars_2025.csv players_tmp

-- Insert only the rows whose primary key (player_id) is still missing.
INSERT OR IGNORE INTO players
SELECT * FROM players_tmp;

DROP TABLE players_tmp;

-- ------------------------------------------------------
-- Tournaments
-- ------------------------------------------------------
.import --skip 1 /data/Tournaments.csv tournaments

-- ------------------------------------------------------
-- Games
-- ------------------------------------------------------
.import --skip 1 /data/Games.csv games

-- ------------------------------------------------------
-- Rankings
-- ------------------------------------------------------
.import --skip 1 /data/Rankings_Avril.csv  rankings
.import --skip 1 /data/Rankings_Mars.csv   rankings

COMMIT;
PRAGMA foreign_keys = ON;

-- Optional    : Sanity check
-- SELECT count(*) FROM players;
-- SELECT count(*) FROM games;


-- ===== Import fictif d'inscriptions Paris Open 2025 =====
DROP TABLE IF EXISTS registrations_staging;
CREATE TABLE registrations_staging (
    tournament_id     INTEGER,
    fide_id           INTEGER,
    registration_date DATE,
    seed              INTEGER,
    bye               INTEGER,
    fee_paid          BOOLEAN
);

.mode csv
.import /data/ParisOpen2025_registrations.csv registrations_staging

INSERT OR REPLACE INTO registrations
SELECT tournament_id,
       fide_id,
       COALESCE(registration_date, date('now')),
       seed,
       COALESCE(bye, 0),
       COALESCE(fee_paid, 0)
FROM   registrations_staging;

DROP TABLE registrations_staging;
