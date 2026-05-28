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

# LOAD EXCEL FILE
file_path = r"\www_orders.xlsx"

SOURCE_PREFIX = "S1"

# S1 = website1
# S2 = website2

df = pd.read_excel(file_path)

df = df[
    [
        'order_id',
        'order_status',
        'order_date',
        'seller_login',
        'buyer_name',
        'buyer_email',
        'buyer_phone',
        'buyer_notes',
        'seller_notes',
        'buyer_city',
        'product_id',
        'product_name',
        'quantity',
        'unit_price',
        'coupon_code',
        'discount_amount',
        'delivery_amount',
        'total_amount'
    ]
]

# PHONE NORMALIZATION
def normalize_phone(phone):

    if pd.isna(phone):
        return None

    digits = re.sub(r'\D', '', str(phone))

    # add Poland code if missing
    if len(digits) == 9:
        digits = '48' + digits

    return digits

df['buyer_phone'] = df['buyer_phone'].apply(normalize_phone)

# PREFIX PRODUCT IDS
df['order_id'] = (
    SOURCE_PREFIX + "_" +
    df['order_id'].astype(str)
)

numeric_columns = [
    'quantity',
    'unit_price',
    'discount_amount',
    'delivery_amount',
    'total_amount'
]

for col in numeric_columns:
    df[col] = pd.to_numeric(df[col], errors='coerce')

df['order_date'] = pd.to_datetime(
    df['order_date'],
    errors='coerce'
)

text_columns = [
    'order_id',
    'order_status',
    'seller_login',
    'buyer_name',
    'buyer_email',
    'buyer_notes',
    'seller_notes',
    'buyer_city',
    'product_id',
    'product_name',
    'coupon_code'
]

for col in text_columns:
    df[col] = (
        df[col]
        .astype(str)
        .str.strip()
    )

df = df.drop_duplicates(
    subset=['order_id', 'product_id']
)

# LOAD TO POSTGRESQL
df.to_sql(
    name='website_orders',
    schema='raw',
    con=engine,
    if_exists='append',
    index=False
)

print("Website data imported successfully!")