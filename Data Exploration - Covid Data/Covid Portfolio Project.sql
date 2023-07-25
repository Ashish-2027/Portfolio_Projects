/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

Select * from Portfolio_Project..CovidDeaths 
where continent is not null
order by 3,4

-- Selecting data that we are going to work with
Select Location, date, total_cases,new_cases, total_deaths, population
from Portfolio_Project..CovidDeaths 
order by 1,2


--Total Cases vs Total Deaths
--Shows likelihood of dying if you contract Covid in your country

Select Location, date,(convert(int,total_cases)) as total_cases,(convert(int,total_deaths)) as total_deaths,
( (convert(float,total_deaths)) / (convert(float,total_cases)))*100 as DeathPercentage
from Portfolio_Project..CovidDeaths 
Where location like '%india%' 
and continent is not null
order by 1,2

--Total Cases vs Population
--Shows percentage of population infected by Covid

Select Location, date, total_cases, population,(total_cases/population)*100 as AffectedPopulation
from Portfolio_Project..CovidDeaths 
order by 1,2


--Countries with Highest Infection Rate compared to Population

Select Location, Max(total_cases) as HighestInfectionCount, population,Max((total_cases/population))*100 as AffectedPopulation
from Portfolio_Project..CovidDeaths 
group by location, population
order by AffectedPopulation desc


Select Location,Population,Date, Max(total_cases) as HighestInfectionCount,Max((total_cases/population))*100 as AffectedPopulation
from Portfolio_Project..CovidDeaths 
group by location, population,Date
order by AffectedPopulation desc

--Countries with Highest Death Count per Population

Select Location, SUM(convert(bigint,total_deaths)) as TotalDeathCount
from Portfolio_Project..CovidDeaths 
where continent is null 
and location not in ('World', 'European Union', 'International','High income','Upper middle income','Lower middle income','Low income')
group by location
order by TotalDeathCount desc


--Countries with Highest Death count By Continent per population

Select continent, Max(cast(total_deaths as int)) as TotalDeathCount
from Portfolio_Project..CovidDeaths 
where continent is not null and location not in ('World', 'European Union', 'International')
group by continent
order by TotalDeathCount desc

--GLOBAL NUMBERS

Select date, Sum(new_cases) as total_cases,sum(cast(new_deaths as int)) as total_deaths,sum(cast(new_deaths as int))/Nullif(Sum(new_cases),0)*100 as DeathPercentage
from Portfolio_Project..CovidDeaths 
where continent is not null
group by date
order by 1,2

--Global Death percentage
Select Sum(new_cases) as total_cases,sum(cast(new_deaths as int)) as total_deaths,
sum(cast(new_deaths as int))/Sum(new_cases)*100 as DeathPercentage
from Portfolio_Project..CovidDeaths 
where continent is not null
order by 1,2

--Total Population vs Vaccinitations 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
Sum(convert(bigint,vac.new_vaccinations)) over (Partition by dea.location order by dea.location, dea.date) as Rolling_People_Vaccinated
From Portfolio_Project..CovidDeaths dea
Join Portfolio_Project..CovidVaccinations vac
	On dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
order by 2,3

--Using CTE to perform Calcualtion on Partition By in Previous Query

With PopvsVac (Continent,Location,Date,Population,New_Vaccinations, Rolling_People_Vaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
Sum(convert(bigint,vac.new_vaccinations)) over (Partition by dea.location order by dea.location, dea.date) as Rolling_People_Vaccinated
From Portfolio_Project..CovidDeaths dea
Join Portfolio_Project..CovidVaccinations vac
	On dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
Select *, (Rolling_People_Vaccinated/Population)*100 as Percent_Populaton_Vaccinated
From PopvsVac


--Using Temp Table to perform Calculation on Partition By in Previous Query

Drop Table if exists #Percent_Populaton_Vaccinated
Create Table #Percent_Populaton_Vaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
Rolling_People_Vaccinated numeric
)

Insert into #Percent_Populaton_Vaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
Sum(convert(bigint,vac.new_vaccinations)) over (Partition by dea.location order by dea.location, dea.date) as Rolling_People_Vaccinated
From Portfolio_Project..CovidDeaths dea
Join Portfolio_Project..CovidVaccinations vac
	On dea.location = vac.location and dea.date = vac.date
--where dea.continent is not null
--order by 2,3

Select *, (Rolling_People_Vaccinated/Population)*100 as Percent_Populaton_Vaccinated
From #Percent_Populaton_Vaccinated



-- Creating View to store data for later Visualisation
Create View Percent_Populaton_Vaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
Sum(convert(bigint,vac.new_vaccinations)) over (Partition by dea.location order by dea.location, dea.date) as Rolling_People_Vaccinated
From Portfolio_Project..CovidDeaths dea
Join Portfolio_Project..CovidVaccinations vac
	On dea.location = vac.location and dea.date = vac.date
where dea.continent is not null
