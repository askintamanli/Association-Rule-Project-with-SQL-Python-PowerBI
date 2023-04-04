-----ONLY ORDERS WITH MORE THAN 1 PRODUCT----------
DROP TABLE IF EXISTS #filtered_OrderId
SELECT OrderId
into #filtered_OrderId
FROM [OrderItem]
GROUP BY OrderId
HAVING COUNT(ProductId) > 1

SELECT * 
FROM #filtered_OrderId 

--------TRANSACTIONS WITH FILTERED ORDER ID----------
DROP TABLE IF EXISTS #transactions
SELECT [#filtered_OrderId].OrderId,ProductName
into #transactions
FROM [#filtered_OrderId] 
INNER JOIN [OrderItem] ON [OrderItem].OrderId = [#filtered_OrderId].OrderId
INNER JOIN [Product] ON [Product].Id =[OrderItem].ProductId

SELECT * 
FROM #transactions 

-----GROUP BY FOR 2 PRODUCT AND SUPPORT VALUES OF THEESE ----------
declare @TOTAL int
select @TOTAL = COUNT(OrderId)  FROM #filtered_OrderId 

DROP TABLE IF EXISTS #table1
SELECT
PRODUCT_1,
PRODUCT_2,
COUNT(OrderId) AS TRANS_COUNT,
CAST((@TOTAL) AS FLOAT)  AS TOTAL,
COUNT(OrderId) / CAST((@TOTAL) AS FLOAT)  AS SUPPORT
into #table1
FROM
(
SELECT
a.OrderId ,
a.ProductName PRODUCT_1,
b.ProductName PRODUCT_2

FROM #transactions a,
#transactions b
WHERE a.OrderId=b.OrderId
and a.ProductName <> b.ProductName
and a.ProductName < b.ProductName
) Temp
GROUP BY PRODUCT_1,PRODUCT_2

HAVING COUNT(OrderId) > 5

SELECT * FROM #table1

-----GROUP BY FOR 2 PRODUCT AND SUPPORT VALUES OF THEESE (PRODUCT1 <--> PROUDCT2) ----------
declare @TOTAL int
select @TOTAL = COUNT(OrderId)  FROM #filtered_OrderId 

DROP TABLE IF EXISTS #table2
SELECT
PRODUCT_1,
PRODUCT_2,
COUNT(OrderId) AS TRANS_COUNT,
CAST((@TOTAL) AS FLOAT)  AS TOTAL,
COUNT(OrderId) / CAST((@TOTAL) AS FLOAT)  AS SUPPORT
into #table2
FROM
(
SELECT
a.OrderId ,
b.ProductName PRODUCT_1,
a.ProductName PRODUCT_2

FROM #transactions a,
#transactions b
WHERE a.OrderId=b.OrderId
and a.ProductName <> b.ProductName
and a.ProductName < b.ProductName
) Temp
GROUP BY PRODUCT_1,PRODUCT_2
HAVING COUNT(OrderId) > 5

SELECT * FROM #table2

SELECT *  
FROM (SELECT * FROM #table1 UNION SELECT * FROM #table2 ) AS #table3


----------------------------  COUNT VALUES FOR EACH PRODUCT----------------------
DROP TABLE IF EXISTS #count_values
SELECT ProductName, COUNT(#filtered_OrderId.OrderId) AS CNT
into #count_values
FROM [#filtered_OrderId] 
INNER JOIN [OrderItem] ON [OrderItem].OrderId = [#filtered_OrderId].OrderId
INNER JOIN [Product] ON [Product].Id =[OrderItem].ProductId
GROUP BY ProductName

SELECT * FROM #count_values


------------------------- ONLY COUNT OF PRODUCT_1 --------------------
DROP TABLE IF EXISTS #main_table
SELECT *
into #main_table
FROM (SELECT * FROM #table1 UNION SELECT * FROM #table2) AS #table3
INNER JOIN #count_values ON [#count_values].ProductName = [#table3].PRODUCT_1

SELECT * FROM #main_table

----------------------------MAIN TABLE WITH COUNT OF PROUDCT1 AND PRODUCT2 -------------------------------
DROP TABLE IF EXISTS #insert_main_table
SELECT 
PRODUCT_1, 
PRODUCT_2, 
TRANS_COUNT, 
[#main_table].CNT AS COUNT_PRODUCT_1,
[#count_values].CNT AS COUNT_PRODUCT_2,
TOTAL,
SUPPORT, 
(CAST((TRANS_COUNT) AS FLOAT) /[#main_table].CNT) / ([#count_values].CNT / TOTAL)  AS LIFT,
CAST((TRANS_COUNT) AS FLOAT) /[#main_table].CNT AS CONFIDENCE

into #insert_main_table
FROM #main_table
INNER JOIN #count_values ON [#count_values].ProductName = [#main_table].PRODUCT_2

SELECT * 
FROM #insert_main_table
WHERE SUPPORT > 0.01

----------CREATE TABLE------------
CREATE TABLE AssociationRules (
    PRODUCT_1 varchar(255),
    PRODUCT_2 varchar(255),
    TRANS_COUNT int,
    COUNT_PRODUCT_1 int,
    COUNT_PRODUCT_2  int,
	TOTAL   int,
	SUPPORT  FLOAT,
	CONFIDENCE  FLOAT,
	LIFT  FLOAT,
);

-----------INSERT TO TABLE---------------
INSERT INTO AssociationRules (PRODUCT_1, PRODUCT_2, TRANS_COUNT, COUNT_PRODUCT_1, COUNT_PRODUCT_2, TOTAL,SUPPORT,CONFIDENCE,LIFT)
SELECT  PRODUCT_1, PRODUCT_2, TRANS_COUNT, COUNT_PRODUCT_1, COUNT_PRODUCT_2, TOTAL,SUPPORT,CONFIDENCE,LIFT
FROM    #insert_main_table  
