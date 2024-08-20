drop table if exists driver;
CREATE TABLE driver(driver_id integer,reg_date date); 

INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'01-01-2021'),
(2,'01-03-2021'),
(3,'01-08-2021'),
(4,'01-15-2021');


drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

drop table if exists rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

drop table if exists rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

drop table if exists driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'01-01-2021 18:15:34','20km','32 minutes',''),
(2,1,'01-01-2021 19:10:54','20km','27 minutes',''),
(3,1,'01-03-2021 00:12:37','13.4km','20 mins','NaN'),
(4,2,'01-04-2021 13:53:03','23.4','40','NaN'),
(5,3,'01-08-2021 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'01-08-2020 21:30:45','25km','25mins',null),
(8,2,'01-10-2020 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'01-11-2020 18:50:20','10km','10minutes',null);


drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','01-01-2021  18:05:02'),
(2,101,1,'','','01-01-2021 19:00:52'),
(3,102,1,'','','01-02-2021 23:51:23'),
(3,102,2,'','NaN','01-02-2021 23:51:23'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,2,'4','','01-04-2021 13:23:46'),
(5,104,1,null,'1','01-08-2021 21:00:29'),
(6,101,2,null,null,'01-08-2021 21:03:13'),
(7,105,2,null,'1','01-08-2021 21:20:29'),
(8,102,1,null,null,'01-09-2021 23:54:33'),
(9,103,1,'4','1,5','01-10-2021 11:22:59'),
(10,104,1,null,null,'01-11-2021 18:34:49'),
(10,104,1,'2,6','1,4','01-11-2021 18:34:49');

select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;

1.How many rolls were ordered ? 

select count(roll_id) from customer_orders

2.How many unique customers orders were made ? 

select count(distinct customer_id) from customer_orders

3.How many sucessful orders were delivered by each driver?

select driver_id,count(order_id)
from driver_order 
where cancellation not in ('Cancellation','Customer Cancellation')
group by driver_id

4.How many of each type of roll was delivered ? 

with cte as 
(select c.order_id,c.customer_id,roll_id,case when cancellation in ('Cancellation','Customer Cancellation') then'cancel' else 'not cancel'  end as order_cancel_details
from customer_orders as c
left join driver_order as d on c.order_id = d.order_id)

select roll_id,count(order_id)
from cte
where order_cancel_details = 'not cancel'
group by roll_id

5.How many Veg and Non Veg Rolls were ordered by each Customer ?

Select customer_id,c.roll_id,r.roll_name,count(c.order_id)as roll_ordered
from customer_orders as c inner join rolls as r on c.roll_id = r.roll_id
group by customer_id,c.roll_id,r.roll_name order by 1 ,2

6.What was the maximum number of rolls delivered in a single order?

with cte as 
(select c.order_id,c.customer_id,roll_id,case when cancellation in ('Cancellation','Customer Cancellation') then'cancel' else 'not cancel'  end as order_cancel_details
from customer_orders as c
left join driver_order as d on c.order_id = d.order_id)

,cte2 as 
(select order_id,count(roll_id) as cnt,rank()over(order by count(roll_id) desc) as rnk
from cte
where order_cancel_details = 'not cancel'
group by order_id
)

select order_id
from cte2
where rnk = 1

7.For each customer,how many delivered roll had at least 1 change and how many had no change?

with new_customer_orders as 
(select order_id,customer_id,roll_id,case when not_include_items is null or not_include_items =' ' then '0' else not_include_items end as not_include_items,
case when extra_items_included is null or extra_items_included =' '  or extra_items_included = 'NaN 'then '0' else extra_items_included end as extra_items_included,
order_date
from customer_orders)

,new_driver_order as 
(select *,case when cancellation  in ('Cancellation','Customer Cancellation' ) then 'cancel' else 'not_cancel'end as new_order_cancel
from driver_order)

,cte as (select *,case when not_include_items = '0' and extra_items_included = '0'  then 'not changed' else 'changed' end as changing
from new_customer_orders 
where order_id in (select order_id from new_driver_order
where new_order_cancel = 'not_cancel'))

select customer_id,changing,count(order_id)
from cte
group by customer_id,changing

8.How many rolls were delivered that had both exclusion and extras ?

with new_customer_orders as 
(select order_id,customer_id,roll_id,case when not_include_items is null or not_include_items =' ' then '0' else not_include_items end as not_include_items,
case when extra_items_included is null or extra_items_included =' '  or extra_items_included = 'NaN 'then '0' else extra_items_included end as extra_items_included,
order_date
from customer_orders)

,new_driver_order as 
(select *,case when cancellation  in ('Cancellation','Customer Cancellation' ) then 'cancel' else 'not_cancel'end as new_order_cancel
from driver_order)

,cte as 
(select *,case when not_include_items <> '0' and extra_items_included <>'0'  then 'both excluded' else '1 excluded' end as changing
from new_customer_orders 
where order_id in (select order_id from new_driver_order
where new_order_cancel = 'not_cancel'))

select changing,count(changing)
from cte
group by changing

9.What was the total number of rolls ordered for each hour of the day ?

with cte as 
(select *,concat(datepart(hour,order_date),'-',datepart(hour,order_date)+1) as hrs
from customer_orders)

select hrs,count(hrs) as rolls_ordered
from cte
group by hrs

10. What was the number of orders for each day of the week ? 

select datename(dw,order_date) as week_day,count(distinct order_id) as week_orders
from customer_orders
group by datename(dw,order_date)

11. What was the average distance travelled for each customer ?

select customer_id,replace(distance,'km','')as distance
from customer_orders as o 
left join driver_order as d 
on o.order_id=d.order_id
where pickup_time is not null

12.What was the difference between the longest and the shortest delivery times for all orders ? 

with cte as 
(Select cast(case when duration like '%min%' then left(duration,CHARINDEX('m',duration)-1) else duration end as int) as durations
from driver_order where duration is not null)

select max(durations) - min (durations)as difference_between
from cte

13.What was the average speed for each driver for each delivery and do you notice any trend for these values ?

with cte as (select a.order_id,cnt,driver_id,distance,durations from 
(Select order_id,driver_id,cast(trim(replace(distance,'km','')) as decimal(4,1))as distance,cast(case when duration like '%min%' then left(duration,CHARINDEX('m',duration)-1) else duration end as int) as durations
from driver_order where duration is not null) as a inner join 
(select order_id,count(roll_id) as cnt from customer_orders group by order_id) as b on a.order_id = b.order_id )

select order_id,driver_id,cnt,distance/durations as avg_speed_per_delivery
from cte

14. What is the successful delivery percentage for each driver ? 

with cte as 
(Select * ,case when cancellation in ('Cancellation','Customer Cancellation') then 0 else 1 end as cancelled_order
from driver_order)

Select driver_id,round(sum(cancelled_order)*1.0/count(cancelled_order)*100,2) as successful_delivery_perc
from cte
group by driver_id