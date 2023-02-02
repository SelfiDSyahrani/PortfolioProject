-- Select dataset
SELECT 
      races.name AS GrandPrix
    , races.date
    , results.positionOrder
    , drivers.forename
    , drivers.surname
    , constructors.name as Team
    , results.points
    , status.status
    , results.fastestLapSpeed
    , driver_standings.positionText AS DriverChampionshipPosition
    , driver_standings.points as DriverChampionshipPoint
    , constructor_standings.positionText as constructorChampPosition
    , constructor_standings.points AS ConstructorChampPoints
    , lap_times.lap as lapRace
    , lap_times.position as positionRace
    , pit_stops.milliseconds AS PitStopDuration_milSec
    , pit_stops.stop AS PitStop
FROM results
INNER JOIN races 
    ON results.raceId = races.raceId
INNER JOIN drivers 
    on drivers.driverId = results.driverId
INNER JOIN constructors 
    on constructors.constructorId = results.constructorId
INNER JOIN driver_standings
    ON driver_standings.driverId = results.driverId and driver_standings.raceId = results.raceId
INNER JOIN constructor_standings
    ON constructor_standings.constructorId = results.constructorId and constructor_standings.raceId = results.raceId
INNER JOIN status
ON status.statusID = results.statusId 
LEFT JOIN lap_times
    ON lap_times.driverId= results.driverId AND lap_times.raceId = results.raceId
LEFT JOIN pit_stops
    ON pit_stops.driverId= results.driverId AND pit_stops.raceId = results.raceId AND lap_times.lap = pit_stops.lap
-- WHERE pit_stops.stop =1 --(just for checking)
ORDER BY races.date, results.positionOrder 

-- which grandprix have most variate winner? (team and driver) from 1950-2022
SELECT  races.name as GrandPrix, 
COUNT (DISTINCT results.driverId) as Total_Driver_Win, 
COUNT (DISTINCT results.constructorId) as Total_Team_Win, 
COUNT(DISTINCT races.date) AS No_held
FROM results
INNER JOIN races 
    ON results.raceId = races.raceId
INNER JOIN drivers 
    on drivers.driverId = results.driverId
WHERE results.positionOrder = 1
GROUP BY races.name
ORDER BY COUNT(DISTINCT races.date) DESC, COUNT (DISTINCT results.driverId) DESC

ALTER TABLE results
ALTER COLUMN positionOrder INT

-- What is the most exciting race to watch? (change of grid position)
SELECT races.name as GrandPrix, races.date
, drivers.forename, drivers.surname
, lap_times.lap as lapRace, lap_times.position as positionRace
, -(lap_times.position - LAG(lap_times.position) OVER (PARTITION BY races.date, drivers.driverId order By results.positionOrder, races.date)) AS GainOrLossPos
FROM results
INNER JOIN races 
    ON results.raceId = races.raceId
INNER JOIN drivers 
    on drivers.driverId = results.driverId
JOIN lap_times
    ON lap_times.driverId= results.driverId AND lap_times.raceId = results.raceId
GROUP BY races.date, races.name, drivers.forename, drivers.surname
ORDER BY races.date DESC, results.positionOrder

-- What is the average number of laps completed by drivers in each racetrack?
SELECT races.name as GrandPrix,
    COUNT(DISTINCT races.[date]) AS RaceStart, 
    COUNT(DISTINCT drivers.forename) AS Drivers,
    COUNT(lap_times.lap) AS LapsComplete,COUNT(lap_times.lap)/(COUNT(DISTINCT races.[date])*COUNT(DISTINCT drivers.forename))AS AvgLapsComplete
FROM results
INNER JOIN races 
    ON results.raceId = races.raceId
INNER JOIN drivers 
    on drivers.driverId = results.driverId
JOIN lap_times
    ON lap_times.driverId= results.driverId AND lap_times.raceId = results.raceId
GROUP BY races.name

-- What is the average fastestlap speed of drivers in each racetrack and race?
SELECT races.name AS GrandPrix
    , YEAR(races.date)
    , ROUND(AVG(CAST(results.fastestLapSpeed AS FLOAT)), 3) AS Avg_topspeed
FROM results
INNER JOIN races 
    ON results.raceId = races.raceId
WHERE results.fastestLapSpeed <> '\N'
-- GROUP BY races.name 
GROUP BY races.name, races.date
ORDER BY races.name, YEAR(races.date)
-- ROUND(AVG(CAST(results.fastestLapSpeed AS FLOAT)), 3) DESC

-- What is the average number of pit stops made by drivers in each race?
SELECT GrandPrix,
AVG(ds.pitstop) AS Avg_pitstop
FROM (SELECT races.name as GrandPrix, drivers.forename, drivers.surname,
        MAX(pit_stops.stop) AS pitstop
      FROM races
      INNER JOIN results 
      ON races.raceId = results.raceId
      INNER JOIN drivers 
      on drivers.driverId = results.driverId
      JOIN pit_stops
      ON pit_stops.driverId= results.driverId AND pit_stops.raceId = results.raceId
      GROUP BY races.name, drivers.forename, drivers.surname) AS ds
GROUP BY GrandPrix

-- What is the average time spent in the pits by drivers in each race?
ALTER TABLE pit_stops
ALTER COLUMN milliseconds FLOAT

UPDATE pit_stops
SET duration = milliseconds/1000

ALTER TABLE pit_stops
ALTER COLUMN duration FLOAT

SELECT GrandPrix,
AVG(ds.DurationInSeconds) AS Avg_duration
FROM (
    SELECT races.name as GrandPrix, races.date,
      AVG(pit_stops.milliseconds/1000) AS DurationInSeconds
      FROM results
      JOIN races 
      ON races.raceId = results.raceId
      INNER JOIN drivers 
      on drivers.driverId = results.driverId
      JOIN pit_stops
      ON pit_stops.driverId= results.driverId AND pit_stops.raceId = results.raceId
      JOIN status
        ON status.statusID = results.statusId 
    WHERE status.status = 'Finished'
    GROUP BY races.name, races.date
    -- ORDER BY pit_stops2.milliseconds DESC
      ) AS ds
GROUP BY GrandPrix
ORDER BY GrandPrix
 /*
    NOTE: as we can see some of races have long pitstop duration (more than a minute or even an hour) 
    Which can caused by red flag due to an accident. (e.i. British Grand Prix 2022)
 */

-- What is the average number of points earned by drivers in each race?
SELECT races.name as GrandPrix,
    drivers.forename, drivers.surname,constructors.name as Team, 
    AVG(results.points)
FROM results
INNER JOIN races 
    ON results.raceId = races.raceId
INNER JOIN drivers 
    on drivers.driverId = results.driverId
INNER JOIN constructors 
    on constructors.constructorId = results.constructorId
GROUP BY races.name, drivers.forename, drivers.surname,constructors.name

-- What is the average number of retirements per race?
SELECT races.name as GrandPrix, 
COUNT(Distinct races.date) AS TotalRaceHeld,
COUNT(distinct drivers.driverId) AS TotalRetirements,
COUNT(distinct drivers.driverId)/COUNT(Distinct races.date) AS AvgRetirement
FROM results
JOIN races 
ON races.raceId = results.raceId
JOIN status
ON status.statusID = results.statusId 
JOIN drivers 
      on drivers.driverId = results.driverId
WHERE status.status <> 'Finished' 
GROUP BY races.name
ORDER BY races.name

-- What is the average number of points earned by teams in each race?
SELECT races.name AS GrandPrix
,CASE 
    WHEN YEAR(races.date) BETWEEN '1950' AND '1959' THEN '1950-1959' 
    WHEN YEAR(races.date) = '1960' THEN '1960'
    WHEN YEAR(races.date) BETWEEN '1961' AND '1990' THEN '1961-1990'
    WHEN YEAR(races.date) BETWEEN '1991' AND '2002' THEN '1991-2002'
    WHEN YEAR(races.date) BETWEEN '2003' AND '2009' THEN '2003-2009'
    WHEN YEAR(races.date) BETWEEN '2010' AND '2018' THEN '2010-2018'
    WHEN YEAR(races.date) >= '2019' THEN '2019-'
    END AS PointSystem
, constructors.name AS Team
,ROUND(AVG(
CASE 
    WHEN YEAR(races.date) BETWEEN '1950' AND '1959' THEN results.points 
    WHEN YEAR(races.date) = '1960' THEN results.points 
    WHEN YEAR(races.date) BETWEEN '1961' AND '1990' THEN results.points  
    WHEN YEAR(races.date) BETWEEN '1991' AND '2002' THEN results.points 
    WHEN YEAR(races.date) BETWEEN '2003' AND '2009' THEN results.points 
    WHEN YEAR(races.date) BETWEEN '2010' AND '2018' THEN results.points
    WHEN YEAR(races.date) >= '2019' THEN results.points ELSE 0 END),3) AS AvgPointsEarned
FROM results
JOIN races 
ON races.raceId = results.raceId
JOIN constructors
ON constructors.constructorId = results.constructorId 
GROUP BY races.name, constructors.name, CASE 
    WHEN YEAR(races.date) BETWEEN '1950' AND '1959' THEN '1950-1959' 
    WHEN YEAR(races.date) = '1960' THEN '1960'
    WHEN YEAR(races.date) BETWEEN '1961' AND '1990' THEN '1961-1990'
    WHEN YEAR(races.date) BETWEEN '1991' AND '2002' THEN '1991-2002'
    WHEN YEAR(races.date) BETWEEN '2003' AND '2009' THEN '2003-2009'
    WHEN YEAR(races.date) BETWEEN '2010' AND '2018' THEN '2010-2018'
    WHEN YEAR(races.date) >= '2019' THEN '2019-' END
ORDER BY races.name, CASE 
    WHEN YEAR(races.date) BETWEEN '1950' AND '1959' THEN '1950-1959' 
    WHEN YEAR(races.date) = '1960' THEN '1960'
    WHEN YEAR(races.date) BETWEEN '1961' AND '1990' THEN '1961-1990'
    WHEN YEAR(races.date) BETWEEN '1991' AND '2002' THEN '1991-2002'
    WHEN YEAR(races.date) BETWEEN '2003' AND '2009' THEN '2003-2009'
    WHEN YEAR(races.date) BETWEEN '2010' AND '2018' THEN '2010-2018'
    WHEN YEAR(races.date) >= '2019' THEN '2019-' END DESC, AVG(results.points) DESC

/*
NOTE: There have been various points system over the years in F1.
Where points system in:
1950-1959 : 8,6,4,3,2,1 for the top 6 and +1 point for fastest lap.
1960      : 8,6,4,3,2,1 (with no extra point for fastest lap)
1961-1990 : 9,6,4,3,2,1 (with no extra point for fastest lap)
1991-2002 : 10,6,4,3,2,1 (with no extra point for fastest lap)
2003-2009 : 10,8,6,5,4,3,2,1 for the top 8
2010-2018 : 25,18,15,12,10,8,6,5,4,2,1 for top 10
2019-     : 25,18,15,12,10,8,6,5,4,2,1 for top 10 and +1 point for fastest lap
*/

-- What is the average number of laps led by drivers in each race?
SELECT GrandPrix, AVG(Bot.AvgLapsLedByDriver)
FROM(SELECT
        races.name AS GrandPrix
        , races.date 
        -- , drivers.forename,drivers.surname
        -- , COUNT(lap_times.lap) Laps
        -- , COUNT(distinct drivers.driverId) TotalLeader
        , COUNT(lap_times.lap)/COUNT(distinct drivers.driverId) AS AvgLapsLedByDriver
    FROM results
    INNER JOIN races 
        ON results.raceId = races.raceId
    INNER JOIN drivers 
        on drivers.driverId = results.driverId
    JOIN lap_times
        ON lap_times.driverId= results.driverId AND lap_times.raceId = results.raceId
    WHERE lap_times.position = 1 
    GROUP BY races.name, races.date
    ) as Bot 
GROUP BY GrandPrix
