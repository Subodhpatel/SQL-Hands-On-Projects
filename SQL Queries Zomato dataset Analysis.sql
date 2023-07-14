/*This is a Zomato like Case study.Where multiple tables such as goldusers_signup,  product,sales,users are created containing the users information such as customers id
their gold membership and product information - product purchase date, product name , product price etc.
Further customer purchasing behaviour , maximum products purchased , Points collected by customers are analyzed using advanced SQL queries.
*/

create database zomato;
use zomato;

/* Creating the different tables and Inserting the values*/

drop table if exists goldusers_signup;
create table goldusers_signup(
user_id int,
gold_signup_date date
);
insert into goldusers_signup values (1,'2017-09-22'),
(2,'2017-04-21');


drop table if exists product;
create table product(
product_id int,
product_name varchar(20),
price int 
);
insert into product values(1,'P1',980),
(2,'P2',870),
(3,'P3',330);

drop table if exists sales;
create table sales(
user_id int,
created_at date,
product int);
insert into sales values (1,'19-04-2017',2),
(3,'18-12-2019',1),
(2,'20-07-2020',3),
(1,'23-10-2019',2),
(1,'19-03-2019',2),
(3,'20-12-2016',2),
(1,'09-11-2016',1),
(1,'20-05-2016',3),
(2,'24-09-2016',1),
(1,'11-03-2017',2),
(1,'11-03-2017',2),
(3,'10-11-2016',1),
(3,'07-12-2017',2),
(3,'15-12-2016',2),
(2,'08-11-2017',2),
(2,'10-09-2018',3);

drop table if exists users;
create table users(
user_id int,
signup_date date);

insert into users values (1,'02-09-2014'),
(2,'15-01-2015'),
(3,'11-04-2014');

/*Checking the schema of the tables*/
desc goldusers_signup;
desc product;
desc sales;
desc users;

/* Retrieving data from the tables using select statement*/

show tables;

select * from goldusers_signup;
select * from product;
select * from sales;
select * from users;

/*
Q.1)- Total Amount Each customer spent on Zomato.
*/

with sales_summary as (
select s.*, p.product_name,p.price from sales s inner join product p on s.product_id=p.product_id)
select user_id,sum(price) as total_amount_spent from sales_summary group by user_id;

-- or
select s.user_id, sum(p.price) as total_amt_spent from sales s inner join product p on s.product_id=p.product_id group by user_id;


/*
Q.2)-How many days each customer visited on zomato
*/

select user_id ,count(distinct created_at) as total_days_spent from sales group by user_id;

/*
Q.3)-What was the first product purchased by each customer
*/

with first_product as (
select *, rank() over(partition by user_id order by created_at) rn  from sales )
select fp.user_id,p.product_name from first_product as fp inner join product p on fp.product_id=p.product_id where rn=1;


/* 
Q.4)-What is the most purchasrd item in the menu and how many times it was purchased by all customer
*/

select user_id, count(product_id) as cnt from sales where product_id = (
select product_id from sales group by product_id order by count(product_id) desc limit 1) group by user_id;


/*
Q.5)-Which item was most popular for each customer
*/

select *, rank() over(partition by user_id order by created_at) rn  from sales;
with fav_product as (
select user_id,product_id,count(product_id) as cnt  from sales group by user_id ,product_id),
final_fav_product as (
select * , rank() over(partition by user_id order by cnt desc) as rn from fav_product)
select fv.user_id,p.product_name as fav_product from final_fav_product as fv inner join product as p on fv.product_id=p.product_id where rn=1;


/*
Q.6)-Which item was purchased first by the customer after they became a gold member
 */

with cte as (
select s.*,gs.gold_signup_date from sales s inner join goldusers_signup gs on s.user_id=gs.user_id and created_at>= gold_signup_date)
select c.user_id,p.product_name as first_product_purchased_after_gold_membership from cte c inner join product p on c.product_id=p.product_id;  


/*
Q.7)-Which item was purchased just before the customer became a gold member
*/
select * from (
select c.*,rank() over(partition by user_id order by created_at desc) rnk from 
(select a.user_id,a.created_at,a.product_id,b.gold_signup_date from sales a inner join goldusers_signup b on a.user_id=b.user_id and 
created_at<=gold_signup_date) c ) d where rnk=1;


/*
Q.8)-What is the total orders and amount spent for each member before they became a member 
*/

with price_smmary as (
select s.user_id,s.created_at ,p.price from sales s inner join product p on s.product_id=p.product_id),
final_summary as (
select ps.*,gs.gold_signup_date from price_smmary ps inner join 
goldusers_signup gs on ps.user_id=gs.user_id where ps.created_at<=gs.gold_signup_date )
select  fs.user_id, count(1) as total_orders ,sum(fs.price) as total_amt_spent from final_summary fs group by fs.user_id order by fs.price desc;


/*
Q.9)-If buying each product generates point for eg. 5rs =2 zomato points and each product has different purchasing points for eg.for P1 5rs=1 zomato
point, for p2 10rs=5 zomato points and p3 5rs=1 zomato point

calculate points collected by each customers and for which product most points have been given till now.
*/

with amt_spent as (
select s.user_id,s.product_id,p.product_name,p.price from sales s inner join product p 
on s.product_id=p.product_id),

points_table as (
select *, sum(price) total_amt_spent from amt_spent group by user_id,product_name),
collected_points as (
select pt.*, case when product_id=1 then 5 
			when product_id=2 then 2
			when product_id=3 then 5
			else 0 end as points
 from points_table as pt),
 final_table as (
select *, round(total_amt_spent/points,0) as points_made from collected_points)
select user_id,sum(points_made) as collected_points from final_table 
group by user_id order by sum(points_made) desc;



with amt_spent as (
select s.user_id,s.product_id,p.product_name,p.price from sales s inner join product p 
on s.product_id=p.product_id),

points_table as (
select *, sum(price) total_amt_spent from amt_spent group by user_id,product_name),
collected_points as (
select pt.*, case when product_id=1 then 5 
			when product_id=2 then 2
			when product_id=3 then 5
			else 0 end as points
 from points_table as pt) ,
 max_points as (
 select *, round(total_amt_spent/points,0) as points_made from collected_points)
select product_name,sum(points_made) as max_points_collected from max_points group by product_name order by sum(points_made) desc limit 1;


/*
Q.10)-In the first one year after a customer joins the gold program(inclusing their join date) irrespective of what 
the customers has purchased they earn 5 zomatoo points for every 10 rs spent. who earned more 1 or 3 and what was their points earning in their first year.
*/
select c.*,d.price*0.5 total_points_earned from (
select a.user_id,a.created_at,a.product_id,b.gold_signup_date from sales a inner join 
goldusers_signup b on a.user_id=b.user_id and created_at>=gold_signup_date and created_at<=date_add(gold_signup_date,interval 1 year)) c
inner join product d on c.product_id=d.product_id;
 
 
 














