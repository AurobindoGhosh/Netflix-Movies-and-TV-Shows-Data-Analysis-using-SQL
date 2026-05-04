create database netflix;
use netflix;

CREATE TABLE netflix
(
	show_id	VARCHAR(5),
	type    VARCHAR(10),
	title	VARCHAR(250),
	director VARCHAR(550),
	casts	VARCHAR(1050),
	country	VARCHAR(550),
	date_added	VARCHAR(55),
	release_year	INT,
	rating	VARCHAR(15),
	duration	VARCHAR(15),
	listed_in	VARCHAR(250),
	description VARCHAR(550)
);

SET SESSION sql_mode = '';
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/netflix_titles.csv'
INTO TABLE netflix
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM netflix;

-- Q1. Count the number of Movies vs TV Shows
SELECT 
	type,
	COUNT(*)
FROM netflix
GROUP BY 1;

-- Q2. Find the most common rating for movies and TV shows
SELECT type, rating AS most_frequent_rating
FROM (
    SELECT 
        type,
        rating,
        COUNT(*) AS rating_count,
        RANK() OVER (
            PARTITION BY type 
            ORDER BY COUNT(*) DESC
        ) AS rnk
    FROM netflix
    GROUP BY type, rating
) ranked
WHERE rnk = 1;

-- Q3. List all movies released in a specific year (e.g., 2020)
SELECT * 
FROM netflix
WHERE release_year = 2020;

-- Q4. Find the top 5 countries with the most content on Netflix
SELECT 
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(country, ',', n.n), ',', -1)) AS country,
    COUNT(*) AS total_content
FROM netflix
JOIN (
    SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 
    UNION ALL SELECT 4 UNION ALL SELECT 5
) n
ON CHAR_LENGTH(country) - CHAR_LENGTH(REPLACE(country, ',', '')) >= n.n - 1
WHERE country IS NOT NULL
  AND TRIM(country) <> ''
GROUP BY country
HAVING country <> ''   -- extra safety
ORDER BY total_content DESC
LIMIT 5;

-- Q.5. Identify the longest movie
SELECT 
    title,
    duration,
    CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) AS duration_minutes
FROM netflix
WHERE type = 'Movie'
  AND duration LIKE '%min'
ORDER BY duration_minutes DESC
LIMIT 1;

-- Q.6. Find content added in the last 5 years
SELECT
    dt,
    COUNT(*) AS titles_added,
    SUM(COUNT(*)) OVER (ORDER BY dt) AS cumulative_titles
FROM (
    SELECT
        STR_TO_DATE(date_added, '%M %d, %Y') AS dt
    FROM netflix
    WHERE date_added IS NOT NULL
      AND date_added LIKE '%, %'   -- ensures proper format
) t
WHERE dt IS NOT NULL
GROUP BY dt
ORDER BY dt;

-- Q.7. Find all the movies/TV shows by director 'Rajiv Chilaka'!
SELECT 
    type,
    title,
    director
FROM netflix
WHERE director LIKE '%Rajiv Chilaka%';

-- Q.8. List all TV shows with more than 5 seasons
SELECT 
    title,
    duration,
    CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) AS seasons
FROM netflix
WHERE type = 'TV Show'
  AND duration LIKE '%Season%'
  AND CAST(SUBSTRING_INDEX(duration, ' ', 1) AS UNSIGNED) > 5
ORDER BY seasons DESC;

-- Q.9. Count the number of content items in each genre

-- Baseline Solution
SELECT listed_in, COUNT(*) AS total_content
FROM netflix
WHERE listed_in IS NOT NULL
GROUP BY listed_in
ORDER BY total_content DESC;

-- Accurate Solution
SELECT 
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(listed_in, ',', n.n), ',', -1)) AS genre,
    COUNT(*) AS total_content
FROM netflix
JOIN (
    SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 
    UNION ALL SELECT 4 UNION ALL SELECT 5
) n
ON CHAR_LENGTH(listed_in) - CHAR_LENGTH(REPLACE(listed_in, ',', '')) >= n.n - 1
WHERE listed_in IS NOT NULL
GROUP BY genre
ORDER BY total_content DESC;

-- Q10. Find each year and the average numbers of content release in India on netflix. return top 5 year with highest avg content release!
WITH monthly_data AS (
    SELECT
        YEAR(STR_TO_DATE(date_added, '%M %d, %Y')) AS year_added,
        MONTH(STR_TO_DATE(date_added, '%M %d, %Y')) AS month_added,
        COUNT(*) AS monthly_count
    FROM netflix
    WHERE country LIKE '%India%'
      AND date_added IS NOT NULL
      AND date_added REGEXP '^[A-Za-z]+ [0-9]{1,2}, [0-9]{4}$'
    GROUP BY year_added, month_added
),
yearly_avg AS (
    SELECT
        year_added,
        AVG(monthly_count) AS avg_content_per_month
    FROM monthly_data
    GROUP BY year_added
)
SELECT *
FROM yearly_avg
ORDER BY avg_content_per_month DESC
LIMIT 5; 

-- Q11, List all movies that are documentries.
SELECT 
    title,
    listed_in
FROM netflix
WHERE type = 'Movie'
  AND listed_in LIKE '%Documentaries%';
  
  -- Q12. Find all the content without a director
  SELECT 
    title,
    type,
    director
FROM netflix
WHERE director IS NULL
   OR TRIM(director) = '';
   
-- Q.13. Find how many movies actor 'Salman Khan' appeared in last 10 years!
SELECT COUNT(*) AS total_movies
FROM netflix
WHERE type = 'Movie'
  AND casts LIKE '%Salman Khan%'
  AND release_year >= YEAR(CURDATE()) - 10;

-- Q14. Find the top 10 actors who have appeared in the highest number of movies produced in India.
SELECT 
    TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(casts, ',', n.n), ',', -1)) AS actor,
    COUNT(*) AS total_movies
FROM netflix
JOIN (
    SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 
    UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6
) n
ON CHAR_LENGTH(casts) - CHAR_LENGTH(REPLACE(casts, ',', '')) >= n.n - 1
WHERE type = 'Movie'
  AND country LIKE '%India%'
  AND casts IS NOT NULL
GROUP BY actor
HAVING actor <> ''
ORDER BY total_movies DESC
LIMIT 10;