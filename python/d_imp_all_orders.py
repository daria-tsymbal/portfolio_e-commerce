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

file_path = r"\allegro_orders.csv"

df = pd.read_csv(
    file_path,
    sep=",",
    encoding="utf-8"
)

# KEEP ONLY NEEDED COLUMNS
df = df[
    [
        "OrderId",
        "SellerLogin",
        "OrderDate",
        "SellerStatus",

        "BuyerId",
        "BuyerName",
        "BuyerPhone",
        "BuyerCity",

        "DeliveryAddressName",
        "DeliveryAddressPhone",
        "DeliveryAddressCity",

        "DeliveryAmount",
        "TotalToPayAmount",

        "BuyerNotes",
        "SellerNotes",

        "Marketplace"
    ]
]

# RENAME COLUMNS
df = df.rename(columns={
    "OrderId": "order_id",
    "SellerLogin": "seller_login",
    "OrderDate": "order_date",
    "SellerStatus": "status",

    "BuyerId": "buyer_id",
    "BuyerName": "buyer_name",
    "BuyerPhone": "buyer_phone",
    "BuyerCity": "buyer_city",
    
    "DeliveryAddressName": "delivery_address_name",
    "DeliveryAddressPhone": "delivery_address_phone",
    "DeliveryAddressCity": "delivery_address_city",

    "DeliveryAmount": "delivery_amount",
    "TotalToPayAmount": "total_to_pay",

    "BuyerNotes": "buyer_notes",
    "SellerNotes": "seller_notes",

    "Marketplace": "marketplace"
})

# DATA CLEANING
# Convert date
df["order_date"] = pd.to_datetime(df["order_date"], errors="coerce")

# Convert numeric columns
df["delivery_amount"] = pd.to_numeric(df["delivery_amount"], errors="coerce")
df["total_to_pay"] = pd.to_numeric(df["total_to_pay"], errors="coerce")

# Clean phone numbers
df["buyer_phone"] = (
    df["buyer_phone"]
    .astype(str)
    .str.replace(r"\D", "", regex=True)
)

df["delivery_address_phone"] = (
    df["delivery_address_phone"]
    .astype(str)
    .str.replace(r"\D", "", regex=True)
)

# Trim text columns
text_columns = [
    "seller_login",
    "status",
    "buyer_id",
    "buyer_name",
    "buyer_city",
    "delivery_address_name",
    "delivery_address_city",
    "seller_notes",
    "buyer_notes",
    "marketplace"
]

for col in text_columns:
    df[col] = df[col].astype(str).str.strip()

df = df.drop_duplicates(subset=["order_id"])

# LOAD INTO POSTGRESQL
df.to_sql(
    name="allegro_orders",
    schema="raw",
    con=engine,
    if_exists="append",
    index=False
)

print("Data imported successfully!")