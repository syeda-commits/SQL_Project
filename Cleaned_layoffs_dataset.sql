-- Step 1: Create a staging table

CREATE TABLE layoffs_staging AS
SELECT *
FROM layoffs;

INSERT INTO layoffs_staging
SELECT 
    company,
    location,
    industry,
    total_laid_off,
    percentage_laid_off,
    CAST(date AS DATE) AS date, -- Cast the date column
    stage,
    country,
    funds_raised_millions
FROM layoffs;

-- Step 2: Remove duplicates using ROW_NUMBER

WITH duplicate_cte AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, date, stage, country, funds_raised_millions
               ORDER BY company
           ) AS row_num
    FROM layoffs_staging
)
DELETE FROM layoffs_staging
WHERE ctid IN (
    SELECT ctid
    FROM duplicate_cte
    WHERE row_num > 1
);

-- Step 3:Standardize data
-- Standardize company names

UPDATE layoffs_staging
SET company = TRIM(company);

-- Standardize industry names

UPDATE layoffs_staging
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Standardize country names

UPDATE layoffs_staging
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- Step 6: Fill missing industry values using other rows

UPDATE layoffs_staging AS t1
SET industry = t2.industry
FROM layoffs_staging AS t2
WHERE t1.company = t2.company
  AND (t1.industry IS NULL OR t1.industry = '')
  AND t2.industry IS NOT NULL;

-- Step 7: Remove rows with null values in critical columns

DELETE FROM layoffs_staging
WHERE total_laid_off IS NULL OR percentage_laid_off IS NULL;

-- Step 8: Select distinct company names to review standardization

SELECT DISTINCT company
FROM layoffs_staging;

-- Step 9: Preview the cleaned data

SELECT *
FROM layoffs_staging;

