#!/bin/bash

csvFile="/home/dragon/FilamentList.csv"

value=$(csvsql --query "SELECT * FROM FilamentList WHERE UID = '$1' OR UID2 = '$1'" "$csvFile" | sed -n '2p')
if [[ -n $value ]]; then
  echo $value
else
  echo "UID '$1' not found"
fi
