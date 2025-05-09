-- ******************************************************
-- *  SQLite Schema for FIDE database (corrected 2025)  *
-- ******************************************************

PRAGMA foreign_keys = ON;

-- ------------------------------------------------------
-- Players
-- ------------------------------------------------------
-- player_id comes from the first column of the CSV (named "unnamed:_0").
-- The same numeric id is referenced by games.joueur_blanc_id,
-- games.joueur_noir_id and tournaments.winner_id, so we MUST
-- preserve it exactly as‑is.
CREATE TABLE IF NOT EXISTS players (
    player_id      INTEGER PRIMARY KEY,  -- from CSV col 1
    fide_id        INTEGER,              -- official FIDE identifier
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

-- ------------------------------------------------------
-- Tournaments
-- ------------------------------------------------------
CREATE TABLE IF NOT EXISTS tournaments (
    tournament_id  INTEGER PRIMARY KEY,
    name           TEXT,
    city           TEXT,
    start_date     TEXT,
    end_date       TEXT,
    format         TEXT,
    winner_id      INTEGER,
    FOREIGN KEY (winner_id) REFERENCES players(player_id)
);

-- ------------------------------------------------------
-- Games
-- ------------------------------------------------------
CREATE TABLE IF NOT EXISTS games (
    game_id          INTEGER PRIMARY KEY,
    tournament_id    INTEGER,
    date             TEXT,
    joueur_blanc_id  INTEGER,
    joueur_noir_id   INTEGER,
    resultat         TEXT,
    format           TEXT,
    FOREIGN KEY (tournament_id)   REFERENCES tournaments(tournament_id),
    FOREIGN KEY (joueur_blanc_id) REFERENCES players(player_id),
    FOREIGN KEY (joueur_noir_id)  REFERENCES players(player_id)
);

-- ------------------------------------------------------
-- Rankings
-- ------------------------------------------------------
-- The rankings CSV identifies players by fide_id.
CREATE TABLE IF NOT EXISTS rankings (
    fide_id       INTEGER,
    date          TEXT,
    elo_standard  INTEGER,
    elo_rapid     INTEGER,
    elo_blitz     INTEGER,
    FOREIGN KEY (fide_id) REFERENCES players(fide_id)
);
