COVID Dataset Link: https://ourworldindata.org/covid-deaths

SELECT *
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4;

SELECT *
FROM CovidVaccinations
WHERE continent IS NOT NULL
ORDER BY 3,4;

--Select Data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;

--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract COVID-19 in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE location LIKE '%states%'
AND continent IS NOT NULL
ORDER BY 1,2;

--Looking at Total Cases vs. Population
--Shows percentage of population that contracted COVID-19

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE location LIKE '%states%'
AND continent IS NOT NULL
ORDER BY 1,2;

-- Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount,  MAX(total_cases/population)*100 AS PercentPopulationInfected
FROM CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- Countries with Highest Death Count per Population

SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NULL 
GROUP BY location
ORDER BY TotalDeathCount DESC

--BREAKING THINGS DOWN BY CONTINENT
--Showing continents with the highest death count

SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC;

--GLOBAL NUMBERS

SELECT SUM(new_cases) AS TotalCases, SUM(CAST(new_deaths AS int)) AS TotalDeaths, SUM(CAST(new_deaths AS int))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2;

--Looking at Total Population vs. Vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated,
--(RollingPeopleVaccinated/population)*100
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

--Using CTE to perform calculation on PARTITION BY in previous query

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac;

--Using Temp Table to perform calculation on PARTITION BY in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
);

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated;

--Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations AS int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM CovidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

SELECT *
FROM PercentPopulationVaccinated;
