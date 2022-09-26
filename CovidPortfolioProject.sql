-- Select Data that we are going to be using
-- Covid Deaths Data
SELECT *
FROM CovidDeaths
WHERE continent is not NULL
ORDER BY 3, 4;

-- Looking at Total Cases vs Total Deaths
-- Had to convert values from INT to FLOAT
-- Shows to likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS float)/CAST(total_cases AS float))*100 as DeathPercentage
FROM CovidDeaths
WHERE location like '%canada%'
    and continent is not NULL
ORDER BY 1, 2;

-- Looking at the Total Cases vs Population
-- Shows what percentage of population has gotten covid
SELECT location, date, population, total_cases, (CAST(total_cases AS float)/CAST(population AS float))*100 as CovidPercentage
FROM CovidDeaths
WHERE location like '%canada%'
ORDER BY 1, 2;

-- Looking at Countries with highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((CAST(total_cases AS float)/CAST(population AS float))*100) as InfectedPercent
FROM CovidDeaths
WHERE continent is not NULL
GROUP BY location, population
ORDER BY InfectedPercent desc;

-- Looking at Countries with highest Death Rate compared to Population
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM CovidDeaths
WHERE continent is not NULL
GROUP BY location
ORDER BY TotalDeathCount desc;

-- Break it down by continent
-- Showing the continents with the Highest Death Counts

-- MOST ACCURATE
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM CovidDeaths
WHERE continent is NULL
GROUP BY location
ORDER BY TotalDeathCount desc;

-- LESS ACCURATE, helps with visual though
SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM CovidDeaths
WHERE continent is not NULL
GROUP BY continent
ORDER BY TotalDeathCount desc;

-- GLOBAL NUMBERS per day basis
SELECT date, SUM(new_cases) as GlobalCases, SUM(new_deaths) as GlobalDeaths, SUM(CAST(new_deaths as float))/SUM(CAST(new_cases as float))*100 as DeathPercentage
FROM CovidDeaths
WHERE continent is not NULL
GROUP BY date
ORDER BY 1, 2;

-- Covid Vaccinations Data
SELECT *
FROM CovidVaccinations;

-- Joining the tables together
SELECT *
FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
        AND dea.date = vac.date;

-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
        AND dea.date = vac.date
WHERE dea.continent is not NULL
ORDER BY 2,3;

-- USE CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
        AND dea.date = vac.date
WHERE dea.continent is not NULL
-- ORDER BY 2,3
)
SELECT *, (cast(RollingPeopleVaccinated as float))/(cast(population as float))*100
FROM PopvsVac

-- TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
    continent NVARCHAR(255),
    location NVARCHAR(255),
    date DATETIME,
    population NUMERIC,
    new_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
)
INSERT into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
        AND dea.date = vac.date
WHERE dea.continent is not NULL

SELECT *, (cast(RollingPeopleVaccinated as float))/(cast(population as float))*100
FROM #PercentPopulationVaccinated

-- Creating View to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
    JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
        AND dea.date = vac.date
WHERE dea.continent is not NULL;

SELECT * From PercentPopulationVaccinated;