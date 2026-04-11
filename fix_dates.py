import pandas as pd

df = pd.read_csv(r'E:\Major Project\Sample - Superstore.csv\Sample - Superstore.csv', encoding='latin-1')

print("Total rows:", len(df))
print("Original dates sample:")
print(df[['Order Date', 'Ship Date']].head(5))

df['Order Date'] = pd.to_datetime(df['Order Date'], format='mixed', dayfirst=False).dt.strftime('%Y-%m-%d')
df['Ship Date'] = pd.to_datetime(df['Ship Date'], format='mixed', dayfirst=False).dt.strftime('%Y-%m-%d')

print("\nFixed dates sample:")
print(df[['Order Date', 'Ship Date']].head(10))
print("\nTotal rows after fix:", len(df))

df.to_csv(r'E:\Major Project\superstore_dates_fixed.csv', index=False)
print("\nDone! File saved!")