SELECT *
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4
;

SELECT *
FROM PortfolioProject.dbo.CovidVaccinations
ORDER BY 3, 4
;

-- Select the data that we are going to use
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2
;

-- Show likelihood of dying if you contract covid in your country
SELECT
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths / total_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2
;

SELECT
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths / total_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location LIKE '%states%' -- Para buscar los valores de Estados Unidos
	AND continent IS NOT NULL
ORDER BY 1, 2
;

SELECT
	location,
	date,
	total_cases,
	total_deaths,
	(total_deaths / total_cases)*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE location LIKE '%Peru%'
	AND continent IS NOT NULL
ORDER BY 1, 2
;

-- Corroboramos que solo haya un Peru
SELECT DISTINCT N.location
FROM
	(SELECT
		location,
		date,
		total_cases,
		total_deaths,
		(total_deaths / total_cases)*100 AS DeathPercentage
	FROM PortfolioProject.dbo.CovidDeaths
	WHERE location LIKE '%Peru%'
		AND continent IS NOT NULL) AS N
	;

-- Total de casos VS. población
-- Muestra el porcentaje de la población que se ha contagiado de covid
SELECT
	location,
	date,
	total_cases,
	population,
	(total_cases / population) * 100 AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2
;

-- Veamos los paises con las tasas de infección más altas
SELECT
	DISTINCT location,
	MAX ( (total_cases / population) * 100 ) AS PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 2 DESC
;

SELECT
	location ,
	population ,
	MAX(total_cases) AS HighestInfectionCount ,
	MAX ((total_cases / population)) * 100 AS  PercentPopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC
;

-- Showing Countries with Highest Death Count per Population
SELECT
	location,
	MAX( CAST(total_deaths AS BIGINT) ) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC
;

-- Cantidad de fallecidos por covid19 por continentes
SELECT
	location,
	MAX( CAST(total_deaths AS INT) ) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL AND location NOT LIKE '%income%' -- Los que tienen 'income' en la columna location, tienen NULL en la columna continent
GROUP BY location
ORDER BY TotalDeathCount DESC
;

SELECT
	continent,
	SUM(M.TotalDeathCount) AS TotalDeathCount
FROM
	(SELECT
		continent,
		location,
		MAX( CAST(total_deaths AS BIGINT) ) AS TotalDeathCount
	 FROM PortfolioProject.dbo.CovidDeaths
	 WHERE continent IS NOT NULL
	 GROUP BY continent, location)
		AS M
GROUP BY continent
ORDER BY TotalDeathCount DESC
;

SELECT
	date,
	SUM(new_cases) AS total_cases,
	SUM( CAST(new_deaths AS BIGINT) ) AS total_deaths,
	( SUM( CAST(new_deaths AS BIGINT) ) / SUM(new_cases) ) *100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1
;

-- GLOBAL NUMBERS
SELECT
	SUM(new_cases) AS total_cases,
	SUM( CAST(new_deaths AS BIGINT) ) AS total_deaths,
	( SUM( CAST(new_deaths AS BIGINT) ) / SUM(new_cases) ) *100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2
;

-- Looking at Total Population	Vs. Vaccinations
SELECT
	dea.continent ,
	dea.location ,
	dea.date ,
	dea.population ,
	vac.new_vaccinations,
	SUM( CONVERT(BIGINT, vac.new_vaccinations) ) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3
;


-- USE CTE
SET ANSI_WARNINGS OFF -- Usamos esto por el error: 'Warning: Null value is eliminated by an aggregate or other SET operation'

GO

WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS -- el numero de columnas del CTE debe ser el mismo que el de la subconsulta
	(
	SELECT
		dea.continent ,
		dea.location ,
		dea.date ,
		dea.population ,
		vac.new_vaccinations,
		SUM( CONVERT(BIGINT, vac.new_vaccinations) ) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
	FROM PortfolioProject..CovidDeaths AS dea
	JOIN PortfolioProject..CovidVaccinations AS vac
		ON dea.location = vac.location AND dea.date = vac.date
	WHERE dea.continent IS NOT NULL
	-- ORDER BY 2,3
	) 
SELECT *, (RollingPeopleVaccinated/population) * 100 AS PercentagePeopleVaccinated
FROM PopvsVac
;

-- TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated ;

CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255), 
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
);

SET ANSI_WARNINGS OFF 

GO

INSERT INTO #PercentPopulationVaccinated
SELECT
	dea.continent ,
	dea.location ,
	dea.date ,
	dea.population ,
	vac.new_vaccinations,
	SUM( CONVERT(BIGINT, vac.new_vaccinations) ) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location AND dea.date = vac.date
where dea.continent IS NOT NULL
-- ORDER BY 2,3
;

SELECT *, (RollingPeopleVaccinated/population) * 100 AS PercentagePeopleVaccinated
FROM #PercentPopulationVaccinated
ORDER BY 2,3
;


-- Creating view to store data for later visualizations
CREATE VIEW PercentPopulationVaccinated AS
SELECT
	dea.continent ,
	dea.location ,
	dea.date ,
	dea.population ,
	vac.new_vaccinations,
	SUM( CONVERT(BIGINT, vac.new_vaccinations) ) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN PortfolioProject..CovidVaccinations AS vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
;


-- Another way to perform the anterior view
DROP VIEW IF EXISTS PercentPopulationVaccinated_2 ;

CREATE VIEW PercentPopulationVaccinated_2 AS 
SELECT
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	vac.Sum_new_vaccinations AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths AS dea
JOIN
	(
	SELECT
		CV1.continent,
		CV1.location, 
		CV1.date, 
		CV1.new_vaccinations,

		(SELECT SUM( CONVERT(BIGINT, new_vaccinations) )
		 FROM PortfolioProject..CovidVaccinations AS CV2
		 WHERE continent IS NOT NULL
			AND CV1.continent = CV2.continent
			AND CV1.location = CV2.location
			AND CV2.date <= CV1.date
		) AS Sum_new_vaccinations
	
	FROM PortfolioProject..CovidVaccinations AS CV1
	WHERE CV1.continent IS NOT NULL
	-- ORDER BY 2,3
	)
	AS vac
	ON (dea.location = vac.location) AND (dea.date = vac.date)
WHERE dea.continent IS NOT NULL
;


SELECT * FROM PercentPopulationVaccinated ORDER BY 1,2 ;
SELECT * FROM PercentPopulationVaccinated_2 ORDER BY 1,2 ;