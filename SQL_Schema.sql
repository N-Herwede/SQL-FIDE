PRAGMA foreign_keys = OFF;
BEGIN TRANSACTION;

-- Players
CREATE TABLE IF NOT EXISTS players (
    fide_id        INTEGER PRIMARY KEY,
    name           TEXT    NOT NULL,
    title          TEXT,
    country        TEXT,
    rating         INTEGER,
    birth_year     INTEGER,
    gender         TEXT,
    fide_join_date DATE         
);

-- Tournaments
CREATE TABLE IF NOT EXISTS tournaments (
    tournament_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    name           TEXT    NOT NULL,
    city           TEXT,
    country        TEXT,
    start_date     DATE,
    end_date       DATE
);

-- Games
CREATE TABLE IF NOT EXISTS games (
    game_id        INTEGER PRIMARY KEY AUTOINCREMENT,
    tournament_id  INTEGER NOT NULL,
    round          INTEGER,
    white_id       INTEGER NOT NULL,
    black_id       INTEGER NOT NULL,
    result         TEXT,
    pgn            TEXT,
    FOREIGN KEY (tournament_id) REFERENCES tournaments(tournament_id) ON DELETE CASCADE,
    FOREIGN KEY (white_id)      REFERENCES players(fide_id)          ON DELETE CASCADE,
    FOREIGN KEY (black_id)      REFERENCES players(fide_id)          ON DELETE CASCADE
);

-- Rankings
CREATE TABLE IF NOT EXISTS rankings (
    fide_id  INTEGER NOT NULL,
    rating   INTEGER NOT NULL,
    rank     INTEGER NOT NULL,
    month    INTEGER NOT NULL,
    year     INTEGER NOT NULL,
    PRIMARY KEY (fide_id, month, year),
    FOREIGN KEY (fide_id) REFERENCES players(fide_id) ON DELETE CASCADE
);

-- Registrations
CREATE TABLE IF NOT EXISTS registrations (
    tournament_id     INTEGER NOT NULL,
    fide_id           INTEGER NOT NULL,
    registration_date DATE    NOT NULL DEFAULT (DATE('now')),
    seed              INTEGER,
    bye               INTEGER NOT NULL DEFAULT 0,
    fee_paid          BOOLEAN NOT NULL DEFAULT 0,
    PRIMARY KEY (tournament_id, fide_id),
    FOREIGN KEY (tournament_id) REFERENCES tournaments(tournament_id) ON DELETE CASCADE,
    FOREIGN KEY (fide_id)       REFERENCES players(fide_id)           ON DELETE CASCADE
);

-- bloque la partie si le joueur n'est pas inscit
CREATE TRIGGER IF NOT EXISTS trg_game_registration_check
BEFORE INSERT ON games
FOR EACH ROW
BEGIN
    SELECT
        CASE
            WHEN (SELECT 1
                  FROM registrations
                  WHERE tournament_id = NEW.tournament_id
                    AND fide_id = NEW.white_id) IS NULL
              OR (SELECT 1
                  FROM registrations
                  WHERE tournament_id = NEW.tournament_id
                    AND fide_id = NEW.black_id) IS NULL
            THEN RAISE(ABORT,
                       'One or both players are not registered for this tournament')
        END;
END;

COMMIT;
PRAGMA foreign_keys = ON;
