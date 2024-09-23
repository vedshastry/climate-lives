# Read/build IMD data
# ref: https://imdlib.readthedocs.io/en/latest/Usage.html#  section - Downloading
import imdlib as imd
import xarray as xr
import pandas as pd
import numpy as np
import geopandas as gpd
import os
from shapely.geometry import Point
from geopandas.tools import sjoin_nearest
from tqdm import tqdm



################################################################################
# 1. Preparing IMD data as dataframe
################################################################################

###########################
# Define reading function
###########################

def build_imd_data(ds_rain, ds_tmin, ds_tmax):
    # Combine tmin and tmax datasets
    ds_combined = xr.merge([ds_tmin, ds_tmax, ds_rain])

    # Convert time to datetime if it's not already
    ds_combined['time'] = pd.to_datetime(ds_combined['time'])

    # Add year and month coordinates
    ds_combined = ds_combined.assign_coords(
        year=('time', ds_combined['time'].dt.year.data),
        month=('time', ds_combined['time'].dt.month.data)
    )

    # Convert to DataFrame for easier handling
    df_combined = ds_combined.to_dataframe().reset_index()

    # Convert 99.9 to NA for both tmin and tmax
    df_combined['rain'] = df_combined['rain'].round(1).replace(-999, np.nan)
    df_combined['tmin'] = df_combined['tmin'].round(1).replace(99.9, np.nan)
    df_combined['tmax'] = df_combined['tmax'].round(1).replace(99.9, np.nan)
    df_combined['tbar'] = (df_combined['tmax']+df_combined['tmin'])/2

    # Group by 'lat' and 'lon' and check for complete NA in both tmin and tmax
    na_analysis = df_combined.groupby(['lat', 'lon']).agg({
        'rain': lambda x: x.isna().all(),
        'tmin': lambda x: x.isna().all(),
        'tmax': lambda x: x.isna().all(),
        'tbar': lambda x: x.isna().all()
    })

    # Identify coordinates where both tmin and tmax are completely NA
    coords_to_drop = na_analysis[(na_analysis['tmin'] & na_analysis['tmax'])].index

    # Drop the identified coordinates
    df_cleaned = df_combined[~df_combined.set_index(['lat', 'lon']).index.isin(coords_to_drop)]

    df_cleaned

    # Group by year, month, lat, lon and calculate statistics
    df_summary = df_cleaned.groupby(['year', 'month', 'lat', 'lon']).agg({
        'rain': ['min', 'mean', 'std', 'max'],
        'tbar': ['min', 'mean', 'std', 'max'],
        'tmin': ['min', 'mean', 'std', 'max'],
        'tmax': ['min', 'mean', 'std', 'max']
    })

    # Flatten column names
    df_summary.columns = ["_".join(a) for a in df_summary.columns.to_flat_index()]

    # Reset index
    df_summary = df_summary.reset_index()

    return df_summary

###########################
# Export dataframes
###########################

data_dir = '/home/ved/dropbox/data/IMD'

export_dir = '/home/ved/dropbox/climate-lives/data/build/input/imd/monthly'
os.makedirs(export_dir, exist_ok=True) # Create export directory if it doesn't exist

# Process data for each year from 1951 to 2023
for year in tqdm(range(1951, 2024), desc="Processing years"):
    # Read data for the current year
    ds_tmin = imd.open_data('tmin', year, year, 'yearwise', data_dir).get_xarray()
    ds_tmax = imd.open_data('tmax', year, year, 'yearwise', data_dir).get_xarray()
    ds_rain = imd.open_data('rain', year, year, 'yearwise', data_dir).get_xarray()

    # Combine and process data
    imd_df = build_imd_data(ds_rain, ds_tmin, ds_tmax)

    # Export data
    export_path = os.path.join(export_dir, f'{year}.csv')
    imd_df.to_csv(export_path, index=False)

print("Processing complete. CSV files have been saved in the specified directory.")

# Combine all years into one data object
all_years_data = []
for year in range(1951, 2024):
    file_path = os.path.join(export_dir, f'{year}.csv')
    if os.path.exists(file_path):
        year_data = pd.read_csv(file_path)
        all_years_data.append(year_data)

# Concatenate all years' data into a single DataFrame
combined_data = pd.concat(all_years_data, ignore_index=True)

# Optionally, save the combined data to a CSV file
export_dir = '/home/ved/dropbox/climate-lives/data/build/input/imd'
combined_data.to_csv(os.path.join(export_dir, 'imd_1951_2023.csv'), index=False)
