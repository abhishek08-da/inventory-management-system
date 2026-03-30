-- 1  Total Suppliers
SELECT COUNT (*) AS total_suppliers FROM suppliers;

-- 2 Total Products
SELECT COUNT (*) AS total_products FROM products;

-- 3 Total categories dealing
SELECT COUNT(DISTINCT category) AS total_categories FROM products;

-- 4 Total sales value (quantity* price)
SELECT COALESCE(ROUND(SUM(ABS(se.change_quantity) * p.price), 2), 0)
FROM stock_entries se
JOIN products p ON se.product_id = p.product_id
WHERE se.change_type = 'Sale';

-- 5 Total restock value made in last 3 months (quantity* price)
SELECT COALESCE(ROUND(SUM(se.change_quantity * p.price), 2), 0)
FROM stock_entries se
JOIN products p ON se.product_id = p.product_id
WHERE se.change_type = 'Restock';


-- 6 Below reorder and no pending reorder
SELECT COUNT (*) FROM products p
LEFT JOIN reorders r
ON r.product_id = p.product_id
AND r.status = 'Pending'
WHERE p.stock_quantity < p.reorder_level
AND r.product_id IS NULL;

         -- OR --

SELECT COUNT(*) AS below_reorder
FROM products p
WHERE p.stock_quantity < p.reorder_level
AND p.product_id NOT IN (
SELECT DISTINCT product_id FROM reorders WHERE status = 'Pending')



-- 7 Suppliers and their  contact details
select supplier_name, contact_name , email, phone from suppliers


-- 8 Product with their suppliers and current stock
select p.product_name,s.supplier_name , p.stock_quantity, p.reorder_level
from products as p 
join suppliers  s on
p.supplier_id = s.supplier_id
order by p.product_name ASC


-- 9 Product needing reorder
select product_id ,product_name, stock_quantity, reorder_level
from products
where stock_quantity<reorder_level


-- 10 Place an reorder
insert into reorders(reorder_id , product_id , reorder_quantity, reorder_date ,status)
select max(reorder_id)+1,  101, 200, curdate(), "ordered" from reorders