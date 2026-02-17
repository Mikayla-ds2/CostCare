-- head of file --
DROP TABLE IF EXISTS insurance;

CREATE TABLE IF NOT EXISTS insurance (
    patient_id SERIAL PRIMARY KEY,
    age INT,
    sex VARCHAR(10),
    bmi FLOAT,
    children INT,
    smoker VARCHAR(5),
    region VARCHAR(20),
    charges FLOAT
);

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'insurance';

/COPY insurance(age, sex, bmi, children, smoker, region, charges)
FROM '/tmp/insurance.csv'
DELIMITER ','
CSV HEADER;

select * from insurance;

-- database & table is workingg; now begin cleaning -- 
select * from insurance
where patient_id is null 
or age is NULL 
or region is null 
or sex is null 
or bmi is null 
or children is null 
or smoker is null 
or charges is null;

select distinct * from insurance;

select * from insurance;

-- proves no duplicates; actually will not work bc of the distinct patient_id -- 

select count(*) from insurance;

-- data.head() --
select * from insurance
limit 10;

-- checking a duplicated value; seems pandas picked up on something sql didn't --
select * from insurance
where region = 'northwest'
and age = 19 and bmi  = 30.59;

-- checking a chat query for duplicates; sure does, patient_id won't ever have a "duplicate" 
-- bc it's a primary key so not present, count shows how many duplicates
select age, sex, bmi, children, smoker, region, charges, count(*) as count from insurance
group by age, sex, bmi, children, smoker, region, charges
having count(*) > 1;

-- showing patient_id; won't necessarily show number of duplicates but yk look with your eyes lol --
select * from insurance
where (age, sex, bmi, children, smoker, region, charges) in (
    select age, sex, bmi, children, smoker, region, charges from insurance
    group by age, sex, bmi, children, smoker, region, charges
    having count(*) > 1);

-- deleting duplicates; ha made a mistake here; needed to only delete one of the rows, not both -- 
DELETE from insurance
where patient_id = 582;

-- verifying --
select * from insurance
where (age, sex, bmi, children, smoker, region, charges) in (
    select age, sex, bmi, children, smoker, region, charges from insurance
    group by age, sex, bmi, children, smoker, region, charges
    having count(*) > 1);

select count(*) from insurance;

-- verifying imbalances -- 
select DISTINCT region, count(*) as region_count from insurance
group by region;
-- quite balanced (324, 324, 364, 325)  mean is 334 --

select DISTINCT smoker, count(*) as smoker_count from insurance
GROUP BY smoker;
-- heavily imbalanced (1063, 274) mean is 668

select DISTINCT sex, count(*) as sex_count from insurance
group by sex
-- balanced (662, 675 ) mean is 668

select DISTINCT children, count(*) as children_count from insurance
group by children
ORDER BY children asc;
-- quite imbalanced (573, 324, 240, 157, 25, 18)  mean = 222 --

select * from insurance

select region, avg(children) as averageChildren from insurance
group by region
order by averageChildren desc;

-- creating this table to utilize numerical => categorical features to check for "imbalance"
drop table if EXISTS insurance_categorical

CREATE TABLE IF NOT EXISTS categorical (
    patient_id SERIAL PRIMARY KEY,
    age INT,
    sex VARCHAR(10),
    bmi FLOAT,
    children INT,
    smoker VARCHAR(5),
    region VARCHAR(20),
    charges FLOAT,
    age_category VARCHAR(20),
    bmi_category VARCHAR(20),
    charges_category VARCHAR(20)
);

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'categorical';

-- adding the data --
COPY categorical(age, sex, bmi, children, smoker, region, charges, age_category, bmi_category, charges_category)
FROM '/tmp/data_categorical.csv'
DELIMITER ','
CSV HEADER;

select * from categorical;

-- allows me to run the queries to check for "imbalance"
select categorical.age_category, count(*) as age_category_count from insurance
join categorical on insurance.patient_id = categorical.patient_id
group by categorical.age_category
order by categorical.age_category asc;
-- balanced (305, 268, 263, 284, 216) mean = 267

select age_category, count(*) as count from categorical
group by age_category
order by count asc;

-- now looking @ bmi --
select categorical.bmi_category, count(*) as bmi_category_count from insurance
join categorical on insurance.patient_id = categorical.patient_id
group by categorical.bmi_category;
-- quite imbalanced (Underweight: 21, Normal: 226, Overweight: 386, Obese: 703) mean = 334


-- men vs. women bmi --
select insurance.sex, categorical.bmi_category, count(*) as count from insurance
join categorical on insurance.patient_id = categorical.patient_id
group by insurance.sex, categorical.bmi_category
order by insurance.sex;
-- much more even than imagined, man this would hit different if i could see the race of these individuals as well --

-- might be dealing with a duplicate issue; there's a one row difference that i don't care enough to find icl --
select insurance.age, insurance.sex, insurance.bmi, insurance.children, insurance.smoker, insurance.region, insurance.charges, categorical.age_category, categorical.bmi_category, count(*) as count 
from insurance
join categorical on insurance.patient_id = categorical.patient_id
group by insurance.age, insurance.sex, insurance.bmi, insurance.children, insurance.smoker, insurance.region, insurance.charges, categorical.age_category, categorical.bmi_category
having count(*) > 1;

drop table if EXISTS errors_dt

CREATE TABLE IF NOT EXISTS errors_dt (
   errorID int PRIMARY KEY,
   true_value FLOAT,
   predicted_value FLOAT,
   error FLOAT,
   abs_error FLOAT,
   pct_error FLOAT,
   age_squared INT,
   log_bmi FLOAT,
   elderly_smoker int,
   obese_smoker int,
   has_children int,
   largeFamily int,
   northeast int,
   northwest int,
   southeast int,
   southwest int,
   female int,
   male int,
   no int,
   yes int
);

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'errors_dt';

-- adding the data --
COPY errors_dt(errorID, true_value, predicted_value, error, abs_error, pct_error, age_squared, log_bmi, elderly_smoker, obese_smoker, has_children, largeFamily, northeast, northwest, southeast, southwest, female, male, no, yes)
FROM '/tmp/errors_dt.csv'
DELIMITER ','
CSV HEADER;

select * from errors_dt;

select count(*) from errors_dt
where northeast = 1 and
female = 1;

select age_squared, pct_error, largeFamily from errors_dt
where northeast = 1 and female = 1

drop table if exists cleaned_data

create table if not exists cleaned_data(
    personID Serial PRIMARY key, 
    age INT,
    sex VARCHAR(10),
    bmi FLOAT,
    children INT,
    smoker VARCHAR(5),
    region VARCHAR(20),
    charges FLOAT,
    age_category VARCHAR(20),
    bmi_category VARCHAR(20),
    charges_category VARCHAR(20),
    elderly_smoker BOOLEAN,
    obese_smoker BOOLEAN,
    has_children BOOLEAN,
    largeFamily BOOLEAN,
    age_squared int,
    log_bmi FLOAT,
    log_charges FLOAT,
    northeast BOOLEAN,
    northwest BOOLEAN,
    southeast BOOLEAN,
    southwest BOOLEAN,
    female BOOLEAN,
    male BOOLEAN,
    no BOOLEAN,
    yes BOOLEAN
);

SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'cleaned_data';

COPY cleaned_data(age, sex, bmi, children, smoker, region, charges, age_category, bmi_category, charges_category, 
elderly_smoker, obese_smoker, has_children, largeFamily, age_squared, log_bmi, log_charges, 
northeast, northwest, southeast, southwest, female, male, no, yes)
FROM '/tmp/cleaned_data.csv'
DELIMITER ','
CSV HEADER;

select * from cleaned_data

select * from cleaned_data
where largeFamily = false
and bmi_category = 'Underweight'
order by sex;

select personID, bmi_category, children, smoker, region, charges_category from cleaned_data
where children = 2
and sex = 'female'
and age_category = '36-45'
order by bmi_category;

select personID, age, sex, bmi_category, charges, smoker, region from cleaned_data
where charges > 9900
and charges < 9999

select personID, age, sex, bmi, children, charges, smoker, charges_category from cleaned_data
where region = 'southwest'
order by charges_category desc;

select count(*) as chargesCategoryCount, charges_category from cleaned_data
where region = 'southwest'
group by charges_category
order by chargesCategoryCount desc;