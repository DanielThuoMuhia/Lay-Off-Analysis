# Layoffs Data Cleaning and Exploratory Data Analysis (EDA)

This project focuses on cleaning a dataset of layoffs and performing exploratory data analysis (EDA) to derive insights. The dataset contains information about companies, their locations, industries, the number of employees laid off, percentages of layoffs, and other related details.

## Data Cleaning

The data cleaning process involved several steps:

1. **Creating a Staging Table**: A staging table was created to avoid making changes directly to the original data. This allows for safer data manipulation and cleaning.

2. **Removing Duplicates**: Duplicate records were identified using a `ROW_NUMBER()` function based on key columns (company, location, industry, total laid off, etc.) and removed from the dataset.

3. **Standardizing Data**: 
   - Trimmed whitespace from company names.
   - Standardized industry names to ensure consistency (e.g., 'Crypto' instead of variations like 'CryptoExchange').
   - Converted date formats to a standard `DATE` type for better analysis.

4. **Handling Missing Values**: Missing industry data was filled in using data from other records of the same company where the industry information was available.

5. **Removing Unnecessary Records**: Records with both `total_laid_off` and `percentage_laid_off` as `NULL` were removed as they provide no useful information.

## Exploratory Data Analysis (EDA)

After cleaning the data, several SQL queries were used to perform EDA and gain insights into layoffs:

- **Layoffs Over Time**: Calculated monthly layoffs and rolling totals to understand trends over time.
- **Company and Industry Trends**: Identified top companies with the most layoffs each year and summarized layoffs by industry.
- **Geographical Analysis**: Analyzed layoffs by country to identify the most affected regions.
- **Stage-wise Analysis**: Analyzed layoffs by the company's stage (e.g., startup, established) to understand which stages were most impacted.

## Conclusion

This project demonstrates the importance of data cleaning to ensure the accuracy and reliability of any analysis. The cleaned data allowed for meaningful insights into trends and patterns in layoffs, which can be useful for understanding the impact on different sectors and regions.
