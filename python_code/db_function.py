import pandas as pd
import numpy as np
import psycopg2

def connect_to_db():
    return psycopg2.connect(
        host="localhost",
        user="postgres",
        password="ZxcvbnM012$",
        database="inventory_management")

def get_basic_info(cursor):
    queries = {
         "Total Suppliers": "SELECT COUNT(*) AS count FROM suppliers",

        "Total Products": "SELECT COUNT(*) AS count FROM products",

        "Total Categories Dealing": "SELECT COUNT(DISTINCT category) AS count FROM products",

        "Total Sale Value": """
            SELECT COALESCE(ROUND(SUM(ABS(se.change_quantity) * p.price), 2), 0)
            FROM stock_entries se
            JOIN products p ON se.product_id = p.product_id
            WHERE se.change_type = 'Sale';
        """,

        "Total Restock Value": """
            SELECT COALESCE(ROUND(SUM(se.change_quantity * p.price), 2), 0)
            FROM stock_entries se
            JOIN products p ON se.product_id = p.product_id
            WHERE se.change_type = 'Restock';
        """,

        "Below Reorder & No Pending Reorders": """
            SELECT COUNT(*) AS below_reorder
            FROM products p
            WHERE p.stock_quantity < p.reorder_level
              AND p.product_id NOT IN (
                  SELECT DISTINCT product_id FROM reorders WHERE status = 'Pending')
        """
    }

    result = {}
    for label, query in queries.items():
        cursor.execute(query)
        row = cursor.fetchone()

        if row:
            value = next(iter(row.values()))
            result[label] = value if value is not None else 0
        else:
            result[label] = 0

    return result


def get_additonal_tables(cursor):
    queries = {
        "Suppliers Contact Details": "SELECT supplier_name, contact_name, email, phone FROM suppliers",

        "Products with Supplier and Stock": """
            SELECT 
                p.product_name,
                s.supplier_name,
                p.stock_quantity,
                p.reorder_level
            FROM products p
            JOIN suppliers s ON p.supplier_id = s.supplier_id
            ORDER BY p.product_name ASC
        """,

        "Products Needing Reorder": """
            SELECT product_name, stock_quantity, reorder_level
            FROM products
            WHERE stock_quantity <= reorder_level
        """
    }

    tables = {}
    for label, query in queries.items():
        cursor.execute(query)
        tables[label] = cursor.fetchall()

    return tables

def get_categories(cursor):
    cursor.execute("select Distinct category  from products  order by category  asc")
    rows= cursor.fetchall()
    return [row["category"] for row in rows]

def get_suppliers(cursor):
    cursor.execute("select supplier_id , supplier_name from suppliers order by  supplier_name asc")
    return cursor.fetchall()

def add_new_product(cursor, db, p_name, p_category, p_price, p_stock, p_reorder, p_supplier):
    query = "SELECT add_new_product(%s, %s, %s, %s, %s, %s)"
    params = (p_name, p_category, p_price, p_stock, p_reorder, p_supplier)

    cursor.execute(query, params)
    db.commit()

def get_all_products(cursor):
    cursor.execute("select product_id, product_name from products order by  product_name")
    return cursor.fetchall()

def get_product_history(cursor, product_id):
    query ="select * from product_inventory_history where product_id= %s order by record_date Desc"
    cursor.execute(query , (product_id,))
    return cursor.fetchall()

def place_reorder(cursor, db, product_id , reorder_quantity):
    query= """
         INSERT INTO reorders (
            reorder_id,
            product_id,
            reorder_quantity,
            reorder_date,
            status
        )
        SELECT 
            COALESCE(MAX(reorder_id), 0) + 1,
            %s,
            %s,
            CURRENT_DATE,
            'Ordered'
        FROM reorders;
         """
    cursor.execute(query,(product_id, reorder_quantity))
    db.commit()

def get_pending_reorders(cursor):
    cursor.execute("""
    select r.reorder_id , p.product_name
    from reorders as r join products as p 
    on r.product_id= p.product_id
    """)
    return cursor.fetchall()

def mark_reorder_received(cursor, db, reorder_id):
    cursor.callproc("mark_reorder_as_received",[reorder_id])
    db.commit()