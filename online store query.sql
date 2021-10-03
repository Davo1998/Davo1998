--__________Tamprory tables monthly_________


drop table if exists #total_users
select a.*
into #total_users
from
(select * from
dbo.[2019-Dec] 
 union all
select * from 
dbo.[2019-Oct] oct
 union all
select * from 
dbo.[2019-Nov] 
 union all
select * from 
dbo.[2020-Jan]
 union all
select * from 
dbo.[2020-Feb] 
) a


--_____________Task 1_____________

--1.1 getting number of users 

--1.2 getting the number of viewed products 

select count(distinct a.user_id) User_number, count(distinct a.product_id) Products_viewed
from #total_users a

--Durind the observed perioud the number of active users is 1639358
--Durind the observed perioud the number of products viewed is 54571

--1.2 second option

select  count(distinct product_id) Products_viewed
from #total_users a
where a.event_type='view'

--for 1.2, if we consider 'viewed products' only the poducts, that have event_type 'view' , the number will be different, 53854: it is less then the previows one

  -- for calculating month over month growth, I subtracted purchased products' amount of October from Febraury

--____________Task2____________

--What were the top 5 products in terms of month over month increase in sales?

select  a.product_id,a.brand, (isnull(sum( case when right(left(a.event_time, 7),2)= 2 then a.price end), 0) -
 isnull(sum( case when right(left(a.event_time, 7),2)= 10 then a.price end), 0) ) dif
from #total_users a
where a.event_type='purchase'

group by product_id,a.brand
order by dif desc

/* Answer-- The top 5 product id-s that had the largest month over month incease in sales, are the products with following product_id-s and brand names : 
5850281	marathon	7440.12
5809910	grattol	    5706.84
5560754	strong	    4861
5877453	jessnail	3963.2
5924482	NULL	    3261.4
5560760	strong	    2604.8
 I included 6 prducts, as 5th product does not have brend name*/


--______________Task3_______________

--03. On average, how long do users take to visit the website again?


drop table if exists #interval
select a.user_id, datediff(DAY,  min(left(a.event_time, 18)),max(left(a.event_time, 18)))/count( a.user_id) inerval_day, datediff(HOUR,  min(left(a.event_time, 18)),max(left(a.event_time, 18)))/count( a.user_id) interval_houre, datediff(MINUTE,  min(left(a.event_time, 18)),max(left(a.event_time, 18)))/count( a.user_id) interval_min, count( a.user_id) user_count
into #interval
from  #total_users a
group by a.user_id
select  round(sum(  cast ( int.inerval_day as decimal(4,0))),4)/1639358 interval_daily, sum(int.interval_houre)/1639358 interval_hourely,   sum(cast (int.interval_min as bigint))/1639358 interval_by_minutes
from 
#interval int

-- the average interval that user is visiting to the website for eny action is 24 houres or  1461 minutes
--it is calculated by measuring interval per user: the formula used for average intrval per user is : (max(event_time)-min(enent_time))/number_of_intervals   number of intervals is the amount user entered to the website for eny event.
--then for calculating average, the interval for every user is averaged
--______________Task 4______________

-- 4.1 ___DAU_____---

drop table if exists #DAU
select 
cast (left(a.event_time, 18) as date) date  ,  datepart(wk,left(a.event_time, 18)) week,  month (left(a.event_time, 18)) month, year(left(a.event_time, 18)) year, count(distinct a.user_id) DAU,
Avg_Dau_monthly = avg(count(distinct a.user_id))  over(partition by   month (left(a.event_time, 18))) ,
Avg_Dau_yearly = avg(count(distinct a.user_id))  over(partition by   year (left(a.event_time, 18))) ,
Avg_dau= avg(count(distinct a.user_id))  over()
into #DAU
from #total_users a
group by cast (left(a.event_time, 18) as date), month (left(a.event_time, 18)) , year(left(a.event_time, 18)) ,datepart(wk,left(a.event_time, 18))
order by 
cast (left(a.event_time, 18) as date) 
--    ____DAU per day_____
select d.date, d.DAU 
from
#DAU d
order by date

-- _____Average Dau monthly_______
select d.month, avg(d.Avg_Dau_monthly) monthly_DAU
from
#DAU d
group by d.month
order by avg(d.Avg_Dau_monthly) desc

--Average DAU is growing monthly and the greatest value is on February it is a good indicator, as it tells tht the sales are rising
 /*month	monthly_DAU
    2	    19662
    1	    19348
    11	    18310
    10	    17952
    12	    17065
 */

---Average, MAX, MIN DAU, STDEV
select max(d.Avg_dau) AVG_DAU, max(d.DAU) MAX, MIN(d.dau) MIN, STDEV(d.DAU) STDEV
from
#DAU d
/*

MAX	        AVG_DAU  	MIN
33859	     18453 	   7430
2019-10-02             2019-12-31

The minimum value of DAU is on december 31 of the 2019
The STD of DAU is 3043.5
*/


--4.2____WAU_____

set datefirst 1;
drop table if exists #WAU
select 
  datepart(wk,left(a.event_time, 18)) week,  month (left(a.event_time, 18)) month, year(left(a.event_time, 18)) year, count(distinct a.user_id) WAU,
Avg_WAU_monthly = avg(count(distinct a.user_id))  over(partition by   month (left(a.event_time, 18))) ,
Avg_WAU_yearly = avg(count(distinct a.user_id))  over(partition by   year (left(a.event_time, 18))) ,
STD_WAU= STDEV(count(distinct a.user_id))  over()

into #WAU
from
#total_users a
group by month (left(a.event_time, 18)) , year(left(a.event_time, 18)) ,datepart(wk,left(a.event_time, 18))
order by 
datepart(wk,left(a.event_time, 18))

select week, WAU  , month, Avg_WAU_monthly, cast(STD_WAU as int) STD_Dev
from
#WAU w
--WAU monthly--
select w.month, max(w.Avg_WAU_monthly) Average_Wau_monthly
 from #WAU w
group by month
order by max(w.Avg_WAU_monthly) desc

select max(wau) max, Min(wau) min, AVG(w.wau) AVG
from
#WAU w
--The minimum value of WAU is 17540: first week of december , the maximum is 115989 : first week of october
--The average number of WAU in the observed peroud is 89738
-- the STD of WAU is 29535 


--4.3_________MAU___________

drop table if exists #MAU
select  month (left(a.event_time, 18)) month,  count(distinct a.user_id) MAU,
STD_MAU=   cast(( STDEV(count(distinct a.user_id))  over()) as decimal(10,2)),
AVG_MAU=   avg(count(distinct a.user_id))  over()
into #MAU
from
#total_users a
group by month (left(a.event_time, 18)) 

select * from #MAU
 order by month
--The maximum number of active  users company hed on January, and minimum: on November,so the dinamics is like tis:  we hade sharp decrease of active users on November, slightly recovery on 
--December, sharp growth on January then slightly decrease on Febraury
--The averae number of monthly active users is 387835, and the stndard deviation is 18315 



--____________Task5____________
--What is the Average Revenue Per User (ARPU) and the Average Expected Revenue Per User in October 2019?
--5.1 What is the Average Revenue Per User (ARPU)
Select CONVERT(DECIMAL(10,2), 
sum(  case when a.event_type='purchase' then a.price end) /count(distinct(a.user_id))) ARPU 
from #total_users a
where month(left(a.event_time, 18))=10

-- ARPU in Otober is 3.03__
--5.2 the Average Expected Revenue Per User in October 2019
---liklyhood of not removing--   not removing cart/
--where a.event_type <>'remove_from_cart'\

select t.Expected_rvenue/t.User_count
from

(	select  cast( cast(( CAst (count( case when a.event_type='cart'  then   a.product_id end)  as float)-CAst (count( case when a.event_type='rmove_from_cart'  then   a.product_id end)  as float))    /CAst (count( case when a.event_type='cart'  then   a.product_id end)  as float) as decimal(10,2)) 
	*cast(sum(case when a.event_type='cart' then a.price end) as decimal(10,2)) as decimal(10,2)) Expected_rvenue, 
	count(distinct a.user_id) User_count
	from
	#total_users a 
	where month(left(a.event_time, 18))=10
)  t
-- the  total expected revenue in October  is 5376641.2 , and the average expected revenue  is 16,6

--____________Task6____________
-- What is the product which was added FIRST to the cart the most?


select b.product_id, b.brand, COUNT(b.user_id) Num_of_bought_first
from (
select  a.user_id, a.product_id,a.brand, left(a.event_time, 18) event_time,a.event_type, 
rank() over (partition by user_id order by left(a.event_time, 18)	   ) rank,
rank() over (partition by user_id, event_time order by left(a.event_time, 18)	   )  transaction_ID
from
#total_users a 
where a.event_type='cart'
)b
where b.rank=1
group by b.product_id, b.brand
order by COUNT(b.user_id) desc


--the product added to the card first most is the product with following ID and brand name: 5809910, grattol which was added first 8393 times 


---____ Task 7  Most sold product groups______
-- For calculaing the number of products mostly sold togather, we need to have unique index for each transaction. We can solve this problam by concatinating the user ID and event time columns
-- I crated temporary table for convinience, where I gathered all sold products , transaction ID-s, and user_ID-s which is clled TMP data

drop table if exists #tmp_data
select    concat(  t.event_time,' ',  t.user_id) OrderNo, product_id OrderItem    , t.user_id 
into #tmp_data
from
#total_users t
where t.event_type='purchase'
order by product_id 
---__________________________

--With this query we can now the distinct number of baskets and number of items they have
select t.OrderNo, count(distinct t.OrderItem) count_of_orders
from 
#tmp_data t
group by t.OrderNo
order by count(distinct t.OrderItem) desc

-- the biggest  basket contains 429 distinct products--
--number of buskets/transactions made is 159 376
 

select    count (distinct  concat(  t.event_time,' ',  t.user_id)) purchase_id
from
#total_users t
where t.event_type='purchase'

drop table if exists #tmp_data
select    concat(  t.event_time,' ',  t.user_id) OrderNo, product_id OrderItem    
into #tmp_data
from
#total_users t
where t.event_type='purchase'
order by product_id 
--____________________________

select top 20 a.PRODUCT_1,a.PRODUCT_2,a.TRANS_COUNT, cast (  cast(a.TRANS_COUNT as decimal(10,2))/ cast(c.Order_count as decimal (10,2))*100 as decimal(10,2)) Confidance
from
(

SELECT 
PRODUCT_1,
PRODUCT_2,
COUNT(TRANSACTION_ID) TRANS_COUNT
FROM
(
SELECT
a.OrderItem PRODUCT_1,
b.OrderItem PRODUCT_2,
b.OrderNo TRANSACTION_ID
FROM #tmp_data a,
#tmp_data b 
WHERE a.OrderNo=b.OrderNo
and a.OrderItem <> b.OrderItem
and a.OrderItem < b.OrderItem
) This
GROUP BY PRODUCT_1,PRODUCT_2 

) a
left join (

SELECT B.product_id,  COUNT (DISTINCT CONCAT(B.user_id, LEFT(B.event_time, 18))) Order_count FROM(
SELECT * FROM 
 DBO.[2019-Nov]
 UNION ALL 
SELECT * FROM 
 DBO.[2019-Dec]
 UNION ALL 
SELECT * FROM 
DBO.[2019-Oct]
UNION ALL
SELECT * FROM 
DBO.[2020-Jan]
UNION ALL
SELECT * FROM 
DBO.[2020-Feb]
) B
where b.event_type='Purchase'
GROUP BY B.product_id
)c


on c.product_id=a.PRODUCT_1
order by a.TRANS_COUNT desc




--We can see that 1st sold product was in 7549 baskets, and 1528  of them are containing second product as well with ID 5809910.
-- The confidance of buying a with b can be calculatd by deviding the frequency of a and b together by the frequency of a  
  --which is 20.24%
  
  -- Based on that  we can say that if a customer is buying the most purchased brand, with 20 % probability he will by product with id 5809910 
  -- we can use the same logic for other top saled products

  PRODUCT_1	PRODUCT_2	TRANS_COUNT	Confidance
  5809910	5809912	     1528	     20.24
  5751383	5751422	     1047	     35.52
  5809910	5809911	     987	     13.07
  5809910	5816170	     774	     10.25
  5809911	5809912	     717	     39.24
  5751422	5849033	     661	     18.77
  5809912	5816170	     573	     17.33
  



 --______Task N8 Retention Metrixes___________

--customer retention rate per month
--non new users/total users
SELECT(
(  select  cast( count(distinct a.user_id) as decimal(10,2))
 from
#total_users a
		where  month(left(a.event_time,18))=2
		and a.user_id  in (
		select a.user_id from  
				#total_users  a
		where month(left(a.event_time,18)) in (10,11,12,1))
		) /
		(
select  cast( count(distinct a.user_id) as decimal(10,2)) from
 #total_users a
 where  month(left(a.event_time,18)) IN (10,11,12,1))*100)

 --Retention rate in fabuary is ~7% which means on Fabruary only 7 % of users left from previows months, other users are new users
 --another metric for calculating our customers retation rate is churn rate, which iscalculated by substracting customers at the end of the perioud from the customers at the bugginning of the perioud and devide them with the amount from the start of the perioud
 
 --ravenue growth rate of customers
 --Repeat purchase ratio
-- Repeat Purchase Ratio = Number of Returning Customers / Number of Total Customers
--product return rate in our case it will be removed products from card/added to the card and purchased rate

--Loyal Customer Rate = Number of Repeat Customers / Total Customers
--churn rate


/*________Task N9________________



The blank values for the brand name can be associated with the fact , that the company haven't filled the data on purpose  in order not to give sales information to the competitor companies. Compeating companies can see the brands that are sold the most and couse some trouble for the online store. They can sale the same brend with lower price to attract custmers to them.'

