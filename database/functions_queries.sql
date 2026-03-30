-- adding new product
CREATE OR REPLACE FUNCTION add_new_product(
    p_name VARCHAR,
    p_category VARCHAR,
    p_price NUMERIC,
    p_stock INT,
    p_reorder INT,
    p_supplier INT
)
RETURNS VOID AS
$$
DECLARE
    new_prod_id INT;
    new_shipment_id INT;
    new_entry_id INT;
BEGIN

    -- generate product id
    SELECT COALESCE(MAX(product_id),0) + 1 INTO new_prod_id FROM products;

    INSERT INTO products(
        product_id, product_name, category, price, stock_quantity, reorder_level, supplier_id
    )
    VALUES(
        new_prod_id, p_name, p_category, p_price, p_stock, p_reorder, p_supplier
    );

    -- shipment
    SELECT COALESCE(MAX(shipment_id),0) + 1 INTO new_shipment_id FROM shipment;

    INSERT INTO shipment(
        shipment_id, product_id, supplier_id, quantity_received, shipment_date
    )
    VALUES(
        new_shipment_id, new_prod_id, p_supplier, p_stock, CURRENT_DATE
    );

    -- stock entry
    SELECT COALESCE(MAX(entry_id),0) + 1 INTO new_entry_id FROM stock_entries;

    INSERT INTO stock_entries(
        entry_id, product_id, change_quantity, change_type, entry_date
    )
    VALUES(
        new_entry_id, new_prod_id, p_stock, 'Restock', CURRENT_DATE
    );

END;
$$ LANGUAGE plpgsql;



--  Product History, [ finding shipment , sales , purchase]
CREATE OR REPLACE VIEW product_inventory_history AS
SELECT 
    pih.product_id,
    pih.record_type,
    pih.record_date,
    pih.quantity,
    pih.change_type,
    pr.supplier_id
FROM 
(
    -- Shipment records
    SELECT 
        product_id,
        'Shipment' AS record_type,
        shipment_date AS record_date,
        quantity_received AS quantity,
        NULL AS change_type
    FROM shipment

    UNION ALL

    -- Stock entries
    SELECT 
        product_id,
        'Stock Entry' AS record_type,
        entry_date AS record_date,
        change_quantity AS quantity,
        change_type
    FROM stock_entries

) AS pih
JOIN products pr 
ON pr.product_id = pih.product_id;



--  receive reorder
CREATE OR REPLACE FUNCTION mark_reorder_as_received(in_reorder_id INT)
RETURNS VOID AS
$$
DECLARE
    prod_id INT;
    qty INT;
    sup_id INT;
    new_shipment_id INT;
    new_entry_id INT;
BEGIN

    -- get product_id and quantity
    SELECT product_id, reorder_quantity
    INTO prod_id, qty
    FROM reorders
    WHERE reorder_id = in_reorder_id;

    -- get supplier_id
    SELECT supplier_id
    INTO sup_id
    FROM products
    WHERE product_id = prod_id;

    -- update reorder status
    UPDATE reorders
    SET status = 'Received'
    WHERE reorder_id = in_reorder_id;

    -- update stock
    UPDATE products
    SET stock_quantity = stock_quantity + qty
    WHERE product_id = prod_id;

    -- generate shipment_id manually (same as your logic)
    SELECT COALESCE(MAX(shipment_id), 0) + 1
    INTO new_shipment_id
    FROM shipment;

    INSERT INTO shipment (
        shipment_id,
        product_id,
        supplier_id,
        quantity_received,
        shipment_date
    )
    VALUES (
        new_shipment_id,
        prod_id,
        sup_id,
        qty,
        CURRENT_DATE
    );

    -- generate entry_id manually
    SELECT COALESCE(MAX(entry_id), 0) + 1
    INTO new_entry_id
    FROM stock_entries;

    INSERT INTO stock_entries (
        entry_id,
        product_id,
        change_quantity,
        change_type,
        entry_date
    )
    VALUES (
        new_entry_id,
        prod_id,
        qty,
        'Restock',
        CURRENT_DATE
    );

END;
$$ LANGUAGE plpgsql;

