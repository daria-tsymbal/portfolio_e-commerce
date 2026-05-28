import pandas as pd
from sqlalchemy import create_engine

DB_USER = "postgres"
DB_PASSWORD = "***"
DB_HOST = "localhost"
DB_PORT = "5432"
DB_NAME = "bouquet_business_db"

engine = create_engine(
    f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

file_path = r"\allegro_order_items.csv"

df = pd.read_csv(
    file_path,
    sep=",",
    encoding="utf-8"
)

# KEEP ONLY NEEDED COLUMNS
df = df[
    [
        "OrderId",
        "OfferId",
        "OfferExternalId",
        "Name",
        "Quantity",
        "Price"
    ]
]

# RENAME COLUMNS
df = df.rename(columns={
    "OrderId": "order_id",

    "OfferId": "offer_id",
    "OfferExternalId": "offer_external_id",

    "Name": "product_name",

    "Quantity": "quantity",
    "Price": "price"
})

# DATA CLEANING
# Convert numeric columns
df["quantity"] = pd.to_numeric(df["quantity"], errors="coerce")
df["price"] = pd.to_numeric(df["price"], errors="coerce")

# Trim text columns
text_columns = [
    "order_id",
    "offer_id",
    "offer_external_id",
    "product_name"
]

for col in text_columns:
    df[col] = df[col].astype(str).str.strip()

df = df.drop_duplicates()

# LOAD INTO POSTGRESQL
df.to_sql(
    name="allegro_order_items",
    schema="raw",
    con=engine,
    if_exists="append",
    index=False
)

print("Order items imported successfully!")