-- SECTION 1 : CRÉATION & MODIFICATION

-- 1.1  Créer ou inscrire un nouveau joueur 
INSERT INTO players (fide_id, name, title, country, rating, birth_year, gender)
VALUES (999001, 'Joueur Test', 'CM', 'FRA', 2100, 2005, 'M');

-- 1.2  Créer un nouveau tournoi avec cadence ici appelé Summer Rapid Cup
INSERT INTO tournaments (tournament_id, name, city, country, start_date, end_date)
VALUES (30, 'Summer Rapid Cup', 'Lyon', 'FRA', '2025-08-02', '2025-08-04');

-- 1.3  Inscrire 8 meilleurs Elo au tournoi 30
INSERT INTO registrations (tournament_id, fide_id, seed, bye, fee_paid)
SELECT 30,
       fide_id,
       ROW_NUMBER() OVER (ORDER BY rating DESC),
       0,
       1
FROM   players
ORDER  BY rating DESC
LIMIT  8;

-- 1.4  Ajouter une partie manuellement dans le tournoi 30
INSERT INTO games (tournament_id, round, white_id, black_id, result, pgn)
VALUES (30, 1, 119, 190, '1-0', '[PGN ICI]');

-- 1.5  Mettre à jour le rating d'un joueur
UPDATE players
SET    rating = rating + 10
WHERE  fide_id = 119;

-- 1.6  Supprimer l'inscription d'un joueur
DELETE FROM registrations
WHERE  tournament_id = 30 AND fide_id = 999001;

-- 1.7  Supprimer un tournoi 
DELETE FROM tournaments
WHERE  tournament_id = 30;

-- SECTION 2 : CLASSEMENTS INSTANTANÉS

-- 2.1  Top 10 mondial
SELECT fide_id, name, rating
FROM   players
ORDER  BY rating DESC
LIMIT  10;

-- 2.2  Top 10 féminin
SELECT fide_id, name, rating
FROM   players
WHERE  gender = 'F'
ORDER  BY rating DESC
LIMIT  10;

-- 2.3  Top 10 masculin
SELECT fide_id, name, rating
FROM   players
WHERE  gender = 'M'
ORDER  BY rating DESC
LIMIT  10;

-- 2.4  Top 5 juniors (< 20 ans)
SELECT fide_id, name, rating,
       strftime('%Y','now') - birth_year AS age
FROM   players
WHERE  birth_year IS NOT NULL
  AND  (strftime('%Y','now') - birth_year) < 20
ORDER  BY rating DESC
LIMIT  5;

-- 2.5  Vue : classement Blitz
CREATE VIEW IF NOT EXISTS v_top_blitz AS
SELECT fide_id, name, elo_blitz
FROM   players
WHERE  elo_blitz IS NOT NULL
ORDER  BY elo_blitz DESC;

-- 2.6  Vue : classement Rapid
CREATE VIEW IF NOT EXISTS v_top_rapid AS
SELECT fide_id, name, elo_rapid
FROM   players
WHERE  elo_rapid IS NOT NULL
ORDER  BY elo_rapid DESC;

-- 2.7  Top 10 Blitz (via vue)
SELECT * FROM v_top_blitz LIMIT 10;

-- 2.8  Top 10 Rapid (via vue)
SELECT * FROM v_top_rapid LIMIT 10;

-- SECTION 3 : STATISTIQUES GLOBALES

-- 3.1  Nombre de joueurs par titre
SELECT title, COUNT(*) AS nb
FROM   players
GROUP  BY title
ORDER  BY nb DESC;

-- 3.2  Âge moyen des joueurs
SELECT AVG(strftime('%Y','now') - birth_year) AS age_moyen
FROM   players
WHERE  birth_year IS NOT NULL;

-- 3.3  Répartition des résultats
SELECT result, COUNT(*) AS nb
FROM   games
GROUP  BY result;

-- 3.4  Vue : moyenne Elo par pays
CREATE VIEW IF NOT EXISTS v_country_avg AS
SELECT country, AVG(rating) AS elo_moyen
FROM   players
WHERE  country <> ''
GROUP  BY country;

-- 3.5  Pays à > 2400 de moyenne
SELECT *
FROM   v_country_avg
WHERE  elo_moyen >= 2400
ORDER  BY elo_moyen DESC;

-- 3.6  Percentile de rating (top 20)
SELECT name,
       rating,
       PERCENT_RANK() OVER (ORDER BY rating) AS percentile
FROM   players
ORDER  BY rating DESC
LIMIT  20;

-- 3.7  Vue : bilan victoires/nuls/défaites par joueur
CREATE VIEW IF NOT EXISTS v_player_score AS
SELECT p.fide_id,
       p.name,
       SUM(CASE WHEN (g.white_id = p.fide_id AND g.result = '1-0')
                 OR (g.black_id = p.fide_id AND g.result = '0-1') THEN 1 ELSE 0 END) AS wins,
       SUM(CASE WHEN g.result = '1/2-1/2' THEN 1 ELSE 0 END)                           AS draws,
       SUM(CASE WHEN (g.white_id = p.fide_id AND g.result = '0-1')
                 OR (g.black_id = p.fide_id AND g.result = '1-0') THEN 1 ELSE 0 END) AS losses
FROM   players AS p
LEFT   JOIN games   AS g
       ON g.white_id = p.fide_id OR g.black_id = p.fide_id
GROUP  BY p.fide_id;

-- 3.8  Exemple : score du joueur 119
SELECT * FROM v_player_score WHERE fide_id = 119;

-- 3.9  Vue : performance moyenne par tournoi
CREATE VIEW IF NOT EXISTS v_perf_tournament AS
SELECT g.tournament_id,
       p.fide_id,
       p.name,
       AVG(
         CASE g.result
              WHEN '1-0' THEN CASE WHEN g.white_id = p.fide_id THEN 1 ELSE 0 END
              WHEN '0-1' THEN CASE WHEN g.black_id = p.fide_id THEN 1 ELSE 0 END
              ELSE 0.5
         END
       ) AS points_par_partie
FROM   games   AS g
JOIN   players AS p
  ON p.fide_id = g.white_id OR p.fide_id = g.black_id
GROUP  BY g.tournament_id, p.fide_id;

-- 3.10 Classement performance tournoi 1
SELECT * 
FROM   v_perf_tournament
WHERE  tournament_id = 1
ORDER  BY points_par_partie DESC
LIMIT  10;

-- SECTION 4 : ÉVOLUTION & ARCHIVAGE

-- 4.1  Vue du  classement le plus récent
CREATE VIEW IF NOT EXISTS v_rankings_latest AS
SELECT r.*
FROM   rankings AS r
WHERE  NOT EXISTS (
        SELECT 1 FROM rankings AS r2
        WHERE  r2.fide_id = r.fide_id
          AND (r2.year  > r.year
               OR (r2.year = r.year AND r2.month > r.month))
);

-- 4.2  Top 20 le plus récent
SELECT l.fide_id, p.name, l.rating
FROM   v_rankings_latest AS l
JOIN   players           AS p USING (fide_id)
ORDER  BY l.rating DESC
LIMIT  20;

-- 4.3  Archivage mensuel : copier ratings actuels
INSERT INTO rankings (fide_id, rating, rank, month, year)
SELECT fide_id,
       rating,
       ROW_NUMBER() OVER (ORDER BY rating DESC),
       strftime('%m','now'),
       strftime('%Y','now')
FROM   players
WHERE  NOT EXISTS (SELECT 1
                   FROM rankings
                   WHERE fide_id = players.fide_id
                     AND month   = strftime('%m','now')
                     AND year    = strftime('%Y','now'));

-- 4.4   évolution Elo entre deux mois
CREATE VIEW IF NOT EXISTS v_rating_diff AS
SELECT r1.fide_id,
       p.name,
       r1.year  AS year1,  r1.month AS month1,  r1.rating AS rating1,
       r2.year  AS year2,  r2.month AS month2,  r2.rating AS rating2,
       r2.rating - r1.rating AS gain
FROM   rankings AS r1
JOIN   rankings AS r2 USING (fide_id)
JOIN   players   AS p  USING (fide_id)
WHERE  (r2.year  > r1.year)
   OR  (r2.year  = r1.year AND r2.month > r1.month);

-- 4.5  Vue : évolution du rang
CREATE VIEW IF NOT EXISTS v_rank_diff AS
SELECT base.fide_id,
       base.name,
       base.month1, base.rank1,
       base.month2, base.rank2,
       base.rank1 - base.rank2 AS places_gagnees
FROM (
    SELECT r1.fide_id,
           p.name,
           r1.month AS month1,
           r1.rank  AS rank1,
           r2.month AS month2,
           r2.rank  AS rank2
    FROM   rankings AS r1
    JOIN   rankings AS r2 USING (fide_id)
    JOIN   players   AS p  USING (fide_id)
    WHERE  r1.year = r2.year
      AND  r2.month = r1.month + 1
) AS base;

-- 4.6  Joueurs gagnant ≥ 50 Elo et ≥ 10 places d'un mois à l'autre
WITH diff AS (
  SELECT d.fide_id, d.name, d.gain,
         r1.rank AS rank_old, r2.rank AS rank_new
  FROM   v_rating_diff AS d
  JOIN   rankings      AS r1
        ON r1.fide_id = d.fide_id AND r1.year = d.year1 AND r1.month = d.month1
  JOIN   rankings      AS r2
        ON r2.fide_id = d.fide_id AND r2.year = d.year2 AND r2.month = d.month2
)
SELECT *
FROM   diff
WHERE  gain >= 50 AND (rank_old - rank_new) >= 10
ORDER  BY gain DESC;

-- SECTION 5 : AUTOMATISATION 

-- 5.1  Trigger avec mise à jour automatique du rating
CREATE TRIGGER IF NOT EXISTS trg_update_player_rating
AFTER INSERT ON rankings
WHEN NOT EXISTS (SELECT 1
                 FROM rankings AS r2
                 WHERE r2.fide_id = NEW.fide_id
                   AND (r2.year  > NEW.year
                        OR (r2.year = NEW.year AND r2.month > NEW.month)))
BEGIN
    UPDATE players
    SET    rating = NEW.rating
    WHERE  fide_id = NEW.fide_id;
END;

-- 5.2  Table de log des suppressions (si non créée)
CREATE TABLE IF NOT EXISTS deletions_log (
    id INTEGER PRIMARY KEY,
    entity TEXT,
    entity_id INTEGER,
    deleted_at TEXT
);

-- 5.3  log avant suppression d'un tournoi
CREATE TRIGGER IF NOT EXISTS trg_log_tournament_delete
BEFORE DELETE ON tournaments
BEGIN
    INSERT INTO deletions_log(entity, entity_id, deleted_at)
    VALUES ('tournament', OLD.tournament_id, datetime('now'));
END;

-- 5.4  Nettoyer les joueurs orphelins
DELETE FROM players
WHERE fide_id NOT IN (SELECT fide_id FROM rankings)
  AND fide_id NOT IN (SELECT white_id FROM games
                       UNION
                      SELECT black_id FROM games);


-- 5.6  Archivage auto lors de l'insertion d'une partie
CREATE TRIGGER IF NOT EXISTS trg_archive_on_game
AFTER INSERT ON games
BEGIN
  INSERT OR IGNORE INTO rankings (fide_id, rating, rank, month, year)
  SELECT fide_id,
         rating,
         ROW_NUMBER() OVER (ORDER BY rating DESC),
         strftime('%m','now'),
         strftime('%Y','now')
  FROM   players
  WHERE  NOT EXISTS (SELECT 1
                     FROM rankings
                     WHERE fide_id = players.fide_id
                       AND month   = strftime('%m','now')
                       AND year    = strftime('%Y','now'));
END;

-- SECTION 6 : VUES & ANALYSES

-- 6.1  Classement final d’un tournoi (points + départage)
CREATE VIEW IF NOT EXISTS v_tournament_standings AS
WITH scores AS (
  SELECT g.tournament_id,
         p.fide_id,
         p.name,
         SUM( CASE
                 WHEN g.white_id = p.fide_id AND g.result = '1-0' THEN 1
                 WHEN g.black_id = p.fide_id AND g.result = '0-1' THEN 1
                 WHEN g.result = '1/2-1/2' THEN 0.5
                 ELSE 0
              END )                           AS pts
  FROM   games g
  JOIN   players p
         ON p.fide_id = g.white_id OR p.fide_id = g.black_id
  GROUP  BY g.tournament_id, p.fide_id
),
sb AS (
  -- somme des points des adversaires battus + moitié des nuls
  SELECT s1.tournament_id,
         s1.fide_id,
         SUM(
           CASE
             WHEN (g.white_id = s1.fide_id AND g.result = '1-0')
               OR (g.black_id = s1.fide_id AND g.result = '0-1')
             THEN s2.pts
             WHEN g.result = '1/2-1/2' THEN 0.5 * s2.pts
             ELSE 0
           END
         ) AS sb_score
  FROM   scores s1
  JOIN   games  g
         ON g.tournament_id = s1.tournament_id
        AND (g.white_id = s1.fide_id OR g.black_id = s1.fide_id)
  JOIN   scores s2   -- adversaire
         ON s2.tournament_id = g.tournament_id
        AND ( (g.white_id = s1.fide_id AND s2.fide_id = g.black_id)
           OR   (g.black_id = s1.fide_id AND s2.fide_id = g.white_id) )
  GROUP  BY s1.tournament_id, s1.fide_id
)
SELECT s.tournament_id,
       s.fide_id,
       s.name,
       s.pts,
       sb.sb_score,
       RANK() OVER (PARTITION BY s.tournament_id
                    ORDER BY s.pts DESC, sb.sb_score DESC) AS classement
FROM   scores s
JOIN   sb      USING (tournament_id, fide_id);

-- Exemple : classement du tournoi 1
SELECT * FROM v_tournament_standings
WHERE  tournament_id = 1
ORDER  BY classement;


-- 6.2  Bilan 1vs1 global pour chaque joueurs
CREATE VIEW IF NOT EXISTS v_h2h_summary AS
SELECT LEAST(white_id, black_id) AS p1,
       GREATEST(white_id, black_id) AS p2,
       SUM(CASE WHEN white_id < black_id AND result = '1-0'
                 OR white_id > black_id AND result = '0-1' THEN 1 ELSE 0 END) AS win_p1,
       SUM(result = '1/2-1/2')                                                AS draws,
       SUM(CASE WHEN white_id < black_id AND result = '0-1'
                 OR white_id > black_id AND result = '1-0' THEN 1 ELSE 0 END) AS win_p2
FROM   games
GROUP  BY p1, p2;

-- Exemple : historique entre fidéles joueur a id  119 et 190
SELECT p1, p2, win_p1, draws, win_p2
FROM   v_h2h_summary
WHERE  p1 = 119 AND p2 = 190;


-- 6.3  Vue : progression annuelle d’Elo par joueur
CREATE VIEW IF NOT EXISTS v_yearly_progress AS
SELECT fide_id,
       year,
       MAX(rating) AS best_rating,
       MIN(rating) AS lowest_rating,
       MAX(rating) - MIN(rating) AS delta
FROM   rankings
GROUP  BY fide_id, year;

-- Exemple : top 10 des plus fortes progressions en 2025
SELECT p.name, v.delta
FROM   v_yearly_progress v
JOIN   players p USING (fide_id)
WHERE  year = 2025
ORDER  BY v.delta DESC
LIMIT  10;


-- 6.4  Vue : top joueur par pays (Elo standard)
CREATE VIEW IF NOT EXISTS v_country_top AS
SELECT country,
       fide_id,
       name,
       rating
FROM   (
  SELECT country, fide_id, name, rating,
         ROW_NUMBER() OVER (PARTITION BY country ORDER BY rating DESC) AS rk
  FROM   players
) t
WHERE  rk = 1;

-- Exemple : top 20 pays
SELECT * FROM v_country_top
ORDER  BY rating DESC
LIMIT  20;


-- 6.5  La forme récente  de chaque joueur sue les 5 dernières parties
CREATE VIEW IF NOT EXISTS v_recent_form AS
WITH last5 AS (
  SELECT game_id,
         fide_id,
         result,
         ROW_NUMBER() OVER (PARTITION BY fide_id ORDER BY game_id DESC) AS rn
  FROM (
    SELECT game_id, white_id AS fide_id,
           CASE result WHEN '1-0' THEN 'W'
                       WHEN '0-1' THEN 'L'
                       ELSE 'D' END AS result
    FROM   games
    UNION ALL
    SELECT game_id, black_id AS fide_id,
           CASE result WHEN '0-1' THEN 'W'
                       WHEN '1-0' THEN 'L'
                       ELSE 'D' END
    FROM   games
  )
)
SELECT fide_id,
       GROUP_CONCAT(result, '') AS last5_results
FROM   last5
WHERE  rn <= 5
GROUP  BY fide_id;

-- Exemple : forme du joueur 119
SELECT p.name, f.last5_results
FROM   v_recent_form f
JOIN   players p USING (fide_id)
WHERE  fide_id = 119;


-- 6.6  Distribution d'âge par tranche de 10 ans
CREATE VIEW IF NOT EXISTS v_age_bucket AS
SELECT ((strftime('%Y','now') - birth_year)/10)*10 AS tranche,
       COUNT(*) AS nb
FROM   players
WHERE  birth_year IS NOT NULL
GROUP  BY tranche
ORDER  BY tranche;

-- Exemple : afficher la distribution
SELECT * FROM v_age_bucket;
