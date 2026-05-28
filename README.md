# E-commerce Sales Analytics — Handmade Business (Poland)

End-to-end data project built for a real Polish e-commerce business selling handmade soap rose and candy arrangements across multiple sales channels. The project covers data collection, pipeline building, database design, and a Power BI dashboard with actionable business insights.

---

## Project Overview

The business operates across two types of channels — local marketplaces (multiple accounts) and proprietary websites — generating 3,000+ orders over 2+ years. The core challenge was consolidating fragmented data from different sources and formats into a single analytical layer.

**Goals:**
- Build a centralized database integrating all sales channels
- Clean and standardize raw, inconsistent source data
- Deliver a Power BI dashboard with insights that directly impact business decisions around marketing, production planning, and pricing strategy

---

## Tech Stack

- **Python** — data extraction, email parsing, data loading
- **PostgreSQL** — database design, data cleaning, transformation, analytical queries
- **Power BI** — dashboard and visualization layer

---

## Database Architecture

The database is split into three schemas:

**Raw schema** — 4 source tables preserving original data as ingested:
- Allegro API export
- Allegro email confirmations (parsed from order confirmation emails)
- Empik API export
- Websites orders

**Staging schema** — cleaned and normalized raw tables.

**Clean schema** — normalized, analysis-ready tables:
- `customers` — deduplicated buyer records across all channels
- `orders` — one row per order with standardized fields
- `products` — product catalog
- `order_items` — line items per order
- `fact_orders` — flat analytical table joining all dimensions, used as the primary source for Power BI

---

## Dashboard Structure
<img width="2075" height="1200" alt="dashboard_page-0001" src="https://github.com/user-attachments/assets/50fff420-10c3-434b-98f2-ebb733164396" />
<img width="2075" height="1200" alt="dashboard_page-0002" src="https://github.com/user-attachments/assets/0fb2db73-4cfa-4eb3-ae4e-e66261db83d5" />

### Page 1 — Business Overview

Key KPIs: Total Revenue, Total Orders, Unique Customers, Average Order Value

Main findings:
- **Business is highly seasonal** — revenue peaks align with Valentine's Day (February 14), Women's Day (March 8), and May (Mother's Day + First Communion, which is a major gifting occasion in Poland)
- **75% of sales come from Allegro**, reflecting both platform trust and its dominant traffic in the Polish market
- **Only 4% repeat customer rate** — consistent with gifting niche behaviour where purchases are occasion-driven rather than habitual
- **Top price segment is 200–350 PLN**, followed by 0–200 PLN; the 350+ PLN premium segment has the smallest share
- **Monday is the peak order day** — orders gradually decline through the week, hit a minimum on Friday, and begin recovering on Saturday; this pattern is consistent year-round

### Page 2 — Holiday Insights

Key KPIs: Share of annual revenue from holiday periods (32%), average days before holiday when order is placed (4 days)

Main findings:
- **Orders peak 3–5 days before every major holiday** across all three events — customers order at the last viable moment given delivery lead times, with almost no early planning behaviour
- **Average order value does not spike significantly before holidays** — customers do not shift to premium products under time pressure; the 200–350 PLN segment remains dominant
- **Small but consistent premium shift on holidays** — the 350+ PLN segment shows a slightly higher share before holidays compared to regular days, most visible around Women's Day
- **May price distribution differs** — higher share of 0–200 PLN orders, likely driven by First Communion which brings a different buyer profile alongside Mother's Day
- **Valentine's Day is the single largest revenue event**, followed by May and then Women's Day
- **Repeat customers are slightly more common around holidays (7% vs 4% baseline)** — suggests retargeting campaigns before key dates could be effective

---

## Key Business Recommendations

1. **Production planning:** Scale capacity starting 7–8 days before each major holiday; the 3–5 day ordering window means demand arrives in a very compressed timeframe
2. **Marketing timing:** Launch holiday campaigns 7–10 days before the date to capture early orders and reduce last-minute production pressure
3. **Retargeting:** The higher repeat rate around holidays justifies a dedicated retargeting segment for customers who purchased in a previous holiday period
4. **Channel strategy:** Own website currently accounts for 25% of orders but likely higher AOV — worth tracking separately and investing in direct traffic to reduce marketplace fee dependency
5. **May strategy:** Treat May as two distinct buyer profiles (Mother's Day vs Communion) — the lower price segment dominance in May suggests Communion buyers are more price-sensitive

---

## Notes on Data

- Data covers January 2024 – May 2026
- Allegro 2024 data was partially sourced from email confirmations due to platform export limitations and may be incomplete for that period
- All customer personal data (names, addresses, contact details) has been excluded from this repository in compliance with GDPR
