-- ===================================================================
-- LEVEL 3 - HARD
-- Dialect: MySQL 8.0 | Schema: ecom
-- ===================================================================


-- -------------------------------------------------------------------
-- Requirement: Top 3 products by total profit within each category
-- Business Context: Revenue can hide weak margins, so this ranks products
--                   by the profit they actually leave behind. It shows
--                   which products carry each category and where the
--                   business leans on just a few items.
-- -------------------------------------------------------------------
WITH product_profit AS (
    SELECT p.category,
           p.product_id,
           p.name AS product_name,
           SUM(t.profit_usd) AS total_profit,
           ROW_NUMBER() OVER (
               PARTITION BY p.category
               ORDER BY SUM(t.profit_usd) DESC
           ) AS profit_rank
    FROM ecom.transactions t
    JOIN ecom.products p
      ON t.product_id = p.product_id
    WHERE t.status = 'completed'
    GROUP BY p.category, p.product_id, p.name
)
SELECT category,
       product_name,
       total_profit,
       profit_rank
FROM product_profit
WHERE profit_rank <= 3
ORDER BY category, profit_rank;


-- -------------------------------------------------------------------
-- Requirement: Top 3 products by completed revenue within each category
-- Business Context: Same ranking as the profit one, but by revenue.
--                   Put the two lists side by side and the products that
--                   sell a lot without earning much stand out.
-- -------------------------------------------------------------------
WITH product_revenue AS (
    SELECT p.category,
           p.product_id,
           p.name AS product_name,
           SUM(t.revenue_usd) AS total_revenue,
           DENSE_RANK() OVER (
               PARTITION BY p.category
               ORDER BY SUM(t.revenue_usd) DESC
           ) AS rnk
    FROM ecom.transactions t
    JOIN ecom.products p
      ON t.product_id = p.product_id
    WHERE t.status = 'completed'
    GROUP BY p.category, p.product_id, p.name
)
SELECT category,
       product_name,
       total_revenue,
       rnk
FROM product_revenue
WHERE rnk <= 3
ORDER BY category, rnk;


-- -------------------------------------------------------------------
-- Requirement: Month-over-month revenue growth % (completed orders only)
-- Business Context: Month-to-month growth shows whether sales are really
--                   growing or just bouncing around. It is also the first
--                   place to look for seasonality, like a holiday peak or
--                   a slow stretch every year.
-- -------------------------------------------------------------------
WITH monthly AS (
    SELECT DATE_FORMAT(date, '%Y-%m') AS month,
           SUM(revenue_usd) AS revenue
    FROM ecom.transactions
    WHERE status = 'completed'
    GROUP BY DATE_FORMAT(date, '%Y-%m')
)
SELECT month,
       revenue,
       ROUND(LAG(revenue) OVER (ORDER BY month), 2) AS prev_month_revenue,
       ROUND((revenue - LAG(revenue) OVER (ORDER BY month)) * 100.0
             / LAG(revenue) OVER (ORDER BY month), 2) AS mom_growth_pct
FROM monthly
ORDER BY month;