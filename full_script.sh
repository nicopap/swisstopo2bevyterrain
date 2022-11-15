#!/usr/bin/env sh

# STEP ONE:
# go to the following addresses and download the list of URLs for the data you
# want to download:
# - https://www.swisstopo.admin.ch/en/geodata/images/ortho/swissimage10.html
# - https://www.swisstopo.admin.ch/en/geodata/height/alti3d.html
#
# You'll get two CSV files. Each line represents an image URL to download,
# to download everything automatically, run the following command:

# How many images to download at the same time. Please only use this with the
# csv files downloaded through the provided links!
CONCURRENT_DOWNLOADS=4

for prog in xargs curl du mkdir cargo cut awk tiff2rgba sed ; do
  if ! which $prog ; then
    echo "'$prog' is required to run this script, yet is not installed"
    echo "either modify the script to not need it or install it"
  fi
done

# Build the conversion utlity
cargo build --release
TARGET_DIR="$(cargo metadata --format-version=1 | sed -n 's/.*"target_directory":"\([^"]*\)".*/\1/p')"
cp "${TARGET_DIR}/release/swisstopo2bevyterrain*" .

# This may take between 10 minutes and 10 hours depending on how much data you
# selected. Make sure to not download more data than you can handle!
mkdir albedo
cd albedo
xargs -P 4 -I _ curl -SL _ --remote-name < ../*swissimage-dop10-*csv
cd ..

mkdir topo
cd topo
xargs -P 4 -I _ curl -SL _ --remote-name < ../*swissalti3d-*csv
cd ..

# You should now have two directories full of thousands of .tif files. Try
# opening an individual image from the albedo directory with an image viewer.
# See how large those files are, to make sure you don't have any surprises.
du -h --summarize topo
du -h --summarize albedo

# As of writing, the file name structure of each image is:
# <PROJECT_NAME>_<YEAR>_<CH1903+ COORD>_<PRECISION>.tif
# Where
# - <PROJECT_NAME> is 'swissalti3d' or 'swissimage-dop10'
# - <YEAR> is when the picture was taken
# - <CH1903+ COORD> is the coordinate of the picture encoded in the Swiss
#   national measure system, at kilometer scale, two values separated by a
#   '-', first value is east/west and second north/south
#   https://www.swisstopo.admin.ch/en/knowledge-facts/surveying-geodesy/coordinates/swiss-coordinates.html
# - <PRECISION> two or three values I'm not sure how to interpret.

# bevy_terrain "attachment" and "height" data must be presented as
# <filename>_<x>_<y>.<fmt>, so we need to transform those values.

# Get min values in CH1903 coords
# We assumet albedo and topo data both have the same set of images.
MIN_LAT=$(ls albedo/ |
  cut -d_ -f 3 |
  awk -F '-' 'BEGIN{lat=9999}{lat = (lat<$1)?lat:$1}END {print lat}')
MIN_LONG=$(ls albedo/ |
  cut -d_ -f 3 |
  awk -F '-' 'BEGIN{long=9999}{long = (long<$2)?long:$2}END {print long}')

# bevy_terrain accepts heights in the form of 16 bits integer, the swisstopo
# alti3d is 32 bits floats. We need to convert them. Currently the tiff crate
# is too limited, it can't read the swissimage-dop10 images because it is
# encoded in YCbCr. I converted the files using the `tiff2rgba` utility, now
# the tiff crate can read it
# NOTE: The lowest point in Switzerland is 193m in lake maggiore, while the
# highest point is 4634m±10m at Pointe Dufour

mkdir clean_albedo
mkdir clean_topo
for file in $(ls albedo) ; do
  OUTPUT=$(echo -n $file | cut -d_ -f 3 | awk -F '-' "{print (\$1 - $MIN_LAT) \"_\" (\$2 - $MIN_LONG)}")
  (tiff2rgba albedo/$file $file.tmp && 
    ./swisstopo2bevyterrain* --input $file.tmp --output clean_albedo/albedo_${OUTPUT}.png albedo &&
    \rm $file.tmp
  ) &
done
for file in $(ls topo) ; do
  OUTPUT=$(echo -n $file | cut -d_ -f 3 | awk -F '-' "{print (\$1 - $MIN_LAT) \"_\" (\$2 - $MIN_LONG)}")
  ./swisstopo2bevyterrain* --input topo/$file --output clean_topo/height_${OUTPUT}.png topo &
done