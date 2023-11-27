--EXPLORING DATA & TABLES 
SELECT *
FROM CovidDeaths$
ORDER BY 1,2

SELECT *
FROM CovidVaccinations$
ORDER BY 2,3

-- Data to be used for analysis
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths$
ORDER BY 1,2

--Exploring total cases vs total deaths (Percentage)
SELECT location, [date], total_cases,total_deaths, ROUND((total_deaths/total_cases)*100, 2) as deathPercent
FROM CovidDeaths$
ORDER BY 1,2

--Exploring total cases vs total deaths for Ghana (Likelihood of dying)
SELECT location, [date], total_cases,total_deaths, ROUND((total_deaths/total_cases)*100, 2) as deathPercent
FROM CovidDeaths$
WHERE [location] LIKE '%United Kingdom%'
ORDER BY 1,2

--Looking at toal cases vs population 
--Show percentage of population got COVID
SELECT location, [date], total_cases, population, ROUND((total_cases/population)*100, 2) as AffectedPercent
FROM CovidDeaths$
WHERE [location] LIKE '%United Kingdom%'
ORDER BY 1,2

--Exploring countries with Highest Infect Rate Compared to Population 
SELECT location,population, MAX(total_cases) as HighestInfectionCount, ROUND(MAX(total_cases/population)*100, 2) as AffectedPercent
FROM CovidDeaths$
GROUP BY [location], population
ORDER BY AffectedPercent desc

--Exploring countries with highest death count per population
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths$
GROUP BY [location]
ORDER BY TotalDeathCount desc

--Data shows grouped data into continents for some locatons
SELECT *
FROM CovidDeaths$
WHERE [location] like '%Asia%'

--Data shows that continents as locations have continent as null
--Editing those out of the analysis to show only where continent is not null
SELECT location, MAX(total_deaths)
FROM CovidDeaths$
WHERE continent is not null 
GROUP BY [location]

-- Viewing data by continent
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths$
WHERE continent is not null
GROUP BY [continent]
ORDER BY TotalDeathCount desc

-- Exploring the continents with the highest death count
SELECT continent, location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM CovidDeaths$
WHERE continent is not null
GROUP BY continent, location
ORDER BY TotalDeathCount desc

--Global Analysis 
SELECT SUM(new_cases) as NewRecordedCases, SUM(cast(new_deaths as int)) as NewDeaths , SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM CovidDeaths$
WHERE continent is not null
ORDER BY 1,2

--Exploring Covid Vaccinations Table
SELECT *
FROM CovidVaccinations$
WHERE [location] like '%Albania%'

--Joining the two table 
SELECT covV.new_vaccinations
FROM CovidDeaths$ as covD 
JOIN CovidVaccinations$ as covV
    ON covD.[location] = covV.[location]
    and covD.[date] = covV.[date]

--Looking at number vaccinated across the world as per population
SELECT covD.continent,covD.[location],covD.[date], covD.population, covV.new_vaccinations
FROM CovidDeaths$ as covD 
JOIN CovidVaccinations$ as covV
    ON covD.[location] = covV.[location]
    and covD.[date] = covV.[date]
WHERE covD.continent is not null
ORDER BY 1,2,3

--Breaking into locations
SELECT covD.continent,covD.[location],covD.[date], covD.population, covV.new_vaccinations, 
    SUM(CONVERT(int,covV.new_vaccinations)) OVER (PARTITION BY covV.location ORDER BY covD.location, covD.date) as RollingPeopleVaccination
FROM CovidDeaths$ as covD 
JOIN CovidVaccinations$ as covV
    ON covD.[location] = covV.[location]
    and covD.[date] = covV.[date]
WHERE covD.continent is not null
ORDER BY 2,3

--USE CTE to find total population vaccinnation
WITH PopvsVac as
(SELECT covD.continent,covD.[location],covD.[date], covD.population, covV.new_vaccinations, 
    SUM(CONVERT(int,covV.new_vaccinations)) OVER (PARTITION BY covV.location ORDER BY covD.location, covD.date) as RollingPeopleVaccinated
FROM CovidDeaths$ as covD 
JOIN CovidVaccinations$ as covV
    ON covD.[location] = covV.[location]
    and covD.[date] = covV.[date]
WHERE covD.continent is not null)

SELECT location, MAX((RollingPeopleVaccinated/population)*100) as RollingPeopleVaccinatedPercent
FROM PopvsVac
WHERE RollingPeopleVaccinated is not null
GROUP BY [location]

--USE TEMP TABLE 
Drop Table if EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent NVARCHAR(255),
location NVARCHAR(255),
Date DATETIME,
Population NUMERIC,
New_vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC

)
INSERT INTO #PercentPopulationVaccinated
SELECT covD.continent,covD.[location],covD.[date], covD.population, covV.new_vaccinations, 
    SUM(CONVERT(int,covV.new_vaccinations)) OVER (PARTITION BY covV.location ORDER BY covD.location, covD.date) as RollingPeopleVaccinated
FROM CovidDeaths$ as covD 
JOIN CovidVaccinations$ as covV
    ON covD.[location] = covV.[location]
    and covD.[date] = covV.[date]
WHERE covD.continent is not null

SELECT location, MAX(RollingPeopleVaccinated/Population)*100 as PercentageVaccinatedPop
From #PercentPopulationVaccinated
GROUP BY location
ORDER BY 2

--Creating Vieww to store data for later visualization 

Create View PercentagePopulationVaccinated as 
SELECT covD.continent,covD.[location],covD.[date], covD.population, covV.new_vaccinations, 
    SUM(CONVERT(int,covV.new_vaccinations)) OVER (PARTITION BY covV.location ORDER BY covD.location, covD.date) as RollingPeopleVaccinated
FROM CovidDeaths$ as covD 
JOIN CovidVaccinations$ as covV
    ON covD.[location] = covV.[location]
    and covD.[date] = covV.[date]
WHERE covD.continent is not null

--Querying View
Select * 
FROM PercentagePopulationVaccinated