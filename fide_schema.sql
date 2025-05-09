
-- Players Table
CREATE TABLE players (
    fide_id TEXT PRIMARY KEY,
    nom TEXT,
    titre TEXT,
    sexe TEXT,
    pays TEXT,
    age INTEGER,
    annee_naissance INTEGER,
    status TEXT
);

-- Rankings Table
CREATE TABLE rankings (
    ranking_id INTEGER PRIMARY KEY AUTOINCREMENT,
    fide_id TEXT,
    date TEXT,
    elo_type TEXT,
    elo INTEGER
);

-- Tournaments Table
CREATE TABLE tournaments (
    tournament_id INTEGER PRIMARY KEY,
    nom TEXT,
    lieu TEXT,
    date_debut TEXT,
    date_fin TEXT,
    format TEXT,
    vainqueur_id TEXT
);

-- Games Table
CREATE TABLE games (
    game_id INTEGER PRIMARY KEY,
    tournament_id INTEGER,
    date TEXT,
    joueur_blanc_id TEXT,
    joueur_noir_id TEXT,
    resultat TEXT,
    format TEXT
);

-- Tournament Registrations Table
CREATE TABLE tournament_registrations (
    registration_id INTEGER PRIMARY KEY,
    fide_id TEXT,
    tournament_id INTEGER,
    registration_date TEXT,
    status TEXT
);
