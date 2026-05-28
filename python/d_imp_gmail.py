import pandas as pd
import re
from sqlalchemy import create_engine

DB_USER = "postgres"
DB_PASSWORD = "***"
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "bouquet_business_db"

engine = create_engine(
    f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

file_path = r"\allegro_gmail.xlsx"

df = pd.read_excel(file_path)

print("RAW INPUT ROWS:", len(df))

def extract_data(text):

    data = {
        "order_id": None,
        "seller_login": None,
        "product_name": None,
        "product_id": None,
        "quantity": None,
        "line_total": None,
        "marketplace": None,
        "buyer_name": None,
        "buyer_city": None,
        "buyer_phone": None
    }

    try:
        text = str(text)

        seller = re.search(r'Dzień dobry (.*?),', text)
        if seller:
            data["seller_login"] = seller.group(1).strip()

        product = re.search(
            r'Sprzedan(?:y|e)\s+przedmiot(?:y)?\s+(.*?)\s+\((\d+)\)\s+(\d+)\s+szt',
            text,
            re.DOTALL
        )
        if product:
            data["product_name"] = product.group(1).strip()
            data["product_id"] = product.group(2).strip()

        qty = re.search(r'(\d+)\s+sztu', text)
        if qty:
            data["quantity"] = int(qty.group(1))

        price = re.search(r'(\d+[,\.\s]?\d*)\s*zł', text)
        if price:
            p = price.group(1).replace(" ", "").replace(",", ".")
            data["line_total"] = float(p)

        market = re.search(r'Rynek sprzedaży\s+(.*?)\s+', text)
        if market:
            data["marketplace"] = market.group(1).strip()

        buyer = re.search(r'\n([A-ZŁŚŻŹĆŃ][^\n]+)\n', text)
        if buyer:
            data["buyer_name"] = buyer.group(1).strip()

        city = re.search(r'\d{2}-\d{3}\s+(.*?)\n', text)
        if city:
            data["buyer_city"] = city.group(1).strip()

        phone = re.search(r'(\+\d{1,3}\s?\d[\d\s]{7,14})', text)
        if phone:
            digits = re.sub(r"\D", "", phone.group(1))
            data['buyer_phone'] = phone.group(1).replace("+", "").replace(" ", "")

        order = re.search(r'Numer zamówienia\s+([a-zA-Z0-9\-]+)', text)
        if order:
            data["order_id"] = order.group(1).strip()

    except Exception as e:
        data["__parse_error__"] = str(e)

    return data

# PARSING LOOP WITH LOGGING
parsed_rows = []
failed_rows = []
empty_rows = []

for i, row in df.iterrows():

    raw_text = row.get("email_text")

    if pd.isna(raw_text):
        empty_rows.append(i)
        continue

    parsed = extract_data(raw_text)

    # track broken records
    if not parsed.get("order_id") and not parsed.get("product_name"):
        failed_rows.append({
            "index": i,
            "text_sample": str(raw_text)[:200]
        })

    parsed["order_date"] = row.get("order_date")

    parsed_rows.append(parsed)

parsed_df = pd.DataFrame(parsed_rows)

print("PARSED ROWS:", len(parsed_df))
print("EMPTY INPUT ROWS:", len(empty_rows))
print("FAILED PARSE ROWS:", len(failed_rows))

before_clean = len(parsed_df)

parsed_df = parsed_df.dropna(subset=["order_id", "product_id"])

after_clean = len(parsed_df)

print(f"DROPPED INVALID ROWS: {before_clean - after_clean}")

print("FINAL DATAFRAME ROWS:", len(parsed_df))


# LOAD TO POSTGRES
try:
    parsed_df.to_sql(
        "gmail_allegro_orders",
        engine,
        schema="raw",
        if_exists="append",
        index=False,
        method="multi"
    )

except Exception as e:
    print("DB INSERT ERROR:", e)

import sqlalchemy as sa

with engine.connect() as conn:
    result = conn.execute(sa.text("""
        SELECT COUNT(*) FROM raw.gmail_allegro_orders
    """))
    db_count = result.fetchone()[0]

print("DB ROWS:", db_count)

print("\nDATA LOSS REPORT")
print("----------------------")
print("Input rows:      ", len(df))
print("Parsed rows:     ", len(parsed_df))
print("DB rows:         ", db_count)
print("Missing rows:    ", len(df) - db_count)
