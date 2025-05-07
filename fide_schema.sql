PRAGMA foreign_keys = ON;

-- Table: Players
CREATE TABLE IF NOT EXISTS players (
    fide_id TEXT PRIMARY KEY,
    nom TEXT,
    titre TEXT,
    sexe TEXT,
    pays TEXT,
    age INTEGER,
    annee_naissance INTEGER
);

-- Table: Rankings
CREATE TABLE IF NOT EXISTS rankings (
    ranking_id INTEGER PRIMARY KEY AUTOINCREMENT,
    fide_id TEXT,
    year_month TEXT, -- Format: 'YYYY-MM'
    elo_type TEXT CHECK (elo_type IN ('standard', 'rapid', 'blitz')),
    elo INTEGER,
    UNIQUE (fide_id, year_month, elo_type),
    FOREIGN KEY (fide_id) REFERENCES players(fide_id)
);

-- Table: Tournaments
CREATE TABLE IF NOT EXISTS tournaments (
    tournament_id INTEGER PRIMARY KEY,
    nom TEXT,
    lieu TEXT,
    date_debut DATE,
    date_fin DATE,
    format TEXT CHECK (format IN ('standard', 'rapid', 'blitz')),
    vainqueur_id TEXT,
    FOREIGN KEY (vainqueur_id) REFERENCES players(fide_id)
);

-- Table: Games
CREATE TABLE IF NOT EXISTS games (
    game_id INTEGER PRIMARY KEY,
    tournament_id INTEGER,
    date DATE,
    joueur_blanc_id TEXT,
    joueur_noir_id TEXT,
    resultat TEXT CHECK (resultat IN ('1-0', '0-1', '1/2-1/2')),
    format TEXT CHECK (format IN ('standard', 'rapid', 'blitz')),
    FOREIGN KEY (tournament_id) REFERENCES tournaments(tournament_id),
    FOREIGN KEY (joueur_blanc_id) REFERENCES players(fide_id),
    FOREIGN KEY (joueur_noir_id) REFERENCES players(fide_id)
);

-- Table: Tournament Registrations
CREATE TABLE IF NOT EXISTS tournament_registrations (
    registration_id INTEGER PRIMARY KEY AUTOINCREMENT,
    fide_id TEXT,
    tournament_id INTEGER,
    registration_date DATE,
    status TEXT DEFAULT 'registered',
    FOREIGN KEY (fide_id) REFERENCES players(fide_id),
    FOREIGN KEY (tournament_id) REFERENCES tournaments(tournament_id)
);
