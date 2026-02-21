import pandas as pd

# CSV file path
csv_file = "dataset/csv/BDBKala_full.csv"

# List of columns (or indices) you want to check
# If your CSV has headers, use names like ["Order_Status","Payment_Method"]
# If no headers, use indices like [0, 4, 5]
wanted_columns = ["Discount", "Order Priority","Order Status","Payment Method","Shipping Method","Ship Mode","Packaging","Shipping Cost","Ratings","Customer Segment","Gender"]
# Read CSV
df = pd.read_csv(csv_file)

for col in wanted_columns:
    if col in df.columns:
        unique_values = df[col].dropna().unique()
        print(f"Column '{col}' has {len(unique_values)} unique values:")
        print(unique_values)
        print("-" * 50)
    else:
        print(f"Column '{col}' not found in CSV.")