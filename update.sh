#!/bin/bash
set -e

wget -O newTypes.json --compression=auto https://raw.githubusercontent.com/Mictronics/readsb-protobuf/dev/webapp/src/db/types.json
wget -O mic-db.zip https://www.mictronics.de/aircraft-database/indexedDB_old.php
unzip -o mic-db.zip

function compress() {
    rm -f "$1.gz"
    7za a -mx=9 "$1.gz" "$1"
}

rm -f db/*
cp ranges.json db/ranges.js
cp airport-coords.json db/airport-coords.js
cp types.json db/icao_aircraft_types.js
cp newTypes.json db/icao_aircraft_types2.js
cp operators.json db/operators.js


sed -i -e 's/},/},\n/g' aircrafts.json
sed -e 's#\\u00c9#\xc3\x89#g' \
    -e 's#\\u00e9#\xc3\xa9#g' \
    -e 's#\\/#/#g' \
    -e "s/''/'/g" \
    aircrafts.json > aircraftUtf.json

perl -i -pe 's/\\u00(..)/chr(hex($1))/eg' aircraftUtf.json

./toJson.py aircraftUtf.json db newTypes.json

sed -i -e 's/\\;/,/' aircraft.csv

for file in db/*; do
    compress "$file"
    mv "$file.gz" "$file"
done

git add db

VERSION="3.14.$(( $(cat version | cut -d'.' -f3) + 1 ))"
echo "$VERSION" > version
git add version

git commit --amend --date "$(date)" -m "database update (to keep the repository small, this commit is replaced regularly)"
git push -f
