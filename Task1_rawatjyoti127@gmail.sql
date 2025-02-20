--created the databse

create database seafoodkart
use seafoodkart

--Update the users table by modifying the start_date column to be a date data type
alter table users 
alter column start_date date

select start_date from users 
where isdate(start_date) = 0  --   tocheck the invalid dates 

update users
SET start_date = CONVERT(DATE, start_date, 105) -- converting the data in same format




--Update the events table by modifying event_time column to be a datetime data type.

alter table events
alter column event_time date

select event_time from events
where isdate(event_time) = 0  --   tocheck the invalid dates

update events
set event_time = convert(date, event_time, 105)  --convert the invalid date in the same format
`



--Update the  Campaign Identifier  table by modifying start_date, end_date columns to be a date data type.
alter table campaign_identifier
alter column start_date date

alter table campaign_identifier
alter column end_date date


update campaign_identifier                     -- converted the both the columns in same date format 
set start_date = convert(date, start_date, 105),
end_date = convert(date , end_date,105)




--What is the count of records in each table?

select count(*) from campaign_identifier
select count(*) from event_identifier
select count(*) from events
select count(*) from page_heirarchy
select count(*) from users




--Create combined table of all the five tables by joining these tables. The final table name should be 'Final_Raw_Data' in the data base (50 Marks)
--Take Base Table as Event Table, and join all the tables to Event Table. This table should be present in the database.
--Check your logic by checking the rows and include all columns from all the tables appropriately.
EXEC sp_rename 'campaign_identifier.start_date', 'c_start_date', 'COLUMN'
EXEC sp_rename 'event_identifier.event_type', 'e_event_type', 'COLUMN'
EXEC sp_rename 'page_heirarchy.page_id', 'p_page_id', 'COLUMN'
EXEC sp_rename 'users.cookie_id', 'u_cookie_id', 'COLUMN'     ---- changed the column names that were same 


select * 
into final_raw_data 
from events as t1
full join page_heirarchy as t2 on t1.page_id = t2.p_page_id 
full join users as t3 on t3.u_cookie_id = t1.cookie_id
full join event_identifier as t4 on t4.e_event_type = t1.event_type
full join campaign_identifier as t5 on t5.c_start_date = t3.start_date

select * from final_raw_data




-- create a new table (product_level_summary) which has the following details:
CREATE TABLE product_level_summary (
    product_id varchar(255) ,
    times_viewed varchar(255) ,
    times_added_to_cart varchar(255) ,
    times_abandoned varchar(255),
    times_purchased varchar(255)
)

INSERT INTO product_level_summary (product_id, times_viewed, times_added_to_cart, times_abandoned, times_purchased)
SELECT 
    f.product_id,
    COUNT(CASE WHEN f.event_name = 'Page View' THEN 1 ELSE null END) AS times_viewed,
    COUNT(CASE WHEN f.event_name = 'Add to Cart' THEN 1 ELSE null END) AS times_added_to_cart,
    COUNT(CASE WHEN f.event_name = 'Add to Cart' AND p.product_id IS NULL THEN 1 ELSE null END) AS times_abandoned,
    COUNT(CASE WHEN f.event_name = 'Purchase' THEN 1 ELSE null END) AS times_purchased
FROM final_raw_data f
LEFT JOIN final_raw_data p ON f.product_id = p.product_id AND p.event_name = 'Purchase'
GROUP BY f.product_id

select * from product_level_summary

--How many times was each product viewed? 

INSERT INTO product_level_summary (product_id, times_viewed, times_added_to_cart, times_abandoned, times_purchased)
with times_viewed as
(select product_id , count(event_name) as views_count
from final_raw_data
where event_name = 'Page View'
group by product_id
order by product_id)


--How many times was each product added to cart? 
select product_id , count(event_name) as addtocart_count
from final_raw_data
where event_name = 'Add to Cart'
group by product_id
order by product_id

--How many times was each product added to a cart but not purchased (abandoned)? 
SELECT product_id, COUNT(event_name) AS addtocartnp_count
FROM final_raw_data
WHERE event_name = 'Add to Cart'
and product_id not in (SELECT product_id FROM final_raw_data
WHERE event_name = 'Purchase')
GROUP BY product_id
order by product_id

--How many times was each product purchased?
select product_id , count(event_name) as purchase_count
from final_raw_data
where event_name = 'Purchase'
group by product_id

--Hint:The above calculations should be at product level (one record for each product). This table should be present in the database.
--Check your logic by checking the rows and columns.




--create a new table (product_category_level_summary) which has the following details:
--How many times was each product viewed? 
--How many times was each product added to cart? 
--How many times was each product added to a cart but not purchased (abandoned)? 
--How many times was each product purchased?

CREATE TABLE product_category_level_summary (
    product_category varchar(255) ,
    times_viewed varchar(255) ,
    times_added_to_cart varchar(255) ,
    times_abandoned varchar(255),
    times_purchased varchar(255)
)

INSERT INTO product_category_level_summary (product_category, times_viewed, times_added_to_cart, times_abandoned, times_purchased)
SELECT 
    f.product_category,
    COUNT(CASE WHEN f.event_name = 'Page View' THEN 1 ELSE null END) AS times_viewed,
    COUNT(CASE WHEN f.event_name = 'Add to Cart' THEN 1 ELSE null END) AS times_added_to_cart,
    COUNT(CASE WHEN f.event_name = 'Add to Cart' AND p.product_id IS NULL THEN 1 ELSE null END) AS times_abandoned,
    COUNT(CASE WHEN f.event_name = 'Purchase' THEN 1 ELSE null END) AS times_purchased
FROM final_raw_data f
LEFT JOIN final_raw_data p ON f.product_category = p.product_category AND p.event_name = 'Purchase'
GROUP BY f.product_category

select * from product_category_level_summary



--Create a new table 'visit_summary' that has 1 single row for every unique visit_id record and has the following 10 columns:
--1. user_id
--2. visit_id 
--3. visit_start_time: the earliest event_time for each visit
--4. page_views: count of page views for each visit
--5. cart_adds: count of product cart add events for each visit 
--6. purchase: 1/0 flag if a purchase event exists for each visit 
--7. campaign_name: map the visit to a campaign if the visit_start_time falls between the start_date and end_date 
--8. impression: count of ad impressions for each visit 
--9. click: count of ad clicks for each visit 
--10. cart_products: a comma separated text value with products added to the cart sorted by the order they were added to the cart (hint: use the sequence_number)

CREATE TABLE visit_summary (
    d_visit_id VARCHAR(255) ,
    user_id INT,
    visit_start_time DATETIME,
    page_views INT,
    cart_adds INT,
    purchase INT,
    campaign_name VARCHAR(255),
    impression INT,
    click INT,
    cart_products VARCHAR(255)
)

INSERT INTO visit_summary (d_visit_id, user_id, visit_start_time, page_views,
    cart_adds, purchase, campaign_name, impression, click, cart_products)
SELECT DISTINCT 
    visit_id AS d_visit_id,
    user_id,
    CONVERT(DATE, MIN(event_time)) AS visit_start_time,
    COUNT(CASE WHEN event_name = 'Page View' THEN 1 END) AS page_views,
    COUNT(CASE WHEN event_name = 'Add to Cart' THEN 1 END) AS cart_adds,
    MAX(CASE WHEN event_name = 'Purchase' THEN 1 ELSE 0 END) AS purchase,
        WHEN CONVERT(DATE, MIN(event_time)) BETWEEN CONVERT(DATE, start_date) AND CONVERT(DATE, end_date) 
        THEN campaign_name
        ELSE 'no_campaign' 
    END AS campaign_name,
    COUNT(CASE WHEN event_name = 'Ad Impression' THEN 1 END) AS impression,
    COUNT(CASE WHEN event_name = 'Ad Click' THEN 1 END) AS click,
    STRING_AGG(products, ',') WITHIN GROUP (ORDER BY sequence_number) AS cart_products
FROM final_raw_data
GROUP BY visit_id, user_id, start_date, end_date, campaign_name;

select * from visit_summary
