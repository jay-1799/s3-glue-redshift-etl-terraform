import zipfile
import os

# Define paths
source_folder = r'C:\Users\Jay Patel\Downloads\2023 data'
destination_folder = r'C:\Users\Jay Patel\Downloads\2023 data\Extracted'

# Create the destination folder if it doesn't exist
os.makedirs(destination_folder, exist_ok=True)

# Extract all .zip files
for filename in os.listdir(source_folder):
    if filename.endswith('.zip'):
        file_path = os.path.join(source_folder, filename)
        with zipfile.ZipFile(file_path, 'r') as zip_ref:
            zip_ref.extractall(destination_folder)
        print(f'Extracted: {filename}')
