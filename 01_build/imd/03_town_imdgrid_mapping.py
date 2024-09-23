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
# 2. Combine towns and IMD gridpoint mapping
################################################################################

# 1 - Read IMD gridpoints as geodataframe
csv_path = '/home/ved/dropbox/climate-lives/data/build/input/imd/imd_1951_2023.csv'
imd_data = pd.read_csv(csv_path)

geometry = [Point(xy) for xy in zip(imd_data['lon'], imd_data['lat'])]
imd_gdf = gpd.GeoDataFrame(imd_data, geometry=geometry, crs="EPSG:4326")

imd_gdf = imd_gdf[['lat', 'lon', 'geometry']].drop_duplicates() # Keep only unique lat, lon combinations

# Export gridpoints csv
imd_export_path = "/home/ved/dropbox/climate-lives/gis/input/imd/imd_gridpoints.csv"
imd_gdf.to_csv(imd_export_path)


# 2a - Read towns geodataframe
town_shapefile_path = '/home/ved/dropbox/climate-lives/gis/input/cen11_towns/Town2011.shp'
towns_gdf = gpd.read_file(town_shapefile_path) # Load town boundaries

# 2b - Read districts geodataframe



# 3 - Define function to map polygon to nearest grid point
def polygon_gridpoint_mapping(gridpoint_gdf, boundary_gdf):

    # gridpoint_gdf = imd_gdf
    # boundary_gdf = towns_gdf

    # Get centroid of each polygon
    gridpoint_gdf = gridpoint_gdf[['lat', 'lon', 'geometry']].drop_duplicates()

    # Ensure both GeoDataFrames have the same CRS
    boundary_gdf = boundary_gdf.to_crs(gridpoint_gdf.crs)

    # For towns without points, find nearest point
    nearest_points = sjoin_nearest(boundary_gdf, gridpoint_gdf, how='left')

    return nearest_points


result = polygon_gridpoint_mapping(imd_gdf, towns_gdf).reset_index()[['CODE_2011', 'lat', 'lon']]
export_dir = '/home/ved/dropbox/climate-lives/data/build/temp'
result.to_csv(os.path.join(export_dir, 'town_imdgrid_mapping.csv'), index=False)
