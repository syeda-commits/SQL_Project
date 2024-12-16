--1. World Map

SELECT 
    location, 
    SUM(total_cases) AS total_cases, 
    SUM(total_deaths) AS total_deaths,
    (SUM(total_vaccinations) / MAX(population)) * 100 AS vaccination_rate
FROM covid_deaths
JOIN covid_vaccinations USING (location)
WHERE population > 0
GROUP BY location
ORDER BY location;

--2. Bar Chart (Top 5 Regions with the Highest Cases and Deaths)

WITH excluded_locations AS (
    SELECT location 
    FROM covid_deaths
    WHERE location IN ('World', 'International', 'European Union', 'Asia', 'North America', 'South America', 'Africa', 'Oceania')
)
SELECT 
    location, 
    SUM(total_cases) AS total_cases, 
    SUM(total_deaths) AS total_deaths
FROM covid_deaths
WHERE location NOT IN (SELECT location FROM excluded_locations)
GROUP BY location
ORDER BY total_cases DESC
LIMIT 5;


--3. Bubble Chart (Infection Rate vs. Population)

SELECT
    location, 
    population, 
    MAX(total_cases) AS total_cases,
    (MAX(total_cases) / population) * 100 AS percent_population_infected
FROM covid_deaths
WHERE population > 0
GROUP BY location, population
ORDER BY percent_population_infected DESC;

--4. Choropleth Map (Cases Per 100,000 People)

SELECT 
    location, 
    SUM(population) AS total_population,
    CASE 
        WHEN SUM(population) = 0 THEN 0
        ELSE (SUM(total_cases) / SUM(population)) * 100000
    END AS cases_per_100k
FROM covid_deaths
GROUP BY location
ORDER BY cases_per_100k DESC;

--5. Stacked Bar Chart (Vaccination Rates by Region)

SELECT 
    v.location,
    SUM(COALESCE(v.total_vaccinations, 0)) AS total_vaccinations,
    SUM(COALESCE(v.people_fully_vaccinated, 0)) AS people_fully_vaccinated,
    (SUM(COALESCE(v.total_vaccinations, 0)) / MAX(d.population)) * 100 AS vaccination_rate
FROM covid_vaccinations v
JOIN covid_deaths d ON v.location = d.location
WHERE d.population > 0
GROUP BY v.location
ORDER BY vaccination_rate DESC;

--6. Before-and-After Bar Chart (Cases Avoided Post-Vaccination)

WITH case_trends AS (
    SELECT 
        c.location, 
        c.date, 
        SUM(COALESCE(c.new_cases, 0)) AS new_cases,
        SUM(COALESCE(v.people_fully_vaccinated, 0)) OVER (PARTITION BY c.location ORDER BY c.date) AS cumulative_vaccinations
    FROM covid_deaths c
    JOIN covid_vaccinations v ON c.iso_code = v.iso_code AND c.date = v.date
    GROUP BY c.location, c.date, v.people_fully_vaccinated, c.new_cases
)
SELECT 
    location,
    MIN(date) AS vaccination_start_date,
    COALESCE(AVG(new_cases) FILTER (WHERE COALESCE(cumulative_vaccinations, 0) = 0), 0) AS avg_cases_pre_vaccination,
    COALESCE(AVG(new_cases) FILTER (WHERE COALESCE(cumulative_vaccinations, 0) > 0), 0) AS avg_cases_post_vaccination,
    COALESCE(AVG(new_cases) FILTER (WHERE COALESCE(cumulative_vaccinations, 0) = 0), 0) - 
    COALESCE(AVG(new_cases) FILTER (WHERE COALESCE(cumulative_vaccinations, 0) > 0), 0) AS cases_avoided
FROM case_trends
GROUP BY location
ORDER BY cases_avoided DESC;





