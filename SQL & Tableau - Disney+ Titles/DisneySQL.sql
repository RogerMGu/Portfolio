SELECT *
FROM Portfolio.dbo.disney_titles


DROP VIEW IF exists dbo.disney_titles_clean
CREATE VIEW dbo.disney_titles_clean as
SELECT id, title, type, release_year, age_certification, runtime, genres, production_countries, seasons, 
try_convert(numeric(3,2), imdb_score) as imdb_score, try_convert(numeric(10,0), imdb_votes) as imdb_votes
FROM Portfolio..disney_titles
WHERE release_year is not null -- 41 NULLS
and imdb_votes is not null -- 412 NULLS


SELECT *
FROM disney_titles_clean
ORDER BY imdb_votes desc


-- Popular disney movies
SELECT TOP 10 title, release_year, runtime, genres, imdb_score, imdb_votes
FROM disney_titles_clean
WHERE type like 'MOVIE'
ORDER BY imdb_votes desc

-- Popular disney shows
SELECT TOP 10 title, release_year, runtime, genres, seasons, imdb_score, imdb_votes
FROM disney_titles_clean
WHERE type like 'SHOW'
ORDER BY imdb_votes desc

-- Popular disney animated movies
SELECT title, type, release_year, runtime, genres, imdb_score, imdb_votes
FROM disney_titles_clean
WHERE genres like '%animation%'
ORDER BY imdb_votes desc

-- Best disney shows
SELECT TOP 10 title, release_year, runtime, genres, seasons, imdb_score, imdb_votes
FROM disney_titles_clean
WHERE type like 'SHOW'
and imdb_votes >= 10000
ORDER BY imdb_score desc



------ Tableau Visualization ------
-- All titles with a new variable "animated"
SELECT title, type, release_year, seasons, runtime, genres, imdb_votes, imdb_score, CASE when genres like '%animation%' then 'Yes' else 'No' end as animated
FROM disney_titles_clean


-- Most popular title per year
SELECT a.title, a.type, a.release_year, a.runtime, a.genres, a.imdb_score, a.imdb_votes
FROM disney_titles_clean a INNER JOIN (
SELECT release_year, max(imdb_votes) as most_votes
FROM disney_titles_clean
GROUP BY release_year
) b ON a.release_year=b.release_year and a.imdb_votes=b.most_votes
ORDER BY release_year