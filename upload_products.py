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
        # Process multiple images from comma-separated string into an array
        images = row["images"].split(",") if "images" in row and row["images"] else []
        
        product = {
            "name": row["name"],
            "price": float(row["price"]),
            "category": row["category"],
            "stock": int(row.get("stock", 10)),  # Use provided stock or default to 10
            "images": images,
            "imagePath": images[0] if images else "",  # Set first image as main imagePath for backward compatibility
            "description": row.get("description", "No description available.")  # Add description field
        }
        
        db.collection("products").add(product)
        print(f"Uploaded: {product['name']} with {len(images)} images")

print("All products uploaded successfully!")