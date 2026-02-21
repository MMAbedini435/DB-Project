import pandas as pd

# Path to your CSV file
csv_file = "bnpl.csv"

# Read CSV
df = pd.read_csv(csv_file)

# Extract 'Order_ID' column
order_ids = df['order_id'].tolist()

# Print all Order_ID values
print(order_ids)