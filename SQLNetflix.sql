-- Some rows start with the description in the id column and the 3 previous attributes are not in the data.
-- Remove 171 titles with the wrong format. 
DROP VIEW IF exists dbo.titles_clean
CREATE VIEW dbo.titles_clean as
SELECT id, title, type, release_year, age_certification, runtime, genres, production_countries, seasons, imdb_id, imdb_score, imdb_votes
FROM titles
WHERE id like 'tm%' 
or id like 'ts%'

-- View of title attributes (seasons only for SHOWS). There are 5.805 titles.
SELECT *
FROM titles_clean

-- View of actors and directors
SELECT *
FROM credits


-- Most voted shows and movies
SELECT title, type, release_year, runtime, genres, production_countries, seasons, imdb_score, imdb_votes
FROM titles_clean
ORDER BY try_convert(numeric(10,1), imdb_votes) desc

-- Best rated movies (with minimum amount of votes)
SELECT title, release_year, runtime, genres, production_countries, imdb_score, imdb_votes
FROM titles_clean
WHERE type like 'MOVIE'
and try_convert(numeric(10,1), imdb_votes) >= 5000
ORDER BY imdb_score desc, try_convert(numeric(10,1), imdb_votes) desc

-- Best rated shows (with minimum amount of votes)
SELECT title, release_year, runtime, genres, production_countries, seasons, imdb_score, imdb_votes
FROM titles_clean
WHERE type like 'SHOW'
and try_convert(numeric(10,1), imdb_votes) >= 5000
ORDER BY imdb_score desc, try_convert(numeric(10,1), imdb_votes) desc


-- Movies or shows from one director
SELECT ti.title, cr.name as director, ti.release_year, ti.genres, ti.production_countries, ti.imdb_score, ti.imdb_votes
FROM credits cr JOIN titles_clean ti
ON cr.id = ti.id
WHERE cr.role like 'DIRECTOR'
and cr.name like '%nolan%'
ORDER BY release_year

-- Movie or show appearences of one actor
SELECT ti.title, cr.name as actor, cr.character, ti.release_year, ti.genres, ti.production_countries, ti.imdb_score, ti.imdb_votes
FROM credits cr JOIN titles_clean ti
ON cr.id = ti.id
WHERE cr.role like 'ACTOR'
and cr.name like '%Leonardo DiCaprio%'
ORDER BY release_year

-- DIRECTOR and ACTORS for the most voted movie
SELECT TOP 8 cr.name, cr.character, cr.role
FROM credits cr JOIN titles_clean ti
ON cr.id = ti.id
WHERE ti.title like '%inception%'

-- DIRECTOR and ACTORS for the most voted show
SELECT TOP 8 cr.name, cr.character, cr.role
FROM credits cr JOIN titles_clean ti
ON cr.id = ti.id
WHERE ti.title like '%breaking bad%'


-- Most voted shows and movies WITH DIRECTOR
-- Note that some movies have 2 directors
SELECT ti.title, ti.type, cr.name as director, ti.release_year, ti.genres, ti.production_countries, ti.imdb_score, ti.imdb_votes
FROM titles_clean ti LEFT OUTER JOIN credits cr
ON ti.id = cr.id
WHERE cr.role like 'DIRECTOR'
ORDER BY try_convert(numeric(10,1), ti.imdb_votes) desc



-- Using CTE (Common table expression) to also add MAIN ACTOR and unique DIRECTOR

With title_dir (id, title, type, director, release_year, genres, production_countries, imdb_score, imdb_votes) as 
(
SELECT ti.id, ti.title, ti.type, dr.name as director, ti.release_year, ti.genres, ti.production_countries, ti.imdb_score, ti.imdb_votes
FROM titles_clean ti JOIN 
(
SELECT *, ROW_NUMBER() OVER (PARTITION BY id ORDER BY role desc) as row_number0
FROM credits
WHERE role like 'DIRECTOR'
) dr -- name of the table with the directors for each title
ON ti.id = dr.id
WHERE dr.row_number0 = 1 -- To get only the first director per title

) -- This concludes the first table with only the director

SELECT td.title, td.type, ac.name as actor, td.director, td.release_year, td.genres, td.production_countries, td.imdb_score, td.imdb_votes
FROM title_dir td JOIN
(
SELECT *, ROW_NUMBER() OVER (PARTITION BY id ORDER BY role) as row_number
FROM credits
WHERE role like 'ACTOR'
) ac -- name of the table of actors
ON td.id = ac.id
WHERE ac.row_number=1 -- To get only the main actor per title
ORDER BY try_convert(numeric(10,1), td.imdb_votes) desc -- ordering by number of votes



-- Creating VIEWS for visualization on POWER BI

--TOP 10 popular movies
SELECT TOP 10 title, release_year, genres, imdb_votes
FROM titles_clean
WHERE type like 'MOVIE'
ORDER BY try_convert(numeric(10,1), imdb_votes) desc

--TOP 10 popular shows
SELECT TOP 10 title, release_year, genres, imdb_votes
FROM titles_clean
WHERE type like 'SHOW'
ORDER BY try_convert(numeric(10,1), imdb_votes) desc

-- TOP 5 movies of 2022
SELECT TOP 5 title, release_year, genres, imdb_votes
FROM titles_clean
WHERE type like 'MOVIE' 
and release_year = 2022
ORDER BY try_convert(numeric(10,1), imdb_votes) desc

-- TOP 5 shows of 2022
SELECT TOP 5 title, release_year, genres, imdb_votes
FROM titles_clean
WHERE type like 'SHOW' 
and release_year = 2022
ORDER BY try_convert(numeric(10,1), imdb_votes) desc

-- TOP 10 movies of this century
SELECT TOP 5 title, release_year, genres, imdb_votes
FROM titles_clean
WHERE type like 'MOVIE' 
and release_year > 1999
ORDER BY try_convert(numeric(10,1), imdb_votes) desc

-- TOP 10 shows of this century
SELECT TOP 5 title, release_year, genres, imdb_votes
FROM titles_clean
WHERE type like 'SHOW' 
and release_year > 1999
ORDER BY try_convert(numeric(10,1), imdb_votes) desc

-- TOP 10 movies of last century
SELECT TOP 5 title, release_year, genres, imdb_votes
FROM titles_clean
WHERE type like 'MOVIE' 
and release_year < 2000
ORDER BY try_convert(numeric(10,1), imdb_votes) desc

-- TOP 10 actors (sum of votes of movies/shows in which he/she is one of the main actors)
SELECT TOP 10 cr.name as actor, cast(avg(try_convert(numeric(10,1),ti.imdb_score)) as numeric(3,2)) as average_score, 
count(cr.name) as main_appearences, sum(try_convert(numeric(10,1),ti.imdb_votes)) as total_votes
FROM 
(
SELECT *, ROW_NUMBER() OVER (PARTITION BY id ORDER BY role) as row_number
FROM credits 
WHERE role like 'ACTOR'
)
cr JOIN titles_clean ti
ON cr.id = ti.id
WHERE cr.row_number < 6 -- Only taking into consideration the first 5 actors
GROUP BY cr.name
ORDER BY total_votes desc


-- TOP 10 directors (sum of votes of movies/shows in which he/she is the director)
SELECT TOP 10 cr.name as director, cast(avg(try_convert(numeric(10,1),ti.imdb_score)) as numeric(3,2)) as average_score, 
count(cr.name) as directed_movies, sum(try_convert(numeric(10,1),ti.imdb_votes)) as total_votes
FROM credits cr JOIN titles_clean ti
ON cr.id = ti.id
WHERE cr.role like 'DIRECTOR'
GROUP BY cr.name
ORDER BY total_votes desc


-- To do:
--	- Show main Movie/Show per actor or director in the Top 10.
--  - TOP 10 total votes per genre (or average score).
--  - TOP 10 movies/shows for the (2, 3, 4 or 5) genres with most votes.
--  - Show the director for the TOP movies and shows (there will be some duplicates).