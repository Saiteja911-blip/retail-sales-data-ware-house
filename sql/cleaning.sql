DROP TABLE IF EXISTS orders;

CREATE TABLE orders (
    row_id VARCHAR(50),
    order_id VARCHAR(50),
    order_date VARCHAR(50),  -- Made VARCHAR to prevent date errors
    ship_date VARCHAR(50),   -- Made VARCHAR to prevent date errors
    ship_mode VARCHAR(100),
    customer_id VARCHAR(50),
    customer_name VARCHAR(255),
    segment VARCHAR(100),
    country VARCHAR(100),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(50),
    region VARCHAR(100),
    retail_sales_people VARCHAR(255),
    product_id VARCHAR(50),
    category VARCHAR(100),
    sub_category VARCHAR(100),
    product_name VARCHAR(500),
    returned VARCHAR(50),
    sales VARCHAR(50),       -- Made VARCHAR to prevent '$' or comma errors
    quantity VARCHAR(50),
    discount VARCHAR(50),
    profit VARCHAR(50)
);

COPY orders 
FROM 'C:\Data Analyst\Projects\Retail Sales Data Warehouse\Retail-Supply-Chain-Sales-Dataset.csv'  
WITH (FORMAT csv, HEADER true, DELIMITER ',', ENCODING 'WIN1252');

select * from orders

create table customers as select customer_id,customer_name,segment,country,city,state,postal_code,region from orders
select * from customers

create table products as select product_id,category,sub_category,product_name from orders
select * from products

create table sales as select order_id,order_date,ship_date,ship_mode,customer_id,product_id,retail_sales_people,returned,sales,quantity,discount,profit from orders
select * from sales


-- Cleaning Customers Data

-- 1 Understand
select * from customers

-- 2 Data type check
select column_name,data_type
from information_schema.columns
where table_name='customers'

alter table customers
alter column postal_code type numeric
using postal_code::numeric

--3 Unique column

select customer_id,count(*)
from customers
group by customer_id
having count(*)>1


-- 4 Standardization
select customer_id from customers group by customer_id

select customer_id from customers where customer_id<>TRIM(customer_id)
update customers 
set customer_id = TRIM(customer_id)

select customer_name,count(*) from customers group by customer_name having count(*)>1
select customer_name from customers where customer_name<>TRIM(customer_name)

select segment,count(*) from customers group by segment having count(*)>1
select segment from customers where segment<>TRIM(segment)

select country,count(*) from customers group by country having count(*)>1

select city,count(*) from customers group by city having count(*)>1
select city from customers where city<>TRIM(city)

select state,count(*) from customers group by state having count(*)>1
select state from customers where state<>trim(state)

select postal_code,count(*) from customers group by postal_code having count(*)>1

select region,count(*) from customers group by region having count(*)>1
select region from customers where region<>trim(region)



-- 5 Blanks

select count(*) from customers where customer_id is null

select count(*) from customers where customer_name is null

select count(*) from customers where segment is null

select count(*) from customers where country is null

select count(*) from customers where city is null

select count(*) from customers where state is null

select count(*) from customers where postal_code is null

select count(*) from customers where region is null



-- 6 Remove Duplicates

with cs as (select *, count(*) over(partition by customer_id,customer_name, segment,country,city,state,postal_code,region) as duplicate_count
from customers
)
select * from cs where duplicate_count>1

--if duplicates present then
create table customers_clean as select distinct * from customers

select * from customers_clean

ALTER TABLE customers_clean
ADD CONSTRAINT customers_pk PRIMARY KEY (customer_id);

select column_name,data_type
from information_schema.columns
where table_name='customers_clean'


-- 7 Rules

select customer_name from customers_clean group by customer_name order by customer_name

UPDATE customers_clean
SET customer_name = INITCAP(TRIM(customer_name));

update customers_clean
set city=initcap(trim(city))

select city from customers_clean group by city order by city

SELECT DISTINCT city
FROM customers_clean
ORDER BY city;

select state from customers_clean group by state order by state 

select region from customers_clean group by region order by region

select postal_code from customers_clean group by postal_code order by postal_code





-- cleaning products table

-- 1 Understand
select * from products

-- 2 Data type check
select column_name, data_type
from information_schema.columns
where table_name='products'  -- perfect


-- 3 Unique Column
select count(*), product_id
from products
group by product_id
HAVING COUNT(*) > 1;


-- 4 Standardizing
select * from products

select product_id
from products
where product_id<> TRIM(upper(product_id))

select product_id
from products
where product_id<> TRIM(initcap(product_id))

select category,count(*) from products group by category

select category
from products
where category<> trim(initcap(category))

select sub_category,count(*) from products group by sub_category

select sub_category
from products
where sub_category<> trim(initcap(sub_category))

select product_name,count(*) from products group by product_name

select product_name
from products
where product_name<> trim(initcap(product_name))

select product_name
from products
where product_name<> trim(initcap(product_name))

update products
set product_name=trim(initcap(product_name))  --some are not initcap so i modified it to initcap



-- 5 Blanks
select count(*) from products where product_id is null

select count(*) from products where category is null

select count(*) from products where sub_category is null

select count(*) from products where product_name is null



-- 6 Removing duplicates
CREATE TABLE products_clean AS
SELECT DISTINCT
    product_id,
    category,
    sub_category,
    product_name
FROM products

select * from products_clean

ALTER TABLE products_clean
ADD CONSTRAINT products_pk PRIMARY KEY (product_id)

-- 7 Rules check

SELECT product_id, COUNT(*)
FROM products_clean
GROUP BY product_id
HAVING COUNT(*) > 1

SELECT *
FROM products_clean
WHERE product_id IN (
    SELECT product_id
    FROM products_clean
    GROUP BY product_id
    HAVING COUNT(*) > 1
)
ORDER BY product_id



SELECT
    product_id,
    COUNT(DISTINCT product_name) AS product_names,
    COUNT(DISTINCT category) AS categories,
    COUNT(DISTINCT sub_category) AS sub_categories
FROM products
GROUP BY product_id
HAVING COUNT(DISTINCT product_name) > 1

-- Found important thing that is product_id is duplicates due to different product names have same product_id so it can't be pk

ALTER TABLE products_clean
ADD COLUMN product_key SERIAL

SELECT *
FROM products_clean
ORDER BY product_key
LIMIT 10;

ALTER TABLE products_clean
ADD CONSTRAINT products_pk
PRIMARY KEY (product_key)



-- cleaning sales table

-- 1 Understand
select * from sales


-- 2 Data type check

select column_name,data_type
from information_schema.columns
where table_name='sales'

alter table sales
alter column order_date Type DATE
using order_date::DATE

alter table sales
alter column ship_date Type DATE
using ship_date::DATE

alter table sales
alter column sales Type numeric
using sales::numeric

alter table sales
alter column quantity Type numeric
using quantity::numeric

alter table sales
alter column discount Type numeric
using discount::numeric

alter table sales
alter column profit Type numeric
using profit::numeric


-- 3 Unique

-- No unique required

-- 4 Standardization
select order_id from sales where order_id<>trim(order_id)

select ship_mode from sales group by ship_mode
select ship_mode from sales where ship_mode<>trim(initcap(ship_mode))

select customer_id from sales where customer_id<>trim(customer_id)

select product_id from sales where product_id<>trim(product_id)


select retail_sales_people from sales group by retail_sales_people
select retail_sales_people from sales where retail_sales_people<>trim(initcap(retail_sales_people))





-- 5 Blanks
select count(*) from sales where order_id is null
select count(*) from sales where order_date is null
select count(*) from sales where ship_date is null
select count(*) from sales where ship_mode is null
select count(*) from sales where customer_id is null
select count(*) from sales where product_id is null
select count(*) from sales where retail_sales_people is null
select count(*) from sales where returned is null
select count(*) from sales where sales is null
select count(*) from sales where quantity is null
select count(*) from sales where discount is null
select count(*) from sales where profit is null


-- 6 Remove Duplicates
create table sales_clean as select distinct * from sales

select count(*) from sales_clean



-- 7 Rules check
select * from sales_clean

SELECT COUNT(*) 
FROM sales 
WHERE  order_date>ship_date

select count(*) from sales where sales <=0
select count(*) from sales where quantity <=0
select count(*) from sales where discount <0
select count(*) from sales where profit <=0
select count(profit) from sales where profit <=0


-- EDA Exploratory Data Analysis

ALTER TABLE sales_clean
ADD COLUMN product_key INTEGER

UPDATE sales_clean s
SET product_key = p.product_key
FROM products_clean p
WHERE s.product_id = p.product_id

alter table sales_clean
add column loss varchar(25)


-- EDA starts


update sales_clean
set loss= case when profit<0 then profit else 0 end


select * from sales_clean
select * from customers_clean
select * from products_clean


--Total profit
select sum(profit) as total_profit from sales_clean

-- Month, Year wise profit
select extract(month from order_date) as month,extract(year from order_date) as year,sum(profit) as profit
from sales_clean
group by extract(month from order_date),extract(year from order_date)
order by year,month

-- Sales,Profit by Sub-category
select p.sub_category,sum(s.sales) as sales, sum(s.profit) as profit
from products_clean p inner join sales_clean s
on p.product_id=s.product_id
group by p.sub_category

--profit by region
select c.region, sum(s.profit) as profit
from customers_clean c inner join sales_clean s
on c.customer_id=s.customer_id
group by c.region

-- discount by profit
SELECT discount,SUM(profit) AS profit
FROM sales_clean
GROUP BY discount
ORDER BY discount


-- retail_sales_people by profit
select retail_sales_people,sum(profit)as profit from sales_clean group by retail_sales_people

-- customer by profit
select c.customer_name,sum(s.profit) as profit
from customers_clean c inner join sales_clean s
on c.customer_id=s.customer_id
group by c.customer_name
order by profit desc
