-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ------------------------------------------------------------ Data Cleaning ------------------------------------------------------------------------------------------------
-- ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 1. Preview the data from the original layoffs table
SELECT *
FROM layoffs;

-- 2. Create a staging table with the same structure as the original layoffs table
CREATE TABLE layoffs_staging
LIKE layoffs;

-- 3. Preview the structure of the newly created staging table
SELECT *
FROM layoffs_staging;

-- 4. Insert data from the original layoffs table into the staging table
INSERT INTO layoffs_staging
SELECT *
FROM layoffs;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------------- Remove Duplicates --------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 5. Identify duplicate rows using a Common Table Expression (CTE)
WITH duplicate_cte AS 
(
    SELECT *,
        ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
    FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;

-- 6. Create a new staging table to store unique records
CREATE TABLE `layoffs_staging_2` (
    `company` TEXT,
    `location` TEXT,
    `industry` TEXT,
    `total_laid_off` INT DEFAULT NULL,
    `percentage_laid_off` TEXT,
    `date` TEXT,
    `stage` TEXT,
    `country` TEXT,
    `funds_raised_millions` INT DEFAULT NULL,
    `row_num` INT 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- 7. Insert unique records into the new staging table, calculating row numbers to identify duplicates
INSERT INTO layoffs_staging_2
SELECT *,
    ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- 8. Preview duplicate records in the new staging table
SELECT *
FROM layoffs_staging_2
WHERE row_num > 1;

-- 9. Delete duplicate rows from the new staging table
DELETE
FROM layoffs_staging_2
WHERE row_num > 1;

-- 10. Preview the cleaned data
SELECT *
FROM layoffs_staging_2;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------------- Standardizing Data -------------------------------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 11. Preview company names to check for extra spaces
SELECT company, TRIM(company) AS trimmed_company
FROM layoffs_staging_2;

-- 12. Remove leading and trailing spaces from company names
UPDATE layoffs_staging_2
SET company = TRIM(company);

-- 13. Standardize the industry name for Crypto-related industries
SELECT DISTINCT *
FROM layoffs_staging_2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging_2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- 14. Standardize country names by removing trailing dots
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country) AS trimmed_country
FROM layoffs_staging_2
ORDER BY 1;

UPDATE layoffs_staging_2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- 15. Preview the 'date' column to ensure correct formatting
SELECT date,
    STR_TO_DATE(date, '%m/%d/%Y') AS formatted_date
FROM layoffs_staging_2;

-- 16. Convert the 'date' column to the correct date format
UPDATE layoffs_staging_2
SET date = STR_TO_DATE(date, '%m/%d/%Y');

-- 17. Modify the 'date' column to be of DATE data type
ALTER TABLE layoffs_staging_2
MODIFY COLUMN date DATE;

-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- --------------------------------------------------------- Removing Blanks ---------------------------------------------------------------------------------------------------
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 18. Set industry values to NULL where they are blank
UPDATE layoffs_staging_2
SET industry = NULL
WHERE industry = '';

-- 19. Preview missing industry values and identify potential replacements
SELECT t1.industry AS missing_industry, t2.industry AS available_industry
FROM layoffs_staging_2 t1
JOIN layoffs_staging_2 t2
    ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;   

-- 20. Fill missing industry values based on other records for the same company
UPDATE layoffs_staging_2 t1
JOIN layoffs_staging_2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;        

-- ---------------------------------------------------------------- Remove Unneeded Columns or Rows ----------------------------------------------------------------------------
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 21. Identify rows where both 'total_laid_off' and 'percentage_laid_off' are NULL
SELECT *
FROM layoffs_staging_2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- 22. Delete rows where both 'total_laid_off' and 'percentage_laid_off' are NULL
DELETE
FROM layoffs_staging_2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- 23. Drop the 'row_num' column as it is no longer needed
ALTER TABLE layoffs_staging_2
DROP COLUMN row_num;

-- ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- -------------------------------------------------------------------- EXPLORATORY DATA ANALYSIS------------------------------------------------------------------------------
-- -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 1. Preview the entire data from the layoffs staging table
SELECT *
FROM layoffs_staging_2;

-- 2. Find the maximum number of layoffs and the maximum percentage of layoffs
SELECT 
    MAX(total_laid_off) AS max_total_laid_off, 
    MAX(percentage_laid_off) AS max_percentage_laid_off
FROM layoffs_staging_2;

-- 3. List all records where 100% of employees were laid off, ordered by total laid off in descending order
SELECT *
FROM layoffs_staging_2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

-- 4. List all records where 100% of employees were laid off, ordered by funds raised in descending order
SELECT *
FROM layoffs_staging_2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

-- 5. Find the total number of employees laid off per company, ordered by the total number of layoffs in descending order
SELECT 
    company, 
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging_2
GROUP BY company
ORDER BY total_laid_off DESC;

-- 6. Find the minimum and maximum dates of layoffs
SELECT 
    MIN(date) AS earliest_date, 
    MAX(date) AS latest_date
FROM layoffs_staging_2;

-- 7. Find the total number of employees laid off per industry, ordered by the total number of layoffs in descending order
SELECT 
    industry, 
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging_2
GROUP BY industry
ORDER BY total_laid_off DESC;

-- 8. Find the total number of employees laid off per country, ordered by the total number of layoffs in descending order
SELECT 
    country, 
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging_2
GROUP BY country
ORDER BY total_laid_off DESC;

-- 9. Find the total number of employees laid off per year, ordered by year in descending order
SELECT 
    YEAR(date) AS year, 
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging_2
GROUP BY YEAR(date)
ORDER BY year DESC;

-- 10. Find the total number of employees laid off per stage, ordered by the total number of layoffs in descending order
SELECT 
    stage, 
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging_2
GROUP BY stage
ORDER BY total_laid_off DESC;

-- 11. Find the total number of employees laid off per month, ordered by month in ascending order
SELECT 
    SUBSTRING(date, 1, 7) AS month, 
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging_2
WHERE SUBSTRING(date, 6, 2) IS NOT NULL
GROUP BY month
ORDER BY month ASC;

-- 12. Calculate the rolling total of layoffs per month
WITH Rolling_Total AS 
(
    SELECT 
        SUBSTRING(date, 1, 7) AS month, 
        SUM(total_laid_off) AS total_off
    FROM layoffs_staging_2
    WHERE SUBSTRING(date, 6, 2) IS NOT NULL
    GROUP BY month
    ORDER BY month ASC
)
SELECT 
    month, 
    total_off, 
    SUM(total_off) OVER(ORDER BY month) AS rolling_total
FROM Rolling_Total;

-- 13. Find the total number of employees laid off per company per year, ordered by total layoffs in descending order
SELECT 
    company, 
    YEAR(date) AS year,  
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging_2
GROUP BY company, YEAR(date)
ORDER BY total_laid_off DESC;

-- 14. Find the top 5 companies with the most layoffs per year
WITH Company_Year AS 
(
    SELECT 
        company, 
        YEAR(date) AS year,  
        SUM(total_laid_off) AS total_laid_off
    FROM layoffs_staging_2
    GROUP BY company, YEAR(date)
),
Company_Year_Rank AS 
(
    SELECT 
        *,
        DENSE_RANK() OVER(PARTITION BY year ORDER BY total_laid_off DESC) AS ranking
    FROM Company_Year
    WHERE year IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE ranking <= 5;


