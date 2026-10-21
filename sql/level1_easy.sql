-- ===================================================================
-- LEVEL 1 - EASY
-- Dialect: MySQL 8.0 | Schema: ecom
-- ===================================================================


-- -------------------------------------------------------------------
-- Requirement: Premium vs non-premium customers: headcount and average age
-- Business Context: Understand the size and age profile of the premium
--                   customer base to evaluate the loyalty program
-- -------------------------------------------------------------------
SELECT COUNT(*) AS total_client,
       is_premium,
       AVG(age) AS average_age
FROM ecom.customers
GROUP BY is_premium;


-- -------------------------------------------------------------------
-- Requirement: Top 5 countries by number of customers
-- Business Context: Identify the main markets
-- -------------------------------------------------------------------
SELECT country,
       COUNT(*) AS customers_num
FROM ecom.customers
GROUP BY country
ORDER BY customers_num DESC
LIMIT 5;


-- -------------------------------------------------------------------
-- Requirement: Number of products, average unit price and average unit
--              cost for each category
-- Business Context: Compare pricing and cost structure across categories
--                   as a first look at where margins are likely higher
-- -------------------------------------------------------------------
SELECT category,
       COUNT(*) AS product_num,
       AVG(unit_price_usd) AS average_price,
       AVG(unit_cost_usd) AS average_cost
FROM ecom.products
GROUP BY category;


-- -------------------------------------------------------------------
-- Requirement: Rank payment methods by completed revenue
-- Business Context: Identify which payment methods drive the most revenue
--                   to prioritize payment partnerships and checkout
--                   optimization
-- -------------------------------------------------------------------
SELECT payment_method,
       COUNT(*) AS total_transactions,
       SUM(revenue_usd) AS total_revenue
FROM ecom.transactions
WHERE status = 'completed'
GROUP BY payment_method
ORDER BY total_revenue DESC;


-- -------------------------------------------------------------------
-- Requirement: Number of transactions with a discount above 20% and
--              their average discount
-- Business Context: Measure how often deep discounts are used, to assess
--                   the pressure they put on margins
-- -------------------------------------------------------------------
SELECT COUNT(*) AS total_transaction,
       ROUND(AVG(discount_pct), 2) AS avg_discount
FROM ecom.transactions
WHERE discount_pct > 0.20;


-- -------------------------------------------------------------------
-- Requirement: Number of returns and total refund amount for each
--              return reason
-- Business Context: Understand why customers return products and what
--                   each reason costs, to prioritize fixes in product
--                   quality, listing accuracy and delivery
-- ---------------------------------------------------------------------
SELECT reason,
       COUNT(*) AS num_returns,
       ROUND(SUM(refund_amount_usd), 2) AS total_refund_amount
FROM ecom.returns
GROUP BY reason
ORDER BY total_refund_amount DESC;