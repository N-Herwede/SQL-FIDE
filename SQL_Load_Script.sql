.headers off
.mode csv
.separator ","

PRAGMA foreign_keys = OFF;
BEGIN TRANSACTION;

------------------------------------------------------------
-- Players  (CSV = 11 colonnes → table finale = 7)
------------------------------------------------------------
DROP TABLE IF EXISTS players_tmp;
CREATE TABLE players_tmp (
    fide_id        INTEGER,
    name           TEXT,
    title          TEXT,
    country        TEXT,
    elo_standard   INTEGER,
    elo_rapid      INTEGER,
    elo_blitz      INTEGER,
    birth_year     INTEGER,
    gender         TEXT,
    age            INTEGER,
    dummy          TEXT
);

.import --skip 1 Data/FIDE_Mars_2025.csv  players_tmp
.import --skip 1 Data/FIDE_Avril_2025.csv players_tmp

INSERT OR IGNORE INTO players (fide_id, name, title, country, rating, birth_year, gender)
SELECT fide_id,
       name,
       title,
       country,
       elo_standard,
       birth_year,
       gender
FROM   players_tmp;

DROP TABLE players_tmp;

------------------------------------------------------------
-- Tournaments  (CSV = 6 colonnes identiques au schéma)
------------------------------------------------------------
DELETE FROM tournaments;                       -- purger les anciennes lignes
.import --skip 1 Data/Tournaments.csv tournaments

------------------------------------------------------------
-- Rankings  (staging + INSERT OR IGNORE)
------------------------------------------------------------
DROP TABLE IF EXISTS rankings_tmp;
CREATE TABLE rankings_tmp (
    fide_id  INTEGER,
    rating   INTEGER,
    rank     INTEGER,
    month    INTEGER,
    year     INTEGER
);

.import --skip 1 Data/Rankings_Mars.csv  rankings_tmp
.import --skip 1 Data/Rankings_Avril.csv rankings_tmp

INSERT OR IGNORE INTO rankings
SELECT fide_id, rating, rank, month, year
FROM   rankings_tmp;

DROP TABLE rankings_tmp;

------------------------------------------------------------
-- Registrations  (Paris Open 2025)
------------------------------------------------------------
DROP TABLE IF EXISTS registrations_staging;
CREATE TABLE registrations_staging (
    tournament_id     INTEGER,
    fide_id           INTEGER,
    registration_date DATE,
    seed              INTEGER,
    bye               INTEGER,
    fee_paid          BOOLEAN
);

.import --skip 1 Data/ParisOpen2025_registrations.csv registrations_staging

INSERT OR REPLACE INTO registrations
SELECT tournament_id,
       fide_id,
       COALESCE(registration_date, date('now')),
       seed,
       COALESCE(bye, 0),
       COALESCE(fee_paid, 0)
FROM   registrations_staging;

DROP TABLE registrations_staging;

------------------------------------------------------------
-- Games  (désactivation puis ré‑activation du trigger)
------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_game_registration_check;

.import --skip 1 Data/Games.csv games

CREATE TRIGGER trg_game_registration_check
BEFORE INSERT ON games
FOR EACH ROW
BEGIN
    SELECT
        CASE
            WHEN (SELECT 1
                  FROM registrations
                  WHERE tournament_id = NEW.tournament_id
                    AND fide_id       = NEW.white_id) IS NULL
              OR (SELECT 1
                  FROM registrations
                  WHERE tournament_id = NEW.tournament_id
                    AND fide_id       = NEW.black_id) IS NULL
            THEN RAISE(ABORT,
                       'One or both players are not registered for this tournament')
        END;
END;

COMMIT;
PRAGMA foreign_keys = ON;
