--How many users are there? -- 
select 
count(distinct user_id) as total_users
from final_raw_data   --unique users

select 
count( user_id) as total_users
from final_raw_data


--How many cookies does each user have on average?

select user_id , avg (cookie_count) as avg_cookie
from (SELECT user_id, count(distinct cookie_id) AS cookie_count
FROM final_raw_data
GROUP BY user_id)
as avgcookies
group by user_id
order by user_id 

--What is the unique number of visits by all users per month?
select  user_id ,  datepart(month , event_time) as month, count(distinct(visit_id)) as no_of_visits
from final_raw_data
group by  user_id ,  datepart(month , event_time)
order by  user_id ,  datepart(month , event_time)

--What is the number of events for each event type?
select event_type ,  count(event_time) as no_of_events
from final_raw_data
group by event_type
order by event_type


 --What is the percentage of visits which have a purchase event?

 select (COUNT(CASE WHEN event_name = 'Purchase' THEN 1 END) * 100.0) / COUNT(visit_id) as percentange_of_visits
 from final_raw_data



 --What is the percentage of visits which view the checkout page but do not have a purchase event?

SELECT 
    (COUNT(distinct CASE 
                        WHEN f.page_name = 'Checkout' 
                             AND p.event_name != 'Purchase' THEN p.visit_id END) / COUNT  ( p.visit_id)) *100  AS percentage_checkout_no_purchase
FROM final_raw_data f
LEFT JOIN final_raw_data p ON f.visit_id = p.visit_id AND p.event_name = 'Purchase'



 --What are the top 3 pages by number of views?

select top 3 page_id , count(event_name) as no_of_views
from final_raw_data
where event_name = 'Page View'
group by page_id
order by count(event_name) desc



 --What is the number of views and cart adds for each product category?
 

 SELECT product_category,
						count( CASE WHEN event_name = 'Page View' THEN product_category END) AS viewed_times,
						count( CASE WHEN event_name = 'Add to Cart' THEN product_category END) AS addcart_times

from final_raw_data
group by product_category



 --What are the top 3 products by purchases?

 select product_category , count(event_name)
 from final_raw_data
 where event_name = 'Purchase'
 group by product_category

 --Using prodct_level_summary and product_category_level_summary tables, 
--Find which product had the most views, cart adds and purchases?

SELECT top 1 product_id,
       times_viewed,
       times_added_to_cart,
       times_purchased
FROM product_level_summary
WHERE product_id IS NOT NULL  -- Exclude NULL rows
ORDER BY times_viewed DESC, times_added_to_cart DESC, times_purchased DESC

SELECT top 1 product_category,
       times_viewed,
       times_added_to_cart,
       times_purchased
FROM product_category_level_summary
WHERE product_category IS NOT NULL  -- Exclude NULL rows
ORDER BY times_viewed DESC, times_added_to_cart DESC, times_purchased DESC


--Find Which product was most likely to be abandoned? 
SELECT top 1 product_category,
       times_abandoned
FROM product_category_level_summary
WHERE product_category IS NOT NULL  -- Exclude NULL rows
ORDER BY times_abandoned DESC


--Find which product had the highest view to purchase percentage? 

SELECT TOP 1 product_id,
       times_viewed,
       times_purchased,
       CASE 
           WHEN times_purchased = 0 THEN 0  -- Prevent division by zero
           ELSE (CAST(times_viewed AS FLOAT) / times_purchased) * 100
       END AS view_to_purchase_percentage
FROM product_level_summary
WHERE product_id IS NOT NULL  -- Exclude NULL rows
ORDER BY view_to_purchase_percentage DESC;




--Find what is the average conversion rate from view to cart add?
SELECT 
    AVG(CASE 
            WHEN times_viewed = 0 THEN 0  -- Prevent division by zero
            ELSE (CAST(times_added_to_cart AS FLOAT) / times_viewed) * 100 
        END) AS avg_conversion_rate_view_to_cart_add
FROM product_level_summary
WHERE times_viewed > 0


--Find What is the average conversion rate from cart add to purchase?

SELECT 
    AVG(CASE 
            WHEN times_purchased = 0 THEN 0  -- Prevent division by zero
            ELSE (CAST(times_purchased AS FLOAT) / times_added_to_cart) * 100 
        END) AS avg_conversion_rate_cart_to_purchase
FROM product_level_summary


--Using visit_summary table, Identifying users who have received
--impressions during each campaign period and comparing each metric with other users who did not have an impression event.
select user_id ,sum(page_views) as impression_totalviews, sum(cart_adds) asimpression_cartsadd , sum(purchase) as impresison_purchase
from visit_summary
where impression = 1
group by user_id

select user_id ,sum(page_views) as impression_totalviews, sum(cart_adds) asimpression_cartsadd , sum(purchase) as impresison_purchase
from visit_summary
where impression = 0
group by user_id


--Using visit_summary table, can we conclude that clicking on an impression lead to higher purchase rates?

SELECT 
    
    COUNT(DISTINCT CASE WHEN impression = 1 AND click = 0 THEN user_id END) AS impression_only_users,
    SUM(CASE WHEN impression = 1 AND click = 0 THEN purchase END) AS impression_only_purchases,
    (SUM(CASE WHEN impression = 1 AND click = 0 THEN purchase END) / 
     COUNT(DISTINCT CASE WHEN impression = 1 AND click = 0 THEN user_id END)) AS impression_only_purchase_rate,

   
    COUNT(DISTINCT CASE WHEN impression = 1 AND click = 1 THEN user_id END) AS clicked_impression_users,
    SUM(CASE WHEN impression = 1 AND click = 1 THEN purchase END) AS clicked_impression_purchases,
    (SUM(CASE WHEN impression = 1 AND click = 1 THEN purchase END) / 
     COUNT(DISTINCT CASE WHEN impression = 1 AND click = 1 THEN user_id END)) AS clicked_impression_purchase_rate
FROM visit_summary
WHERE impression = 1

--yes we can colclude this that clicking on an impression lead to higher purchase rate




--Using visit_summary table, What is the uplift in purchase rate when comparing users who click on a campaign impression
--versus users who do not receive an impression? What if we compare them with users who just an impression but do not click?



SELECT 
    
    COUNT(DISTINCT CASE WHEN impression = 1 AND click = 1 THEN user_id END) AS clicked_impression_users,
    SUM(CASE WHEN impression = 1 AND click = 1 THEN purchase END) AS purchase_clicked_impression_users,
	(SUM(CASE WHEN impression = 1 AND click = 1 THEN purchase END) / 
	COUNT(DISTINCT CASE WHEN impression = 1 AND click = 1 THEN user_id END)) as purchaserate_clicked_impression_users,
   
    COUNT(DISTINCT CASE WHEN impression = 0  THEN user_id END) AS non_impression_users,
    SUM(CASE WHEN impression = 0 THEN purchase END) AS purchase_non_impression_users,
	(SUM(CASE WHEN impression = 0 THEN purchase END) /
	 COUNT(DISTINCT CASE WHEN impression = 0  THEN user_id END)) as purchaserate_non_impression_users,


     COUNT(DISTINCT CASE WHEN impression = 1 AND click = 0 THEN user_id END) AS impression_users,
	 SUM (CASE WHEN impression = 1 AND click = 0 THEN purchase END) AS purchase_impression_users,
	 (SUM (CASE WHEN impression = 1 AND click = 0 THEN purchase END)/
	  COUNT(DISTINCT CASE WHEN impression = 1 AND click = 0 THEN user_id END)) as purchaserate_impression_users
   
FROM visit_summary




--Using visit_summary table, What metrics can you use to quantify the success or failure of each campaign compared to each other?
-- total impresstion per campaign

SELECT campaign_name, COUNT(DISTINCT d_visit_id) AS impressions
FROM visit_summary
WHERE impression = 1
GROUP BY campaign_name

-- click through rate
 select campaign_name , (count (distinct case  when click = 1 then d_visit_id  end)  /
						count (distinct case when impression = 1 then d_visit_id  end ) ) as click_rates
from visit_summary
group by campaign_name

--page views
SELECT campaign_name, AVG(page_views) AS avg_page_views
FROM visit_summary
GROUP BY campaign_name

--Cart Add Rate = (Number of Users Who Added Items to Cart / Total Number of Users Who Clicked) * 100

select campaign_name , (count (distinct case when cart_adds > 0 then d_visit_id  end)  /
						count (distinct case when click = 1 then d_visit_id  end )   * 100) as cart_add_rate
from visit_summary
group by campaign_name


--purchase conversion rate

SELECT campaign_name,
       (SUM(CASE WHEN purchase = 1 THEN 1 ELSE 0 END) / 
        COUNT(DISTINCT CASE WHEN click = 1 THEN user_id END)) AS purchase_conversion_rate
FROM visit_summary
GROUP BY campaign_name




