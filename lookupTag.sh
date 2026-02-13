#!/bin/bash
csvFile="$1"

# Ensuring that Filament Data CSV is available
if [ ! -f "$csvFile" ]; then
  echo "Filament CSV Data is not valid. Exiting."
  exit 1
fi

value=$(csvsql --query "SELECT * FROM FilamentList WHERE UID = '$2' OR UID2 = '$2'" "$csvFile" | sed -n '2p')
if [[ -n $value ]]; then
  echo $value
else
  echo "UID '$2' not found"
fi
