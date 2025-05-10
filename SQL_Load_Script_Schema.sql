.headers off
.mode csv
.separator ","

PRAGMA foreign_keys = OFF;
BEGIN TRANSACTION;

-- Nettoyage des triggers vues et tables existants suppression des anciens elements
DROP TRIGGER IF EXISTS trg_game_registration_check;
DROP VIEW    IF EXISTS v_top_blitz;
DROP VIEW    IF EXISTS v_top_rapid;
DROP TABLE   IF EXISTS games;
DROP TABLE   IF EXISTS registrations;
DROP TABLE   IF EXISTS tournaments;
DROP TABLE   IF EXISTS rankings;
DROP TABLE   IF EXISTS players;

-- 1 Table des joueurs creation de la table principale des joueurs
CREATE TABLE players (
  fide_id        INTEGER PRIMARY KEY,
  name           TEXT    NOT NULL,
  title          TEXT,
  country        TEXT,
  rating         INTEGER      -- cote elo standard
  , elo_rapid      INTEGER      -- cote elo rapide
  , elo_blitz      INTEGER      -- cote elo blitz
  , birth_year     INTEGER
  , gender         TEXT
  , fide_join_date DATE
);

-- Import des joueurs par table temporaire alignement avec les colonnes du fichier csv
CREATE TABLE players_import (
  idx              INTEGER,
  fide_id          INTEGER,
  nom              TEXT,
  titre            TEXT,
  sexe             TEXT,
  pays             TEXT,
  age              REAL,
  annee_naissance  REAL,
  elo_standard     INTEGER,
  elo_rapid        INTEGER,
  elo_blitz        INTEGER
);
.import --skip 1 Data/FIDE_Mars_2025.csv   players_import
.import --skip 1 Data/FIDE_Avril_2025.csv players_import

INSERT OR IGNORE INTO players (
  fide_id, name, title, country,
  rating, elo_rapid, elo_blitz,
  birth_year, gender
)
SELECT
  fide_id,
  nom     AS name,
  titre   AS title,
  pays    AS country,
  elo_standard AS rating,
  elo_rapid,
  elo_blitz,
  CAST(annee_naissance AS INTEGER) AS birth_year,
  sexe    AS gender
FROM players_import;
DROP TABLE players_import;

-- 2 Table des classements creation de la table des classements avec toutes les cotes
CREATE TABLE rankings (
  fide_id    INTEGER,
  rating     INTEGER,
  elo_rapid  INTEGER,
  elo_blitz  INTEGER,
  rank       INTEGER,
  month      INTEGER,
  year       INTEGER
);

-- Import des classements par table temporaire alignement des donnees du fichier csv
CREATE TABLE rankings_import (
  player_id      INTEGER,
  date           TEXT,
  elo_standard   INTEGER,
  elo_rapid      INTEGER,
  elo_blitz      INTEGER
);
.import --skip 1 Data/Rankings_Mars.csv  rankings_import
.import --skip 1 Data/Rankings_Avril.csv rankings_import

INSERT OR IGNORE INTO rankings (
  fide_id, rating, elo_rapid, elo_blitz, rank, month, year
)
SELECT
  ri.player_id           AS fide_id,
  ri.elo_standard        AS rating,
  ri.elo_rapid           AS elo_rapid,
  ri.elo_blitz           AS elo_blitz,
  ROW_NUMBER() OVER (
    PARTITION BY
      CAST(strftime('%Y', ri.date) AS INTEGER),
      CAST(strftime('%m', ri.date) AS INTEGER)
    ORDER BY ri.elo_standard DESC
  )                       AS rank,
  CAST(strftime('%m', ri.date) AS INTEGER)   AS month,
  CAST(strftime('%Y', ri.date) AS INTEGER)   AS year
FROM rankings_import ri
JOIN players p ON p.fide_id = ri.player_id;
DROP TABLE rankings_import;

-- 3 Table des tournois creation de la table des tournois
CREATE TABLE tournaments (
  tournament_id INTEGER PRIMARY KEY,
  name          TEXT,
  start_date    DATE,
  end_date      DATE,
  location      TEXT,
  category      TEXT
);

-- Import des tournois par table temporaire alignement avec le fichier csv
CREATE TABLE tournaments_import (
  tournament_id INTEGER,
  name          TEXT,
  city          TEXT,
  country       TEXT,
  start_date    DATE,
  end_date      DATE
);
.import --skip 1 Data/Tournaments.csv tournaments_import

INSERT OR IGNORE INTO tournaments (
  tournament_id, name, start_date, end_date, location, category
)
SELECT
  tournament_id,
  name,
  start_date,
  end_date,
  city    AS location,
  country AS category
FROM tournaments_import;
DROP TABLE tournaments_import;

-- 4 Table des inscriptions creation de la table des inscriptions des tournois
CREATE TABLE registrations (
  tournament_id     INTEGER,
  fide_id           INTEGER,
  registration_date DATE,
  seed              INTEGER,
  bye               INTEGER,
  fee_paid          BOOLEAN
);

-- Import des inscriptions par table temporaire alignement avec le fichier csv
CREATE TABLE registrations_import (
  tournament_id     INTEGER,
  fide_id           INTEGER,
  registration_date TEXT,
  seed              INTEGER,
  bye               INTEGER,
  fee_paid          INTEGER
);
.import --skip 1 Data/ParisOpen2025_registrations.csv registrations_import

INSERT OR IGNORE INTO registrations (
  tournament_id, fide_id, registration_date, seed, bye, fee_paid
)
SELECT
  tournament_id,
  fide_id,
  registration_date,
  seed,
  bye,
  fee_paid
FROM registrations_import;
DROP TABLE registrations_import;

-- 5 Table des parties creation de la table des parties jouees
CREATE TABLE games (
  game_id      INTEGER PRIMARY KEY,
  tournament_id INTEGER,
  round         INTEGER,
  board         INTEGER,
  white_id      INTEGER,
  black_id      INTEGER,
  result        TEXT,
  termination   TEXT
);

-- Import des parties par table temporaire alignement avec le fichier csv
CREATE TABLE games_import (
  game_id         INTEGER,
  tournament_id   INTEGER,
  date            TEXT,
  joueur_blanc_id INTEGER,
  joueur_noir_id  INTEGER,
  resultat        TEXT,
  format          TEXT
);
.import --skip 1 Data/Games.csv games_import

INSERT OR IGNORE INTO games (
  game_id, tournament_id, round, board, white_id, black_id, result, termination
)
SELECT
  game_id,
  tournament_id,
  NULL  AS round,
  NULL  AS board,
  joueur_blanc_id AS white_id,
  joueur_noir_id  AS black_id,
  resultat        AS result,
  format          AS termination
FROM games_import;
DROP TABLE games_import;

-- Verification des inscriptions sur les parties creation du trigger de validation
CREATE TRIGGER trg_game_registration_check
BEFORE INSERT ON games
FOR EACH ROW
WHEN (
  (SELECT 1 FROM registrations WHERE tournament_id = NEW.tournament_id AND fide_id = NEW.white_id) IS NULL
  OR
  (SELECT 1 FROM registrations WHERE tournament_id = NEW.tournament_id AND fide_id = NEW.black_id) IS NULL
)
BEGIN
  SELECT RAISE(ABORT, 'Un des deux joueurs nest pas inscrit dans ce tournoi');
END;

-- Creation des vues pour visualization des meilleurs blitz rapid
CREATE VIEW v_top_blitz AS
SELECT name, elo_blitz FROM players
ORDER BY elo_blitz DESC;

CREATE VIEW v_top_rapid AS
SELECT name, elo_rapid FROM players
ORDER BY elo_rapid DESC;

COMMIT;
PRAGMA foreign_keys = ON;
