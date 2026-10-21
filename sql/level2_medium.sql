-- ===================================================================
-- LEVEL 2 - MEDIUM
-- Dialect: MySQL 8.0 | Schema: ecom
-- ===================================================================


-- -------------------------------------------------------------------
-- Requirement: Monthly completed revenue and profit for 2023
-- Business Context: Finance wants a month-by-month picture of 2023. The
--                   goal is to see which months carried the year and
--                   whether profit followed revenue or lagged behind it.
-- -------------------------------------------------------------------
SELECT DATE_FORMAT(date, '%Y-%m') AS month,
       SUM(revenue_usd) AS monthly_revenue,
       SUM(profit_usd) AS monthly_profit
FROM ecom.transactions
WHERE status = 'completed'
  AND date BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY month
ORDER BY month ASC;


-- -------------------------------------------------------------------
-- Requirement: Top 10 customers by lifetime completed revenue, with full
--              name, country and premium status
-- Business Context: These are the customers the business can least afford
--                   to lose. Knowing who they are, where they live and
--                   whether they are already premium shows who deserves
--                   personal outreach or a loyalty perk.
-- -------------------------------------------------------------------
SELECT c.customer_id,
       c.first_name,
       c.last_name,
       c.country,
       c.is_premium,
       SUM(t.revenue_usd) AS lifetime_revenue
FROM ecom.customers c
JOIN ecom.transactions t
  ON c.customer_id = t.customer_id
WHERE t.status = 'completed'
GROUP BY c.customer_id, c.first_name, c.last_name, c.country, c.is_premium
ORDER BY lifetime_revenue DESC
LIMIT 10;


-- -------------------------------------------------------------------
-- Requirement: Inactive products that still have stock, and the value of
--              that stock (stock units x unit cost)
-- Business Context: Products we no longer sell but still keep in the
--                   warehouse are cash sitting on a shelf. This puts a
--                   dollar value on them so the biggest ones can be
--                   cleared out first.
-- -------------------------------------------------------------------
SELECT p.name AS product_name,
       p.is_active,
       i.stock_units,
       p.unit_cost_usd,
       (i.stock_units * p.unit_cost_usd) AS tied_up_cost
FROM ecom.products p
JOIN ecom.inventory i
  ON p.product_id = i.product_id
WHERE p.is_active = 0
  AND i.stock_units > 0
ORDER BY tied_up_cost DESC;


-- -------------------------------------------------------------------
-- Requirement: Customers (first name, last name) with more than 3 completed
--              orders and more than 1,000 USD spent in total
-- Business Context: A quick way to find proven repeat buyers: people who
--                   came back several times and spent real money. This is
--                   the group a VIP or early-access offer should start with.
-- -------------------------------------------------------------------
SELECT c.customer_id,
       c.first_name,
       c.last_name,
       SUM(t.revenue_usd) AS total_spend,
       COUNT(t.transaction_id) AS total_transaction
FROM ecom.customers c
JOIN ecom.transactions t
  ON c.customer_id = t.customer_id
WHERE t.status = 'completed'
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING SUM(t.revenue_usd) > 1000
   AND COUNT(t.transaction_id) > 3;


-- -------------------------------------------------------------------
-- Requirement: Number every transaction of each customer by date
--              (oldest = 1)
-- Business Context: Gives each purchase an order number within its
--                   customer. It is not an answer on its own, but it is
--                   the building block for anything about first purchases,
--                   repeat buying or the time between orders.
-- -------------------------------------------------------------------
SELECT t.customer_id,
       t.date,
       t.transaction_id,
       ROW_NUMBER() OVER (PARTITION BY t.customer_id ORDER BY t.date ASC) AS rn
FROM ecom.transactions t;


-- -------------------------------------------------------------------
-- Requirement: First transaction of each customer
-- Business Context: Isolates the purchase that brought each customer in.
--                   It is the starting point for acquisition questions,
--                   such as which products or dates win new customers.
-- -------------------------------------------------------------------
WITH rankk_cte AS (
    SELECT t.customer_id,
           t.date,
           t.transaction_id,
           ROW_NUMBER() OVER (PARTITION BY t.customer_id ORDER BY t.date ASC) AS rn
    FROM ecom.transactions t
)
SELECT *
FROM rankk_cte
WHERE rn = 1;


-- -------------------------------------------------------------------
-- Requirement: Number of completed, refunded and cancelled transactions
--              per customer country
-- Business Context: Shows how orders end up in each country. A country
--                   with an unusually high share of refunds or
--                   cancellations may have a delivery or product problem
--                   worth looking into.
-- -------------------------------------------------------------------
SELECT c.country,
       COUNT(CASE WHEN t.status = 'completed' THEN 1 END) AS completed_transactions,
       COUNT(CASE WHEN t.status = 'refunded'  THEN 1 END) AS refunded_transactions,
       COUNT(CASE WHEN t.status = 'cancelled' THEN 1 END) AS cancelled_transactions
FROM ecom.transactions t
JOIN ecom.customers c
  ON t.customer_id = c.customer_id
GROUP BY c.country
ORDER BY c.country;