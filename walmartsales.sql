use Walmartsales;
select * from walmartsales;

-- Task 1: Identifying the Top Branch by Sales Growth Rate
with monthly_sales as (
    select Branch, DATE_FORMAT(STR_TO_DATE(Date, '%d-%m-%Y'), '%Y-%m') as month, SUM(Total) as total_sales
    from walmartsales
    group by Branch, month
),
growth_calc as (
    select Branch, month, total_sales - lag(total_sales) over (partition by Branch order by month) 
	as growth_amount
    from monthly_sales
)
select Branch, month, growth_amount
from growth_calc
where growth_amount IS NOT NULL
order by growth_amount DESC
limit 1;


-- Task 2: Finding the Most Profitable Product Line for Each Branch
WITH profit_calc as (
    SELECT Branch, `Product line`, round(SUM(`gross income`),2) as total_profit
    FROM walmartsales
    GROUP BY Branch, `Product line`
),
ranked AS (
    select *, rank() over (partition by Branch order by total_profit DESC) as rnk
    from profit_calc
)
select Branch, `Product line`, total_profit
from ranked
where rnk = 1;

-- Task 3: Analyzing Customer Segmentation Based on Spending
with customer_spending as (
    select `Customer ID`, round(SUM(Total),3) as total_spent
    from walmartsales
    group by `Customer ID`
),
percentile_split as (
    select `Customer ID`, total_spent, NTILE(4) over (ORDER BY total_spent) AS quartile
    from customer_spending
)
select `Customer ID`, total_spent,
case 
when quartile = 4 then 'High'
when quartile = 3 then 'Medium'
else 'Low'
end as spending_category
from percentile_split order by `Customer ID` asc;

-- task 4 Detecting Anomalies in Sales Transactions
WITH stats AS (
    SELECT `Product line`, round(AVG(Total),2) AS avg_sale, STDDEV(Total) AS std_sale
    FROM walmartsales
    GROUP BY `Product line`
)
select w.`Invoice ID`, w.`Product line`, w.Total, s.avg_sale, s.std_sale,
case
when w.Total > s.avg_sale + 2 * s.std_sale then 'High Anomaly'
when w.Total < s.avg_sale - 2 * s.std_sale then 'Low Anomaly'
end as anomaly_flag
FROM walmartsales w
JOIN stats s USING (`Product line`) WHERE w.Total > s.avg_sale + 2*s.std_sale OR w.Total < s.avg_sale - 2*s.std_sale;

-- Task 5: Most Popular Payment Method by City
with payment_count as (
    select City, Payment, COUNT(*) as txn_count
    from walmartsales
    group by City, Payment
),
ranked as (
    select * , RANK() OVER (partition by City order by txn_count DESC) as rnk
    FROM payment_count
)
select City, Payment as most_used_payment_method, txn_count
from ranked where rnk = 1;

-- Task 6 Monthly Sales Distribution by Gender

select DATE_FORMAT(STR_TO_DATE(Date, '%d-%m-%Y'), '%Y-%m') 
as month, Gender, round(SUM(Total),2)as total_sales
from walmartsales
group by month, Gender order by month, Gender;

-- Task 7  Best Product Line by Customer Type
with sales_data as (
    select `Customer type`, `Product line`, round(SUM(Total),3) as total_sales
    from walmartsales
    group by `Customer type`, `Product line`
),
ranked as (
    select *, rank() over (partition by `Customer type` order by total_sales DESC) as rnk
    from sales_data
)
select `Customer type`, `Product line`, total_sales
from ranked
where rnk = 1;

-- Task 8 Identifying Repeat Customers
WITH purchases AS (
    SELECT `Customer ID`, STR_TO_DATE(Date, '%d-%m-%Y') AS purchase_date, LAG(STR_TO_DATE(Date, '%d-%m-%Y')) OVER (
	PARTITION BY `Customer ID` ORDER BY STR_TO_DATE(Date, '%d-%m-%Y') ) AS prev_purchase
    FROM walmartsales
),
repeat_events AS (
    SELECT `Customer ID`
    FROM purchases
    WHERE prev_purchase IS NOT NULL AND DATEDIFF(purchase_date, prev_purchase) <= 30
)
SELECT `Customer ID`, COUNT(*) AS repeat_count_within_30_days
FROM repeat_events
GROUP BY `Customer ID`
ORDER BY repeat_count_within_30_days DESC;

-- Task 9 Finding Top 5 Customers by Sales Volume
SELECT `Customer ID`, round(SUM(Total),2) AS total_spent
FROM walmartsales
GROUP BY `Customer ID`
ORDER BY total_spent DESC
LIMIT 5;

-- Task 10 Sales Trend by Day of the Week
SELECT DAYNAME(STR_TO_DATE(Date, '%d-%m-%Y')) AS day_of_week, round(SUM(Total),3) AS total_sales
FROM walmartsales
GROUP BY day_of_week
ORDER BY  total_sales asc;












