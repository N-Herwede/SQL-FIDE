
PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS players (
    player_id INTEGER PRIMARY KEY,
    nom TEXT,
    titre TEXT,
    sexe TEXT,
    pays TEXT,
    age INTEGER,
    annee_naissance INTEGER
);

CREATE TABLE IF NOT EXISTS rankings (
    ranking_id INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id INTEGER,
    date DATE,
    elo_standard INTEGER,
    elo_rapid INTEGER,
    elo_blitz INTEGER,
    FOREIGN KEY (player_id) REFERENCES players(player_id)
);

CREATE TABLE IF NOT EXISTS tournaments (
    tournament_id INTEGER PRIMARY KEY,
    nom TEXT,
    lieu TEXT,
    date_debut DATE,
    date_fin DATE,
    format TEXT,
    vainqueur_id INTEGER,
    FOREIGN KEY (vainqueur_id) REFERENCES players(player_id)
);

CREATE TABLE IF NOT EXISTS games (
    game_id INTEGER PRIMARY KEY,
    tournament_id INTEGER,
    date DATE,
    joueur_blanc_id INTEGER,
    joueur_noir_id INTEGER,
    resultat TEXT,
    format TEXT,
    FOREIGN KEY (tournament_id) REFERENCES tournaments(tournament_id),
    FOREIGN KEY (joueur_blanc_id) REFERENCES players(player_id),
    FOREIGN KEY (joueur_noir_id) REFERENCES players(player_id)
);

CREATE TABLE IF NOT EXISTS tournament_registrations (
    registration_id INTEGER PRIMARY KEY AUTOINCREMENT,
    player_id INTEGER,
    tournament_id INTEGER,
    registration_date DATE,
    status TEXT,
    FOREIGN KEY (player_id) REFERENCES players(player_id),
    FOREIGN KEY (tournament_id) REFERENCES tournaments(tournament_id)
);
