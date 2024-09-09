select * from Final_Raw_Data as f

--Q1. What was the total quantity sold for all products?  
select f.product_name,sum(f.qty) as total_qty_sold from Final_Raw_Data as f
group by f.product_name

--Q2. What is the total generated revenue for all products before discounts? 
select f.product_name,sum(f.amount) as revenue_before_discount from Final_Raw_Data as f
group by f.product_name

--Q3. What was the total discount amount for all products?
select f.product_name,round(sum(f.amount*(cast(discount as float))/100),1) as total_discount_amount from Final_Raw_Data as f
group by f.product_name

--Q4. How many unique transactions were there? 
select count(distinct f.txn_id) as unique_txn from Final_Raw_Data as f

--Q5. What is the average unique products purchased in each transaction? 
select sum(ps.qty)/count(distinct ps.txn_id) as avg_product_qty from Product_Sales as ps

--Q6. What are the 25th, 50th and 75th percentile values for the revenue per transaction?  
select distinct PERCENTILE_CONT(0.25) WITHIN GROUP(ORDER BY revenue) OVER () AS percentile25,PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY revenue) OVER () AS percentile50,PERCENTILE_CONT(0.75) WITHIN GROUP(ORDER BY revenue) OVER () AS percentile75  from (
select f.txn_id,sum(f.amount) as revenue from Final_Raw_Data as f group by f.txn_id) as t

--Q7. What is the average discount value per transaction?  

WITH temp_cte AS (
  SELECT
    txn_id,
    SUM (cast(qty as int) * price - (cast(qty as int) * price * cast(discount as float)/100)) AS transactions,
    SUM (cast(qty as int) * price) as transactions_nodisc
  FROM
    Final_Raw_Data as f
  GROUP BY
    txn_id
)
SELECT
  ROUND(AVG(transactions_nodisc - transactions),1) AS avg_order_disc
FROM
  temp_cte

--Q8. What is the percentage split of all transactions for members vs non-members?  
select t.member_per,100-t.member_per as non_member_per from (
select 100*cast(count(distinct f.txn_id) as float) /(select count(distinct f.txn_id) from Final_Raw_Data as f) as member_per from Final_Raw_Data as f
where f.member_flag=1) as t

--Q9. What is the average revenue for member transactions and non-member transactions? 
select round(avg(t.revenue),2) as avg_revenue_trx from(
select f.member_flag,f.txn_id,sum(f.amount*(1-(cast(f.discount as float)/100)))as revenue from Final_Raw_Data as f
group by f.member_flag,f.txn_id) as t
group by t.member_flag

--Q10. What are the top 3 products by total revenue before discount? 
select top 3 f.product_name from Final_Raw_Data as f
group by f.product_name
order by sum(f.amount) desc

--Q11. What is the total quantity, revenue and discount for each segment?  
select pd.level_text, sum(f.qty) as qty,round(sum(f.amount*(1-(cast(f.discount as float)/100))),2)as revenue,round(sum(f.amount*cast(f.discount as float)/100),2) as discount from Final_Raw_Data as f inner join Product_Hierarchy as pd on f.Parent_id_segment=pd.Parent_id
group by pd.level_text

--Q12. What is the top selling product for each segment?
select t.level_text,t.product_name from (
select ph.level_text,f.product_name,rank() over(partition by ph.level_text order by sum(f.qty) desc) as rank_ from Final_Raw_Data as f inner join Product_Hierarchy as ph on f.Parent_id_segment=ph.Parent_id
group by ph.level_text,f.product_name)  as t
where rank_=1

--Q13. What is the total quantity, revenue and discount for each category?  
select pd.level_text, sum(f.qty) as qty,round(sum(f.amount*(1-(cast(f.discount as float)/100))),2)as revenue,round(sum(f.amount*cast(f.discount as float)/100),2) as discount from Final_Raw_Data as f inner join Product_Hierarchy as pd on f.Parent_id_category=pd.Parent_id
group by pd.level_text

--Q14. What is the top selling product for each category?
select t.level_text,t.product_name from (
select ph.level_text,f.product_name,rank() over(partition by ph.level_text order by sum(f.qty) desc) as rank_ from Final_Raw_Data as f inner join Product_Hierarchy as ph on f.Parent_id_category=ph.Parent_id
group by ph.level_text,f.product_name)  as t
where rank_=1

--Q15. What is the percentage split of revenue by product for each segment?  
select ph.level_text,f.product_name,round(100*sum(f.amount*(1-(cast(f.discount as float)/100)))/sum(sum(f.amount*(1-(cast(f.discount as float)/100)))) over(partition by ph.level_text),2) as revenue_per  from Final_Raw_Data as f inner join Product_Hierarchy as ph on f.Parent_id_segment=ph.Parent_id
group by ph.level_text,f.product_name

--Q16. What is the percentage split of revenue by segment for each category? 
select pd.Parent_id_category,pd.Parent_id_segment,round(100*sum(f.amount*(1-(cast(f.discount as float)/100)))/sum(sum(f.amount*(1-(cast(f.discount as float)/100)))) over(partition by pd.Parent_id_category),2) as revenue_per  from Final_Raw_Data as f inner join Product_Details as pd on pd.product_id=f.prod_id
group by pd.Parent_id_category,pd.Parent_id_segment

--Q17. What is the percentage split of total revenue by category?   
select ph.level_text,round(100*sum(f.amount*(1-(cast(f.discount as float)/100)))/(select sum(f.amount*(1-(cast(f.discount as float)/100))) from Final_Raw_Data as f),2) as total_revenue from Final_Raw_Data as f inner join Product_Hierarchy as ph on f.Parent_id_category=ph.Parent_id
group by ph.level_text

--Q18. What is the total transaction “penetration” for each product?  
select f.product_name,count(distinct f.txn_id) from Final_Raw_Data as f
group by f.product_name

SELECT
  prod_id,
  product_name,
  CONCAT(ROUND(100 * COUNT(txn_id) / (
    SELECT
      COUNT(DISTINCT txn_id)
    FROM
      Product_Sales), 2),' %') AS penetration
FROM
  Product_Sales AS s
LEFT JOIN
 Product_Details AS p
ON
  s.prod_id = p.product_id
GROUP BY 
  prod_id,
  product_name

--Q19. What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction? 
SELECT top 1
  s.prod_id as product_a,
  s1.prod_id as product_b,
  s2.prod_id as product_c,
  COUNT(*) AS combination_count
FROM
  Product_Sales s
JOIN
  Product_Sales s1
ON
  s1.txn_id = s.txn_id
  AND s.prod_id < s1.prod_id
JOIN
  Product_Sales s2
ON
  s2.txn_id = s.txn_id
  AND s1.prod_id < s2.prod_id
GROUP BY
  s.prod_id,
  s1.prod_id, 
  s2.prod_id 
ORDER BY
  combination_count DESC

/*Q20. Calculate the below metrics by each month. 
Revenue
Qty
Average transaction value 
No_of_transactions
No_of_Customers
Discount amount
No_customers_who_are_members
No_of_distinct_products
Product_name_with_highest_sales
*/
select t1.*,t2.customer_who_are_member,t3.top_product_by_sales from (
select f.month_,round(sum(f.amount*(1-(cast(f.discount as float)/100))),2) as net_revenue,sum(f.qty) as total_qty,
sum(f.amount*(1-(cast(f.discount as float)/100)))/count(f.txn_id) as avg_txn_value,count(f.txn_id) as txn_cnt,count(distinct f.user_id) as user_cnt,
sum(f.amount*(1-(cast(f.discount as float))/100)) as discount_amount,
count(distinct f.prod_id) as distinct_product
from Final_Raw_Data as f 
group by f.month_) as t1
inner join (
select f.month_,count(distinct f.user_id) as customer_who_are_member from Final_Raw_Data as f where f.member_flag=1 group by f.month_) as t2 on t1.month_=t2.month_
inner join(
select t.month_,t.product_name as top_product_by_sales from (
select f.month_,f.product_name,rank() over(partition by f.month_ order by sum(f.amount) desc) as rank_ from Final_Raw_Data as f
group by f.month_,f.product_name) as t
where t.rank_=1) as t3 on t1.month_=t3.month_