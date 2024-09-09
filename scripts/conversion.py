import pandas as pd
import os

# Define paths
source_folder = r'C:\Users\Jay Patel\Downloads\2023 data\Extracted'
destination_folder = r'C:\Users\Jay Patel\Downloads\2023 data\CSV'

# Create the destination folder if it doesn't exist
os.makedirs(destination_folder, exist_ok=True)

# Convert all .dat files to .csv
for filename in os.listdir(source_folder):
    if filename.endswith('.dat'):
        dat_file_path = os.path.join(source_folder, filename)
        csv_file_path = os.path.join(destination_folder, filename.replace('.dat', '.csv'))
        
        # Read .dat file with semicolon delimiter and save as .csv
        df = pd.read_csv(dat_file_path, delimiter=';')
        df.to_csv(csv_file_path, index=False)
        print(f'Converted: {filename} to {csv_file_path}')
