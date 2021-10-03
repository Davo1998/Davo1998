
drop table if exists #oct
select * 
into #oct
from 
dbo.[2019-Oct] oct

drop table if exists #nov
select * 
into #nov
from 
dbo.[2019-Nov] 

drop table if exists #dec
select * 
into #dec
from 
dbo.[2019-Dec] 

drop table if exists #jan
select * 
into #jan
from 
dbo.[2020-Jan]

drop table if exists #feb
select * 
into #feb
from 
dbo.[2020-Feb] 


drop table if exists #total_users
select a.*
into #total_users
from
(select * from
#dec union all
select * from 
#oct union all
select * from 
#nov union all
select * from 
#jan union all
select * from 
#feb) a


select t.product_id, count(distinct t.user_id)
from 
#total_users t
group by t.product_id
order by count(distinct t.user_id) desc





drop table if exists #tmp_data
select    concat(  t.event_time,' ',  t.user_id) OrderNo, product_id OrderItem    
into #tmp_data
from
#total_users t
where t.event_type='purchase'
order by product_id 



--__________________________________
select t.OrderNo, count(distinct t.OrderItem) count_of_orders
from 
#tmp_data t
group by t.OrderNo
order by count(distinct t.OrderItem) desc

-- max basket contains 429 distinct products--
--number of buskets/transactions made is 159 376


--_________________________________________

--select t.OrderNo, count(distinct t.OrderItem) count_of_orders
select t.OrderItem, count(t.OrderNo) times_purhased
from 
#tmp_data t
group by t.OrderItem
order by count( t.OrderNo) desc

/*
OrderItem	N of purchase
5809910	    7549
5854897	    4631
5700037	    3684
5802432	    3533
5751422	    3521
*/

--5809910
5809912
--5751422
5751383
5849033
--we need to identify frequency of this products being purchased together

select 
CASE WHEN  C.first<>0   then c.OrderNo end ,  C.second
from
(

select t.OrderNo, 
case when t.OrderItem=5809912 then 5809912  else 0 end first,
case when t.OrderItem=5809910 then 5809910   else 0 end second
from 
#tmp_data  t
ORDER BY case when t.OrderItem=5809910 then 580990  else 0 end  DESC
--ORDER BY T.OrderNo  
) c
order by CASE WHEN  C.first<>0   then c.OrderNo end desc


SELECT T.OrderItem, COUNT (distinct T.OrderNo)_item_count
FROM #tmp_data T
WHERE T.OrderNo IN
(
SELECT t.OrderNo 
FROM 
#tmp_data T
WHERE T.OrderItem LIKE '5854897'

)
GROUP BY T.OrderItem
ORDER BY COUNT (distinct OrderNo) DESC


--The first product :5809910 is mostly bought with the product with id 5809912, which is bought tougether 1528 times
--The second Item :5854897 is bought mostly with the product with ID: 5700037, in 447 cases


--_________________________________
CREATE TABLE dbo.importantProducts
WITH(DISTRIBUTION = Round_Robin)
 as
 select Top 100 count(*) as nTrans,  t.OrderItem ProductKey
 FROM
 #tmp_data t



drop  TABLE if exists #largeTransactions 
	SELECT t.OrderNo, count(*) as nProducts
	into #largeTransactions 
	from #tmp_data t
	group by t.OrderNo
	having count(*) > 1
	select * from
	#largeTransactions lt

drop  TABLE if exists #importantProducts

select Top 100 count(*) as nTrans, t.OrderItem aS ProductKey
into #importantProducts
from 
#tmp_data t
group by t.OrderItem 
order by count(*) DESC

select * from 
#importantProducts pr


drop TABLE if exists #FactSalesKept
 select t.OrderItem as ProductKey, i.nTrans, t.OrderNo 
 into #FactSalesKept

 from 
 #tmp_data t
 inner join #importantProducts i
 on i.ProductKey=t.OrderItem
 inner join #largeTransactions lt
 on lt.OrderNo=t.OrderNo
 
 select * from #FactSalesKept

 declare @count decimal(12,5) -- the number of shopping baskets

set @count = (select count (distinct t.OrderNo) from #tmp_data t)

select @count -- 159376.00000



drop table if exists #importantProductsNewCount
select Top 100 count(*) as nTrans, t.OrderItem ProductKey
into #importantProductsNewCount
from #tmp_data t
group by t.OrderItem
order by count(*)  desc

select * from #importantProductsNewCount

CREATE TABLE dbo.Pairs

select top 100000 * from 
#nov
order by product_id
