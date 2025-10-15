-- EDA STARTS

USE laptops;

SELECT * FROM laptop;

-- head, tail, sample
select * from laptop order by `index` limit 5;
select * from laptop order by `index` DESC limit 5;
select * from laptop order by rand() limit 5;

-- numerical columns --> inches,resolution_width
-- resolution_width, cpu_speed, ram, primary_storage_size
-- secondary_storage_size, weight, price

-- price
SELECT
    COUNT(*) AS total_rows,
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    AVG(price) AS avg_price,
    STD(price) AS std_price
FROM laptop;

-- let's see cheapest and most expensive laptop
SELECT * FROM laptop WHERE PRICE = (SELECT MIN(PRICE) FROM LAPTOP);
SELECT * FROM laptop WHERE PRICE = (SELECT MAX(PRICE) FROM LAPTOP);

-- quartiles
WITH ranked_prices AS (
  SELECT price,
         ROW_NUMBER() OVER (ORDER BY price) AS rn,
         COUNT(*) OVER () AS total_rows
  FROM laptop
)
SELECT
  (SELECT price FROM ranked_prices WHERE rn = FLOOR(total_rows * 0.25)) AS Q1,
  (SELECT AVG(price) FROM ranked_prices WHERE rn IN (FLOOR((total_rows + 1) / 2), CEIL((total_rows + 1) / 2))) AS median,
  (SELECT price FROM ranked_prices WHERE rn = FLOOR(total_rows * 0.75)) AS Q3;

-- checking NULL values
select count(price) from laptop where price is null;

-- outliers
WITH ranked_prices AS (
  SELECT price,
         ROW_NUMBER() OVER (ORDER BY price) AS rn,
         COUNT(*) OVER () AS total_rows
  FROM laptop
),
quartiles AS (
  SELECT
    (SELECT price FROM ranked_prices WHERE rn = FLOOR(total_rows * 0.25)) AS Q1,
    (SELECT price FROM ranked_prices WHERE rn = FLOOR(total_rows * 0.75)) AS Q3
)
SELECT *
FROM laptop
WHERE price < (SELECT Q1 - 1.5 * (Q3 - Q1) FROM quartiles)
   OR price > (SELECT Q3 + 1.5 * (Q3 - Q1) FROM quartiles);

-- histogram 
select t.buckets,repeat('*',count(*)/10) from(select price,
case
	when price between 0 and 25000 then '0-25k'
    when price between 25001 and 50000 then '25k-50k'
    when price between 50001 and 75000 then '50k-75k'
    when price between 75001 and 100000 then '75k-100k'
    when price between 100001 and 150000 then '100k-150k'
    when price between 150001 and 200000 then '150k-200k'
    else '>200k'
end as buckets
from laptop) t
group by t.buckets
order by t.buckets ASC;


-- for filling NULL values we have multiple methods.
-- replace with mean price of table
update laptop
set price = (select avg(price) from  laptop)
where price is null;

-- replace with mean of the company laptop
update laptop l1
set price = (select avg(price) from  laptop l2
			where l2.company = l1.company)
where price is null;

-- replace with mean + processor name and many more condition we can add
update laptop l1
set price = (select avg(price) from  laptop l2
			where l2.company = l1.company
            and l2.cpu_core = l1.cpu_core)
where price is null;

-- numerical column --> ram

-- head tail and sample
select ram from laptop order by `index` limit 5;
select ram from laptop order by ram DESC limit 5;
select ram from laptop order by rand() limit 5;

-- checking NULL values
select count(*) from laptop where ram is null;

-- 8 number summary
SELECT
    COUNT(*) AS total_rows,
    MIN(ram) AS min_ram,
    MAX(ram) AS max_ram,
    AVG(ram) AS avg_ram,
    STD(ram) AS std_ram
FROM laptop;

-- quartiles
WITH ranked_ram AS (
  SELECT ram,
         ROW_NUMBER() OVER (ORDER BY ram) AS rn,
         COUNT(*) OVER () AS total_rows
  FROM laptop
)
SELECT
  (SELECT ram FROM ranked_ram WHERE rn = FLOOR(total_rows * 0.25)) AS Q1,
  (SELECT AVG(ram) FROM ranked_ram WHERE rn IN (FLOOR((total_rows + 1) / 2), CEIL((total_rows + 1) / 2))) AS median,
  (SELECT ram FROM ranked_ram WHERE rn = FLOOR(total_rows * 0.75)) AS Q3;
-- here we can see median and Q3 to be same which is suspicious


SELECT ram,COUNT(*) FROM laptop
GROUP BY ram;
-- number of laptops having 8GB ram are more than 50%
-- which explains the median == Q3


-- outliers
WITH ranked_ram AS (
  SELECT ram,
         ROW_NUMBER() OVER (ORDER BY ram) AS rn,
         COUNT(*) OVER () AS total_rows
  FROM laptop
),
quartiles AS (
  SELECT
    (SELECT ram FROM ranked_ram WHERE rn = FLOOR(total_rows * 0.25)) AS Q1,
    (SELECT ram FROM ranked_ram WHERE rn = FLOOR(total_rows * 0.75)) AS Q3
)
SELECT *
FROM laptop
WHERE ram < (SELECT Q1 - 1.5 * (Q3 - Q1) FROM quartiles)
   OR ram > (SELECT Q3 + 1.5 * (Q3 - Q1) FROM quartiles);


-- some exploration and filling of values
UPDATE laptop SET ram = '12' WHERE ram = 1; -- because cost was 53k it has to be 12GB ram
UPDATE laptop SET ram = 4 WHERE ram = 2; -- no laptop has 2GB ram so converted it to 4GB
UPDATE laptop SET ram = 8 WHERE `index` = 71;
UPDATE laptop SET ram = 16 WHERE `index` = 720;
UPDATE laptop SET ram = 32 WHERE `index` = 1066;

-- numerical column --> weight

-- checking NULL values
select count(*) from laptop where weight is null;

-- 8 number summary
SELECT
    COUNT(*) AS total_rows,
    MIN(weight) AS min_weight,
    MAX(weight) AS max_weight,
    AVG(weight) AS avg_weight,
    STD(weight) AS std_weight
FROM laptop;
-- some laptops were even 8kg which is strange !!

-- quartiles
WITH ranked_weight AS (
  SELECT weight,
         ROW_NUMBER() OVER (ORDER BY weight) AS rn,
         COUNT(*) OVER () AS total_rows
  FROM laptop
)
SELECT
  (SELECT weight FROM ranked_weight WHERE rn = FLOOR(total_rows * 0.25)) AS Q1,
  (SELECT AVG(weight) FROM ranked_weight WHERE rn IN (FLOOR((total_rows + 1) / 2), CEIL((total_rows + 1) / 2))) AS median,
  (SELECT weight FROM ranked_weight WHERE rn = FLOOR(total_rows * 0.75)) AS Q3;
-- here we can confirm that laptops weighing over
-- 3kg are outliers

-- weight can't be 0kg and 11kg
UPDATE laptop SET weight = 1.66 WHERE weight = 0;
UPDATE laptop SET weight = 1.6 WHERE weight = 11.1;


-- let's see outliers
select *
from laptop where weight > 4.5;

-- updating values
UPDATE laptop SET weight = 1.8 WHERE `index` = 133;
UPDATE laptop SET weight = 2.2 WHERE `index` = 173;
UPDATE laptop SET weight = 2.7 WHERE `index` = 238;
UPDATE laptop SET weight = 1.7 WHERE `index` = 240;
UPDATE laptop SET weight = 2.5 WHERE `index` = 302;
UPDATE laptop SET weight = 1.9 WHERE `index` = 326;
UPDATE laptop SET weight = 2.7 WHERE `index` = 577;
UPDATE laptop SET weight = 1.5 WHERE `index` = 587;
UPDATE laptop SET weight = 2.0 WHERE `index` = 656;
UPDATE laptop SET weight = 2.6 WHERE `index` = 1048;
UPDATE laptop SET weight = 2.7 WHERE `index` = 1081;
UPDATE laptop SET weight = 2.6 WHERE `index` = 1116; 


-- numerical column --> primary_storage_size

-- checking NULL values
select count(*) from laptop where primary_storage_size is null;

SELECT
    COUNT(*) AS total_rows,
    MIN(primary_storage_size) AS min_primary_storage_size,
    MAX(primary_storage_size) AS max_primary_storage_size,
    AVG(primary_storage_size) AS avg_primary_storage_size,
    STD(primary_storage_size) AS std_primary_storage_size
FROM laptop;

-- quartiles
WITH ranked_primary_storage_size AS (
  SELECT primary_storage_size,
         ROW_NUMBER() OVER (ORDER BY primary_storage_size) AS rn,
         COUNT(*) OVER () AS total_rows
  FROM laptop
)
SELECT
  (SELECT primary_storage_size FROM ranked_primary_storage_size WHERE rn = FLOOR(total_rows * 0.25)) AS Q1,
  (SELECT AVG(primary_storage_size) FROM ranked_primary_storage_size WHERE rn IN (FLOOR((total_rows + 1) / 2), CEIL((total_rows + 1) / 2))) AS median,
  (SELECT primary_storage_size FROM ranked_primary_storage_size WHERE rn = FLOOR(total_rows * 0.75)) AS Q3;
  -- no suspicious values
  
-- numerical column --> cpu_speed

-- checking NULL values
select count(*) from laptop where cpu_speed is null;

SELECT
    COUNT(*) AS total_rows,
    MIN(cpu_speed) AS min_cpu_speed,
    MAX(cpu_speed) AS max_cpu_speed,
    AVG(cpu_speed) AS avg_cpu_speed,
    STD(cpu_speed) AS std_cpu_speed
FROM laptop;

-- quartiles
WITH ranked_cpu_speed AS (
  SELECT cpu_speed,
         ROW_NUMBER() OVER (ORDER BY cpu_speed) AS rn,
         COUNT(*) OVER () AS total_rows
  FROM laptop
)
SELECT
  (SELECT cpu_speed FROM ranked_cpu_speed WHERE rn = FLOOR(total_rows * 0.25)) AS Q1,
  (SELECT AVG(cpu_speed) FROM ranked_cpu_speed WHERE rn IN (FLOOR((total_rows + 1) / 2), CEIL((total_rows + 1) / 2))) AS median,
  (SELECT cpu_speed FROM ranked_cpu_speed WHERE rn = FLOOR(total_rows * 0.75)) AS Q3;
-- nothing strange here

-- categorical columns --> company, typename, touchscreen
-- ips_panel, cpu_brand, cpu_core, primary_storage_type
-- gpu_brand, opsys

-- company
-- checking NULL values
select count(*) from laptop where company is null;

-- VALUE COUNTS
SELECT company,COUNT(company)
FROM laptop GROUP BY company;

-- typename
-- checking NULL values
select count(*) from laptop where typename is null;

-- VALUE COUNTS
SELECT typename,COUNT(typename)
FROM laptop GROUP BY typename;

-- touchscreen
-- checking NULL values
select count(*) from laptop where touchscreen is null;

-- VALUE COUNTS
SELECT touchscreen,COUNT(touchscreen)
FROM laptop GROUP BY touchscreen;

-- ips_panel
-- VALUE COUNTS
SELECT ips_panel,COUNT(ips_panel)
FROM laptop GROUP BY ips_panel;

-- cpu_brand
-- VALUE COUNTS
SELECT cpu_brand,COUNT(cpu_brand)
FROM laptop GROUP BY cpu_brand;

-- cpu_core
-- VALUE COUNTS
SELECT cpu_core,COUNT(cpu_core)
FROM laptop GROUP BY cpu_core;

-- primary_storage_type
SELECT * FROM laptop WHERE primary_storage_type IS NULL;

-- VALUE COUNTS
SELECT primary_storage_type,COUNT(primary_storage_type)
FROM laptop GROUP BY primary_storage_type;

-- gpu_brand
-- VALUE COUNTS
SELECT gpu_brand,COUNT(gpu_brand)
FROM laptop GROUP BY gpu_brand;

-- opsys
-- VALUE COUNTS
SELECT opsys,COUNT(opsys)
FROM laptop GROUP BY opsys;
-- NO OS is also an Operating System

-- BIVARIATE ANALYSIS

-- numerical-numerical

-- as PRICE is the most important column
-- all bivariate analysis would be around it only.

-- PRICE & CPU SPEED
SELECT cpu_speed,COUNT(*),AVG(price) FROM laptop
GROUP BY cpu_speed
ORDER BY cpu_speed;

SELECT
    COUNT(*) AS total_rows,
    MIN(price) AS min_price,
    MIN(cpu_speed) AS min_cpu_speed,
    MAX(price) AS max_price,
    MAX(cpu_speed) AS max_cpu_speed,
    AVG(price) AS avg_price,
    AVG(cpu_speed) AS avg_cpu_speed,
    STD(price) AS std_price,
    STD(cpu_speed) AS std_cpu_speed
FROM laptop;

-- PRICE & RAM
SELECT ram,COUNT(*),AVG(price) FROM laptop
GROUP BY ram
ORDER BY ram;

SELECT
    COUNT(*) AS total_rows,
    MIN(price) AS min_price,
    MIN(ram) AS min_ram,
    MAX(price) AS max_price,
    MAX(ram) AS max_ram,
    AVG(price) AS avg_price,
    AVG(ram) AS avg_ram,
    STD(price) AS std_price,
    STD(ram) AS std_ram
FROM laptop;


-- PRICE & primary_storage_size
SELECT primary_storage_size,COUNT(*),AVG(price) FROM laptop
GROUP BY primary_storage_size
ORDER BY primary_storage_size;

SELECT
    COUNT(*) AS total_rows,
    MIN(price) AS min_price,
    MIN(primary_storage_size) AS min_primary_storage_size,
    MAX(price) AS max_price,
    MAX(primary_storage_size) AS max_primary_storage_size,
    AVG(price) AS avg_price,
    AVG(primary_storage_size) AS avg_primary_storage_size,
    STD(price) AS std_price,
    STD(primary_storage_size) AS std_primary_storage_size
FROM laptop;

-- PRICE & INCHES
SELECT inches,COUNT(*),AVG(price) FROM laptop
GROUP BY inches
ORDER BY inches;

-- BIVARIATE ANALYSIS

-- categorical - numerical 

-- price & company
select company,count(*),
min(price),
max(price),
avg(price),
std(price)
from laptop
group by company;

-- price & typename
select typename,count(*),
min(price),
max(price),
avg(price),
std(price)
from laptop
group by typename;

-- price & screensize
select screensize,count(*),
min(price),
max(price),
avg(price),
std(price)
from laptop
group by screensize;

-- price & cpu_brand
select cpu_brand,count(*),
min(price),
max(price),
avg(price),
std(price)
from laptop
group by cpu_brand;

-- price & primary_storage_type
select primary_storage_type,count(*),
min(price),
max(price),
avg(price),
std(price)
from laptop
group by primary_storage_type;

-- price & gpu_brand
select gpu_brand,count(*),
min(price),
max(price),
avg(price),
std(price)
from laptop
group by gpu_brand;

-- price & opsys
select opsys,count(*),
min(price),
max(price),
avg(price),
std(price)
from laptop
group by opsys;

-- BIVARIATE ANALYSIS

-- categorical - categorical
-- contigency table

-- company & touchscreen
select company,count(company),
sum(case when touchscreen = 1 then 1 else 0 end) as 'touchscreen_yes',
sum(case when touchscreen = 0 then 1 else 0 end) as 'touchscreen_no'
from laptop group by company order by touchscreen_yes desc;

select distinct(typename) from laptop;

-- company & typename
select company,count(company),
sum(case when typename = 'Gaming' then 1 else 0 end) as 'gaming',
sum(case when typename = 'Notebook' then 1 else 0 end) as 'notebook',
sum(case when typename = 'Ultrabook' then 1 else 0 end) as 'Ultrabook',
sum(case when typename = '2 in 1 Convertible' then 1 else 0 end) as '2 in 1 Convertible',
sum(case when typename = 'Workstation' then 1 else 0 end) as 'Workstation'
from laptop group by company order by count(company) desc;

select distinct(cpu_brand) from laptop;

-- -- company & cpu_brand
select company,count(company),
sum(case when cpu_brand = 'Intel' then 1 else 0 end) as 'Intel',
sum(case when cpu_brand = 'AMD' then 1 else 0 end) as 'AMD',
sum(case when cpu_brand = 'Samsung' then 1 else 0 end) as 'Samsung'
from laptop group by company order by count(company) desc;
select distinct(cpu_core) from laptop;

-- company & cpu_core
select company,count(company),
sum(case when cpu_core = 'Core i5' then 1 else 0 end) as 'Core i5',
sum(case when cpu_core = 'Core i7' then 1 else 0 end) as 'Core i7',
sum(case when cpu_core = 'Core i3' then 1 else 0 end) as 'Core i3'
from laptop group by company order by count(company) desc;

-- Feature Engineering
use laptops;

-- ppi
ALTER TABLE laptop ADD COLUMN ppi INTEGER 
AFTER resolution_height;

UPDATE laptop
SET ppi = ROUND(SQRT(resolution_width*resolution_width +
resolution_height*resolution_height)/inches);

-- screen size bracket
SELECT inches,COUNT(*)
FROM laptop
GROUP BY inches
ORDER BY inches;

ALTER TABLE laptop ADD COLUMN screensize VARCHAR(255) 
AFTER inches;

UPDATE laptop
SET screensize = 
CASE 
WHEN INCHES <= 13.3 THEN 'small'
WHEN INCHES > 13.3 AND INCHES <= 15.6 THEN 'medium'
WHEN INCHES > 15.6 THEN 'large'
END;

SELECT DISTINCT(gpu_brand) FROM LAPTOP;

-- ONE HOT ENCODING
SELECT gpu_brand,
CASE WHEN gpu_brand = 'Intel' THEN 1 ELSE 0 END AS 'intel',
CASE WHEN gpu_brand = 'AMD' THEN 1 ELSE 0 END AS 'amd',
CASE WHEN gpu_brand = 'Nvidia' THEN 1 ELSE 0 END AS 'nvidia',
CASE WHEN gpu_brand = 'ARM' THEN 1 ELSE 0 END AS 'arm'
FROM laptop;

SELECT
    resolution_width,
    resolution_height,
    COUNT(*) AS count
FROM laptop
GROUP BY resolution_width, resolution_height
ORDER BY count DESC;

ALTER TABLE laptop ADD COLUMN screen_type VARCHAR(255);

UPDATE laptop
SET screen_type = CASE
    WHEN resolution_width <= 1366 AND resolution_height <= 768 THEN 'HD'
    WHEN resolution_width <= 1920 AND resolution_height <= 1200 THEN 'FHD'
    WHEN resolution_width <= 2560 AND resolution_height <= 1600 THEN 'QHD'
    WHEN resolution_width > 2560 AND resolution_height > 1600 THEN 'UHD'
    ELSE 'Other'
END;

select * from laptop;