-- =============================================
-- SUPERSTORE RETAIL SALES ANALYSIS
-- Author: Your Name
-- Date: March 2026
-- Database: MySQL 8.0
-- =============================================

USE superstore;

-- =============================================
-- SECTION 1: DATABASE SETUP
-- =============================================

CREATE TABLE orders (
  order_id        VARCHAR(20),
  order_date      DATE,
  ship_date       DATE,
  shipping_days   INT,
  order_year      INT,
  order_month     VARCHAR(10),
  ship_mode       VARCHAR(30),
  customer_id     VARCHAR(20),
  customer_name   VARCHAR(100),
  segment         VARCHAR(20),
  country         VARCHAR(50),
  city            VARCHAR(50),
  state           VARCHAR(50),
  postal_code     VARCHAR(10),
  region          VARCHAR(20),
  product_id      VARCHAR(25),
  category        VARCHAR(30),
  sub_category    VARCHAR(30),
  product_name    VARCHAR(255),
  sales           DECIMAL(10,2),
  quantity        INT,
  discount        DECIMAL(4,2),
  discount_band   VARCHAR(20),
  profit          DECIMAL(10,2),
  profit_margin   DECIMAL(10,2),
  profit_status   VARCHAR(15)
);

-- =============================================
-- SECTION 2: BASIC ANALYSIS QUERIES
-- =============================================

-- Query 1: Monthly Sales and Profit Trend
SELECT 
    order_year,
    order_month,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM orders
GROUP BY order_year, order_month
ORDER BY order_year, MIN(order_date);

-- Query 2: Sales and Profit by Category
SELECT 
    category,
    sub_category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(AVG(profit_margin), 2) AS avg_margin
FROM orders
GROUP BY category, sub_category
ORDER BY total_sales DESC;

-- Query 3: Top 10 Customers by Sales
SELECT 
    customer_name,
    segment,
    region,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders
GROUP BY customer_name, segment, region
ORDER BY total_sales DESC
LIMIT 10;

-- Query 4: State Performance
SELECT 
    state,
    region,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(AVG(profit_margin), 2) AS avg_margin
FROM orders
GROUP BY state, region
ORDER BY total_profit DESC;

-- Query 5: Segment Performance
SELECT 
    segment,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    ROUND(AVG(profit_margin), 2) AS avg_margin
FROM orders
GROUP BY segment
ORDER BY total_sales DESC;

-- =============================================
-- SECTION 3: CORPORATE ANALYSIS QUERIES
-- =============================================

-- Query 6: Year over Year Revenue Growth
SELECT 
    order_year,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(LAG(SUM(sales)) OVER (ORDER BY order_year), 2) AS prev_year_sales,
    ROUND(((SUM(sales) - LAG(SUM(sales)) OVER (ORDER BY order_year)) 
        / LAG(SUM(sales)) OVER (ORDER BY order_year)) * 100, 2) AS yoy_growth_pct
FROM orders
GROUP BY order_year;

-- Query 7: Customer RFM Segmentation
WITH customer_stats AS (
    SELECT 
        customer_id, customer_name, segment,
        COUNT(DISTINCT order_id) AS frequency,
        ROUND(SUM(sales), 2) AS monetary,
        MAX(order_date) AS last_order_date
    FROM orders
    GROUP BY customer_id, customer_name, segment
),
rfm AS (
    SELECT *,
        CASE 
            WHEN frequency >= 10 THEN 'High'
            WHEN frequency >= 5  THEN 'Medium'
            ELSE 'Low'
        END AS frequency_band,
        CASE 
            WHEN monetary >= 5000 THEN 'High Value'
            WHEN monetary >= 1000 THEN 'Mid Value'
            ELSE 'Low Value'
        END AS monetary_band
    FROM customer_stats
)
SELECT 
    frequency_band,
    monetary_band,
    COUNT(*) AS customer_count,
    ROUND(AVG(monetary), 2) AS avg_spend
FROM rfm
GROUP BY frequency_band, monetary_band
ORDER BY avg_spend DESC;

-- Query 8: Discount Impact on Profitability
SELECT 
    discount_band,
    COUNT(*) AS total_orders,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(AVG(profit_margin), 2) AS avg_profit_margin,
    COUNT(CASE WHEN profit_status = 'Loss' THEN 1 END) AS loss_orders,
    ROUND(COUNT(CASE WHEN profit_status = 'Loss' THEN 1 END) * 100.0 
        / COUNT(*), 2) AS loss_percentage
FROM orders
GROUP BY discount_band
ORDER BY avg_profit_margin DESC;

-- Query 9: Running Cumulative Revenue by Month
SELECT 
    order_year,
    order_month,
    ROUND(SUM(sales), 2) AS monthly_sales,
    ROUND(SUM(SUM(sales)) OVER (
        PARTITION BY order_year 
        ORDER BY MIN(order_date)
    ), 2) AS cumulative_sales,
    ROUND(SUM(profit), 2) AS monthly_profit,
    ROUND(SUM(SUM(profit)) OVER (
        PARTITION BY order_year 
        ORDER BY MIN(order_date)
    ), 2) AS cumulative_profit
FROM orders
GROUP BY order_year, order_month;

-- Query 10: Product Performance Matrix
WITH product_summary AS (
    SELECT 
        category, sub_category, product_name,
        ROUND(SUM(sales), 2) AS total_sales,
        ROUND(SUM(profit), 2) AS total_profit,
        SUM(quantity) AS total_units_sold,
        ROUND(AVG(profit_margin), 2) AS avg_margin,
        COUNT(DISTINCT order_id) AS times_ordered
    FROM orders
    GROUP BY category, sub_category, product_name
)
SELECT *,
    RANK() OVER (PARTITION BY category ORDER BY total_profit DESC) AS rank_in_category,
    CASE 
        WHEN total_profit > 0 AND total_sales > 1000 THEN 'Star Product'
        WHEN total_profit > 0 AND total_sales <= 1000 THEN 'Niche Product'
        WHEN total_profit <= 0 AND total_sales > 1000 THEN 'High Risk'
        ELSE 'Underperformer'
    END AS product_status
FROM product_summary
ORDER BY total_profit DESC;

-- Query 11: Regional Sales vs National Average
SELECT 
    region,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(AVG(profit_margin), 2) AS avg_margin,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(sales) / (SELECT SUM(sales) FROM orders) * 100, 2) AS sales_contribution_pct,
    CASE 
        WHEN SUM(sales) > (SELECT AVG(region_sales) FROM 
            (SELECT region, SUM(sales) AS region_sales 
             FROM orders GROUP BY region) r)
        THEN 'Above Average'
        ELSE 'Below Average'
    END AS vs_national_avg
FROM orders
GROUP BY region
ORDER BY total_sales DESC;

-- Query 12: Shipping Efficiency Analysis
SELECT 
    ship_mode,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(AVG(shipping_days), 1) AS avg_shipping_days,
    MIN(shipping_days) AS min_days,
    MAX(shipping_days) AS max_days,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(AVG(profit_margin), 2) AS avg_margin
FROM orders
GROUP BY ship_mode
ORDER BY avg_shipping_days;

-- Query 13: Top 10 Profitable vs Loss Making States
SELECT * FROM (
    SELECT 'Top Profitable' AS performance, 
        state,
        ROUND(SUM(profit), 2) AS total_profit,
        ROUND(SUM(sales), 2) AS total_sales
    FROM orders
    GROUP BY state
    ORDER BY total_profit DESC
    LIMIT 10
) top_states
UNION ALL
SELECT * FROM (
    SELECT 'Loss Making' AS performance, 
        state,
        ROUND(SUM(profit), 2) AS total_profit,
        ROUND(SUM(sales), 2) AS total_sales
    FROM orders
    GROUP BY state
    ORDER BY total_profit ASC
    LIMIT 10
) loss_states;

-- Query 14: Customer Retention Analysis
WITH customer_orders AS (
    SELECT 
        customer_id, customer_name, segment,
        COUNT(DISTINCT order_id) AS total_orders,
        ROUND(SUM(sales), 2) AS total_spent,
        MIN(order_date) AS first_order,
        MAX(order_date) AS last_order
    FROM orders
    GROUP BY customer_id, customer_name, segment
)
SELECT *,
    CASE 
        WHEN total_orders = 1 THEN 'One-time Buyer'
        WHEN total_orders BETWEEN 2 AND 5 THEN 'Returning Customer'
        ELSE 'Loyal Customer'
    END AS customer_type
FROM customer_orders;

-- Query 15: Executive KPI Summary
SELECT
    ROUND((SELECT SUM(sales) FROM orders), 2) AS total_revenue,
    ROUND((SELECT SUM(profit) FROM orders), 2) AS total_profit,
    ROUND((SELECT AVG(profit_margin) FROM orders), 2) AS avg_profit_margin,
    (SELECT COUNT(DISTINCT order_id) FROM orders) AS total_orders,
    (SELECT COUNT(DISTINCT customer_id) FROM orders) AS total_customers,
    (SELECT COUNT(DISTINCT product_name) FROM orders) AS total_products,
    ROUND((SELECT SUM(sales) FROM orders WHERE profit_status = 'Loss'), 2) AS loss_revenue,
    (SELECT COUNT(*) FROM orders WHERE discount_band = 'High (41-80%)') AS high_discount_orders,
    (SELECT region FROM orders GROUP BY region 
     ORDER BY SUM(sales) DESC LIMIT 1) AS top_region,
    (SELECT category FROM orders GROUP BY category 
     ORDER BY SUM(profit) DESC LIMIT 1) AS most_profitable_category;

-- =============================================
-- SECTION 4: VIEWS
-- =============================================

CREATE VIEW monthly_trend AS
SELECT order_year, order_month,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit
FROM orders GROUP BY order_year, order_month;

CREATE VIEW category_performance AS
SELECT category, sub_category,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(AVG(profit_margin), 2) AS avg_margin
FROM orders GROUP BY category, sub_category;

CREATE VIEW top_customers AS
SELECT customer_name, segment, region,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders GROUP BY customer_name, segment, region
ORDER BY total_sales DESC LIMIT 10;

CREATE VIEW state_performance AS
SELECT state, region,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(AVG(profit_margin), 2) AS avg_margin
FROM orders GROUP BY state, region;

CREATE VIEW segment_performance AS
SELECT segment,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS total_customers,
    ROUND(AVG(profit_margin), 2) AS avg_margin
FROM orders GROUP BY segment;

CREATE VIEW yoy_growth AS
SELECT order_year,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(LAG(SUM(sales)) OVER (ORDER BY order_year), 2) AS prev_year_sales,
    ROUND(((SUM(sales) - LAG(SUM(sales)) OVER (ORDER BY order_year)) 
        / LAG(SUM(sales)) OVER (ORDER BY order_year)) * 100, 2) AS yoy_growth_pct
FROM orders GROUP BY order_year;

CREATE VIEW rfm_segments AS
WITH customer_stats AS (
    SELECT customer_id, customer_name, segment,
        COUNT(DISTINCT order_id) AS frequency,
        ROUND(SUM(sales), 2) AS monetary,
        MAX(order_date) AS last_order_date
    FROM orders GROUP BY customer_id, customer_name, segment
)
SELECT *,
    CASE WHEN frequency >= 10 THEN 'High'
         WHEN frequency >= 5 THEN 'Medium'
         ELSE 'Low' END AS frequency_band,
    CASE WHEN monetary >= 5000 THEN 'High Value'
         WHEN monetary >= 1000 THEN 'Mid Value'
         ELSE 'Low Value' END AS monetary_band
FROM customer_stats;

CREATE VIEW discount_impact AS
SELECT discount_band,
    COUNT(*) AS total_orders,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(AVG(profit_margin), 2) AS avg_profit_margin,
    COUNT(CASE WHEN profit_status = 'Loss' THEN 1 END) AS loss_orders,
    ROUND(COUNT(CASE WHEN profit_status = 'Loss' THEN 1 END) * 100.0 
        / COUNT(*), 2) AS loss_percentage
FROM orders GROUP BY discount_band;

CREATE VIEW cumulative_revenue AS
SELECT order_year, order_month,
    ROUND(SUM(sales), 2) AS monthly_sales,
    ROUND(SUM(SUM(sales)) OVER (
        PARTITION BY order_year ORDER BY MIN(order_date)
    ), 2) AS cumulative_sales,
    ROUND(SUM(profit), 2) AS monthly_profit,
    ROUND(SUM(SUM(profit)) OVER (
        PARTITION BY order_year ORDER BY MIN(order_date)
    ), 2) AS cumulative_profit
FROM orders GROUP BY order_year, order_month;

CREATE VIEW product_matrix AS
WITH product_summary AS (
    SELECT category, sub_category, product_name,
        ROUND(SUM(sales), 2) AS total_sales,
        ROUND(SUM(profit), 2) AS total_profit,
        SUM(quantity) AS total_units_sold,
        ROUND(AVG(profit_margin), 2) AS avg_margin,
        COUNT(DISTINCT order_id) AS times_ordered
    FROM orders GROUP BY category, sub_category, product_name
)
SELECT *,
    RANK() OVER (PARTITION BY category ORDER BY total_profit DESC) AS rank_in_category,
    CASE WHEN total_profit > 0 AND total_sales > 1000 THEN 'Star Product'
         WHEN total_profit > 0 AND total_sales <= 1000 THEN 'Niche Product'
         WHEN total_profit <= 0 AND total_sales > 1000 THEN 'High Risk'
         ELSE 'Underperformer' END AS product_status
FROM product_summary;

CREATE VIEW regional_performance AS
SELECT region,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(AVG(profit_margin), 2) AS avg_margin,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(sales) / (SELECT SUM(sales) FROM orders) * 100, 2) AS sales_contribution_pct,
    CASE WHEN SUM(sales) > (SELECT AVG(region_sales) FROM 
        (SELECT region, SUM(sales) AS region_sales FROM orders GROUP BY region) r)
    THEN 'Above Average' ELSE 'Below Average' END AS vs_national_avg
FROM orders GROUP BY region;

CREATE VIEW shipping_efficiency AS
SELECT ship_mode,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(AVG(shipping_days), 1) AS avg_shipping_days,
    MIN(shipping_days) AS min_days,
    MAX(shipping_days) AS max_days,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(AVG(profit_margin), 2) AS avg_margin
FROM orders GROUP BY ship_mode;

CREATE VIEW top_bottom_states AS
SELECT * FROM (
    SELECT 'Top Profitable' AS performance, state,
        ROUND(SUM(profit), 2) AS total_profit,
        ROUND(SUM(sales), 2) AS total_sales
    FROM orders GROUP BY state
    ORDER BY total_profit DESC LIMIT 10
) top_states
UNION ALL
SELECT * FROM (
    SELECT 'Loss Making' AS performance, state,
        ROUND(SUM(profit), 2) AS total_profit,
        ROUND(SUM(sales), 2) AS total_sales
    FROM orders GROUP BY state
    ORDER BY total_profit ASC LIMIT 10
) loss_states;

CREATE VIEW customer_retention AS
WITH customer_orders AS (
    SELECT customer_id, customer_name, segment,
        COUNT(DISTINCT order_id) AS total_orders,
        ROUND(SUM(sales), 2) AS total_spent,
        MIN(order_date) AS first_order,
        MAX(order_date) AS last_order
    FROM orders GROUP BY customer_id, customer_name, segment
)
SELECT *,
    CASE WHEN total_orders = 1 THEN 'One-time Buyer'
         WHEN total_orders BETWEEN 2 AND 5 THEN 'Returning Customer'
         ELSE 'Loyal Customer' END AS customer_type
FROM customer_orders;

CREATE VIEW executive_kpi AS
SELECT
    ROUND((SELECT SUM(sales) FROM orders), 2) AS total_revenue,
    ROUND((SELECT SUM(profit) FROM orders), 2) AS total_profit,
    ROUND((SELECT AVG(profit_margin) FROM orders), 2) AS avg_profit_margin,
    (SELECT COUNT(DISTINCT order_id) FROM orders) AS total_orders,
    (SELECT COUNT(DISTINCT customer_id) FROM orders) AS total_customers,
    (SELECT COUNT(DISTINCT product_name) FROM orders) AS total_products,
    ROUND((SELECT SUM(sales) FROM orders WHERE profit_status = 'Loss'), 2) AS loss_revenue,
    (SELECT COUNT(*) FROM orders WHERE discount_band = 'High (41-80%)') AS high_discount_orders,
    (SELECT region FROM orders GROUP BY region 
     ORDER BY SUM(sales) DESC LIMIT 1) AS top_region,
    (SELECT category FROM orders GROUP BY category 
     ORDER BY SUM(profit) DESC LIMIT 1) AS most_profitable_category;
     
     
     
     
     USE superstore;

-- View 16: Customer Churn Risk
CREATE VIEW customer_churn_risk AS
WITH customer_last_order AS (
    SELECT 
        customer_id,
        customer_name,
        segment,
        MAX(order_date) AS last_order_date,
        COUNT(DISTINCT order_id) AS total_orders,
        ROUND(SUM(sales), 2) AS total_spent,
        DATEDIFF('2017-12-31', MAX(order_date)) AS days_since_last_order
    FROM orders
    GROUP BY customer_id, customer_name, segment
)
SELECT *,
    CASE 
        WHEN days_since_last_order <= 90 THEN 'Active'
        WHEN days_since_last_order <= 180 THEN 'At Risk'
        WHEN days_since_last_order <= 365 THEN 'Churning'
        ELSE 'Lost'
    END AS churn_status
FROM customer_last_order;

-- View 17: Pareto Analysis (80/20 Rule)
CREATE VIEW pareto_analysis AS
WITH customer_revenue AS (
    SELECT 
        customer_id,
        customer_name,
        ROUND(SUM(sales), 2) AS total_revenue,
        ROUND(SUM(profit), 2) AS total_profit
    FROM orders
    GROUP BY customer_id, customer_name
),
ranked AS (
    SELECT *,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
        ROUND(SUM(total_revenue) OVER (ORDER BY total_revenue DESC) / 
            (SELECT SUM(sales) FROM orders) * 100, 2) AS cumulative_pct
    FROM customer_revenue
)
SELECT *,
    CASE 
        WHEN cumulative_pct <= 80 THEN 'Top 80% Revenue'
        ELSE 'Bottom 20% Revenue'
    END AS pareto_group
FROM ranked;

-- View 18: Purchase Frequency Trend
CREATE VIEW purchase_frequency_trend AS
SELECT 
    order_year,
    order_month,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT customer_id) AS unique_customers,
    ROUND(COUNT(DISTINCT order_id) * 1.0 / 
        COUNT(DISTINCT customer_id), 2) AS orders_per_customer,
    ROUND(SUM(sales) / COUNT(DISTINCT customer_id), 2) AS revenue_per_customer
FROM orders
GROUP BY order_year, order_month;

-- View 19: Sub-Category Profitability Heatmap
CREATE VIEW subcategory_heatmap AS
SELECT 
    category,
    sub_category,
    order_year,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(AVG(profit_margin), 2) AS avg_margin,
    COUNT(*) AS total_orders,
    CASE 
        WHEN AVG(profit_margin) >= 20 THEN 'Highly Profitable'
        WHEN AVG(profit_margin) >= 10 THEN 'Profitable'
        WHEN AVG(profit_margin) >= 0  THEN 'Low Margin'
        ELSE 'Loss Making'
    END AS profitability_tier
FROM orders
GROUP BY category, sub_category, order_year;

-- View 20: Discount vs Profit Scatter
CREATE VIEW discount_profit_scatter AS
SELECT 
    order_id,
    product_name,
    category,
    sub_category,
    discount,
    discount_band,
    ROUND(sales, 2) AS sales,
    ROUND(profit, 2) AS profit,
    ROUND(profit_margin, 2) AS profit_margin,
    profit_status,
    region
FROM orders;

-- View 21: Loss Recovery Opportunity
CREATE VIEW loss_recovery AS
WITH loss_analysis AS (
    SELECT 
        category,
        sub_category,
        product_name,
        discount_band,
        COUNT(*) AS loss_orders,
        ROUND(SUM(profit), 2) AS total_loss,
        ROUND(SUM(sales), 2) AS revenue_at_risk,
        ROUND(AVG(discount), 2) AS avg_discount
    FROM orders
    WHERE profit_status = 'Loss'
    GROUP BY category, sub_category, product_name, discount_band
)
SELECT *,
    ROUND(ABS(total_loss), 2) AS potential_recovery,
    CASE 
        WHEN avg_discount >= 0.4 THEN 'Remove High Discount'
        WHEN avg_discount >= 0.2 THEN 'Reduce Discount'
        ELSE 'Review Pricing'
    END AS recommended_action
FROM loss_analysis
ORDER BY potential_recovery DESC;

-- View 22: Geographic Customer Distribution  
CREATE VIEW geographic_customers AS
SELECT 
    state,
    region,
    COUNT(DISTINCT customer_id) AS total_customers,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(AVG(profit_margin), 2) AS avg_margin,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(sales) / COUNT(DISTINCT customer_id), 2) AS revenue_per_customer
FROM orders
GROUP BY state, region;

-- View 23: Category Profit Trend by Year
CREATE VIEW category_profit_trend AS
SELECT 
    category,
    sub_category,
    order_year,
    ROUND(SUM(sales), 2) AS total_sales,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND(AVG(profit_margin), 2) AS avg_margin,
    COUNT(DISTINCT order_id) AS total_orders
FROM orders
GROUP BY category, sub_category, order_year
ORDER BY category, sub_category, order_year;