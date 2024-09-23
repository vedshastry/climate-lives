# Download IMD data
# ref: https://imdlib.readthedocs.io/en/latest/Usage.html#  section - Downloading

import imdlib as imd

# define data dir
# data_dir = '/home/ved/dropbox/data/IMD'
data_dir = '/home/ved/dropbox/climate-lives/data/raw/IMD'

# specify dataset(s), start and end years
datavars = ['tmin','tmax','rain']
start_yr = 1951
end_yr = 2023

# iterate for each type
for type in datavars:
    data = imd.get_data(type, start_yr, end_yr, fn_format='yearwise', file_dir=data_dir)
