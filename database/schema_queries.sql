CREATE TABLE suppliers (
    supplier_id SERIAL PRIMARY KEY,
    supplier_name VARCHAR(100) NOT NULL,
    contact_name VARCHAR(100),
    email VARCHAR(100),
    phone VARCHAR(20),
    address TEXT
);
ALTER TABLE suppliers
ALTER COLUMN phone TYPE VARCHAR(50);


CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50),
    price NUMERIC(10,2) NOT NULL,
    stock_quantity INT DEFAULT 0,
    reorder_level INT NOT NULL,
    supplier_id INT,
    CONSTRAINT fk_supplier
        FOREIGN KEY (supplier_id)
        REFERENCES suppliers(supplier_id)
        ON DELETE SET NULL
);


CREATE TABLE shipment (
    shipment_id SERIAL PRIMARY KEY,
    product_id INT NOT NULL,
    supplier_id INT NOT NULL,
    quantity_received INT NOT NULL,
    shipment_date DATE DEFAULT CURRENT_DATE,

    CONSTRAINT fk_shipment_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id),

    CONSTRAINT fk_shipment_supplier
        FOREIGN KEY (supplier_id)
        REFERENCES suppliers(supplier_id)
);


CREATE TABLE stock_entries (
    entry_id SERIAL PRIMARY KEY,
    product_id INT NOT NULL,
    change_quantity INT NOT NULL,
    change_type VARCHAR(10) NOT NULL,
    entry_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_stock_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
);


CREATE TABLE reorders (
    reorder_id SERIAL PRIMARY KEY,
    product_id INT NOT NULL,
    reorder_quantity INT NOT NULL,
    reorder_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'PENDING',

    CONSTRAINT fk_reorder_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
);