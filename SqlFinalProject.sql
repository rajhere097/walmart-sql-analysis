-- Sql Final Project

/* Task 1: Identifying the Top Branch by Sales Growth Rate (6 Marks)
Walmart wants to identify which branch has exhibited the highest sales growth over time. Analyze the total sales
for each branch and compare the growth rate across months to find the top performer.
*/
WITH monthly_sales AS (
    SELECT 
        branch, 
        DATE_FORMAT(sales_date, '%b') AS Months, 
        ROUND(SUM(total), 2) AS Total_Sales 
    FROM 
        walmartsales
    GROUP BY 
        branch, Months
),
sales_growth AS (
    SELECT 
        branch, 
        Months, 
        Total_Sales, 
        LAG(Total_Sales, 1) OVER (PARTITION BY branch ORDER BY Months) AS Previous_Month_Sales,
        ROUND(
            (
                (Total_Sales - LAG(Total_Sales, 1) OVER (PARTITION BY branch ORDER BY Months))
                / LAG(Total_Sales, 1) OVER (PARTITION BY branch ORDER BY Months)
            ) * 100, 2
        ) AS Growth_Rate
    FROM 
        monthly_sales
),
avg_growth AS (
    SELECT 
        branch,
        ROUND(AVG(Growth_Rate), 2) AS Avg_Growth_Rate
    FROM 
        sales_growth
    WHERE 
        Growth_Rate IS NOT NULL
    GROUP BY 
        branch
)
SELECT 
    *
FROM 
    avg_growth
ORDER BY 
    Avg_Growth_Rate DESC
LIMIT 1;

/* Task 2: Finding the Most Profitable Product Line for Each Branch (6 Marks)
Walmart needs to determine which product line contributes the highest profit to each branch.The profit margin
should be calculated based on the difference between the gross income and cost of goods sold.
*/

select * from walmartsales;

select branch, `product line`, round(sum(cogs- `gross income`),2) as Total_Profit,
round(round(sum(cogs- `gross income`),2)*100/sum(cogs),2) from walmartsales
group by branch, `product line`
order by branch, Total_Profit desc;

with Profit as
(select branch, `product line`, round(sum(cogs- `gross income`),2) as Total_Profit,
round(round(sum(cogs- `gross income`),2)*100/sum(cogs),2) as Profit_margin,
ROW_NUMBER() OVER (PARTITION BY branch ORDER BY round(sum(cogs - `gross income`), 2) DESC) AS Rn
from walmartsales
group by branch, `product line`)
select * from Profit
where Rn = 1;

/* Task 3: Analyzing Customer Segmentation Based on Spending (6 Marks)
Walmart wants to segment customers based on their average spending behavior. Classify customers into three
tiers: High, Medium, and Low spenders based on their total purchase amounts.
*/

select `customer id`, round(sum(total),2) as Total_Spent,
case
when round(sum(total),2) >= 20000 then 'High'
when round(sum(total),2) >= 10000 then 'Medium' else 'Low'
end as Classify
from walmartsales
group by `customer id`
order by `customer id`, Total_Spent desc;


-- 
with Profit as
(select `customer id`, round(sum(total),2) as Total_Spent,
row_number() over(partition by `customer id` order by sum(total) desc) as Rn,
case
when round(sum(total),2) >= 20000 then 'High'
when round(sum(total),2) >= 10000 then 'Medium' else 'Low'
end as Classify
from walmartsales
group by `customer id`
order by `customer id`, Total_Spent desc)
select * from profit
where Classify = 'High';

/* Task 4: Detecting Anomalies in Sales Transactions (6 Marks)
Walmart suspects that some transactions have unusually high or low sales compared to the average for the
product line. Identify these anomalies. */

SELECT 
    `Customer ID`,
    `Product line`,
    Total,
    (SELECT AVG(Total) 
     FROM walmartsales AS ws2 
     WHERE ws2.`Product line` = ws1.`Product line`) AS avg_total_by_product,
     
    CASE
        WHEN Total >= 1.5 * (
            SELECT AVG(Total)
            FROM walmartsales AS ws2 
            WHERE ws2.`Product line` = ws1.`Product line`
        ) THEN 'High Anomaly'
        
        WHEN Total <= 0.5 * (
            SELECT AVG(Total)
            FROM walmartsales AS ws2 
            WHERE ws2.`Product line` = ws1.`Product line`
        ) THEN 'Low Anomaly'
        
        ELSE 'Normal'
    END AS Anomaly_Status

FROM 
    walmartsales AS ws1;
    
    
    -- 
    
    SELECT 
    `Customer ID`,
    `Product line`,
    Total,
    (SELECT AVG(Total) 
     FROM walmartsales AS ws2 
     WHERE ws2.`Product line` = ws1.`Product line`) AS avg_total_by_product,
     
    CASE
        WHEN Total >= 1.5 * (
            SELECT AVG(Total)
            FROM walmartsales AS ws2 
            WHERE ws2.`Product line` = ws1.`Product line`
        ) THEN 'High Anomaly'
        
        WHEN Total <= 0.5 * (
            SELECT AVG(Total)
            FROM walmartsales AS ws2 
            WHERE ws2.`Product line` = ws1.`Product line`
        ) THEN 'Low Anomaly'
        
        ELSE 'Normal'
    END AS Anomaly_Status

FROM 
    walmartsales AS ws1

WHERE
    CASE
        WHEN Total >= 1.5 * (
            SELECT AVG(Total)
            FROM walmartsales AS ws2 
            WHERE ws2.`Product line` = ws1.`Product line`
        ) THEN 'High Anomaly'
        
        WHEN Total <= 0.5 * (
            SELECT AVG(Total)
            FROM walmartsales AS ws2 
            WHERE ws2.`Product line` = ws1.`Product line`
        ) THEN 'Low Anomaly'
        
        ELSE 'Normal'
    END IN ('High Anomaly', 'Low Anomaly');
    




/* Task 5: Most Popular Payment Method by City (6 Marks)
Walmart needs to determine the most popular payment method in each city to tailor marketing strategies */

With Top_Payment_Method as
(select city, payment, count(*) as Payment_Method_count,
row_number() over (partition by city order by count(*) desc) as rn
from walmartsales
group by city, payment
order by city, Payment_Method_count desc)
select * from Top_Payment_Method
where rn = 1;

/* Task 6: Monthly Sales Distribution by Gender (6 Marks)
Walmart wants to understand the sales distribution between male and female customers on a monthly basis */

select * from walmartsales;
select gender, date_format(sales_date, '%b') as Months, round(sum(total),2) as TotalSales
from walmartsales
group by gender, Months
order by gender, TotalSales desc;

/*Task 7: Best Product Line by Customer Type (6 Marks)
Walmart wants to know which product lines are preferred by different customer types(Member vs. Normal).
 */
With Best_Productline as
(select `Customer type`, `Product line`, round(avg(total),2) as AvgTotal,
rank() over(partition by `Customer type` order by avg(total) desc) as RankCustomerType
from walmartsales
group by `Customer type`, `Product line`)
select * from Best_Productline
where RankCustomerType = 1;

/* Task 8: Identifying Repeat Customers (6 Marks)
Walmart needs to identify customers who made repeat purchases within a specific time frame (e.g., within 30
days). */

select date_format(sales_date, '%b') as Months, `customer id`, count(`invoice id`) as TransactionCount from walmartsales
group by Months, `customer id`
having Months = 'Mar'
order by TransactionCount desc;

/* Task 9: Finding Top 5 Customers by Sales Volume (6 Marks)
Walmart wants to reward its top 5 customers who have generated the most sales Revenue.
*/

with Top_5_Customers as
(select `customer id`, round(sum(`unit price` * quantity),2) as Revenue,
rank() over(order by sum(`unit price` * quantity) desc) as Ranking
from walmartsales
group by `customer id`)
select * from Top_5_Customers
where ranking in (1,2,3,4,5);

/* Task 10: Analyzing Sales Trends by Day of the Week (6 Marks)
Walmart wants to analyze the sales patterns to determine which day of the week
brings the highest sales. */

select dayname(sales_date) as NameofDay, round(sum(total),2) as TotalSales from walmartsales
group by NameofDay
order by TotalSales desc;