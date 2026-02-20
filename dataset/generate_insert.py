import pandas as pd

# CSV file path
csv_file = "BDBKala_full.csv"

# Table name
table_name = "BDB"

# Column names in order (from your example)
columns = [
    "Order_ID","Order_Date","Order_Priority","Order_Quantity","Order_Status","Payment_Method",
    "Product_Name","Product_Category","Product_Sub-Category","Unit_Price","Unit_Cost","Discount",
    "Shipping_Address","Shipping_Method","Ship_Date","Ship_Mode","Packaging","Shipping_Cost",
    "Region","City","Zip_Code","Ratings","Customer_Segment","Customer_Name","Customer_Age",
    "Email","Phone","Gender","Income"
]

# Columns that should NOT have quotes (numbers)
numeric_columns = {
    "Order_ID","Order_Quantity","Unit_Price","Unit_Cost","Discount",
    "Shipping_Cost","Zip_Code","Ratings","Customer_Age","Income"
}

# Read CSV without headers
df = pd.read_csv(csv_file, header=None)

for index, row in df.iterrows():
    values = []
    for col, value in zip(columns, row):
        if pd.isna(value):
            values.append("NULL")
        elif col in numeric_columns:
            values.append(str(value))
        else:
            # Escape single quotes in strings
            text = str(value).replace("'", "''")
            values.append(f"'{text}'")
    
    values_str = ",".join(values)
    sql = f"INSERT INTO {table_name}({','.join(columns)}) VALUES ({values_str});"
    print(sql)