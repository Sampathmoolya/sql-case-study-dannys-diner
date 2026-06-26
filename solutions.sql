
 -- Case Study Questions And Solutions.
 
 -- 1. What is the total amount each customer spent at the restaurant?
 SELECT 
 s.customer_id, SUM(me.price) as total_amount
 FROM sales s
 JOIN menu me
 ON s.product_id = me.product_id
 GROUP BY s.customer_id
 ORDER BY s.customer_id

 --2. How many days has each customer visited the restaurant?
 SELECT
 customer_id, COUNT(DISTINCT order_date) as days_visited
 FROM sales
 GROUP BY customer_id

 --3. What was the first item from the menu purchased by each customer?
 WITH CTE1 AS(
SELECT
 s.customer_id, s.order_date, DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) as rn,
 s.product_id, m.product_name
 FROM sales s
 JOIN menu m
 ON s.product_id = m.product_id
)

 SELECT customer_id, product_name
 FROM CTE1
 WHERE rn = 1
 
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
WITH CTE2 AS(
SELECT 
s.product_id, COUNT(*) AS purchase_count, DENSE_RANK() over(ORDER BY COUNT(*) DESC) as cn,
m.product_name
from sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.product_id, m.product_name
)

SELECT product_id, product_name, purchase_count
FROM CTE2
WHERE cn =1 
ORDER BY purchase_count DESC

 
--5. Which item was the most popular for each customer?

with cte as(
SELECT customer_id, product_id,
COUNT(*) as counting,
DENSE_RANK() OVER( partition by customer_id order by count(*) DESC) as rank
FROM sales
GROUP BY customer_id, product_id
ORDER BY customer_id
)

SELECT
*
from cte 
WHERE rank = 1

-- 6. Which item was purchased first by the customer after they became a member?
WITH CTE AS(

SELECT * FROM(
SELECT 
s.customer_id, 
s.product_id,
me.product_name,
m.join_date,
s.order_date,
s.order_date - m.join_date as day_diff
from members m
JOIN sales s
	ON m.customer_id = s.customer_id 
JOIN menu me
	ON s.product_id = me.product_id
)T
WHERE day_diff >= 0
), 
cte2 as(
SELECT *,
DENSE_RANK() OVER(partition by customer_id  ORDER BY day_diff) as rnk
from cte
)
select customer_id, product_id, 
join_date, order_date, product_name from cte2 where rnk = 1


-- 7. Which item was purchased just before the customer became a member?
WITH CTE AS(

SELECT * FROM(
SELECT 
s.customer_id, 
s.product_id,
me.product_name,
m.join_date,
s.order_date,
s.order_date - m.join_date as day_diff
from members m
JOIN sales s
	ON m.customer_id = s.customer_id 
JOIN menu me
	ON s.product_id = me.product_id
)T
WHERE day_diff < 0
), 
cte2 as(
SELECT *,
DENSE_RANK() OVER(partition by customer_id  ORDER BY day_diff DESC) as rnk
from cte
)
select customer_id, product_id, 
join_date, order_date, product_name, rnk from cte2 where rnk = 1

--8. What is the total items and amount spent for each member before they became a member?
SELECT 
s.customer_id, 
COUNT(s.product_id) as total_items,
SUM(me.price) as total_price
from members m
JOIN sales s
	ON m.customer_id = s.customer_id 
JOIN menu me
	ON s.product_id = me.product_id

WHERE s.order_date < m.join_date
GROUP BY s.customer_id

--9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT 
s.customer_id,
SUM(CASE
	WHEN m.product_name = 'sushi' THEN price*10*2
	ELSE
		price*10
END)
FROM menu m
JOIN sales s 
ON m.product_id = s.product_id

GROUP BY s.customer_id

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
-- not just sushi - how many points do customer A and B have at the end of January?

SELECT 
s.customer_id,	
SUM(CASE
   WHEN s.order_date - m.join_date BETWEEN 0 AND 6 THEN me.price * 10 * 2
   WHEN me.product_name = 'sushi' THEN me.price*10*2
   ELSE me.price*10*1
END
)as points

   FROM sales s 
   JOIN members m 
   ON s.customer_id = m.customer_id
   JOIN menu me
   ON s.product_id = me.product_id

WHERE s.order_date <= '2021-01-31'
GROUP BY s.customer_id

-- BONUS QUESTIONS: 
SELECT 
s.customer_id,
s.order_date,
me.product_name,
me.price,
(CASE 
WHEN m.join_date is NULL THEN 'N'
WHEN s.order_date < m.join_date THEN 'N'
	else 'Y'
end
) AS members
FROM sales s
JOIN menu me
ON s.product_id = me.product_id
LEFT JOIN members m
ON s.customer_id = m.customer_id
ORDER BY customer_id, order_date;

-- Danny also requires further information about the ranking of customer products,
-- but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records
-- when customers are not yet part of the loyalty program.

WITH CTE AS(
SELECT 
s.customer_id,
s.order_date,
m.join_date,
me.product_name,
me.price,
(CASE 
	WHEN m.join_date <= s.order_date THEN 'Y'
	ELSE 'N'
end
) as members
FROM sales s
JOIN menu me
ON s.product_id = me.product_id
LEFT JOIN members m
ON s.customer_id = m.customer_id
),
ranked_cte AS(
select DISTINCT customer_id, order_date,
dense_rank() over(partition by customer_id order by order_date) as ranking
FROM CTE 
where members = 'Y'
 )
SELECT c.customer_id, c.order_date, c.product_name, c.price, c.members, r.ranking
from CTE c
LEFT JOIN ranked_cte r
ON c.customer_id = r.customer_id AND c.order_date = r.order_date


