USE `BR_Ecom`;
-- 0. number of states and cities
SELECT COUNT(DISTINCT(customer_state)), COUNT(DISTINCT(customer_city))
FROM customers;

-- 1. State by total customers
SELECT 
    COUNT(customer_id) AS Customer_Number,
    customer_state
FROM
    customers
GROUP BY  customer_state
ORDER BY COUNT(customer_id) DESC ;
-- 2. City by total customers
SELECT 
    COUNT(customer_id) AS Customer_Number,
    customer_city
FROM
    customers
GROUP BY  customer_city
ORDER BY COUNT(customer_id) DESC;
	-- 2.1 City of most customers
    SELECT  
    COUNT(customer_id) AS customer_sum,
    customer_city
    FROM
    customers
    GROUP BY  customer_city
    ORDER BY COUNT(customer_id) DESC
    LIMIT 1;
-- 3. City total customers v.s. average number of customers in the state
SELECT 
	customer_city,
    count(customer_id) AS city_customer_sum,
    AVG(COUNT(customer_id)) OVER(PARTITION BY customer_state) AS state_customer_avg,
    customer_state
FROM customers
GROUP BY customer_city ,customer_state 
HAVING COUNT(customer_id)>1000 
ORDER BY city_customer_sum DESC;

-- 4. Order histroy range
SELECT MAX(order_purchase_timestamp), MIN(order_purchase_timestamp)
FROM orders; -- 2016/09/04 - 2018/10/17

-- 5. order 
	-- 5.0 totol oder number
    SELECT 
    COUNT(order_id),
    COUNT(distinct(order_id))
    from orders;
	SELECT 
    COUNT(order_id),
    COUNT(distinct(order_id))
    from order_items;
	-- 5.1 biggest order price
    SELECT SUM(price) AS order_price_max
    FROM order_items
    GROUP BY order_id
    ORDER BY SUM(price) DESC
    LIMIT 1;
    -- 5.2 average price 
    SELECT 
		   CAST(AVG(price) AS DECIMAL(16,2)) AS price_avg
    FROM order_items ;
	-- 5.2 lowest order price
    SELECT SUM(price) AS order_price_min
    FROM order_items
    GROUP BY order_id
    ORDER BY SUM(price)
    LIMIT 1;
    -- 5.3 order ranking by total payment
	SELECT
    o.order_id,
    sum(ot.price) AS total_payment,
    dense_rank()over(order by sum(ot.price) DESC)  AS total_pay_rank
    FROM
		 orders o
        JOIN order_items ot ON o.order_id = ot.order_id
	GROUP BY 1
    ORDER BY total_pay_rank;
-- 5.4 order_item
    SELECT 
    COUNT(order_id),
    COUNT(DISTINCT (order_id)),
    COUNT(DISTINCT (order_item_id)),
    COUNT(DISTINCT (product_id)),
    COUNT(DISTINCT (seller_id)),
    COUNT(DISTINCT (shipping_limit_date)),
    COUNT(DISTINCT (price)),
    COUNT(DISTINCT (freight_value))
FROM
    order_items;
-- 6. Product 
    -- 6.1total prodcut numbers
	SELECT 
    COUNT(product_id),
    COUNT(distinct(product_id))
    from products;
	SELECT 
    COUNT(product_id),
    COUNT(distinct(product_id)),
    COUNT(order_item_id),
    COUNT(distinct(order_item_id))
    from order_items;
    -- 6.2  highest & lowest pruchase amount (product)
    SELECT  CAST(max(price) AS DECIMAL(16,2)) AS price_max,
		    CAST(min(price) AS DECIMAL(16,2)) AS price_min
    FROM order_items;
    -- 6.3 avgrage pruachse amount (top 1000, 10000 products)
    SELECT CAST(AVG(price) AS DECIMAL(16,2)) AS top_1000_product_price_avg
    FROM(   SELECT price
			FROM order_items 
            GROUP BY price
            order by count(product_id) DESC
			limit 1000) AS TOP1000;
	SELECT CAST(AVG(price) AS DECIMAL(16,2)) AS top_10000_product_price_avg
    FROM(   SELECT price
			FROM order_items 
            GROUP BY price
            order by count(product_id) DESC
			limit 10000) AS TOP10000;
  -- 6.4 BEST selling single product (id) & category by sold_quantity
    SELECT ot.product_id,  pcn.product_category_name_english,count(ot.product_id) AS product_sold_times
    FROM order_items ot
    JOIN products p ON ot.product_id = p.product_id
    JOIN product_category_name  pcn ON p.product_category_name = pcn.product_category_name
    group by product_id,product_category_name_english
    ORDER BY count(product_id) DESC
    limit 1; 
  -- 6.5 Total sales of each product category
  SELECT 
    pcn.product_category_name_english AS prodcut_cate_eng,
    COUNT(ot.product_id) AS product_sale_sum
FROM
    order_items ot
        JOIN products p ON ot.product_id = p.product_id
        JOIN product_category_name pcn ON p.product_category_name = pcn.product_category_name
GROUP BY pcn.product_category_name_english
ORDER BY COUNT(ot.product_id) DESC;
  
  -- 6.6 best selling product category in each state
  SELECT 
   state,
   product_cate_eng,
   product_sale_sum
   from (
	SELECT
    c.customer_state AS state,
    pcn.product_category_name_english AS product_cate_eng,
    count(ot.product_id) AS product_sale_sum,
    row_number()over(partition by c.customer_state order by count(ot.product_id) DESC )  AS state_rank
    FROM
    order_items ot
		JOIN orders o ON o.order_id = ot.order_id
        JOIN customers c ON o.customer_id = c.customer_id
        JOIN products p ON ot.product_id = p.product_id
        JOIN product_category_name pcn ON p.product_category_name = pcn.product_category_name
	GROUP BY 1,2 ) ranks
WHERE state_rank = 1
ORDER BY product_sale_sum DESC;
 -- 6.7 BEST SELLING PRODUCT BY YEAR
 
 
 -- 6.8  set price comparison of bed_bath_table and furniture_decor
 SELECT pcn.product_category_name_english AS product_cate_eng,
		COUNT(p.product_id) AS product_num,
		CAST(AVG(price)AS DECIMAL (16,2)) AS avg_set_price,
		CAST(max(price)AS DECIMAL (16,2)) AS max_set_price,
	    CAST(min(price)AS DECIMAL (16,2)) AS min_set_price
FROM products p 
JOIN product_category_name pcn ON p.product_category_name = pcn.product_category_name
LEFT JOIN order_items ot ON p.product_id = ot.product_id
WHERE pcn.product_category_name_english IN ( "bed_bath_table", "furniture_decor")
GROUP BY pcn.product_category_name_english;


-- 7. SELLER
	-- 7.1 total numbers, average prodcust per seller, average orders per seller
    SELECT 
    COUNT(distinct(s.seller_id)) AS total_sellers,
    COUNT(DISTINCT(ot.product_id))/COUNT(distinct(s.seller_id))  AS product_quantity_per_seller,
    COUNT(DISTINCT(ot.order_id)) /COUNT(distinct(s.seller_id)) AS order_quantity_per_seller,
    COUNT(ot.order_item_id) /COUNT(distinct(s.seller_id)) AS item_quantity_per_seller
    FROM order_items ot
    LEFT JOIN sellers s on ot.seller_id = s.seller_id;
    -- 7.2 sellers mainly from which state? --SP
    SELECT * 
    FROM(
    SELECT
    seller_state,
    COUNT(seller_id),
    dense_rank() OVER(order by COUNT(seller_id)DESC) AS D_RANK
    from sellers
    GROUP BY 1)ranks 
    ORDER BY D_RANK;
	-- 7.2 sellers mainly from which citY in sp? 
    SELECT * 
    FROM(
    SELECT
    seller_city,
    COUNT(seller_id),
    dense_rank() OVER(order by COUNT(seller_id)DESC) AS D_RANK
    from sellers
    where seller_state = "SP"
    GROUP BY 1)ranks 
    ORDER BY D_RANK; -- sao paulo
  -- 7.4 which seller has made most revenue so far? (total payment)
