-- Introduction
-- Danny seriously loves Japanese food so in the beginning of 2021, he decides to embark upon a risky venture and opens up a cute little restaurant that sells his 3 favourite foods: sushi, curry and ramen.

-- Danny’s Diner is in need of your assistance to help the restaurant stay afloat - the restaurant has captured some very basic data from their few months of operation but have no idea how to use their data to help them run the business.




-- Problem Statement
-- Danny wants to use the data to answer a few simple questions about his customers, especially about their visiting patterns, how much money they’ve spent and also which menu items are their favourite. Having this deeper connection with his customers will help him deliver a better and more personalised experience for his loyal customers.

-- He plans on using these insights to help him decide whether he should expand the existing customer loyalty program - additionally he needs help to generate some basic datasets so his team can easily inspect the data without needing to use SQL.

-- Danny has provided you with a sample of his overall customer data due to privacy issues - but he hopes that these examples are enough for you to write fully functioning SQL queries to help him answer his questions!


create database if not exists dannys_diner;

use dannys_diner;


CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');


-- What is the total amount each customer spent at the restaurant?
with filtered_data as (
select sales.*,menu.price as price from sales inner join menu
on (menu.product_id=sales.product_id))
select fd.customer_id,sum(price) as total_spent from 
filtered_data as fd inner join members on (members.customer_id=fd.
customer_id)
group by 1
order by 1;


-- How many days has each customer visited the restaurant?
with fd as (
select sales.customer_id,sales.order_date,count(*) as cc from sales inner join members
on (members.customer_id=sales.customer_id)
group by 1,2)
select fd.customer_id,sum(cc) as days from fd
group by 1;


-- What was the first item from the menu purchased by each customer?
with fd as(
select sales.customer_id,sales.order_date,menu.product_name,dense_rank()
over(partition by sales.customer_id order by sales.order_date) as ranks from sales
inner join menu on (menu.product_id=sales.product_id) inner join members on(members.customer_id=
sales.customer_id))
select customer_id,product_name from fd
where ranks=1;

-- What is the most purchased item on the menu and how many times was it purchased by all customers?

select sales.customer_id,count(sales.customer_id) as times_buy ,menu.product_name from sales inner join members
on(members.customer_id=sales.customer_id) inner join menu on(menu.product_id=sales.product_id)
where sales.product_id=(
select product_id from(
select sales.product_id,count(*) as occ from sales inner join menu on(menu.product_id=sales.product_id)
inner join members on (members.customer_id=sales.customer_id)
group by 1
order by occ desc) as temptable
limit 1)
group by 1;


-- Which item was the most popular for each customer?
select customer_id,product_name from(
with fd as (
select sales.customer_id,menu.product_name,count(sales.customer_id) as sales_occ 
from sales inner join
members on (sales.customer_id=members.customer_id) inner join menu on (menu.product_id=sales.product_id)
group by 1,2
order by 1)
select customer_id,product_name,sales_occ,dense_rank() over(partition by customer_id order by sales_occ 
desc) as ranks from fd) as temptable
where ranks=1;

-- Which item was purchased first by the customer after they became a member?
select customer_id,menu.product_name from (
select sales.* ,dense_rank() over(partition by customer_id order by order_date) as ranks from sales,members where (sales.customer_id=members.customer_id)
and (sales.order_date>=members.join_date)) as temptable inner join menu on (menu.product_id=temptable.product_id)
where ranks=1;

-- Which item was purchased just before the customer became a member?

select customer_id,menu.product_name from (
select sales.* ,dense_rank() over(partition by customer_id order by order_date desc) as ranks from sales,members where (sales.customer_id=members.customer_id)
and (sales.order_date<members.join_date)) as temptable inner join menu on (menu.product_id=temptable.product_id)
where ranks=1;

-- What is the total items and amount spent for each member before they became a member?
with fd as (
select sales.*,menu.price from (sales,members)
inner join menu on(menu.product_id=sales.product_id) where (sales.customer_id=members.customer_id)
and (sales.order_date<members.join_date))
select customer_id,count(customer_id) as total_items,sum(price) as total_price from fd
group by 1
order by 1;


-- If each $1 spent equates to 10 points 
-- and sushi has a 2x points multiplier - how many points would each customer have?

select customer_id,sum(points) as total_points from (
select sales.*,if (menu.product_name="sushi",20*menu.price,10*menu.price) as points from sales
inner join menu on(menu.product_id=sales.product_id) inner join members on (members.customer_id=
sales.customer_id) ) as temptable
group by 1;

-- In the first week after a customer joins the program (including their join date) 
-- they earn 2x points on all items, 
-- not just sushi - how many points do customer A and B have at the end of January?
select customer_id,sum(points) as total_points from (
with fd as(
select sales.customer_id,sales.order_date,menu.product_name,menu.price,members.join_date as lower_date,date_add(members.join_date,INTERVAL 7 day)
as upper_date from (sales,members)
inner join menu on(menu.product_id=sales.product_id) where (sales.customer_id=members.customer_id)
and (sales.customer_id>=members.customer_id))
select fd.customer_id,if((fd.order_date>=lower_date and fd.order_date<=upper_date),fd.price*20,
if(fd.product_name="sushi",fd.price*20,fd.price*10)) as points from fd) as temptable
group by 1;
