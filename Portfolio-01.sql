CREATE database portfolio;

-- allow MySQL to import local files
SET GLOBAL local_infile=1;
SHOW GLOBAL VARIABLES LIKE 'local_infile';

-- create covid_deaths table from csv data
DROP TABLE if EXISTs covid_deaths;
create table if not exists covid_deaths (
	ID int primary key,
	iso_code text,
	continent text,
	location text, 
	population bigint,
	date date,
	total_cases int,
	new_cases int,
	total_deaths int,
	new_deaths int
);

-- import local files
LOAD DATA local INFILE 'D:/OneDrive/Projects2023/Data/Portfolio/covid_deaths.csv' 
INTO TABLE covid_deaths
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- test with generic selects
SELECT * from covid_deaths;
select count(*) from covid_deaths;

-- create covid_vaccines table from csv
DROP TABLE if EXISTs covid_vaccines;
CREATE TABLE IF NOT EXISTS covid_vaccines (
	ID int PRIMARY KEY,
	iso_code text,
	continent text,
	location text,
	population bigint,
	date date,
	new_tests int,
	total_vaccinations int,
	people_vaccinated int,
	people_fully_vaccinated int,
	total_boosters int,
	new_vaccinations int
);
-- import local files
LOAD DATA local INFILE 'D:/OneDrive/Projects2023/Data/Portfolio/covid_vaccines.csv' 
INTO TABLE covid_vaccines
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- test with generic selects
SELECT * FROM covid_vaccines;
SELECT count(*) FROM covid_vaccines;

-- total cases per continent
SELECT round(sum(new_cases)/1000000,2) total_cases_millions, continent FROM covid_deaths
WHERE continent <> ""
GROUP BY 2;

-- total cases in millions by continent and country 
SELECT continent, location, round(sum(newcases)/1000000, 2)AS million_cases
FROM(
SELECT sum(new_cases) AS newcases, max(total_cases) AS totalcases, location, continent
FROM covid_deaths
WHERE continent <> "" AND location <> "China" 
GROUP BY 4, 3
)a 
GROUP BY 2, 1
HAVING million_cases >= 0.01
ORDER BY 1, 3 DESC;

--  populations and infection rates by continent and country
SELECT continent, location, population, sum(new_cases)total_cases, round((sum(new_cases)/population)*100,2) as infection_rate_of_population 
	FROM covid_deaths 
	WHERE continent <> "" 
    GROUP BY 1, 2, 3
    HAVING infection_rate_of_population <> 0
    ORDER BY 1, 5 DESC;

-- mortality rate and case fatality rate by continent and country
SELECT continent, location, population, sum(new_cases) AS total_cases, sum(new_deaths) AS total_deaths,  
	round((sum(new_deaths)/sum(new_cases) * 100),2) AS case_fatality_rate, 
	round((sum(new_deaths)/population * 100000),2) AS deaths_per_100000
	FROM covid_deaths 
	WHERE continent <> "" 
    GROUP BY 2, 1, 3
    HAVING total_deaths <> 0
    ORDER BY 1, 4 DESC;
    
-- line graph of total cases and total deaths
SELECT date, sum(new_cases) AS Cases_daily, sum(new_deaths) AS Deaths_daily FROM covid_deaths 	
	WHERE continent <> "" 
    GROUP BY 1;

    
/*-- Total Population vs Vaccine by continent, country and date
Numbers reveal total shots, not individuals vaccinated. in other words some percentages are over 100
WITH popvsvac  AS ( SELECT dea.continent AS continent,  dea.location AS location, dea.date AS date, 
	dea.population AS population, vac.new_vaccinations AS new_vac, 
    -- sum(new_vaccinations) 
   total_vaccinations AS rollingvac
    FROM covid_deaths AS dea 
    JOIN covid_vaccines as vac on dea.ID = vac.ID
	WHERE dea.continent <> "" 
  )
    SELECT continent, location, date, population, new_vac,
    sum(rollingvac) OVER (PARTITION BY location order by location, date), (rollingvac/population)*100 as Vac_percentage
    FROM popvsvac
    ORDER BY 1, 2, 3;*/

-- vaccinated population totals and percentage with countries
SELECT continent, location, round(sum(population)/1000000,2) AS population_mil, round(sum(vaxed)/1000000,2) AS vaxed_mil, round((sum(vaxed)/sum(population) * 100), 2) as vaxperc
FROM(
SELECT continent,  location, population, max(people_vaccinated) AS vaxed, max((people_vaccinated)/population) AS vaxperc
	FROM covid_vaccines
    WHERE  continent <> "" 
    GROUP BY 1,2, 3
    ) a
GROUP BY 1, 2
HAVING vaxperc<= 99
ORDER BY 1, 2, 3 DESC;

-- Vaccination rates and counts continents only
SELECT continent, round(sum(population)/1000000,2) AS population_mil, round(sum(vaxed)/1000000,2) AS 
vaxed_mil, round((sum(vaxed)/sum(population) * 100), 2) AS vaxperc
FROM(
SELECT continent,   population, max(people_vaccinated) as vaxed, max((people_vaccinated)/population) as vaxperc
	FROM covid_vaccines
    WHERE  continent <> "" 
    GROUP BY 1, 2
    ) a
GROUP BY 1 
HAVING vaxperc<= 99
ORDER BY 1, 2, 3 DESC;

-- quick totals
SELECT SUM(new_cases) total_cases, sum(new_deaths) total_deaths FROM covid_deaths
 WHERE  continent <> "" 

