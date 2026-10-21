-- ===================================================================
-- LEVEL 4 - EXPERT
-- Dialect: MySQL 8.0 | Schema: ecom
-- ===================================================================


-- -------------------------------------------------------------------
-- Requirement: Stockout risk: days of stock cover vs supplier lead time
-- Assumptions: Demand = average monthly units over the last 6 months of
--              data (Jul-Dec 2024), excluding cancelled orders. Active
--              products only.
-- Business Context: Purchasing needs to know which products will run out
--                   before the next delivery can arrive. Cover is the
--                   current stock divided by recent daily sales, compared
--                   with the supplier's lead time. The products at the
--                   top of the list are the ones to reorder first.
-- -------------------------------------------------------------------
WITH demand AS (
    SELECT product_id,
           SUM(quantity) / 6.0 AS avg_monthly_units
    FROM ecom.transactions
    WHERE status <> 'cancelled'
      AND date >= '2024-07-01' AND date <= '2024-12-31'
    GROUP BY product_id
)
SELECT p.product_id,
       p.name,
       p.category,
       i.stock_units,
       i.reorder_point,
       i.supplier_lead_days,
       ROUND(d.avg_monthly_units, 1)                          AS avg_monthly_units,
       ROUND(i.stock_units / (d.avg_monthly_units / 30.0), 1) AS days_of_cover,
       ROUND(i.supplier_lead_days - i.stock_units / (d.avg_monthly_units / 30.0), 1) AS shortfall_days
FROM ecom.products p
JOIN ecom.inventory i ON i.product_id = p.product_id
JOIN demand d         ON d.product_id = p.product_id
WHERE p.is_active = 1
  AND i.stock_units / (d.avg_monthly_units / 30.0) < i.supplier_lead_days
ORDER BY shortfall_days DESC;