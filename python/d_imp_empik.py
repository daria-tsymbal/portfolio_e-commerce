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

file_path = r"\empik_orders.xlsx"

df = pd.read_excel(file_path)

df = df[
    [
        'order_id',
        'order_status',
        'order_date',
        'buyer_name',
        'buyer_email',
        'buyer_phone',
        'buyer_city',
        'product_id',
        'product_name',
        'quantity',
        'unit_price',
        'delivery_amount', 
        'line_total'
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

# data normalization
df['order_date'] = pd.to_datetime(
    df['order_date'],
    format='%d.%m.%Y - %H:%M:%S',
    errors='coerce'
)

numeric_columns = [
    'quantity',
    'unit_price',
    'delivery_amount',
    'line_total'
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
    'buyer_name',
    'buyer_email',
    'buyer_city',
    'product_id',
    'product_name'
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
    name='empik_orders',
    schema='raw',
    con=engine,
    if_exists='append',
    index=False
)

print("Website data imported successfully!")