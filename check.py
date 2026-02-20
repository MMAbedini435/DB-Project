import pandas as pd

file_path = "dataset/BDBKala_full.csv"
column_name = "Order Quantity"

chunk_size = 50_000  # adjust depending on memory

empty_rows = []
non_integer_rows = []

row_offset = 0  # track real row number in file

for chunk in pd.read_csv(file_path, chunksize=chunk_size):
    
    # Track original row numbers
    chunk.index = range(row_offset, row_offset + len(chunk))
    row_offset += len(chunk)

    col = chunk[column_name]

    # 1️⃣ Check empty (NaN or blank)
    empty_mask = col.isna() | (col.astype(str).str.strip() == "")
    empty_rows.extend(chunk[empty_mask].index.tolist())

    # 2️⃣ Check non-integer values
    numeric_col = pd.to_numeric(col, errors="coerce")
    non_integer_mask = (
        numeric_col.isna() |                # not numeric
        (numeric_col % 1 != 0)              # decimal values
    ) & ~empty_mask                        # exclude already counted empty

    non_integer_rows.extend(chunk[non_integer_mask].index.tolist())

# Report results
if not empty_rows and not non_integer_rows:
    print("✅ 'Order Quantity' contains only valid integers.")
else:
    if empty_rows:
        print(f"❌ Empty values found at rows: {empty_rows[:10]} ...")
    if non_integer_rows:
        print(f"❌ Non-integer values found at rows: {non_integer_rows[:10]} ...")