CREATE SCHEMA dannys_dinner;
SET search_path = dannys_diner;

USE dannys_dinner;

CREATE TABLE dannys_dinner.sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO dannys_dinner.sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', 1),
  ('A', '2021-01-01', 2),
  ('A', '2021-01-07', 2),
  ('A', '2021-01-10', 3),
  ('A', '2021-01-11', 3),
  ('A', '2021-01-11', 3),
  ('B', '2021-01-01', 2),
  ('B', '2021-01-02', 2),
  ('B', '2021-01-04', 1),
  ('B', '2021-01-11', 1),
  ('B', '2021-01-16', 3),
  ('B', '2021-02-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-01', 3),
  ('C', '2021-01-07', 3);

CREATE TABLE dannys_dinner.menu (
	product_id INTEGER,
    product_name VARCHAR(5),
    price INTEGER
);

INSERT INTO dannys_dinner.menu
	(product_id, product_name, price)
VALUES
	(1, 'sushi', 10),
    (2, 'curry', 15),
    (3, 'ramen', 12);

CREATE TABLE dannys_dinner.members (
	customer_id VARCHAR(1),
    join_date DATE
);

INSERT INTO dannys_dinner.members
	(customer_id, join_date)
VALUES
	('A', '2021-01-07'),
    ('B', '2021-01-09');

## 1- What is the total amount each customer spent at the restaurant?
SELECT s.customer_id, SUM(m.price)
FROM menu m
JOIN sales s
ON m.product_id = s.product_id
GROUP BY s.customer_id;

## 2- How many days has each customer visited the restaurant?
SELECT s.customer_id, COUNT(DISTINCT(s.order_date))
FROM sales s
GROUP BY s.customer_id;

## 3- What was the first item from the menu purchased by each customer?
WITH rank_query AS
(
SELECT s.customer_id, m.product_name, s.order_date, DENSE_RANK()
OVER (PARTITION BY s.customer_id ORDER BY s.order_date ASC)
AS 'rank_col'
FROM menu m
JOIN sales s
ON m.product_id = s.product_id
GROUP BY s.customer_id, m.product_name, s.order_date
)
SELECT customer_id, order_date, product_name
FROM rank_query
WHERE rank_col = 1;

## 4- What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name, COUNT(s.product_id) AS number_of_times
FROM menu m
JOIN sales s
ON s.product_id = m.product_id
GROUP BY m.product_name
ORDER BY COUNT(s.product_id) DESC
LIMIT 1;

## 5- Which item was the most popular one for each customer?
WITH rank_query AS
(
SELECT s.customer_id, m.product_name, COUNT(s.product_id) AS number_of_times, DENSE_RANK()
OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC)
AS 'rank_col'
FROM menu m
JOIN sales s
ON m.product_id = s.product_id
GROUP BY s.customer_id, m.product_name
)
SELECT customer_id, product_name, number_of_times
FROM rank_query
WHERE rank_col = 1;

## 6- Which item was purchased first by the customer after they became a member?
WITH rank_query AS
(
SELECT s.customer_id, m.product_name, s.order_date, DENSE_RANK()
OVER (PARTITION BY s.customer_id ORDER BY s.order_date ASC)
AS 'rank_col'
FROM menu m
JOIN sales s
ON m.product_id = s.product_id
JOIN members me
ON s.customer_id = me.customer_id
WHERE s.order_date > me.join_date
)
SELECT customer_id, product_name, order_date
FROM rank_query
WHERE rank_col = 1;

## 7 - Which item was purchased just before the customer became a member?
WITH rank_query AS
(
SELECT s.customer_id, m.product_name, s.order_date, DENSE_RANK()
OVER (PARTITION BY s.customer_id ORDER BY s.order_date ASC)
AS 'rank_col'
FROM menu m
JOIN sales s
ON m.product_id = s.product_id
JOIN members me
ON s.customer_id = me.customer_id
WHERE s.order_date < me.join_date
)
SELECT customer_id, product_name, order_date
FROM rank_query
WHERE rank_col = 1;

## 8 - What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id, COUNT(s.product_id) AS 'total_items', SUM(m.price) AS 'amount_spent'
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
JOIN members me
ON s.customer_id = me.customer_id
WHERE s.order_date < me.join_date
GROUP BY s.customer_id
ORDER BY customer_id;

## 9 - If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT s.customer_id,
	SUM(CASE 
		WHEN (m.product_name = 'sushi') THEN m.price * 10 * 2
		ELSE m.price * 10
        END) AS 'points'
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY customer_id;

## 10 - In the first week a customer joins the program (including their join date) they earn 2x points on all items, not just sushi
## - how many points do customer A and B have at the end of January?

