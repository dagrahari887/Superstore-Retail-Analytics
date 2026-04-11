import pandas as pd
import mysql.connector

df = pd.read_csv(r'E:\Major Project\superstore_final_clean.csv', encoding='latin-1')

print("Total rows in CSV:", len(df))
print("Columns:", list(df.columns))

conn = mysql.connector.connect(
    host='localhost',
    user='root',
    password='1234',
    database='superstore'
)
cursor = conn.cursor()

cursor.execute("TRUNCATE TABLE orders")

inserted = 0
errors = 0
for _, row in df.iterrows():
    try:
        cursor.execute("""
            INSERT INTO orders (
                order_id, order_date, ship_date, ship_mode,
                customer_id, customer_name, segment, country,
                city, state, postal_code, region, product_id,
                category, sub_category, product_name, sales,
                quantity, discount, profit, profit_margin,
                shipping_days, order_year, order_month,
                profit_status, discount_band
            ) VALUES (
                %s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,
                %s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s
            )
        """, (
            row['order_id'],
            row['order_date'],
            row['ship_date'],
            row['ship_mode'],
            row['customer_id'],
            row['customer_name'],
            row['segment'],
            row['country'],
            row['city'],
            row['state'],
            row['postal_code'],
            row['region'],
            row['product_id'],
            row['category'],
            row['sub_category'],
            row['product_name'],
            row['sales'],
            row['quantity'],
            row['discount'],
            row['profit'],
            row['profit_margin'],
            row['shipping_days'],
            row['order_year'],
            row['order_month'],
            row['profit_status'],
            row['discount_band']
        ))
        inserted += 1
    except Exception as e:
        errors += 1
        print("Error on row:", row['order_id'], "->", e)

conn.commit()
cursor.close()
conn.close()

print("Successfully inserted:", inserted, "rows")
print("Errors:", errors, "rows")