SELECT*
FROM [Sales].[Customer]

SELECT *
FROM [Sales].[SalesOrderHeader]

SELECT *
FROM [Sales].[SalesOrderDetail]

SELECT *
FROM [Production].[Product]

SELECT *
FROM[Person].[Person]




--Joining salesorderheader,salesorderdetail for rfm analysis
SELECT 
    a.CustomerID,
    a.SalesOrderNumber,
    a.OrderDate,
    b.ProductID,
    b.OrderQty,
    b.UnitPrice,
    b.LineTotal
INTO #Rfm_bse
FROM[Sales].[SalesOrderHeader] a
INNER JOIN[Sales].[SalesOrderDetail] b 
ON a.[SalesOrderID] = b.[SalesOrderID]


SELECT * FROM #Rfm_bse

SELECT 
  MAX(Orderdate) AS most_recent_Orderdate
FROM #Rfm_bse

--declare today's date (Date of my analysis)
DECLARE @today_date AS DATE = '2014-07-31'


SELECT MAX(OrderDate),
      MIN(OrderDate)
FROM #Rfm_bse


--Recency test on each customer by the orderdate
SELECT
    CustomerID AS Customer_Id, ProductID,
    MAX(Orderdate) as most_recent_orderdate,
    MIN(Orderdate) as min_orderdate
FROM 
   #Rfm_bse
GROUP BY 
    CustomerID,ProductID



--Recency score based on today's date i.e difference btw today's date and the Max(orderdate) by each customer
SELECT
    CustomerID AS Customer_Id, ProductID
    ,MAX(Orderdate) as most_recent_Orderdate
    ,MIN(Orderdate) as last_past_orderdate
    ,DATEDIFF(Day, MAX(Orderdate), '2014-07-31') AS recency_value
FROM 
    #Rfm_bse
GROUP BY 
    CustomerID, ProductID

--frequency value by customer i.e , how many purchases each cx has made 
SELECT
    CustomerID AS Customer_Id, ProductID,
    MAX(Orderdate) as most_recent_Orderdate,
    --MIN(Orderdate) as last_past_orderdate,
    DATEDIFF(Day, MAX(Orderdate),'2014-07-31' ) AS recency_value,
    COUNT(SalesOrderNumber) as frequency_value
FROM 
   #Rfm_bse
GROUP BY 
    CustomerID,ProductID


--to get the monetary VALUE
SELECT
    CustomerID AS Customer_Id, ProductID,
    MAX(Orderdate) as most_recent_Orderdate,
    DATEDIFF(Day, MAX(Orderdate), '2014-07-31') AS recency_value,
    COUNT(SalesOrderNumber) as frequency_value,
    SUM([LineTotal]) as monetary_value 
 INTO #base_rfm0
 FROM 
    #Rfm_bse
 GROUP BY  CustomerID, ProductID
 ORDER BY monetary_value DESC


SELECT * FROM #base_rfm0

--Ranking the rfm by percentages
SELECT
    Customer_id, ProductID
    ,recency_value
    ,frequency_value
    ,monetary_value
    ,NTILE (5) OVER (ORDER BY recency_value DESC) as R 
    ,NTILE (5) OVER (ORDER BY frequency_value ASC) as F
    ,NTILE (5) OVER (ORDER BY monetary_value ASC) as M 
INTO #Rfm_table00
FROM #base_rfm0

SELECT * FROM #Rfm_table00

--creating rfm_scores

SELECT 
    Customer_id,ProductID
    ,recency_value
    ,frequency_value
    ,monetary_value
    ,NTILE (5) OVER (ORDER BY recency_value DESC) as R 
    ,NTILE (5) OVER (ORDER BY frequency_value ASC) as F
    ,NTILE (5) OVER (ORDER BY monetary_value ASC) as M 
    ,CONCAT( R,  F,  M) AS rfm_point
    ,(R + F + M) / 3 as average_rfm
INTO #Basementt
FROM #Rfm_table00
    
SELECT * FROM #Basementt


--SEGMENTING OUR CUSTOMERS BASED ON THEIR RFM  
SELECT *,
CASE 
   WHEN rfm_point in ('111','112','121','122','123','131','132','211','141','151') THEN 'Can_lose_customer'
   WHEN rfm_point in ('133','134','143','244','334','343','344','144','212','114','154','155','144','214','215','115','113','114') THEN 'Cannot_lose_customer'
   WHEN rfm_point in ('512','513','511','513','514','422','421','412','411','311')THEN 'New_customers'
   WHEN rfm_point in ('255','254','245','244','253','252','243','242','235','234','225','224','153','152','145','143','142','135','134','133','125','124') THEN 'Potential_churn'
   when rfm_point in ('535','534','443','434','343','334','325','324') THEN 'Need_Attention'
   when rfm_point in ('332','322','231','241','251','233','232','223','222','212','211','331','321','312','221','213','231','241','251') THEN 'hibenating_customer'
   WHEN rfm_point in ('525','524','523','522','521','515','514','513','425','424','413','414','415','315','314','313') THEN 'Promising'
   WHEN rfm_point in ('553','551','552','541','542','443','533','532','531','452','451','442','441','431','453','433','432','423','353','352','351','342','341','333','323') THEN 'Potential loyalist'
   WHEN rfm_point in ('543','435','444','355','354','345','344','335') THEN 'loyal_customer'
   WHEN rfm_point in ('555','554','544','545','454','455','445') THEN 'Champion_customers'
END AS Customer_Segmentation 
INTO #segmentation_cx
FROM #Basementt
 
 select *
 FROM #segmentation_cx

--select a. * ,
--       b.productID as product1,
--       b.product2,
--       b.purchase_frequency
--FROM
--   #segmentation_cx a
--INNER JOIN #purchase_together b
--on a.productID = b.productID

SELECT * FROM #segmentation_cx


--Question 2 - Query for customers at risk of churning]
SELECT *
FROM #segmentation_cx
WHERE Customer_Segmentation = 'potential_churn';

--TABLE 2 for Cx Retention 
SELECT 
    a.CustomerID,
    a.SalesOrderID,
    a.SalesOrderNumber,
    b.ProductID,
    c.[Name],
    c.[SafetyStockLevel],
    d.[SalesLastYear],
    d.[SalesYTD],
    e.[Title],
    e.[FirstName],
    e.[MiddleName],
    e.[LastName]
INTO #Rfm_base0
FROM[Sales].[SalesOrderHeader] a
INNER JOIN[Sales].[SalesOrderDetail] b 
ON a.[SalesOrderID] = b.[SalesOrderID]
INNER JOIN [Production].[Product] c 
ON b.ProductID = c.ProductID
INNER JOIN [Sales].[SalesPerson] d
ON a.[TerritoryID] = d.[TerritoryID]
INNER JOIN [Person].[Person] e
ON d.[BusinessEntityID] = e.[BusinessEntityID]
--WHERE SafetyStockLevel = 800

SELECT* FROM #Rfm_base0


SELECT 
    a.CustomerID,
    a.SalesOrderID,
    a.SalesOrderNumber,
    b.ProductID,
    c.[Name],
    c.[SafetyStockLevel],
    d.[SalesLastYear],
    d.[SalesYTD],
    e.[Title],
    e.[FirstName],
    e.[MiddleName],
    e.[LastName]
--INTO #Rfm_base0
FROM [Sales].[SalesOrderHeader] a
INNER JOIN[Sales].[SalesOrderDetail] b 
ON a.[SalesOrderID] = b.[SalesOrderID]
INNER JOIN [Sales].[SalesPerson] d
ON a.[TerritoryID] = d.[TerritoryID]
INNER JOIN [Person].[Person] e
ON d.[BusinessEntityID] = e.[BusinessEntityID]
FULL JOIN [Production].[Product] c 
ON b.ProductID = c.ProductID










--#3 Product frequently purchased together
select * into #Rfm_bse2 from #Rfm_bse

--WITH cte_rfm1
--AS ()
    

--SELECT a.*,
--       b.*
--from #purchase_togethers as a
--INNER JOIN #segmentation_cx as b
--ON a.CustomerID = b.Customer_Id




--SELECT *
--FROM cte_rfm1;

--select * into #Rfm_base2 from #Rfm_base1
--select * from #Rfm_base0
--select * from #Rfm_bse2

SELECT a.CustomerID,
       a.ProductID,                          
       b.ProductID,
       COUNT(*) AS purchase_frequency       
FROM #Rfm_base0 a
INNER JOIN #Rfm_bse2 b
ON a.CustomerID = b.CustomerID
AND a.ProductID < b.ProductID
GROUP BY a.productID, b.productID, a.CustomerID
ORDER BY purchase_frequency



-- orderheader,PhoneNumber,EmailAddress,Personaddress,country
SELECT 
     a.CustomerID,
     c.[PhoneNumber],
     d.[EmailAddress],
     f.[AddressLine1],
     f.[AddressLine2],
     f.[City],
     f.[PostalCode],
     f.[StateProvinceID]
FROM [Sales].[SalesOrderHeader] a 
INNER JOIN [Sales].[SalesPerson] b 
ON a.[TerritoryID] = b.[TerritoryID]
INNER JOIN[Person].[PersonPhone] c 
ON b.[BusinessEntityID] = c.[BusinessEntityID]
INNER JOIN [Person].[EmailAddress] d 
ON c.[BusinessEntityID] = d.[BusinessEntityID] 
INNER JOIN[Person].[BusinessEntityAddress] e
ON d.[BusinessEntityID] = e.[BusinessEntityID]
INNER JOIN[Person].[Address] f
ON e.[AddressID] = f.[AddressID]





