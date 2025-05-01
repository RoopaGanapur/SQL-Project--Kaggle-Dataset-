/****** Script for SelectTopNRows command from SSMS  ******/
-- Solve the below SQL problems using the Famous Paintings & Museum dataset:

--1) Fetch all the paintings which are not displayed on any museums?

SELECT DISTINCT NAME FROM work WHERE [museum_id] IS NULL;

--2) Are there museuems without any paintings?

select * from museum m
	where not exists (select 1 from work w
					 where w.museum_id=m.museum_id)



--3) How many paintings have an asking price of more than their regular price? 

SELECT COUNT(DISTINCT work_id) FROM product_size WHERE [sale_price]>[regular_price];



--4) Identify the paintings whose asking price is less than 50% of its regular price

WITH CTE AS(
SELECT * FROM product_size WHERE [sale_price]<[regular_price]*0.5)
SELECT NAME FROM WORK W JOIN CTE C ON W.work_id=C.work_id


--5) Which canva size costs the most?
with cte as(
SELECT * ,RANK() OVER(ORDER BY sale_price desc) AS rn FROM product_size)
SELECT c.label,p.sale_price from cte p join canvas_size c
on c.size_id=p.size_id and rn=1;


--6) Delete duplicate records from work, product_size, subject and image_link tables

with cte as (
select artist_id, work_id, row_number() over(partition by artist_id, work_id order by name ) as rn from work)
delete from cte where rn>1;

with cte as (
select work_id,size_id, row_number() over(partition by work_id,size_id order by work_id ) as rn from product_size)
delete from cte where rn>1




-
--7) Fetch the top 10 most famous painting subject

with cte as(
select s.subject,count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as ranking
		from work w
		join subject s on s.work_id=w.work_id
		group by s.subject)
		select * from cte where ranking<=10;





--8) Identify the museums which are open on both Sunday and Monday. Display museum name, city.


SELECT m.museum_name, m.city
FROM museums m
JOIN museum_hours mh1 ON m.museum_id = mh1.museum_id
JOIN museum_hours mh2 ON m.museum_id = mh2.museum_id
WHERE mh1.day = 'Sunday' AND mh2.day = 'Monday';



--9) How many museums are open every single day?




SELECT COUNT(*) AS museums_open_every_day
FROM (
  SELECT mh.museum_id
  FROM museum_hours mh
  GROUP BY mh.museum_id
  HAVING COUNT(DISTINCT mh.day) = 7
) AS subquery;







--10) Which are the top 5 most popular museum? (Popularity is defined based on most no of paintings in a museum)


with cte as(
select m.museum_id, count(1) as no_of_painintgs
			, rank() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			group by m.museum_id)
			select *
			from cte where rnk<=5




--11) Who are the top 5 most popular artist? (Popularity is defined based on most no of paintings done by an artist)



with cte as(
select m.artist_id, count(1) as no_of_painintgs
			, rank() over(order by count(1) desc) as rnk
			from work w
			join artist m on m.artist_id=w.artist_id
			group by m.artist_id)
			select *
			from cte where rnk<=5



--12) Display the 3 least popular canva sizes


select label,ranking,no_of_paintings
	from (
		select cs.size_id,cs.label,count(1) as no_of_paintings
		, dense_rank() over(order by count(1) ) as ranking
		from work w
		join product_size ps on ps.work_id=w.work_id
		join canvas_size cs on cs.size_id = ps.size_id
		group by cs.size_id,cs.label) x
	where x.ranking<=3;










--13) Which museum is open for the longest during a day. Dispay museum name, state and hours open and which day?


WITH OpenHours AS (
  SELECT 
    m.museum_name,
    m.state,
    mh.day_of_week,
    DATEDIFF(MINUTE, mh.open_time, mh.close_time) / 60.0 AS hours_open
  FROM museums m
  JOIN museum_hours mh ON m.museum_id = mh.museum_id
)
SELECT TOP 1 
  museum_name,
  state,
  day_of_week,
  hours_open
FROM OpenHours
ORDER BY hours_open DESC;





--14) Which museum has the most no of most popular painting style?


with pop_style as 
			(select style
			,rank() over(order by count(1) desc) as rnk
			from work
			group by style),
		cte as
			(select w.museum_id,m.name as museum_name,ps.style, count(1) as no_of_paintings
			,rank() over(order by count(1) desc) as rnk
			from work w
			join museum m on m.museum_id=w.museum_id
			join pop_style ps on ps.style = w.style
			where w.museum_id is not null
			and ps.rnk=1
			group by w.museum_id, m.name,ps.style)
	select museum_name,style,no_of_paintings
	from cte 
	where rnk=1;


--15) Identify the artists whose paintings are displayed in multiple countries



with cte as
		(select distinct a.full_name as artist,
		 w.name as painting, m.name as museum
		, m.country
		from work w
		join artist a on a.artist_id=w.artist_id
		join museum m on m.museum_id=w.museum_id)
	select artist,count(1) as no_of_countries
	from cte
	group by artist
	having count(1)>1
	order by 2 desc;











--16) Display the country and the city with most no of museums. Output 2 seperate columns to mention the city and country. 
--If there are multiple value, seperate them with comma.


	WITH CityMuseumCount AS (
    SELECT 
        city, 
        country,
        COUNT(*) AS museum_count
    FROM museum
    GROUP BY city, country
),
MaxCount AS (
    SELECT 
        MAX(museum_count) AS max_museums
    FROM CityMuseumCount
)
SELECT 
    STRING_AGG(city, ', ') AS Cities_With_Max_Museums,
    STRING_AGG(country, ', ') AS Countries_With_Max_Museums
FROM CityMuseumCount
WHERE museum_count = (SELECT max_museums FROM MaxCount);




--17) Identify the artist and the museum where the most expensive and least expensive painting is placed. Display
--the artist name, sale_price, painting name, museum name, museum city and canvas label



with cte as 
		(select *
		, rank() over(order by sale_price desc) as rnk
		, rank() over(order by sale_price ) as rnk_asc
		from product_size )
	select w.name as painting
	, cte.sale_price
	, a.full_name as artist
	, m.name as museum, m.city
	, cz.label as canvas
	from cte
	join work w on w.work_id=cte.work_id
	join museum m on m.museum_id=w.museum_id
	join artist a on a.artist_id=w.artist_id
	join canvas_size cz on cz.size_id = cte.size_id
	where rnk=1 or rnk_asc=1;










--18) Which country has the 5th highest no of paintings?

with cte as 
		(select m.country, count(1) as no_of_Paintings
		, rank() over(order by count(1) desc) as rnk
		from work w
		join museum m on m.museum_id=w.museum_id
		group by m.country)
	select country, no_of_Paintings
	from cte 
	where rnk=5;
	   	  


--19) Which are the 3 most popular and 3 least popular painting styles?

with cte as 
		(select style, count(1) as cnt
		, rank() over(order by count(1) desc) rnk
		, count(1) over() as no_of_records
		from work
		where style is not null
		group by style)
	select style
	, case when rnk <=3 then 'Most Popular' else 'Least Popular' end as remarks 
	from cte
	where rnk <=3
	or rnk > no_of_records - 3;

	   	 


--20) Which artist has the most no of Portraits paintings outside USA?. Display artist name, no of paintings and the artist nationality.


select full_name as artist_name, nationality, no_of_paintings
	from (
		select a.full_name, a.nationality
		,count(1) as no_of_paintings
		,rank() over(order by count(1) desc) as rnk
		from work w
		join artist a on a.artist_id=w.artist_id
		join subject s on s.work_id=w.work_id
		join museum m on m.museum_id=w.museum_id
		where s.subject='Portraits'
		and m.country != 'USA'
		group by a.full_name, a.nationality) x
	where rnk=1;	

