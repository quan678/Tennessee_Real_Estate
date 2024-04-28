-- ----------------------------------------------------------------------------------------------- -- 
-- ---Create database and its associate table, then import records using MySQL import wiz--- -- 
CREATE DATABASE housing_market;
USE housing_market;
CREATE TABLE housing_info
(
    UniqueID INT PRIMARY KEY,
    ParcelID VARCHAR(150) NULL,
    Land_Use VARCHAR(150) NULL,
    Property_Address varchar(150) NULL,
    Sale_Date VARCHAR(150) NULL,
    Sale_Price INT NULL,
    Legal_Reference VARCHAR(150) NULL,
    Sold_As_Vacant VARCHAR(100) NULL,
    Owner_Name VARCHAR(100) NULL,
    Owner_Address VARCHAR(150) NULL,
    Acreage FLOAT NULL,
    Tax_District VARCHAR(150) NULL,
    Land_Value INT NULL,
    Building_Value INT NULL,
    Total_Value INT NULL,
    Year_Built INT NULL,
    Bedrooms VARCHAR(250) NULL,
    Full_Bath INT NULL,
    Half_Bath INT NULL 
);

-- Create a back-up table
CREATE TABLE housing_info_back_up
(
    UniqueID INT PRIMARY KEY,
    ParcelID VARCHAR(150) NULL,
    Land_Use VARCHAR(150) NULL,
    Property_Address varchar(150) NULL,
    Sale_Date VARCHAR(150) NULL,
    Sale_Price INT NULL,
    Legal_Reference VARCHAR(150) NULL,
    Sold_As_Vacant VARCHAR(100) NULL,
    Owner_Name VARCHAR(100) NULL,
    Owner_Address VARCHAR(150) NULL,
    Acreage FLOAT NULL,
    Tax_District VARCHAR(150) NULL,
    Land_Value INT NULL,
    Building_Value INT NULL,
    Total_Value INT NULL,
    Year_Built INT NULL,
    Bedrooms VARCHAR(250) NULL,
    Full_Bath INT NULL,
    Half_Bath INT NULL
);

INSERT INTO housing_info_back_up
(
	SELECT * FROM housing_info
);
-- --------------------------------------------------------- --                  
-- ----------- Data Cleansing Stage ------------ --
SELECT
	*
FROM
	housing_info;
-- Drop unecessary column
ALTER TABLE housing_info
	DROP COLUMN half_bath;
-- Break the table into two smaller tables, one is for housing information and the another is for owner status
DROP TABLE owner_status;
CREATE TABLE owner_status
(
	UniqueID INT,
	FOREIGN KEY (UniqueID) REFERENCES housing_info(UniqueId),
	Owner_Name VARCHAR(250),
    Owner_Address VARCHAR(250)
    );
INSERT INTO owner_status
(
	SELECT
		UniqueID,
        	Owner_Name,
        	Owner_Address
	FROM
		housing_info
    );
ALTER TABLE housing_info
	DROP Owner_Name,
    DROP Owner_Address;
-- ------ Column 'ParcelID' ------ --
-- Check for missing values
SELECT
	COALESCE(ParcelID, 'missing value') AS missing_values_report
FROM
	housing_info;
SELECT
	SUM(CASE WHEN ParcelID IS NULL THEN 1 ELSE 0 END) AS missing_values_count
FROM
	housing_info;
-- ------ Column 'Land_Use' ------ -- 
-- Check for missing values
SELECT
	COALESCE(Land_Use, 'missing value') AS mssing_values_report
FROM
	housing_info;
SELECT
	SUM(CASE WHEN Land_Use IS NULL THEN 1 ELSE 0 END) AS missing_values_count
FROM
	housing_info;
-- Check unique values and their frequencies
SELECT
	h1.Land_Use,
	COUNT(h2.Land_Use) AS unique_values_count
FROM
	housing_info h1
    JOIN
    housing_info h2 ON h1.UniqueID = h2.UniqueID
GROUP BY h1.Land_Use
ORDER BY unique_values_count DESC;
-- Omit the unecessary information of each value to save memory
UPDATE housing_info
SET Land_Use = REPLACE(Land_Use, 'FAMILY' , ''),
	Land_Use = REPLACE(Land_Use, 'LAND', ''),
	Land_Use = REPLACE(Land_Use, '(ONE OR TWO STORIES)', ''),
	Land_Use = REPLACE(Land_Use, 'LOW RISE (BUILT SINCE 1960)', ''),
    Land_Use = REPLACE(Land_Use, 'WITHOUT GAS', '');
UPDATE housing_info
SET Land_Use = SUBSTRING(Land_Use, LOCATE('RETAIL', Land_Use), LENGTH(Land_Use))
WHERE
	Land_Use = 'ONE STORY GENERAL RETAIL STORE';
UPDATE housing_info
SET Land_Use = SUBSTRING(Land_Use, LOCATE('WAREHOUSE', Land_Use), LENGTH(Land_Use))
WHERE
	Land_Use = 'TERMINAL/DISTRIBUTION WAREHOUSE';
-- ------ Column 'Property_Address' ------ --
-- Check missing values
SELECT
	SUM(CASE WHEN Property_Address IS NULL THEN 1 ELSE 0 END) AS missing_values_count
FROM
	housing_info;
-- Check unique values and their frequencies
SELECT
	h1.Property_Address,
    COUNT(h2.Property_Address) AS unique_values_count
FROM
	housing_info h1
    JOIN
    housing_info h2 ON h1.UniqueID = h2.UniqueID
GROUP BY Property_Address
ORDER BY unique_values_count DESC;
-- Break the address into individual columns, one containing the street name and another containing the city
SELECT
    property_address,
	SUBSTRING(property_address, 1, LOCATE(',', Property_Address) - 1) AS Property_Address,
    SUBSTRING(property_address, LOCATE(',', Property_Address) + 1) AS Property_City
FROM
	housing_info
WHERE
	UniqueID = 2;
ALTER TABLE housing_info
ADD Property_Addr VARCHAR(250),
ADD Property_City VARCHAR(250);

UPDATE housing_info
SET Property_Addr = SUBSTRING(property_address, 1, LOCATE(',', Property_Address) - 1);
UPDATE housing_info
SET Property_City = SUBSTRING(property_address, LOCATE(',', Property_Address) + 1);

ALTER TABLE housing_info
DROP COLUMN Property_Address;

ALTER TABLE housing_info 
MODIFY COLUMN Property_Addr VARCHAR(255) AFTER Land_use,
MODIFY COLUMN Property_City VARCHAR(255) AFTER Property_Addr;
-- ------ Column 'Sale_Date' ------ --
-- Check missing values
SELECT
	SUM(CASE WHEN Sale_Date IS NULL THEN 1 ELSE 0 END) AS missing_values_count
FROM
	housing_info;
-- Standardize date format into short date format: "yyyy-mm-dd"
SELECT
	DATE_fORMAT(STR_TO_DATE(Sale_Date, '%M %d, %Y'), '%Y-%m-%d') AS Sale_Date
FROM
	housing_info;

UPDATE housing_info
SET Sale_Date = DATE_fORMAT(STR_TO_DATE(Sale_Date, '%M %d, %Y'), '%Y-%m-%d');
-- ------ Column 'Sold_As_Vacant' ------ --
-- Check missing values
SELECT 
	SUM(CASE WHEN Sold_as_vacant IS NULL THEN 1 ELSE 0 END) AS missing_values_count
FROM
	housing_info;
SELECT * FROM housing_info;
-- Check unique values and their frequencies
SELECT
	h1.Sold_as_vacant,
    COUNT(h2.Sold_as_vacant) AS frequencies
FROM
	housing_info h1
    JOIN
    housing_info h2 ON h1.UniqueID = h2.UniqueID
GROUP BY h1.Sold_As_Vacant
ORDER BY frequencies;
-- Change the ENUM values 'Yes' and 'No' to 'Y' and 'N'
SELECT
	CASE WHEN Sold_As_Vacant = 'Yes' THEN 'Y' ELSE 'N' END AS Sold_As_Vacant
FROM
	housing_info;

UPDATE housing_info
SET Sold_As_Vacant = CASE WHEN Sold_As_Vacant = 'Yes' THEN 'Y' ELSE 'N' END;
-- ------ Column 'Tax_District' ------ --
-- Check missing values
SELECT
	SUM(CASE WHEN Tax_District IS NULL THEN 1 ELSE 0 END) AS missing_values_count
FROM
	housing_info;
 -- Check unique values and their frequencies
 SELECT
	h1.Tax_District,
    COUNT(h2.Tax_District) AS frequencies
FROM
	housing_info h1
    JOIN
    housing_info h2 ON h1.UniqueID = h2.UniqueID
GROUP BY h1.Tax_District;
-- Omit the unecessary information of each value
UPDATE housing_info
SET Tax_District = REPLACE(Tax_District, 'DISTRICT' , ''),
	Tax_District = REPLACE(Tax_District, 'CITY OF', '');
-- --------------------------------------------------------- --                  
-- ----------- Data Exploration Stage ------------ --
SELECT
	*
FROM
	housing_info;
-- Calculate the average sale price of properties in each tax district
SELECT
    Tax_District,
    ROUND(AVG(Sale_Price),2) AS Average_Price
FROM
	housing_info
GROUP BY Tax_District
ORDER BY Average_Price DESC;
-- Rank top 10 properties by sale price in each tax district
WITH Property_Price_ctes AS (
	SELECT
		ParcelID,
        Property_Addr,
        Property_City,
        Sale_Price,
        Tax_District,
        RANK() OVER(PARTITION BY Tax_District ORDER BY Sale_Price DESC) AS Price_Ranking
	FROM
		housing_info
)
SELECT
	Property_Addr,
    Property_City,
    Sale_Price,
    Tax_District,
    Price_Ranking
FROM
	Property_Price_ctes
WHERE
	Price_Ranking < 11;
-- Create stored procedure to calculate the ROI for each property
-- Check data available for calculating
SELECT
	h1.ParcelID,
	h1.Sale_Price AS Latest_Price,
    h2.Total_Value,
    h1.Sale_Date AS Latest_Date,
    h2.Sale_Date
FROM
	housing_info h1
    JOIN
    housing_info h2 ON h1.ParcelID = h2.ParcelID
WHERE
	h1.Sale_Date > h2.Sale_Date;
-- Start building the program
DELIMITER $$
CREATE PROCEDURE ROI_Calculation(IN in_ParcelID VARCHAR(250))
BEGIN
	WITH Property_Price_ctes AS (
		SELECT
			h1.ParcelID,
            h1.Property_Addr,
            h1.Property_City,
            h1.Sale_Price AS Latest_Sale_Price,
			h1.Sale_Date AS Latest_Sale_Date
		FROM
			housing_info h1
            JOIN
            housing_info h2 ON h1.ParcelID = h2.ParcelID
		WHERE
			h1.Sale_Date > h2.Sale_Date),
        Property_Value_ctes AS (
		SELECT
			h1.ParcelID,
            h1.Total_Value AS Initial_Investment,
            h1.Sale_Date AS Sale_Date
		FROM
			housing_info h1
            JOIN
            housing_info h2 ON h1.ParcelID = h2.ParcelID
		WHERE 
			h1.Sale_Date < h2.Sale_Date)
		SELECT 
			PP_ctes.ParcelID,
            PP_ctes.Property_Addr,
            PP_ctes.Property_City,
            ((PP_ctes.Latest_Sale_Price - PV_ctes.Initial_Investment) / PV_ctes.Initial_Investment) * 100 AS ROI_Calculated 
		FROM
			Property_Price_ctes PP_ctes 
            JOIN
            Property_Value_ctes PV_ctes ON PP_ctes.ParcelID = PV_ctes.ParcelID
		WHERE
			PP_ctes.ParcelID = in_ParcelID;
END $$
DELIMITER ;
-- Look at the net income of each property and rank them from low to high level of profit
SELECT
	ParcelID,
    Property_Addr,
    Property_City,
    Sale_Price - Total_Value AS Net_Income,
    Year_Built,
    CASE WHEN Sale_Price - Total_Value > 150000 THEN 'Very High'
		 WHEN Sale_Price - Total_Value BETWEEN 100000 AND 150000 THEN 'High'
         WHEN Sale_Price - Total_Value BETWEEN 50000 AND 100000 THEN 'Medium'
         WHEN Sale_Price - Total_Value BETWEEN 0 AND 50000 THEN 'Low'
         WHEN Sale_Price - Total_Value < 0 THEN 'Loss'
	END AS Profit_Level
FROM
	housing_info
ORDER BY Net_Income DESC
LIMIT 20;
-- Look at the top highest value properties and their characteristic
SELECT
	Property_Addr,
    Property_City,
    Sold_As_Vacant,
    Acreage,
    Land_Use,
    Land_Value,
    Building_Value,
    Sale_Price,
    Year_Built,
    Bedrooms,
    Full_Bath
FROM
	housing_info
ORDER BY Land_Value DESC
LIMIT 40;
-- Look at average sale price, value and acreage of properties in each city
SELECT
	Property_City,
    ROUND(AVG(Sale_Price), 2) AS Average_Sale_Price,
    ROUND(AVG(Acreage), 2) AS Average_Acreage
FROM
	housing_info
WHERE
	Property_City <> ''
GROUP BY Property_City;
-- Look at the sale price trend over time in each city
SELECT 
	Property_City, 
    Sale_Date, 
    ROUND(AVG(Sale_Price), 2) AS Average_Sale_Price
FROM 
	housing_info
GROUP BY 
	Property_City, Sale_Date
ORDER BY 
	Property_City DESC, Sale_Date ASC;
-- ----------------------------------------------------------------------------------------------- -- 
