-- ====================
-- 1. DATABASE SETUP
-- ====================

create database if not exists superstore;

use superstore;

SELECT * FROM train;


-- ==================================
-- 2. DATA TYPE TRANSFORMATION
-- ==================================

-- 2.1 ORDER DATE CONVERSION

alter table train
add column order_date_new DATE;

set sql_safe_updates=0;

update train
set order_date_new=str_to_date(`order date`,'%m/%d/%Y');

select `order date`, order_date_new from train;



-- 2.2 SHIP DATE CONVERSION

ALTER TABLE train
ADD COLUMN ship_date_new DATE;

set sql_safe_updates=0;

UPDATE train
SET ship_date_new = STR_TO_DATE(`ship date`,'%m/%d/%Y');



-- 2.3 NULL VALUE ANALYSIS

SELECT *
FROM train
WHERE sales IS NULL
   OR `customer id` IS NULL;
 
 
   
-- 2.4 DUPLICATE RECORD CHECK

   SELECT
    `order id`,
    COUNT(*) AS duplicate_count
FROM train
GROUP BY `order id`
HAVING COUNT(*) > 1;



-- ===========================
-- 3.     SALES ANALYSIS
-- ===========================


-- 3.1 TOTAL REVENUE

SELECT 
ROUND(SUM(sales),2) AS total_revenue 
FROM train; 

-- RESULT SUMMERY --> REVENUE:2272449.86$


-- 3.2 MONTHLY SALES TREND

SELECT  
extract(year from order_date_new) as Year,
extract(Month from order_date_new) as Month, 
sum(sales)as total_sales 
from train 
group by 1,2;



-- 3.3 AVG ORDER VALUE

SELECT  
`order id` , 
AVG(sales) AS avg_sales
FROM train
GROUP BY 1;


/* INSIGHT :
Sales peak mostly during Q4 (October–December), indicating strong festive or holiday season demand.

Low Sales: January–March
High Sales: September–December

RECOMMENDATION:

1.Increase marketing before Q4.
2.Run campaigns during low-performing months like January and February */




-- ==================================
-- 4. PRODUCT PERFORMANCE ANALYSIS 
-- ==================================

-- 4.1 TOP PRODUCTS BY REVENUE
 
SELECT 
    `product id`,
    `product name`,
     ROUND(SUM(SALES),2) AS total_revenue
FROM train
GROUP BY 1,2
ORDER BY total_revenue DESC
LIMIT 10;


-- 4.2 PRODUCT REVENUE CONTRIBUTION

SELECT 
    Category,
    ROUND(SUM(Sales),2) AS Total_Revenue,
    ROUND(100 * SUM(Sales) / (SELECT SUM(Sales) FROM train),
        2) AS Revenue_Contribution_Percentage
FROM train
GROUP BY Category
ORDER BY Total_Revenue DESC;


-- 4.3 PRODUCT RANKING BY REVENUE

SELECT 
    `product name`,
    ROUND(SUM(sales),2) AS total_sales,
    DENSE_RANK()OVER(
    ORDER BY SUM(sales) DESC) AS product_ranking
    FROM train
    GROUP BY 1;


/* INSIGHT

-- TECHNOLOGY CATEGORY GENERATES MAX REVENUE.

--TOP 5 RANKING PRODUCTS: 

Canon imageCLASS 2200 Advanced Copier,
Fellowes PB500 Electric Punch Plastic Comb Binding Machine with Manual Bind,
Cisco TelePresence System EX90 Videoconferencing Unit,
HON 5400 Series Task Chairs for Big and Tall,
GBC DocuBind TL300 Electric Binding System  */







-- ===========================
-- 5.   CUSTOMER ANALYSIS
-- ===========================

-- 5.1 CUSTOMER WITH HIGHEST PURCHASES 

SELECT  
    `customer name`,
	COUNT(`product id`) AS number_of_orders,
    SUM(sales) AS total_sales
FROM train
GROUP BY 1
ORDER BY total_sales DESC;

-- Sean Miller,	15 ORDERS,	25043.05 REVENUE


-- 5.2 MOST FREQUENT CUSTOMERS

SELECT 
    `customer id`,
    `customer name`, 
    COUNT(order_date_new)AS days_visited
FROM train
GROUP BY 1,2
ORDER BY days_visited DESC ;

/* INSIGHT: MOST FREQUENT CUSTOMERS VISITED 30 AND ABOVE TIMES
William Brown
Matt Abelman
John Lee
Chloris Kastensmidt
Paul Prost
Emily Phan
Arthur Prichep
Edward Hooks
Jonathan Doherty
Zuschuss Carroll
Seth Vernon */


-- 5.3 DETAILED CUSTOMER AND PRODUCT ANALYSIS

SELECT  
    EXTRACT(YEAR FROM order_date_new) AS year,
    EXTRACT(MONTH FROM order_date_new) AS month,
    `product name`,
    `customer name`,
    `customer id`, 
    SUM(sales) AS total_sales 
FROM train
GROUP BY 1,2,3,4,5
ORDER BY total_sales DESC;


-- ===============================
-- 6. CUSTOMER RETENTION ANALYSIS
-- ===============================

-- 6.1 MONTHLY ACTIVE CUSTOMERS 

SELECT 
  year,
  SUM(CASE WHEN month = 1 THEN active_customers ELSE 0 END) AS Jan,
  SUM(CASE WHEN month = 2 THEN active_customers ELSE 0 END) AS Feb,
  SUM(CASE WHEN month = 3 THEN active_customers ELSE 0 END) AS Mar,
  SUM(CASE WHEN month = 4 THEN active_customers ELSE 0 END) AS Apr,
  SUM(CASE WHEN month = 5 THEN active_customers ELSE 0 END) AS May,
  SUM(CASE WHEN month = 6 THEN active_customers ELSE 0 END) AS Jun,
  SUM(CASE WHEN month = 7 THEN active_customers ELSE 0 END) AS Jul,
  SUM(CASE WHEN month = 8 THEN active_customers ELSE 0 END) AS Aug,
  SUM(CASE WHEN month = 9 THEN active_customers ELSE 0 END) AS Sep,
  SUM(CASE WHEN month = 10 THEN active_customers ELSE 0 END) AS Oct,
  SUM(CASE WHEN month = 11 THEN active_customers ELSE 0 END) AS Nov,
  SUM(CASE WHEN month = 12 THEN active_customers ELSE 0 END) AS december
  FROM (select 
            EXTRACT(YEAR FROM order_date_new) as year,
            EXTRACT(Month from order_date_new) as Month,
            COUNT(DISTINCT `customer id`) AS active_customers
        FROM train
        GROUP BY 1,2
        ORDER BY 1,2)t
GROUP BY year
ORDER BY year;

-- Result Summary:

-- Peak: 2017 (highest activity)
-- Low months: multiple months with 0–1 customers
-- Pattern: higher activity in year-end months



-- 6.2 RETENTION & CHURN RATE 

select  
	COUNT(DISTINCT `customer id`) AS Total_customers,

-- One-time Customers
    COUNT(DISTINCT CASE WHEN  order_count=1 THEN `customer id` END) AS "ONE-TIME Customers",

-- Repeat Customers
    COUNT(DISTINCT CASE WHEN  order_count>1 THEN `customer id` END) AS "REPEAT Customers",

-- Retention %
    ROUND(COUNT(DISTINCT CASE WHEN order_count>1 THEN `customer id` END)*100.0
    /COUNT(DISTINCT `customer id`),2) AS "Retention_Rate(%)",

-- Churn %
    100.0-ROUND(COUNT(DISTINCT CASE WHEN order_count>1 then`customer id` END)*100.0
    /COUNT(DISTINCT `customer id`),2) AS "Churn_Rate(%)"
    
FROM
(SELECT `customer id`,COUNT(*) AS order_count
FROM train
GROUP BY 1)t;

-- Result:
-- Retained: 52.17%
-- Churned: 47.83%


-- 6.3 LIFESPAN

SELECT `customer id` ,
MIN(order_date_new) AS "1ST ORDER",
MAX(order_date_new) AS "LAST ORDER",
MAX(order_date_new)-MIN(order_date_new)AS lifespan_days
FROM train
GROUP BY 1;

-- Result summery:
-- majority cuustomers has 0 lifespan days.

-- INSIGHT : 
/* 1. Monthly Activity :
Customer activity was highest in 2017, especially around mid-year and year-end. 
But many months still have very low or no activity, so engagement is not consistent.
   
   2. Retention Insight :
Around 52% of customers are retained while 48% are lost. 
Even among retained users, most only make 2–3 purchases, so repeat engagement is still weak.

3. Lifespan Insight :
Most customers have a lifespan of 0 days, which means they don’t come back after 
their first purchase—leading to high churn.
   
   -- RECOMMENDATION :
   Improve retention with regular campaigns, loyalty programs, and follow-ups to drive repeat purchases. */
   


-- =========================================================
--   7.  Customer Intelligence & Segmentation Analysis
-- =========================================================


-- 7.1 Customer Intelligence & Loyalty Analysis

SELECT 
    `customer id`,
    `customer name`,
    COUNT(`order id`) AS total_orders,
    ROUND(SUM(sales),2) AS total_spent,

    CASE
        WHEN COUNT(`order id`) >= 6 
             AND SUM(sales) >= 5000
        THEN 'VIP Customers'

        WHEN COUNT(`order id`) BETWEEN 3 AND 5
        THEN 'Loyal Customers'

        ELSE 'Occasional Buyers'
    END AS customer_segment

FROM train
GROUP BY 1,2
ORDER BY total_spent DESC;




-- 7.2 Customer Segment Distribution

SELECT 
    customer_segment,
    COUNT(*) AS segment_count
FROM (
SELECT 
    `customer id`,
    `customer name`,
    COUNT(`order id`) AS total_orders,
    ROUND(SUM(sales),2) AS total_spent,

    CASE
        WHEN COUNT(`order id`) >= 6 
             AND SUM(sales) >= 5000
        THEN 'VIP Customers'

        WHEN COUNT(`order id`) BETWEEN 3 AND 5
        THEN 'Loyal Customers'

        ELSE 'Occasional Buyers'
    END AS customer_segment

FROM train
GROUP BY 1,2
ORDER BY total_spent DESC)as customer_groups
GROUP BY 1;


/*

=================================
FINAL BUSINESS INSIGHTS
=================================

1. Technology generated the highest revenue (~₹0.84M), making it the strongest-performing category.

2. Customer retention rate was approximately 52%, indicating a reasonably loyal customer base.

3. Nearly 48% of customers made only one purchase, highlighting an opportunity for retention campaigns.

4. Copiers, Phones, and Accessories were among the most profitable products.

5. Furniture generated strong revenue but comparatively lower profit margins.

6. Sales performance peaked in 2017, showing significant business growth.

7. Customer segmentation identified VIP, Loyal, and Occasional Buyers, enabling targeted marketing strategies.

=================================
RECOMMENDATIONS
=================================

1. Implement loyalty and retention programs for one-time customers.

2. Focus marketing efforts on VIP and Loyal Customers.

3. Optimize pricing and costs in low-margin categories such as Furniture.

4. Increase promotion of high-profit products.

5. Use customer segmentation for personalized marketing campaigns.

6. Plan targeted promotions during lower-performing sales periods.

*/