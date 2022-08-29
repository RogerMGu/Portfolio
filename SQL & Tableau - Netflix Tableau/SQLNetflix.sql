-- Some rows start with the description in the id column and the 3 previous attributes are not in the data.
-- Remove 171 titles with the wrong format. 
DROP VIEW IF exists dbo.titles_clean

CREATE VIEW dbo.titles_clean as
SELECT id, title, type, release_year, age_certification, runtime, genres, production_countries, seasons, imdb_id, 
try_convert(numeric(3,2), imdb_score) as imdb_score, try_convert(numeric(10,0), imdb_votes) as imdb_votes
FROM Portfolio..titles
WHERE id like 'tm%' 
or id like 'ts%'

-- View of title attributes (seasons only for SHOWS). There are 5.805 titles.
SELECT *
FROM titles_clean

-- View of actors and directors
SELECT *
FROM Portfolio..credits

-- Some time series


-- Average runtime of movies per year (1990 onwards)
SELECT release_year, cast(AVG(runtime) as numeric(10,2)) as average_runtime, cast(AVG(imdb_score) as numeric(3,2)) as average_score, 
cast(sum(imdb_votes) as numeric(10,0)) as total_votes, COUNT(id) as number_titles
FROM titles_clean
WHERE release_year is not null
AND imdb_id is not null
AND type like 'MOVIE'
AND release_year > 1989
GROUP BY release_year
ORDER BY release_year

-- Multiple time series 
SELECT title, release_year, type, runtime, seasons, genres, imdb_score, imdb_votes
FROM titles_clean
WHERE release_year is not null
AND imdb_id is not null
ORDER BY release_year

-- Most voted shows and movies
SELECT title, type, release_year, runtime, genres, production_countries, seasons, imdb_score, imdb_votes
FROM titles_clean
ORDER BY imdb_votes desc

-- Best rated movies (with minimum amount of votes)
SELECT title, release_year, runtime, genres, production_countries, imdb_score, imdb_votes
FROM titles_clean
WHERE type like 'MOVIE'
and imdb_votes >= 5000
ORDER BY imdb_score desc, imdb_votes desc

-- Best rated shows (with minimum amount of votes)
SELECT title, release_year, runtime, genres, production_countries, seasons, imdb_score, imdb_votes
FROM titles_clean
WHERE type like 'SHOW'
and try_convert(numeric(10,1), imdb_votes) >= 5000
ORDER BY imdb_score desc, imdb_votes desc


-- Movies or shows from one director
SELECT ti.title, cr.name as director, ti.release_year, ti.genres, ti.production_countries, ti.imdb_score, ti.imdb_votes
FROM Portfolio..credits cr JOIN titles_clean ti
ON cr.id = ti.id
WHERE cr.role like 'DIRECTOR'
and cr.name like '%nolan%'
ORDER BY release_year

-- Movie or show appearences of one actor
SELECT ti.title, cr.name as actor, cr.character, ti.release_year, ti.genres, ti.production_countries, ti.imdb_score, ti.imdb_votes
FROM Portfolio..credits cr JOIN titles_clean ti
ON cr.id = ti.id
WHERE cr.role like 'ACTOR'
and cr.name like '%Leonardo DiCaprio%'
ORDER BY release_year

-- DIRECTOR and ACTORS for the most voted movie
SELECT TOP 8 cr.name, cr.character, cr.role
FROM Portfolio..credits cr JOIN titles_clean ti
ON cr.id = ti.id
WHERE ti.title like '%inception%'

-- DIRECTOR and ACTORS for the most voted show
SELECT TOP 8 cr.name, cr.character, cr.role
FROM Portfolio..credits cr JOIN titles_clean ti
ON cr.id = ti.id
WHERE ti.title like '%breaking bad%'


-- Most voted shows and movies WITH DIRECTOR
-- Note that some movies have 2 directors
SELECT ti.title, ti.type, cr.name as director, ti.release_year, ti.genres, ti.production_countries, ti.imdb_score, ti.imdb_votes
FROM titles_clean ti LEFT OUTER JOIN Portfolio..credits cr
ON ti.id = cr.id
and cr.role like 'DIRECTOR'
ORDER BY ti.imdb_votes desc



-- Using CTE (Common table expression) to also add MAIN ACTOR and unique DIRECTOR
DROP VIEW if exists dbo.titles_compl
CREATE VIEW dbo.titles_compl as
With title_dir (id, title, type, director, release_year, genres, production_countries, imdb_score, imdb_votes) as 
(
SELECT ti.id, ti.title, ti.type, dr.name as director, ti.release_year, ti.genres, ti.production_countries, ti.imdb_score, ti.imdb_votes
FROM titles_clean ti LEFT JOIN 
(
SELECT *, ROW_NUMBER() OVER (PARTITION BY id ORDER BY role desc) as row_number0
FROM Portfolio..credits
WHERE role like 'DIRECTOR'
) dr -- name of the table with the directors for each title
ON ti.id = dr.id and
dr.row_number0 = 1 -- To get only the first director per title

) -- This concludes the first table with only the director, called title_dir

SELECT td.title, td.type, td.director, ac.name as main_actor, td.release_year, td.genres, td.production_countries, td.imdb_score, td.imdb_votes
FROM title_dir td LEFT JOIN
(
SELECT *, ROW_NUMBER() OVER (PARTITION BY id ORDER BY role) as row_number
FROM Portfolio..credits
WHERE role like 'ACTOR'
) ac -- name of the table of actors
ON td.id = ac.id
and ac.row_number=1 -- To get only the main actor per title
-- ORDER BY try_convert(numeric(10,1), td.imdb_votes) desc -- ordering by number of votes




-- Creating tables for visualization on POWER BI

--TOP 10 popular movies of all time
SELECT TOP 10 title, release_year, genres, director, main_actor, imdb_votes, imdb_score
FROM titles_compl
WHERE type like 'MOVIE'
ORDER BY imdb_votes desc

--TOP 10 popular shows of all time
SELECT TOP 10 title, release_year, genres, main_actor, imdb_votes, imdb_score
FROM titles_compl
WHERE type like 'SHOW'
ORDER BY imdb_votes desc

-- TOP 5 movies of 2022
SELECT TOP 5 title, release_year, genres, director, main_actor, imdb_votes
FROM titles_compl
WHERE type like 'MOVIE' 
and release_year = 2022
ORDER BY imdb_votes desc

-- TOP 5 shows of 2022
SELECT TOP 5 title, release_year, genres, main_actor, imdb_votes
FROM titles_compl
WHERE type like 'SHOW' 
and release_year = 2022
ORDER BY imdb_votes desc

-- TOP 10 movies of this century
SELECT TOP 10 title, release_year, genres, director, main_actor, imdb_votes
FROM titles_compl
WHERE type like 'MOVIE' 
and release_year > 1999
ORDER BY imdb_votes desc

-- TOP 10 shows of this century
SELECT TOP 10 title, release_year, genres, main_actor, imdb_votes
FROM titles_compl
WHERE type like 'SHOW' 
and release_year > 1999
ORDER BY imdb_votes desc

-- TOP 10 movies of last century
SELECT TOP 10 title, release_year, genres, director, main_actor, imdb_votes
FROM titles_compl
WHERE type like 'MOVIE' 
and release_year < 2000
ORDER BY imdb_votes desc

-- TOP 10 shows of last century
SELECT TOP 10 title, release_year, genres, main_actor, imdb_votes
FROM titles_compl
WHERE type like 'SHOW' 
and release_year < 2000
ORDER BY imdb_votes desc


-- TOP 10 actors (sum of votes of movies/shows in which he/she is one of the main actors)
SELECT TOP 10 cr.name as actor, cast(avg(ti.imdb_score) as numeric(3,2)) as average_score, 
count(cr.name) as main_appearences, sum(ti.imdb_votes) as total_votes
FROM 
(
SELECT *, ROW_NUMBER() OVER (PARTITION BY id ORDER BY role) as row_number
FROM Portfolio..credits 
WHERE role like 'ACTOR'
)
cr JOIN titles_clean ti
ON cr.id = ti.id
WHERE cr.row_number < 6 -- Only taking into consideration the first 5 actors
GROUP BY cr.name
ORDER BY total_votes desc


-- TOP 10 directors (sum of votes of movies/shows in which he/she is the director)
SELECT TOP 10 cr.name as director, cast(avg(ti.imdb_score) as numeric(3,2)) as average_score, 
count(cr.name) as directed_movies, sum(ti.imdb_votes) as total_votes
FROM Portfolio..credits cr JOIN titles_clean ti
ON cr.id = ti.id
WHERE cr.role like 'DIRECTOR'
GROUP BY cr.name
ORDER BY total_votes desc


-- by GENRES 
SELECT type, cast(avg(imdb_score) as numeric(3,2)) as average_score, 
sum(imdb_votes) as total_votes, count(title) as amount
FROM titles_compl
WHERE genres like '%drama%'
and try_convert(numeric(10,1), imdb_votes) >= 5000 -- to not have biased scores with a few votes
GROUP BY type

SELECT type, cast(avg(imdb_score) as numeric(3,2)) as average_score, 
sum(imdb_votes) as total_votes, count(title) as amount
FROM titles_compl
WHERE genres like '%comedy%'
and imdb_votes >= 5000
GROUP BY type

SELECT type, cast(avg(imdb_score) as numeric(3,2)) as average_score, 
sum(imdb_votes) as total_votes, count(title) as amount
FROM titles_compl
WHERE genres like '%thriller%'
and try_convert(numeric(10,1), imdb_votes) >= 5000
GROUP BY type

SELECT type, cast(avg(imdb_score) as numeric(3,2)) as average_score, 
sum(imdb_votes) as total_votes, count(title) as amount
FROM titles_compl
WHERE genres like '%action%'
and imdb_votes >= 5000
GROUP BY type

SELECT type, cast(avg(imdb_score) as numeric(3,2)) as average_score, 
sum(imdb_votes) as total_votes, count(title) as amount
FROM titles_compl
WHERE genres like '%romance%'
and imdb_votes >= 5000
GROUP BY type


-- TOP 10 popular drama movies
SELECT TOP 10 title, director, main_actor, release_year, genres, imdb_score, imdb_votes
FROM titles_compl
WHERE genres like '%drama%'
and type like 'MOVIE'
ORDER BY imdb_votes desc

-- TOP 10 popular drama shows
SELECT TOP 10 title, main_actor, release_year, genres, imdb_score, imdb_votes
FROM titles_compl
WHERE genres like '%drama%'
and type like 'SHOW'
ORDER BY imdb_votes desc

-- TOP 10 popular comedy movies
SELECT TOP 10 title, director, main_actor, release_year, genres, imdb_score, imdb_votes
FROM titles_compl
WHERE genres like '%comedy%'
and type like 'MOVIE'
ORDER BY imdb_votes desc

-- TOP 10 popular comedy shows
SELECT TOP 10 title, main_actor, release_year, genres, imdb_score, imdb_votes
FROM titles_compl
WHERE genres like '%comedy%'
and type like 'SHOW'
ORDER BY imdb_votes desc

-- TOP 10 popular thriller movies
SELECT TOP 10 title, director, main_actor, release_year, genres, imdb_score, imdb_votes
FROM titles_compl
WHERE genres like '%thriller%'
and type like 'MOVIE'
ORDER BY imdb_votes desc

-- TOP 10 popular thriller shows
SELECT TOP 10 title, main_actor, release_year, genres, imdb_score, imdb_votes
FROM titles_compl
WHERE genres like '%thriller%'
and type like 'SHOW'
ORDER BY imdb_votes desc

-- TOP 10 popular romance movies
SELECT TOP 10 title, director, main_actor, release_year, genres, imdb_score, imdb_votes
FROM titles_compl
WHERE genres like '%romance%'
and type like 'MOVIE'
ORDER BY imdb_votes desc

-- TOP 10 popular romance shows
SELECT TOP 10 title, main_actor, release_year, genres, imdb_score, imdb_votes
FROM titles_compl
WHERE genres like '%romance%'
and type like 'SHOW'
ORDER BY imdb_votes desc