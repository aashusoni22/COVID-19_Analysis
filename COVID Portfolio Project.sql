/*
Covid 19 Data Exploration

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/


SELECT * 
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4

--SELECT * 
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3, 4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Now looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE location = 'Canada' AND continent IS NOT NULL
ORDER BY 1, 2

-- Now looking at Total Cases vs Population
-- Shows what percentage of population got covid

SELECT location, date, Population, total_cases, (total_cases/Population)* 100 AS Percent_of_Population_Infected
FROM PortfolioProject..CovidDeaths
-- WHERE location = 'Canada' AND continent IS NOT NULL
ORDER BY 1, 2

-- Looking at Countries wiht Highest Infection Rate Compared to Population
SELECT Location, Population, MAX(total_cases) AS Highest_Infection_Count, MAX(total_cases/Population)* 100 AS Percent_of_Population_Infected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location, population
ORDER BY Percent_of_Population_Infected DESC

-- Showing Countries with Highest Death Count per Population

SELECT Location, MAX(cast(total_deaths as INT)) AS Total_Death_Count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY Location
ORDER BY Total_Death_Count DESC

-- Looking at total death counts per continent

SELECT location, MAX(cast(total_deaths as INT)) AS Total_Death_Count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY Total_Death_Count DESC



-- ****LET'S BREAK THINGS DOWN BY CONTINENT****

-- Showing Continents with the highest death count per population

SELECT continent, MAX(cast(total_deaths as INT)) AS Total_Death_Count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Total_Death_Count DESC



-- ****GLOBAL NUMBERS****

-- Calculate Total number of cases and deaths on each day across the world

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS INT)) AS total_deaths, SUM(cast(new_deaths AS INT))/SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths 
WHERE continent IS NOT NULL
GROUP BY date                      
ORDER BY 1, 2
 

-- Calculate total number of cases and deaths accross the world

SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths AS INT)) AS total_deaths, SUM(cast(new_deaths AS INT))/SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths 
WHERE continent IS NOT NULL                     
ORDER BY 1, 2


-- Looking at Total Population vs Vaccinations 

-- Bascially calculating how many people in the world has been vaccinated per day

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations  
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

-- Now looking at total vaccination per location (Rolling Count)

SELECT 
dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea
	JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

-- Now looking at total number of population who is fully vaccinated per location

SELECT 
dea.continent, dea.location, dea.date, dea.population, vac.people_fully_vaccinated, SUM(CAST(vac.people_fully_vaccinated AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea
	JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3


-- USE CTE to find out how many in speicifc country are vaccinated in %

WITH popuVSvacc (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated) AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	   SUM(Cast(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea
	JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/population)*100 AS total_Population_Vaccinated_Percent
FROM popuVSvacc


-- TEMP table

DROP TABLE if exists #PercentPopulationVaccinated 
CREATE TABLE #PercentPopulationVaccinated 
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
	   SUM(Cast(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea
	JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
-- WHERE dea.continent IS NOT NULL
--ORDER BY 1, 2

SELECT *, (RollingPeopleVaccinated/population)*100 AS total_Population_Vaccinated_Percent
FROM #PercentPopulationVaccinated


-- Creating a view for later visualization 
 
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null 


CREATE VIEW TotalDeaths_Continent AS
SELECT location, MAX(cast(total_deaths as INT)) AS Total_Death_Count
FROM PortfolioProject..CovidDeaths
WHERE continent IS NULL
GROUP BY location
--ORDER BY Total_Death_Count DESC


CREATE VIEW TotalFullyVaccinatted AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.people_fully_vaccinated, SUM(CAST(vac.people_fully_vaccinated AS BIGINT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea
	JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3
