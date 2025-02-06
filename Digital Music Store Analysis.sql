/*
 
Digital Music Store Analysis
Skills used: Joins, Subqueries, Windows Functions, Aggregate Functions, CTEs, Case

*/


-- Top 10 best selling artists
SELECT ar.ArtistId, ar.Name, SUM(inl.Quantity * inl.UnitPrice) AS Profit
FROM invoiceline inl
LEFT JOIN track t
	ON inl.TrackId = t.TrackId
LEFT JOIN album a
	ON t.AlbumId = a.AlbumId
LEFT JOIN artist ar
	ON a.ArtistId = ar.ArtistId
GROUP BY ar.ArtistId, ar.Name
ORDER BY Profit DESC
LIMIT 10
;

-- Revenue of Artists filter by Genre
WITH profit_by_artist AS
(SELECT inl.UnitPrice * inl.Quantity as tProfit, ar.ArtistId,
ar.Name as Artist, g.Name as Genre
FROM invoiceline inl
LEFT JOIN track t
	ON inl.TrackId = t.TrackId
LEFT JOIN album a
	ON t.AlbumId = a.AlbumId
LEFT JOIN artist ar
	ON a.ArtistId = ar.ArtistId
LEFT JOIN genre g
	ON t.GenreId = g.GenreId)
SELECT Genre, ArtistId, Artist, SUM(tProfit) as Profit
FROM profit_by_artist
GROUP BY Genre, ArtistId, Artist
ORDER BY Genre, Profit DESC;

-- Top 10 albums by sales
SELECT a.AlbumId, a.Title as Album_Name,
SUM(inl.UnitPrice * inl.Quantity) AS Profit,
COUNT(Quantity) AS Quantity
FROM invoiceline inl
LEFT JOIN invoice inv
	ON inl.InvoiceId = inv.InvoiceId
LEFT JOIN track t
	ON inl.TrackId = t.TrackId
LEFT JOIN album a
ON t.AlbumId = a.AlbumId
GROUP BY a.AlbumId, a.Title
ORDER BY Profit DESC
LIMIT 10
;


-- Top 10 city corresponds to the best customers?
SELECT BillingCity,
BillingCountry,
SUM(Total) AS TotalPurchase
FROM invoice
GROUP BY BillingCity, BillingCountry
ORDER BY SUM(Total) DESC
LIMIT 10
;

-- Top 10 countries have the highest number of invoices
SELECT BillingCountry,
COUNT(InvoiceLineId) AS Number_of_Invoices
FROM invoice inv
JOIN invoiceline inl
	ON inv.InvoiceId = inl.InvoiceId
GROUP BY BillingCountry
ORDER BY COUNT(InvoiceLineId) DESC
LIMIT 10
;


-- Top 10 best customer (customer who spent the most money).
SELECT inv.CustomerId,
CONCAT_WS(' ', FirstName, LastName) AS FullName,
SUM(Total) AS Total_Purchase
FROM invoice inv
LEFT JOIN customer cus
	ON inv.CustomerId = cus.CustomerId
GROUP BY inv.CustomerId
ORDER BY SUM(Total) DESC, CONCAT_WS(' ', FirstName, LastName)
LIMIT 10
;


-- List the customers from USA that have an order more than 8$
SELECT CustomerId, 
CONCAT_WS(' ' , FirstName, LastName) AS FullName,
City, State, Country
FROM customer
WHERE CustomerId IN (
SELECT CustomerId
FROM invoice
WHERE BillingCountry = 'USA'
AND Total > 8)
ORDER BY CustomerId;


-- If customers have spend more than $40 or $45, give a 5% or 10% discount on their next order, respectively
SELECT inv.CustomerId,
CONCAT_WS(' ', FirstName, LastName) AS FullName,
SUM(Total) AS Total_Purchase,
CASE  
	WHEN SUM(Total) > 45 THEN '10% Discount'
    WHEN SUM(Total) > 40 THEN '5% Discount'
    ELSE 'No Discount'
END AS Discount
FROM invoice inv
JOIN customer cus
	ON inv.CustomerId = cus.CustomerId
GROUP BY inv.CustomerId
;


-- Top 3 genres in each country
WITH TP AS
(SELECT BillingCountry, g.Name AS Genre,
SUM(inl.UnitPrice * inl.Quantity) AS Profit
FROM invoice inv
JOIN invoiceline inl
	ON inv.InvoiceId = inl.InvoiceId
JOIN track tr
	ON inl.TrackId = tr.TrackId
JOIN genre g
	ON tr.GenreId = g.GenreId
GROUP BY BillingCountry, g.Name),
rank_no AS
(
SELECT *, 
DENSE_RANK () OVER(PARTITION BY BillingCountry ORDER BY Profit DESC) AS ranking
from TP
)
SELECT *
FROM rank_no 
WHERE ranking <= 3
;


-- Report the support representative for each customer.
SELECT CustomerId,
CONCAT_WS(' ', c.FirstName, c.LastName) AS Customer,
CONCAT_WS(' ', e.FirstName, e.LastName) AS Employee
FROM customer c
JOIN employee e
	ON c.SupportRepId = e.EmployeeId
ORDER BY CustomerId
;

-- List the employees hierarchy of the Store 
WITH RECURSIVE emp_hierarchy AS
	(SELECT EmployeeId, CONCAT_WS(' ', FirstName, LastName) AS Employee, ReportsTo, Title, 1 as lvl
    FROM employee
    WHERE EmployeeId = 1
    UNION
    SELECT E.EmployeeId, CONCAT_WS(' ', E.FirstName, E.LastName), E.ReportsTo, E.Title, H.lvl + 1 AS Level
    FROM emp_hierarchy H
    JOIN employee E
		ON H.EmployeeId = E.ReportsTo
	)
SELECT * FROM emp_hierarchy;



