USE laptops;

-- to see data
SELECT * FROM laptop;

-- to see how much space our dataset occupies in memory
SELECT Data_length/1024 FROM information_schema.TABLES
WHERE table_schema = 'laptops'
AND TABLE_NAME = 'laptop';

-- checking null values in each column
SELECT *
FROM laptop
WHERE (Company IS NULL OR TRIM(Company) = '')
  AND (TypeName IS NULL OR TRIM(TypeName) = '')
  AND inches IS NULL
  AND (ScreenResolution IS NULL OR TRIM(ScreenResolution) = '')
  AND (`Cpu` IS NULL OR TRIM(Cpu) = '')
  AND ram IS NULL
  AND (`Memory` IS NULL OR TRIM(Memory) = '')
  AND (Gpu IS NULL OR TRIM(Gpu) = '')
  AND (OpSys IS NULL OR TRIM(OpSys) = '')
  AND (Weight IS NULL OR TRIM(Weight) = '')
  AND Price IS NULL
  AND `index` IS NULL;
-- no null values found  

-- delete duplicate rows
WITH RankedLaptops AS (
  SELECT `index`,
			ROW_NUMBER() OVER (
			PARTITION BY company, typename, inches, screenresolution,
                        `cpu`, ram, `memory`, gpu, opsys, weight, price
			ORDER BY `index`  
								) 	AS rn
  FROM laptop
)
DELETE FROM laptop
WHERE `index` IN (
  SELECT `index`
  FROM RankedLaptops
  WHERE rn > 1
);

-- finding NULL values and correcting datatypes of each column
-- company
Select Distinct company from laptop;

-- typename
Select Distinct typename from laptop;

-- inches
Select Distinct inches from laptop;
alter table laptop modify column inches decimal(10,1);

-- Ram
Select Distinct Ram from laptop;
UPDATE laptop l1
JOIN laptop l2 ON l1.`index` = l2.`index`
SET l1.ram = REPLACE(l2.ram, 'GB', '');
alter table laptop modify column ram integer;


-- Weight
Select Distinct Weight from laptop;
Update laptop l1
Join laptop l2 ON l1.`index` = l2.`index`
SET l1.weight = Replace(l2.weight,'kg','');
Select * from laptop where weight = 0;
UPDATE laptop SET Weight = '1.65' WHERE `index` = 208;
alter table laptop modify column weight Decimal(10,1);

-- price
SELECT DISTINCT price FROM laptop;
Update laptop l1
JOIN (
    SELECT `index`, ROUND(price) AS rounded_price
    FROM laptop
) AS temp ON l1.`index` = temp.`index`
SET l1.price = temp.rounded_price;
alter table laptop modify column price INTEGER;

-- opsys
SELECT DISTINCT opsys FROM laptop;
UPDATE laptop
SET opsys = 
CASE
	WHEN opsys LIKE '%mac%' THEN 'mac'
    WHEN opsys LIKE '%windows%' THEN 'windows'
    WHEN opsys LIKE '%linux%' THEN 'linux'
    WHEN opsys LIKE '%no os%' THEN 'no os'
    ELSE 'other'
END;

-- gpu
ALTER TABLE laptop
ADD COLUMN gpu_brand VARCHAR(255) AFTER gpu,
ADD COLUMN gpu_name VARCHAR(255) AFTER gpu_brand;

UPDATE laptop l1
JOIN (
    SELECT `index`, SUBSTRING_INDEX(gpu, ' ', 1) AS gpu_brand
    FROM laptop
) AS l2 
ON l1.`index` = l2.`index`
SET l1.gpu_brand = l2.gpu_brand;

UPDATE laptop l1
JOIN (
    SELECT `index`, REPLACE(gpu,gpu_brand,'') AS gpu_name
    FROM laptop
) AS l2 
ON l1.`index` = l2.`index`
SET l1.gpu_name = l2.gpu_name;

ALTER TABLE laptop DROP COLUMN gpu;

-- memory
ALTER TABLE laptop
ADD COLUMN cpu_brand VARCHAR(255) AFTER `cpu`,
ADD COLUMN cpu_core VARCHAR(255) AFTER cpu_brand,
ADD COLUMN cpu_speed DECIMAL(10,1) AFTER cpu_core;

UPDATE laptop l1
JOIN (
    SELECT `index`, SUBSTRING_INDEX(cpu, ' ', 1) AS cpu_brand
    FROM laptop
) AS l2 
ON l1.`index` = l2.`index`
SET l1.cpu_brand = l2.cpu_brand;

UPDATE laptop l1
JOIN (
    SELECT `index`, CAST(REPLACE(SUBSTRING_INDEX(cpu, ' ', -1),
    'GHz','') AS DECIMAL(10,2))
    AS cpu_speed FROM laptop
) AS l2 
ON l1.`index` = l2.`index`
SET l1.cpu_speed = l2.cpu_speed;

UPDATE laptop l1
JOIN (
    SELECT `index`,
           TRIM(
               REPLACE(
                   REPLACE(cpu, SUBSTRING_INDEX(cpu, ' ', 1), ''),  -- remove brand
                   SUBSTRING_INDEX(cpu, ' ', -1), ''                -- remove speed
               )
           ) AS cpu_core
    FROM laptop
) AS temp ON l1.`index` = temp.`index`
SET l1.cpu_core = temp.cpu_core;

ALTER TABLE laptop DROP COLUMN Cpu;

-- memory
ALTER TABLE laptop
ADD COLUMN primary_storage_size INTEGER AFTER `memory`,
ADD COLUMN primary_storage_type VARCHAR(255) AFTER primary_storage_size,
ADD COLUMN secondary_storage_size INTEGER AFTER primary_storage_type,
ADD COLUMN secondary_storage_type VARCHAR(255) AFTER secondary_storage_size;

DELETE FROM laptop WHERE memory = '?';

ALTER TABLE laptop
ADD COLUMN primary_memory_row TEXT,
ADD COLUMN secondary_memory_row TEXT;

UPDATE laptop
SET primary_memory_row = TRIM(SUBSTRING_INDEX(Memory, '+', 1)),
    secondary_memory_row = CASE 
        WHEN Memory LIKE '%+%' THEN TRIM(SUBSTRING_INDEX(Memory, '+', -1))
        ELSE NULL
    END;

UPDATE laptop
SET primary_storage_size = CASE
    WHEN primary_memory_row LIKE '%TB%' THEN
        ROUND(CAST(REPLACE(SUBSTRING_INDEX(primary_memory_row, ' ', 1), 'TB', '') AS DECIMAL(10,2)) * 1024)
    WHEN primary_memory_row LIKE '%GB%' THEN
        CAST(REPLACE(SUBSTRING_INDEX(primary_memory_row, ' ', 1), 'GB', '') AS UNSIGNED)
    ELSE NULL
END;

UPDATE laptop
SET primary_storage_type = TRIM(SUBSTRING_INDEX(primary_memory_row, ' ', -1));
UPDATE laptop
SET primary_storage_type = REPLACE(primary_storage_type, 'Storage', 'Flash');

UPDATE laptop
SET secondary_storage_size = CASE
    WHEN secondary_memory_row LIKE '%TB%' THEN
        ROUND(CAST(REPLACE(SUBSTRING_INDEX(secondary_memory_row, ' ', 1), 'TB', '') AS DECIMAL(10,2)) * 1024)
    WHEN secondary_memory_row LIKE '%GB%' THEN
        CAST(REPLACE(SUBSTRING_INDEX(secondary_memory_row, ' ', 1), 'GB', '') AS UNSIGNED)
    ELSE NULL
END;
UPDATE laptop
SET secondary_storage_type = TRIM(SUBSTRING_INDEX(secondary_memory_row, ' ', -1));

ALTER TABLE laptop DROP COLUMN Memory;
ALTER TABLE laptop DROP COLUMN primary_memory_row;
ALTER TABLE laptop DROP COLUMN secondary_memory_row;

-- screenresolution
ALTER TABLE laptop
ADD COLUMN resolution_width INTEGER AFTER screenresolution,
ADD COLUMN resolution_height INTEGER AFTER resolution_width;


SELECT `index`,SCREENRESOLUTION,
SUBSTRING_INDEX(SUBSTRING_INDEX(screenresolution,' ',-1),'x',1) AS LASTITEM,
SUBSTRING_INDEX(SUBSTRING_INDEX(screenresolution,' ',-1),'x',-1) AS RESOL
FROM laptop;

UPDATE laptop
SET resolution_width = SUBSTRING_INDEX(SUBSTRING_INDEX(screenresolution,' ',-1),'x',1),
resolution_height = SUBSTRING_INDEX(SUBSTRING_INDEX(screenresolution,' ',-1),'x',-1);

ALTER TABLE laptop
ADD COLUMN touchscreen INTEGER AFTER resolution_height;
UPDATE laptop
SET touchscreen = screenresolution LIKE '%Touch%';

ALTER TABLE laptop
ADD COLUMN ips_panel INTEGER AFTER touchscreen;
UPDATE laptop
SET ips_panel = screenresolution LIKE '%IPS%';

ALTER TABLE laptop DROP COLUMN screenresolution;

-- CPU_NAME
SELECT cpu_core,
SUBSTRING_INDEX(TRIM(cpu_core),' ',2)
FROM laptop;

UPDATE laptop
SET cpu_core = SUBSTRING_INDEX(TRIM(cpu_core),' ',2);


UPDATE laptop
SET secondary_storage_size = COALESCE(secondary_storage_size, 0),
    secondary_storage_type = COALESCE(secondary_storage_type, 'None');

ALTER TABLE laptop DROP COLUMN gpu_name;

select * from laptop