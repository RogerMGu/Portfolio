-- First view of cases and deaths.

SELECT location, date, new_cases, total_cases
FROM Portfolio..Covid
WHERE continent is not null
ORDER BY location, date

-- Death rate by country

SELECT location, date, total_deaths, total_cases, total_deaths/total_cases*100 as DeathPercentage
FROM Portfolio..Covid
WHERE continent is not null
and location like 'Spain'
ORDER BY location, date

-- Infected population or "Probability of having gotten infected at any time of the study for a person in a certain country"

SELECT location, max(population) as population, sum(new_cases) as total_cases, sum(new_cases)/max(population)*100 as InfectionPercentage
FROM Portfolio..Covid
WHERE continent is not null
GROUP BY location
ORDER BY InfectionPercentage desc


-- Locations with most deaths

SELECT location, max(population) as population, sum(cast(new_deaths as int)) as total_deaths, max(convert(decimal(10,2), replace(total_deaths_per_million, ',', '.'))) as DeathsPerMillion
FROM Portfolio..Covid
WHERE continent is not null
GROUP BY location
ORDER BY total_deaths desc

-- Death rate compared to how aged the population is

SELECT co.location, max(co.population) as population, max(co.total_deaths)/max(co.total_cases)*100 as DeathPercentage,
max(tr.median_age) as median_age, max(tr.life_expectancy) as life_expectancy
FROM Portfolio..Covid co JOIN Portfolio..Traits tr
ON co.location = tr.location and co.date = tr.date
WHERE co.continent is not null
GROUP BY co.location
ORDER BY median_age desc

-- Do smoking or having diabetes influence on the death rate?

SELECT co.location, max(co.population) as population, max(co.total_deaths)/max(co.total_cases)*100 as DeathPercentage,
(max(convert(decimal(10,2), replace(tr.female_smokers, ',', '.'))) + max(convert(decimal(10,2), replace(tr.male_smokers, ',', '.'))))/2 
as SmokersPercentage, max(tr.diabetes_prevalence) as diabetes_prevalence, max(tr.cardiovasc_death_rate) as CardiovascDeathPercentage
FROM Portfolio..Covid co JOIN Portfolio..Traits tr
ON co.location = tr.location and co.date = tr.date
WHERE co.continent is not null
GROUP BY co.location
ORDER BY SmokersPercentage desc

-- Death rate compared to country's development and economy

SELECT co.location, max(co.population) as population, max(co.total_deaths)/max(co.total_cases) as DeathRate,
max(tr.human_development_index) as human_development_index, max(tr.gdp_per_capita) as gdp_per_capita, 
max(tr.extreme_poverty) as extreme_poverty
FROM Portfolio..Covid co JOIN Portfolio..Traits tr
ON co.location = tr.location and co.date = tr.date
WHERE co.continent is not null
and human_development_index is not null
GROUP BY co.location
ORDER BY human_development_index -- desc

-- New vaccinations per day

SELECT location, date, population, new_vaccinations
FROM Portfolio..Covid
WHERE continent is not null
and location like 'Canada'
ORDER BY 1,2

-- Total_vaccinations per day

SELECT location, date, population, new_vaccinations, 
sum(convert(int, new_vaccinations)) OVER (PARTITION BY location ORDER BY location, date) as rolling_vaccinations
-- rolling_vaccinations/population*100 as rolling_aggregate
FROM Portfolio..Covid
WHERE continent is not null
and location like 'Canada'
ORDER BY location, date

-- Using CTE (Common table expression)

With PopVaccinated (location, date, population, new_vaccinations, rolling_vaccinations) as 
(
SELECT location, date, population, new_vaccinations, 
sum(convert(int, new_vaccinations)) OVER (PARTITION BY location ORDER BY location, date) as rolling_vaccinations
FROM Portfolio..Covid
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
FROM Portfolio..Covid
WHERE continent is not null
and location like 'Colombia'
-- ORDER BY location, date

SELECT *, rolling_vaccinations/population*100 as vaccination_percentage
FROM PopulationVaccinated


-- People fully vaccinated

SELECT location, max(population) as population,
max(convert(float(2), replace(people_vaccinated_per_hundred, ',', '.'))) as people_vaccinated_per_hundred, 
max(convert(float(2), replace(people_fully_vaccinated_per_hundred, ',', '.'))) as people_fully_vaccinated_per_hundred
FROM Portfolio..Covid
WHERE continent is not null
GROUP BY location
ORDER BY people_fully_vaccinated_per_hundred desc


-- Creating views for later visualizations

-- Views for Covid for continent
DROP VIEW IF EXISTS dbo.covidbycontinent
CREATE VIEW dbo.covidbycontinent as
SELECT continent, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, 
sum(cast(new_deaths as int))/sum(new_cases)*100 as death_percentage
FROM Portfolio..Covid
WHERE continent is not null
GROUP BY continent

-- View for Covid by continent
DROP VIEW IF EXISTS dbo.covidbylocation
CREATE VIEW covidbylocation as
SELECT location, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, 
sum(cast(new_deaths as int))/sum(new_cases)*100 as death_percentage
FROM Portfolio..Covid
WHERE continent is not null
GROUP BY location

-- View for traits by continent
DROP VIEW IF EXISTS dbo.traitsbycontinent
CREATE VIEW traitsbycontinent as
With TraitContinent (continent, location, smokers_percentage, human_development_index, gdp_per_capita) as 
(
SELECT continent, location, (max(convert(decimal(10,2), replace(female_smokers, ',', '.'))) + 
max(convert(decimal(10,2), replace(male_smokers, ',', '.'))))/2 as smokers_percentage, 
max(human_development_index) as human_development_index, max(gdp_per_capita) as gdp_per_capita
FROM Portfolio..Traits
WHERE continent is not null
GROUP BY continent, location
)
SELECT continent, avg(smokers_percentage) as smokers_percentage, avg(human_development_index) as human_development_index, 
avg(gdp_per_capita) as gdp_per_capita
FROM TraitContinent
GROUP BY continent;

-- View for traits by location
DROP VIEW IF EXISTS dbo.traitsbylocation
CREATE VIEW traitsbylocation as
SELECT location, (max(convert(decimal(10,2), replace(female_smokers, ',', '.'))) + 
max(convert(decimal(10,2), replace(male_smokers, ',', '.'))))/2 as smokers_percentage, 
max(human_development_index) as human_development_index, max(gdp_per_capita) as gdp_per_capita
FROM Portfolio..Traits
WHERE continent is not null
GROUP BY location


-- View of Covid in the world

DROP VIEW IF EXISTS dbo.covidintheworld
CREATE VIEW covidintheworld as		-- Saved in master database
SELECT sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, 
sum(cast(new_deaths as int))/sum(new_cases)*100 as death_percentage
FROM Portfolio..Covid
WHERE continent is not null

-- View for a time series plot

DROP VIEW IF EXISTS dbo.covidbydate
CREATE VIEW covidbydate as       -- Saved in master database
With CovidDate (location, date, new_cases, total_cases, new_deaths, total_deaths) as 
(
SELECT location, date, new_cases, sum(new_cases) OVER (PARTITION BY location ORDER BY location, date) as total_cases, new_deaths,
sum(cast(new_deaths as int)) OVER (PARTITION BY location ORDER BY location, date) as total_deaths
FROM Portfolio..Covid
WHERE continent is not null
and location like 'Spain'
)
SELECT *, total_deaths/total_cases*100 as death_percentage
FROM CovidDate
