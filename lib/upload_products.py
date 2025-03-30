import csv
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase
cred = credentials.Certificate("firebase-key.json")  # Path to your Firebase key
firebase_admin.initialize_app(cred)
db = firestore.client()

# Read data from CSV file
csv_file = "product_upload.csv"  # Path to your CSV file

with open(csv_file, newline="", encoding="utf-8") as file:
    reader = csv.DictReader(file)
    for row in reader:
        product = {
            "image_url": row["image_url"],
            "name": row["name"],
            "price": float(row["price"]),
            "category": row["category"],
            "stock": 10,  # Default stock value, change as needed
        }
        db.collection("products").add(product)
        print(f"Uploaded: {product['name']}")

print("All products uploaded successfully!")