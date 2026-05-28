-- raw.allegro_orders
CREATE TABLE raw.allegro_orders (
    order_id TEXT,
    seller_login TEXT,
    order_date TIMESTAMP,
	status TEXT,
	buyer_id TEXT,
    buyer_name TEXT,
    buyer_phone TEXT,
    buyer_city TEXT,
  	delivery_address_name TEXT,
  	delivery_address_phone TEXT,
    delivery_address_city TEXT,
    delivery_amount NUMERIC(10,2),
    total_to_pay NUMERIC(10,2),
    buyer_notes TEXT,
  	seller_notes TEXT,
    marketplace TEXT
);

-- raw.allegro_order_items
CREATE TABLE raw.allegro_order_items (
    order_id TEXT,
    offer_id TEXT,
    offer_external_id TEXT,
    product_name TEXT,
    quantity INT,
    price NUMERIC(10,2),
	seller_login TEXT
);

-- raw.website_orders
CREATE TABLE raw.website_orders (
    order_id TEXT,
    order_status TEXT,
    order_date TIMESTAMP,
    seller_login TEXT,
    buyer_name TEXT,
    buyer_email TEXT,
    buyer_phone TEXT,
    buyer_notes TEXT,
    seller_notes TEXT,
    buyer_city TEXT,
    product_id TEXT,
    product_name TEXT,
    quantity INTEGER,
    unit_price NUMERIC(10,2),
    coupon_code TEXT,
    discount_amount NUMERIC(10,2),
    delivery_amount NUMERIC(10,2),
    total_amount NUMERIC(10,2)
);

-- raw.empik_orders
CREATE TABLE raw.empik_orders (
    order_id TEXT,
    order_status TEXT,
    order_date TIMESTAMP,
    seller_login TEXT,
    buyer_name TEXT,
    buyer_email TEXT,
    buyer_phone TEXT,
    buyer_city TEXT,
    product_id TEXT,
    product_name TEXT,
    quantity INTEGER,
    unit_price NUMERIC(10,2),
    delivery_amount NUMERIC(10,2),
    line_total NUMERIC(10,2)
);

-- raw.gmail_allegro_orders
CREATE TABLE raw.gmail_allegro_orders (
    order_date TIMESTAMP,
    order_id TEXT,
    seller_login TEXT,
    product_name TEXT,
    product_id TEXT,
    quantity INTEGER,
    line_total NUMERIC(10,2),
    marketplace TEXT,
    buyer_name TEXT,
    buyer_city TEXT,
    buyer_phone TEXT
);

-- allegro_orders_clean
DROP TABLE IF EXISTS staging.allegro_orders_clean;
CREATE TABLE staging.allegro_orders_clean AS
SELECT DISTINCT
    order_id,
    buyer_id AS customer_id,
    CAST(order_date AS TIMESTAMP) AS order_date,
    TRIM(buyer_name) AS buyer_name,
    REGEXP_REPLACE(
        buyer_phone,'[^0-9]','','g'
    ) AS buyer_phone,
    TRIM(buyer_city) AS buyer_city,
    CAST(total_to_pay AS NUMERIC(10,2))
        AS line_total,
	CAST(delivery_amount AS NUMERIC(10,2))
        AS delivery_amount,
    buyer_notes,
    seller_notes,
    seller_login,
    marketplace,
    status,
    'allegro' AS source
FROM raw.allegro_orders
WHERE status != 'CANCELLED';

-- allegro_order_items_clean
DROP TABLE IF EXISTS staging.allegro_order_items_clean;
CREATE TABLE staging.allegro_order_items_clean AS
SELECT DISTINCT
    oi.order_id,
    oi.offer_id AS product_id,
    oi.offer_external_id AS external_product_id,
    product_name,
    CAST(oi.quantity AS INTEGER)
        AS quantity,
    CAST(oi.price AS NUMERIC(10,2))
        AS unit_price,
    CAST(oi.quantity AS INTEGER)
        * CAST(price AS NUMERIC(10,2))
        AS line_total,
    oi.seller_login,
    'allegro' AS source
FROM raw.allegro_order_items oi 
JOIN raw.allegro_orders o on oi.order_id = o.order_id
WHERE offer_id IS NOT NULL
AND status != 'CANCELLED';

-- gmail_orders_clean
DROP TABLE IF EXISTS staging.gmail_orders_clean;
CREATE TABLE staging.gmail_orders_clean AS
SELECT
    order_id,
    MAX(buyer_phone) AS customer_id,
    MAX(CAST(order_date AS TIMESTAMP))
        AS order_date,
    MAX(buyer_name)
        AS buyer_name,
    MAX(
        REGEXP_REPLACE(
            buyer_phone,'[^0-9]','','g'
        )
    ) AS buyer_phone,
    MAX(buyer_city) AS buyer_city,
    SUM(
        CAST(line_total AS NUMERIC(10,2))
    ) AS line_total,
    0::NUMERIC(10,2) AS delivery_amount,
    MAX(seller_login) AS seller_login,
    MAX(marketplace) AS marketplace,
    'COMPLETED' AS status,
    'gmail_allegro' AS source
FROM raw.gmail_allegro_orders
GROUP BY order_id;

-- gmail_order_items_clean
DROP TABLE IF EXISTS staging.gmail_order_items_clean;
CREATE TABLE staging.gmail_order_items_clean AS
SELECT
    order_id,
    product_id,
    NULL AS external_product_id,
    product_name,
    CAST(quantity AS INTEGER)
        AS quantity,
    CAST(line_total AS NUMERIC(10,2))
        / NULLIF(
            CAST(quantity AS NUMERIC(10,2)),
            0
        ) AS unit_price,
    CAST(line_total AS NUMERIC(10,2))
        AS line_total,
    seller_login,
    'gmail_allegro' AS source
FROM raw.gmail_allegro_orders;

-- website_orders_clean
DROP TABLE IF EXISTS staging.website_orders_clean;
CREATE TABLE staging.website_orders_clean AS
SELECT DISTINCT
    order_id,
    REGEXP_REPLACE(buyer_phone,'[^0-9]','','g')
	AS customer_id,
    CAST(order_date AS TIMESTAMP) AS order_date,
    TRIM(buyer_name) AS buyer_name,
    REGEXP_REPLACE(buyer_phone,'[^0-9]','','g'
    ) AS buyer_phone,
    TRIM(buyer_city) AS buyer_city,
    CAST(delivery_amount AS NUMERIC(10,2))
        AS delivery_amount,
    CAST(total_amount AS NUMERIC(10,2))
        AS line_total,
    buyer_notes,
    seller_notes,
    seller_login,
    order_status AS status,
    coupon_code,
    'website' AS marketplace,
    'website' AS source
FROM raw.website_orders
WHERE order_status != 'Не доставлен';

-- website_order_items_clean
DROP TABLE IF EXISTS staging.website_order_items_clean;
CREATE TABLE staging.website_order_items_clean AS
SELECT DISTINCT
    order_id,
    product_id,
    NULL AS external_product_id,
    product_name,
    CAST(quantity AS INTEGER)
        AS quantity,

    CAST(unit_price AS NUMERIC(10,2))
        AS unit_price,

    CAST(quantity AS INTEGER)
        * CAST(unit_price AS NUMERIC(10,2))
        AS line_total,
    seller_login,
    'website' AS source
FROM raw.website_orders
WHERE order_status != 'Не доставлен'
    AND LOWER(product_name) NOT LIKE '%картк%'
    AND LOWER(product_name) NOT LIKE '%листів%'
    AND LOWER(product_name) NOT LIKE '%открытк%'
    AND LOWER(product_name) NOT LIKE '%bilecik%';


-- empik_orders_clean
DROP TABLE IF EXISTS staging.empik_orders_clean;
CREATE TABLE staging.empik_orders_clean AS
SELECT DISTINCT
    order_id,
    REGEXP_REPLACE(buyer_phone,'[^0-9]','','g')
	AS customer_id,
    CAST(order_date AS TIMESTAMP) AS order_date,
    TRIM(buyer_name) AS buyer_name,
    REGEXP_REPLACE(buyer_phone,'[^0-9]','','g'
    ) AS buyer_phone,
    TRIM(buyer_city) AS buyer_city,
    CAST(delivery_amount AS NUMERIC(10,2))
        AS delivery_amount,
    CAST(line_total AS NUMERIC(10,2))
        AS line_total,
    null as buyer_notes,
    null as seller_notes,
    seller_login,
    order_status AS status,
    'empik' AS marketplace,
    'empik' AS source
FROM raw.empik_orders
WHERE order_status != 'Odrzucono'
AND order_status != 'Nie obciążono'
AND order_status != 'Anulowano';

-- empik_order_items_clean
DROP TABLE IF EXISTS staging.empik_order_items_clean;
CREATE TABLE staging.empik_order_items_clean AS
SELECT DISTINCT
    order_id,
    product_id,
    NULL AS external_product_id,
    product_name,
    CAST(quantity AS INTEGER) AS quantity,
    CAST(unit_price AS NUMERIC(10,2)) AS unit_price,
    CAST(quantity AS INTEGER)
        * CAST(unit_price AS NUMERIC(10,2))
        AS line_total,
    seller_login,
    'empik' AS source
FROM raw.empik_orders
WHERE order_status != 'Odrzucono'
AND order_status != 'Nie obciążono'
AND order_status != 'Anulowano';

-- analytics.orders
DROP TABLE IF EXISTS analytics.orders;
CREATE TABLE analytics.orders AS
SELECT
    order_id,
    customer_id,
    order_date,
    line_total,
    delivery_amount,
    seller_login,
    marketplace,
    status,
    'allegro' AS source
FROM staging.allegro_orders_clean
UNION ALL
SELECT
    order_id,
    customer_id,
    order_date,
    line_total,
    delivery_amount,
    seller_login,
    marketplace,
    status,
    'gmail_allegro' AS source
FROM staging.gmail_orders_clean
UNION ALL
SELECT
    order_id,
    customer_id,
    order_date,
    line_total,
    delivery_amount,
    seller_login,
    marketplace,
    status,
    'website' AS source
FROM staging.website_orders_clean
UNION ALL
SELECT
    order_id,
    customer_id,
    order_date,
    line_total,
    delivery_amount,
    seller_login,
    marketplace,
    status,
    'empik' AS source
FROM staging.empik_orders_clean;

-- analytics.customers
DROP TABLE IF EXISTS analytics.customers;
CREATE TABLE analytics.customers AS
WITH all_customers AS (
    -- ALLEGRO ORDERS
    SELECT
        customer_id,
        buyer_name AS customer_name,
        buyer_phone AS customer_phone,
        buyer_city AS customer_city,
        'allegro' AS source
    FROM staging.allegro_orders_clean
    UNION ALL
    -- GMAIL ALLEGRO
    SELECT
        customer_id,
        buyer_name AS customer_name,
        buyer_phone AS customer_phone,
        buyer_city AS customer_city,
        'gmail_allegro' AS source
    FROM staging.gmail_orders_clean
    UNION ALL
    -- WEBSITE
    SELECT
        customer_id,
        buyer_name AS customer_name,
        buyer_phone AS customer_phone,
        buyer_city AS customer_city,
        'website' AS source
    FROM staging.website_orders_clean
	UNION ALL
    -- EMPIK
    SELECT
        customer_id,
        buyer_name AS customer_name,
        buyer_phone AS customer_phone,
        buyer_city AS customer_city,
        'empik' AS source
    FROM staging.empik_orders_clean
)
SELECT
    customer_id,
    MAX(customer_name) AS customer_name,
    MAX(customer_phone) AS customer_phone,
    MAX(customer_city) AS customer_city,
    COUNT(DISTINCT source) AS sources_count
FROM all_customers
WHERE customer_id IS NOT NULL
GROUP BY customer_id;

--analytics.order_items
DROP TABLE IF EXISTS analytics.order_items;
CREATE TABLE analytics.order_items AS
SELECT
    order_id,
    product_id,
    quantity,
    unit_price,
    line_total,
    seller_login,
    'allegro' AS source
FROM staging.allegro_order_items_clean
UNION ALL
SELECT
    order_id,
    product_id,
    quantity,
    unit_price,
    line_total,
    seller_login,
    'website' AS source
FROM staging.website_order_items_clean
UNION ALL
SELECT
    order_id,
    product_id,
    quantity,
    unit_price,
    line_total,
    seller_login,
    'empik' AS source
FROM staging.empik_order_items_clean;

--analytics.products
DROP TABLE IF EXISTS analytics.products;
CREATE TABLE analytics.products AS
WITH all_products AS (
    SELECT
        product_id,
        external_product_id,
        product_name,
        seller_login,
        unit_price,
        'allegro' AS source
    FROM staging.allegro_order_items_clean
    UNION ALL
    SELECT
        product_id,
        external_product_id,
        product_name,
        seller_login,
        unit_price,
        'website' AS source
    FROM staging.website_order_items_clean
	UNION ALL
    SELECT
        product_id,
        external_product_id,
        product_name,
        seller_login,
        unit_price,
        'empik' AS source
    FROM staging.empik_order_items_clean
)
SELECT DISTINCT ON (product_id)
    product_id,
    external_product_id,
    product_name,
    seller_login
FROM all_products
ORDER BY product_id, unit_price DESC;

-- analytics.fact_orders;
DROP TABLE IF EXISTS analytics.fact_orders;
CREATE TABLE analytics.fact_orders AS
SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    o.line_total,
    o.delivery_amount,
    o.marketplace,
    o.source,
    c.customer_name,
    c.customer_city
FROM analytics.orders o
LEFT JOIN analytics.customers c
    ON o.customer_id = c.customer_id;

-- FOREIGN KEY: orders -> customers
ALTER TABLE analytics.orders
ADD CONSTRAINT fk_orders_customers
FOREIGN KEY (customer_id)
REFERENCES analytics.customers(customer_id);

-- FOREIGN KEY: order_items -> orders
ALTER TABLE analytics.order_items
ADD CONSTRAINT fk_order_items_orders
FOREIGN KEY (order_id)
REFERENCES analytics.orders(order_id);

-- FOREIGN KEY: order_items -> products
ALTER TABLE analytics.order_items
ADD CONSTRAINT fk_order_items_products
FOREIGN KEY (product_id)
REFERENCES analytics.products(product_id);

