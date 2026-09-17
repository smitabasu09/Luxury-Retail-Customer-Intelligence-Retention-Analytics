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
group by 1,2
order by total_sales desc;

SELECT  
extract(year from order_date_new) as Year,
extract(Month from order_date_new) as Month, 
sum(sales)as total_sales 
from train 
group by 1,2
order by total_sales asc;



-- 3.3 AVG ORDER VALUE

select 
  round(sum(sales)/count(distinct `order id`),2) as Avg_order_value
from train;

-- Result --> Average Order Value: $460.85

/* INSIGHT :
Sales peak mostly during Q4 (October–December), indicating strong festive or holiday season demand.

Low Sales: January–February
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
-- Retained: 99.24%
-- Churned: 0.76%


-- 6.3 LIFESPAN

SELECT `customer id` ,
MIN(order_date_new) AS "1ST ORDER",
MAX(order_date_new) AS "LAST ORDER",
MAX(order_date_new)-MIN(order_date_new)AS lifespan_days
FROM train
GROUP BY 1;

-- Result summery:
-- only 3 cuustomers has 0 lifespan days.

   


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

/* Result:
VIP Customers	114
Loyal Customers	72
Occasional Buyers	607 */




/*
=================================
FINAL BUSINESS INSIGHTS
=================================

1. Total revenue across the dataset is $2,272,449.86, with an average order 
   value of $460.85.

2. Sales are strongly seasonal — revenue peaks in September–December (Q4) 
   and dips in January–February, pointing to festive/holiday-driven demand.

3. Technology is the top-performing category by revenue contribution, ahead 
   of the other categories.

4. The top 5 products by revenue are the Canon imageCLASS 2200 Advanced 
   Copier, Fellowes PB500 Electric Punch Plastic Comb Binding Machine, 
   Cisco TelePresence System EX90, HON 5400 Series Task Chairs, and the 
   GBC DocuBind TL300 Electric Binding System.

5. Sean Miller is the top customer by spend (15 orders, $25,043.05 in sales).

6. Customer-level retention is very high — 99.24% of customers placed more 
   than one order, with only 0.76% being true one-time buyers. Customer 
   lifespans are correspondingly long, with only 3 customers showing a 
   0-day lifespan.

7. Monthly active customers peaked in 2017, and activity is consistently 
   higher in year-end months across years.

8. Segmenting all 793 customers by order count and spend shows the base is 
   top-heavy toward low engagement: 607 are Occasional Buyers (76.5%), 
   72 are Loyal Customers (9.1%), and only 114 qualify as VIP Customers 
   (14.4%, ≥6 orders and ≥$5,000 spent).

=================================
RECOMMENDATIONS
=================================

1. Focus growth efforts on converting Occasional Buyers (76.5% of the base) 
   into Loyal/VIP tiers — this segment is the largest lever for revenue 
   growth since near-total retention means the issue is order frequency 
   and spend, not customer loss.

2. Protect and reward the 186 Loyal + VIP customers (11.4% of the base) 
   with a loyalty program, since they likely drive a disproportionate 
   share of revenue.

3. Increase marketing spend ahead of Q4 to capture the existing seasonal 
   peak, and run targeted promotions in January–February to offset the 
   seasonal dip.

4. Double down on the Technology category and the top 5 revenue products 
   through bundling, cross-selling, and inventory prioritization.

5. Use the customer segmentation to personalize outreach — e.g., re-engagement 
   campaigns for Occasional Buyers, and account-management-style attention 
   for top spenders like Sean Miller.

6. Since profit/margin data wasn't part of this analysis, a follow-up study 
   incorporating a profit column (if available) would sharpen recommendation 
   #4 by confirming whether top-revenue products are also top-margin.
*/
