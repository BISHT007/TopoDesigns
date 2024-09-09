--create database TopoDesigns


/*Q. Update all tables with appropriate data types (convert all the columns into appropriate data types specially date related columns) 

Update the Product_Sales table by modifying the start_txn_time column to be a datetime data type

Create new columns by deriving the  Year, Month, Weekend_flag values from start_txn_time */

alter table Product_Sales
add weekend_flag varchar(10)
 

update Product_Sales
set year_=YEAR(date_start_txn),month_=MONTH(date_start_txn),weekend_flag=DATENAME(WEEKDAY,start_txn_time)

update Product_Sales
set weekend_flag='1'
where weekend_flag in ('saturday','sunday')

update Product_Sales
set weekend_flag='0'
where weekend_flag in ('monday','tuesday','wednesday','thursday','friday')

--Q. What is the count of records in each table? 
select count(*) from Product_Details
union all 
select count(*) from Product_Hierarchy
union all
select count(*) from Product_Price
union all
select count(*) from Product_Sales
union all
select count(*) from Users



/*
Q. Create combined table of all the four tables by joining these tables. The final table name should be 'Final_Raw_Data' in the data base. 
Also create new column 'amount' with calculation of qty*price. 
*/
select * into Final_Raw_Data from (
select ps.*,pp.price,pd.Parent_id_category,pd.Parent_id_segment,pd.Parent_id_style,pd.product_name,u.cookie_id,u.Gender,u.Location from Product_Sales as ps
left join Product_Price as pp on ps.prod_id=pp.product_id
left join Product_Details as pd on ps.prod_id=pd.product_id
left join Users as u on ps.user_id=u.User_id) as t


/*
Q. Create summary table with name 'customer_360' with below columns 

User_id
Gender
Location
Max_transaction_date
No_of_transactions
No_of_transactions_weekends
No_of_transactions_weekdays
No_of_transactions_after_2PM
No_of_transactions_before_2PM
Total_spend
Total_discount_amount
Discount_percentage
Total_quanty
No_of_transactions_with_discount_more_than_20pct
No_of_distinct_products_purchased
No_of_distinct_Categories_Purchased
No_of_distinct_segments_purchased
No_of_distinct_styles_purchased
*/
select * into customer_360 from(

select t1.*,t2.weekend_cnt,t3.weekdays_cnt,t4.txn_after2_cnt,t5.txn_before2_cnt,t6.total_discount_amount,t6.total_spend,t7.txn_more_20pct from
(select f.user_id,f.Gender,f.Location,max(date_start_txn) as max_txn_date,count(f.txn_id) as txn_cnt,
count(distinct f.prod_id) as total_product_cnt,count(distinct f.Parent_id_category) as total_category_cnt,count(distinct f.Parent_id_segment)as total_segment_cnt,count(distinct f.Parent_id_style) as total_style_cnt
from Final_Raw_Data as f 
group by f.user_id,f.Gender,f.Location) as t1
left join
(select f.user_id,count(f.txn_id) as weekend_cnt from Final_Raw_Data as f
where f.weekend_flag='1' 
group by f.user_id) as t2 on t1.user_id=t2.user_id
left join
(select f.user_id,count(f.txn_id) as weekdays_cnt from Final_Raw_Data as f
where f.weekend_flag='0' 
group by f.user_id) as t3 on t1.user_id=t3.user_id
left join
(select f.user_id,count(f.txn_id) as txn_after2_cnt from Final_Raw_Data as f
where f.time_start_txn>'14:00'
group by f.user_id)as t4 on t1.user_id=t4.user_id
left join
(select f.user_id,count(f.txn_id) as txn_before2_cnt from Final_Raw_Data as f
where f.time_start_txn<'14:00'
group by f.user_id)as t5 on t1.user_id=t5.user_id
left join
(select f.user_id,sum(f.amount) as total_spend,sum(f.amount*cast(100-f.discount as float)/100) as total_discount_amount from Final_Raw_Data as f
group by f.user_id) as t6 on t1.user_id=t6.user_id
left join
(select f.user_id,count(f.txn_id) as txn_more_20pct from Final_Raw_Data as f
where f.discount>20
group by f.user_id) as t7 on t1.user_id=t7.user_id
)as tt 

/**Q. Create new column as 'segment' in 'customer_360' table with below definition. 
if Total Spend<500 then Segment = 'Low'
if Total Spend between 500 and 1000 then Segment = 'Medium'
if Total Spend>1000, then Segment = 'High'
**/

alter table customer_360
add segment varchar(10)

update customer_360
set segment= (
case 
when customer_360.total_spend<500 then 'Low' 
when customer_360.total_spend between 500 and 1000 then 'Medium'
when customer_360.total_spend>1000 then 'High'
end
)

