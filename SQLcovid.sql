-- First view of cases and deaths.

SELECT location, date, new_cases, total_cases
FROM Covid
WHERE continent is not null
ORDER BY location, date

-- Death rate by country

SELECT location, date, total_deaths, total_cases, total_deaths/total_cases*100 as DeathPercentage
FROM Covid
WHERE continent is not null
and location like 'Spain'
ORDER BY location, date

-- Infected population or "Probability of having gotten infected at any time of the study for a person in a certain country"

SELECT location, max(population) as population, sum(new_cases) as total_cases, sum(new_cases)/max(population)*100 as InfectionPercentage
FROM Covid
WHERE continent is not null
GROUP BY location
ORDER BY InfectionPercentage desc


-- Locations with most deaths

SELECT location, max(population) as population, sum(cast(new_deaths as int)) as total_deaths, max(convert(decimal(10,2), replace(total_deaths_per_million, ',', '.'))) as DeathsPerMillion
FROM Covid
WHERE continent is not null
GROUP BY location
ORDER BY total_deaths desc

-- Death rate compared to how aged the population is

SELECT co.location, max(co.population) as population, max(co.total_deaths)/max(co.total_cases)*100 as DeathPercentage,
max(tr.median_age) as median_age, max(tr.life_expectancy) as life_expectancy
FROM Covid co JOIN Traits tr
ON co.location = tr.location and co.date = tr.date
WHERE co.continent is not null
GROUP BY co.location
ORDER BY median_age desc

-- Do smoking or having diabetes influence on the death rate?

SELECT co.location, max(co.population) as population, max(co.total_deaths)/max(co.total_cases)*100 as DeathPercentage,
(max(convert(decimal(10,2), replace(tr.female_smokers, ',', '.'))) + max(convert(decimal(10,2), replace(tr.male_smokers, ',', '.'))))/2 
as SmokersPercentage, max(tr.diabetes_prevalence) as diabetes_prevalence, max(tr.cardiovasc_death_rate) as CardiovascDeathPercentage
FROM Covid co JOIN Traits tr
ON co.location = tr.location and co.date = tr.date
WHERE co.continent is not null
GROUP BY co.location
ORDER BY SmokersPercentage desc

-- Death rate compared to country's development and economy

SELECT co.location, max(co.population) as population, max(co.total_deaths)/max(co.total_cases) as DeathRate,
max(tr.human_development_index) as human_development_index, max(tr.gdp_per_capita) as gdp_per_capita, 
max(tr.extreme_poverty) as extreme_poverty
FROM Covid co JOIN Traits tr
ON co.location = tr.location and co.date = tr.date
WHERE co.continent is not null
and human_development_index is not null
GROUP BY co.location
ORDER BY human_development_index -- desc

-- New vaccinations per day

SELECT location, date, population, new_vaccinations
FROM Covid
WHERE continent is not null
and location like 'Canada'
ORDER BY 1,2

-- Total_vaccinations per day

SELECT location, date, population, new_vaccinations, 
sum(convert(int, new_vaccinations)) OVER (PARTITION BY location ORDER BY location, date) as rolling_vaccinations,
rolling_vaccinations/population*100 as 
FROM Covid
WHERE continent is not null
and location like 'Canada'
ORDER BY location, date

-- Using CTE (Common table expression)

With PopVaccinated (location, date, population, new_vaccinations, rolling_vaccinations) as 
(
SELECT location, date, population, new_vaccinations, 
sum(convert(int, new_vaccinations)) OVER (PARTITION BY location ORDER BY location, date) as rolling_vaccinations
FROM Covid
WHERE continent is not null
and location like 'Colombia'
-- ORDER BY location, date
)
SELECT *, rolling_vaccinations/population*100 as vaccination_percentage
FROM PopVaccinated


-- Using temp table (temporary table)

DROP TABLE if exists PopulationVaccinated
CREATE TABLE PopulationVaccinated
(
Location nvarchar(255),
Date nvarchar(255),
Population numeric,
new_vaccinations numeric,
rolling_vaccinations numeric
)

INSERT INTO PopulationVaccinated
SELECT location, date, population, new_vaccinations, 
sum(convert(int, new_vaccinations)) OVER (PARTITION BY location ORDER BY location, date) as rolling_vaccinations
FROM Covid
WHERE continent is not null
and location like 'Colombia'
-- ORDER BY location, date

SELECT *, rolling_vaccinations/population*100 as vaccination_percentage
FROM PopulationVaccinated


-- People fully vaccinated

SELECT location, max(population) as population,
max(convert(float(2), replace(people_vaccinated_per_hundred, ',', '.'))) as people_vaccinated_per_hundred, 
max(convert(float(2), replace(people_fully_vaccinated_per_hundred, ',', '.'))) as people_fully_vaccinated_per_hundred
FROM Covid
WHERE continent is not null
GROUP BY location
ORDER BY people_fully_vaccinated_per_hundred desc


-- Creating views for later visualizations

-- Views for Covid

CREATE VIEW covidbycontinent as
SELECT continent, max(total_cases) as total_cases, max(total_deaths) as total_deaths, 
max(total_deaths)/max(total_cases)*100 as death_percentage
FROM Covid
WHERE continent is not null
GROUP BY continent

CREATE VIEW covidbylocation as
SELECT location, max(total_cases) as total_cases, max(total_deaths) as total_deaths, 
max(total_deaths)/max(total_cases)*100 as death_percentage
FROM Covid
WHERE continent is not null
GROUP BY location

-- View for traits
CREATE VIEW traitsbycontinent as
SELECT continent, (avg(convert(decimal(10,2), replace(female_smokers, ',', '.'))) + 
avg(convert(decimal(10,2), replace(male_smokers, ',', '.'))))/2 as SmokersPercentage, 
avg(human_development_index) as human_development_index, avg(gdp_per_capita) as gdp_per_capita
FROM Traits
WHERE continent is not null
GROUP BY continent

CREATE VIEW traitsbylocation as
SELECT location, (max(convert(decimal(10,2), replace(female_smokers, ',', '.'))) + 
max(convert(decimal(10,2), replace(male_smokers, ',', '.'))))/2 as SmokersPercentage, 
max(human_development_index) as human_development_index, max(gdp_per_capita) as gdp_per_capita
FROM Traits
WHERE continent is not null
GROUP BY location
