# 📊 Retail Sales Data Warehouse & Profitability Analysis

An end-to-end data analysis project that takes raw retail supply-chain order data, cleans and models it into a proper relational structure using SQL, and builds an interactive Power BI dashboard to find out where the business is actually making money — and where it's quietly losing it.

---

## 🎯 Objective

A single flat orders file hides more than it shows — margins, discount impact, and regional performance only become visible once the data is modeled properly. The goal of this project was to:

- Take a raw retail orders dataset and load it into PostgreSQL
- Split it into a proper relational schema (customers, products, sales)
- Clean and validate every table using SQL — types, duplicates, nulls, and business rules
- Perform EDA in SQL to understand profit drivers
- Build an interactive Power BI dashboard for year/region/sub-category drill-downs
- Do a root-cause comparison between the worst-performing segment and the best-performing one

---

## 🗂️ Dataset

Raw dataset: `Retail-Supply-Chain-Sales-Dataset.csv` — order-level retail transactions with these fields:

| Column | Description |
|---|---|
| Row ID, Order ID | Record and order identifiers |
| Order Date, Ship Date | Transaction and shipping dates |
| Ship Mode | Shipping method used |
| Customer ID, Customer Name, Segment | Customer details |
| Country, City, State, Postal Code, Region | Location |
| Retail Sales People | Sales rep assigned |
| Product ID, Category, Sub-Category, Product Name | Product details |
| Returned | Whether the order was returned |
| Sales, Quantity, Discount, Profit | Transaction metrics |

---

## 🛠️ Tools Used

- **PostgreSQL** — data loading, cleaning, modeling, and EDA (100% SQL, no Python/pandas in this one)
- **Excel/CSV** — raw data source
- **Power BI** — interactive dashboard

---

## 🧹 Data Cleaning Process (all in SQL)

### 1. Load and split into a relational schema
The raw CSV was loaded into a single staging table (`orders`) with every column as `VARCHAR` to avoid import errors from `$`, commas, or malformed dates. From there, it was split into 3 proper tables using `CREATE TABLE ... AS SELECT`:

- **`customers`** — customer_id, customer_name, segment, country, city, state, postal_code, region
- **`products`** — product_id, category, sub_category, product_name
- **`sales`** — order_id, order_date, ship_date, ship_mode, customer_id, product_id, retail_sales_people, returned, sales, quantity, discount, profit

### 2. Cleaning `customers`
- Fixed `postal_code` from text to `NUMERIC`
- Checked `customer_id` for duplicates and confirmed uniqueness
- Standardized every text column with `TRIM()` to catch stray whitespace
- Checked every column for nulls
- Used a window function (`COUNT(*) OVER (PARTITION BY ...)`) to catch full-row duplicates, then rebuilt as `customers_clean` with `DISTINCT`
- Added a primary key constraint on `customer_id`
- Applied consistent formatting — `INITCAP()` on `customer_name` and `city` so casing is uniform

### 3. Cleaning `products`
- Checked `product_id` for duplicates
- Standardized `product_id`, `category`, `sub_category`, `product_name` with `TRIM()`/`INITCAP()` checks
- Fixed inconsistent casing in `product_name`
- Checked every column for nulls, removed duplicates into `products_clean`
- **Key finding:** `product_id` wasn't actually a valid primary key — the same ID showed up attached to multiple *different* product names. Instead of forcing a bad key, I kept `product_id` as a regular column and added a surrogate `product_key` (`SERIAL`) as the real primary key.

### 4. Cleaning `sales`
- Cast `order_date`/`ship_date` to proper `DATE`, and `sales`/`quantity`/`discount`/`profit` to `NUMERIC`
- Standardized text fields with `TRIM()`
- Checked every column for nulls, removed duplicates into `sales_clean`
- **Business rule checks:** flagged orders where `order_date > ship_date` (logically impossible), and checked for `sales <= 0`, `quantity <= 0`, `discount < 0`, `profit <= 0`
- Linked `sales_clean` back to `products_clean` via the new `product_key` (since `product_id` alone wasn't reliable)
- Added a `loss` column that isolates negative-profit transactions for easier analysis

---

## 🔍 Exploratory Data Analysis (EDA) — in SQL

- Total profit across all orders
- Month/year-wise profit trend
- Sales and profit by sub-category
- Profit by region
- Discount vs. profit relationship
- Profit by sales rep
- Profit by customer, ranked

---

## 📊 The Dashboard

![Dashboard Overview](Images/dashboard_overview.png)

The dashboard has slicers for **Year, Region,** and **Sub-Category**, five KPI cards at the top, and four charts: Discount vs Profit (scatter), Sales vs Profit by Sub-Category, Profit by Region, and Monthly Sales & Profit trend.

### Overall picture (no filters applied)

| Metric | Value |
|---|---|
| Total Sales | 2.30M |
| Total Profit | 286.41K |
| Total Orders | 5K |
| Profit Margin | **12.47%** |
| Return Rate | 5.9% |

West is the strongest-performing region by profit (106K), followed by East (65K), Central (60K), and South (55K).

---

## 🔎 Root Cause Analysis

The overview shows a healthy 12.47% margin overall, but that number hides some very different stories underneath. Drilling into specific year/region/sub-category combinations tells a much sharper story.

### Biggest loss: Central → 2014 → Binders

![Root Cause - Loss](Images/root_cause_loss.png)

| Metric | Value |
|---|---|
| Total Sales | 6.15K |
| Total Profit | -3.72K |
| Total Orders | 66 |
| Profit Margin | **-60.48%** |
| Return Rate | 9.1% |

This segment is deeply unprofitable — losing money on every dollar of sales. The Discount vs Profit scatter shows why: discounts in this segment cluster around **70-80%**, and profit craters as discount rises. There's a sharp loss spike in **July 2014 (-4.3K)**.

### Biggest profit: West → 2017 → Copiers

![Root Cause - Profit](Images/root_cause_profit.png)

| Metric | Value |
|---|---|
| Total Sales | 21.34K |
| Total Profit | 9.74K |
| Total Orders | 7 |
| Profit Margin | **45.65%** |
| Return Rate | 14.3% |

The same business, a completely different outcome — discounts here stay low (around **0.2**), and profit margin is nearly **46%**. Sales and profit peak together in **March 2017**.

**Takeaway:** the difference between a -60% margin and a +46% margin isn't the product category or the region alone — it's **discount depth**. Heavy discounting (70-80%) on Binders in Central during 2014 erased all profit and pushed the segment deep into loss, while disciplined, low discounting on Copiers in West during 2017 produced the strongest margin in the dataset.

---

## 💡 Key Insights

- Overall the business runs a healthy 12.47% margin, but that average hides segments losing over 60%.
- **Discount depth is the single biggest driver of profit outcome** — the Discount vs Profit scatter shows a consistent pattern: profit collapses as discount rises past roughly 50-60%.
- West is the most profitable region overall, and its 2017 Copiers performance shows what "healthy" pricing discipline looks like.
- Central's 2014 Binders performance shows what happens when discounting isn't controlled — a near-total wipeout of profit despite steady order volume (66 orders).

---

## ✅ Recommendations

- Cap discounts on low-margin sub-categories like Binders — anything above ~50% should require explicit approval.
- Study West's 2017 pricing approach on Copiers and see if the same discount discipline can be applied to other high-value sub-categories.
- Build a discount-threshold alert into future dashboards so segments crossing into loss territory get flagged early, not discovered after the fact.

---

## 📁 Repository Structure

```
Retail Sales Data Warehouse/
│
├── Images/
│   ├── dashboard_overview.png
│   ├── root_cause_loss.png
│   └── root_cause_profit.png
│
├── Power BI/
│   └── retail_sales_analysis.pbix
│
├── SQL/
│   └── retail_sales_cleaning_eda.sql
│
├── Retail-Supply-Chain-Sales-Dataset.csv
└── README.md
```

## 🚀 How to Reproduce

1. Create a PostgreSQL database and open `SQL/retail_sales_cleaning_eda.sql` in pgAdmin's Query Tool.
2. Update the file path in the `COPY` statement to point to your local copy of `Retail-Supply-Chain-Sales-Dataset.csv`.
3. Run the script top to bottom — it loads the raw data, builds the relational schema, cleans all 3 tables, and runs the EDA queries.
4. Open `Power BI/retail_sales_analysis.pbix` in Power BI Desktop, connect it to your database (or the cleaned tables), and explore the dashboard.

---

## 🔗 Connect

- LinkedIn: [linkedin.com/in/saitejabonagiri](https://linkedin.com/in/saitejabonagiri/)
- GitHub: [github.com/Saiteja911-blip](https://github.com/Saiteja911-blip/)
