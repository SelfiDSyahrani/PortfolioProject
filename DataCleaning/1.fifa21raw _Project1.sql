----------------------------------------------------------------------------------------------------------------
--                                            DATA CLEANING 1 : fifa21raw 
Data Source:https://github.com/SelfiDSyahrani/PortfolioProject/blob/main/fifa21%20raw%20data%20v2.csv
----------------------------------------------------------------------------------------------------------------
----------------------------*Convert the height and weight column to numerical data------------------------------  
    --Add COLUMN Height_cm
        ALTER TABLE fifa21raw
        ADD Height_cm FLOAT

    -- Remove 'cm' in Height 
        UPDATE fifa21raw
        SET Height_cm = CAST(SUBSTRING (Height,1, 3) AS FLOAT)
        WHERE Height LIKE '%cm'

    -- Convert Height from ft_inch to cm
        UPDATE fifa21raw
        SET Height_cm = ROUND(CAST(SUBSTRING (Height,1, 1) AS FLOAT)*30.48 + CAST(REPLACE(SUBSTRING (Height,3, 2),'"', '')AS FLOAT) *2.54, 0)
        WHERE Height NOT LIKE '%cm'

    --Add COLUMN Weight_kg
        ALTER TABLE fifa21raw
        ADD Weight_kg FLOAT

    -- Remove 'kg' in Weight
        UPDATE fifa21raw
        SET Weight_kg = CAST(SUBSTRING (Weight, 1, len(Weight) -2)AS FLOAT)
        WHERE Weight LIKE '%kg'

    -- Convert Weight from lbs to kg
        UPDATE fifa21raw
        SET Weight_kg = ROUND(CAST(SUBSTRING (Weight, 1, len(Weight) -3) as FLOAT)/2.20462,0)
        WHERE Weight LIKE '%lbs'

---------------------------------------------------------------------------------------------------------------
--Checking
    SELECT 
    Height, Height_cm, Weight, Weight_kg
    FROM fifa21raw

    SELECT * FROM fifa21raw

--Dropping 
    ALTER TABLE fifa21raw
    DROP COLUMN Height
    ALTER TABLE fifa21raw
    DROP COLUMN Weight
---------------------------------------------------------------------------------------------------------------

-----------------------------------*Remove unnecesary space in column Club*------------------------------------
    
    --Remove unnecesary space
        UPDATE fifa21raw
        SET Club = SUBSTRING (Club,5, len(Club))

---------------------------------------------------------------------------------------------------------------

---*Convert 'M' and 'K' in Value, Wage and Release_Clause columns into numeric value of million or thousands*-- 
 
    --Remove unnecesary character
        -- temporary column
        ALTER TABLE fifa21raw
        ADD Value_Euro int, Wage_Euro int, Release_Clause_Euro INT

        UPDATE fifa21raw
        SET 
        Value_Euro = CAST(SUBSTRING(Value,2, len(Value)-2)AS FLOAT)* 1000000,
        Wage_Euro= CAST(SUBSTRING(Wage,2, len(Wage)-2)AS FLOAT)*1000,
        Release_Clause_Euro= CAST(SUBSTRING(Release_Clause,2, len(Release_Clause)-2)AS FLOAT)*1000000

    --SET datatype Value, Wage and Release_Clause to INT
        UPDATE fifa21raw
        SET Value =0, Wage = 0, Release_Clause = 0

        ALTER TABLE fifa21raw
        ALTER COLUMN Value INT
        ALTER TABLE fifa21raw
        ALTER COLUMN Wage INT
        ALTER TABLE fifa21raw
        ALTER COLUMN Release_Clause INT
    
    --UPDATE Value, Wage and Release_Clause
        UPDATE fifa21raw
        SET Value = Value_Euro, Wage = Wage_Euro, Release_Clause = Release_Clause_Euro

        --Dropping temporary column
        ALTER TABLE fifa21raw
        DROP COLUMN Value_Euro, Wage_Euro , Release_Clause_Euro 

---------------------------------------------------------------------------------------------------------------

----------------------------------*Remove star characters from W_F, SM, IR column*------------------------------
--Remove star character
        UPDATE fifa21raw
        SET W_F = SUBSTRING(W_F, 1, 1), SM = SUBSTRING(SM, 1, 1), IR = SUBSTRING(IR, 1, 1)

---------------------------------------------------------------------------------------------------------------

---------------------------------------------*Add Column PeriodYear*--------------------------------------------
--                                                    __________________________________________________
------------------------------------------------------NB: PeriodYear = since joined till 6th Augt 2021
-- Column PeriodYear
    ALTER TABLE fifa21raw
    ADD PeriodYear INT

    UPDATE fifa21raw
    SET PeriodYear = DATEDIFF(year, Joined, '2021-08-06')

---------------------------------------------------------------------------------------------------------------------




