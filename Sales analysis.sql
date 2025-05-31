create database Analytics;

CREATE TABLE transactions (
    transaction_Date DATE,
    Product_id VARCHAR(10),
    customer_id VARCHAR(10),
    quantity INT,
    revenue INT,
    region VARCHAR(10)
);

CREATE TABLE marketing_campaigns (
    campaign_id VARCHAR(10),
    start_date DATE,
    end_date DATE,
    region VARCHAR(10),
    spend INT
);

CREATE TABLE customer_database (
    customer_id VARCHAR(10),
    location VARCHAR(50),
    signup_date DATE
);

-- 1. Total revenue by region 
SELECT 
    region, SUM(revenue) AS total_revenue
FROM
    transactions
GROUP BY region;

-- 2. Total Quantity Sold by Region
SELECT 
    SUM(quantity) AS total_quantity, region
FROM
    transactions
GROUP BY region;

-- 3. Compare quantity sold vs. AOV (Average Order Value) in West
SELECT 
    region,
    SUM(quantity),
    SUM(revenue) / COUNT(DISTINCT customer_id)
FROM
    transactions
WHERE
    region = 'West'
GROUP BY region;

-- 4. New vs. returning customers in West
select
	t.customer_id,
	case
		when c.signup_date >= '2025-03-01' then 'NEW'
        else 'RETURNING'
	end as customer_type,
    sum(t.revenue) as total_revenue
from transactions t
join customer_database c
on t.customer_id = c.customer_id
where region = 'west'
group by customer_id,
	case
		when c.signup_date >= '2025-03-01' then 'NEW'
        else 'RETURNING'
	end;

-- 5. Total Marketing Spend by Region
SELECT 
    region, SUM(spend) AS total_spend
FROM
    marketing_campaigns
GROUP BY region;

-- 6. Campaign Effectiveness (Revenue vs Spend) by Region
SELECT 
    t.region,
    SUM(t.revenue) AS total_revenue,
    SUM(m.spend) AS total_spend,
    SUM(t.revenue) / SUM(m.spend) AS ROI
FROM
    transactions t
        JOIN
    marketing_campaigns m ON t.region = m.region
        AND t.transaction_Date BETWEEN m.start_date AND m.end_date
GROUP BY t.region;

-- 7. Revenue Growth Comparison: West Region vs Other Regions
SELECT 
    region, SUM(revenue)
FROM
    transactions
GROUP BY region;

-- 8. Top 5 Best-Selling Products in West Region
SELECT 
    t.product_id, p.category, SUM(t.revenue) AS total_revenue
FROM
    transactions t
        JOIN
    product_catalog p ON t.Product_id = p.product_id
WHERE
    region = 'west'
GROUP BY t.Product_id , p.category
ORDER BY total_revenue DESC
LIMIT 5;

-- 9. Customer Acquisition Rate in the West Region
#Step 1: Create a region mapping inside the query
with customer_with_region as(
select customer_id, signup_date,
	case
		when location in ('mumbai', 'pune', 'Ahmedabad', 'indore', 'nagpur') then 'west'
		else 'other_state'
	end as region
from customer_database
)

#Step 2: Get new customers in the West region
,new_customer as(
	select count(distinct customer_id) as 'New_cust'
	from customer_with_region
	where region = 'west' and signup_date between '2025-03-01' and '2025-05-01'
)
#Step 3: Get total customers at the start of the period
, total_old_customer as (
	select count(distinct customer_id) as 'old_cust'
	from customer_with_region
	where region = 'west' and signup_date < '2025-03-01'
)
#Step 4: Calculate the Acquisition Rate
SELECT 
    n.new_cust,
    o.old_cust,
    (n.new_cust / o.old_cust) * 100 AS acquisition_rate
FROM
    new_customer n,
    total_old_customer o;

-- 10. Revenue and Quantity Comparison by Product Category in the West Region
SELECT 
    SUM(t.revenue) AS total_revenue,
    SUM(t.quantity) AS total_quantity,
    p.category
FROM
    transactions t
        JOIN
    product_catalog p ON t.product_id = p.product_id
WHERE
    t.region = 'west'
GROUP BY p.category
ORDER BY total_revenue DESC;



