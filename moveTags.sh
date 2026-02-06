#!/bin/bash

# Variables
outputDirectory="/home/dragon/output-bins"


dumpJSONFiles=$(ls $outputDirectory/hf-mf*.json)

for dumpJSONFile in $dumpJSONFiles
do
  echo "================================================================================="
  echo "Processing $dumpJSONFile..."
  # Moving to Proper Folder
  echo "Moving to proper folder..."
  filePrefix=$(echo "${dumpJSONFile##*/}" | cut -c1-14)

  # Parsing CSV Filament Data for Tag
  IFS=','
  read -r -a filamentCSVData <<< $(./lookupTag.sh "$tagUID")
  unset IFS

  # Checking Filament Type Directory Exists
  if ! [ -d "$outputDirectory/${filamentCSVData[0]}" ]; then
    echo "Making Filament Type Directory '${filamentCSVData[0]}'..."
    mkdir "$outputDirectory/${filamentCSVData[0]}"
  fi

  # Checking Filament Variant Directory Exists
  if ! [ -d "$outputDirectory/${filamentCSVData[0]}/${filamentCSVData[1]}" ]; then
    echo "Making Filament Type Directory '${filamentCSVData[1]}'..."
    mkdir "$outputDirectory/${filamentCSVData[0]}/${filamentCSVData[1]}"
  fi

  # Checking Filament Color Directory Exists
  if ! [ -d "$outputDirectory/${filamentCSVData[0]}/${filamentCSVData[1]}/${filamentCSVData[2]}" ]; then
    echo "Making Filament Type Directory '${filamentCSVData[2]}'..."
    mkdir "$outputDirectory/${filamentCSVData[0]}/${filamentCSVData[1]}/${filamentCSVData[2]}"
  fi

  # Checking UID Directory Exists
  if ! [ -d "$outputDirectory/${filamentCSVData[0]}/${filamentCSVData[1]}/${filamentCSVData[2]}/$tagUID" ]; then
    echo "Making Filament Type Directory '$tagUID'..."
    mkdir "$outputDirectory/${filamentCSVData[0]}/${filamentCSVData[1]}/${filamentCSVData[2]}/$tagUID"
  fi

  echo "Moving '$filePrefix' to '$outputDirectory/${filamentCSVData[0]}/${filamentCSVData[1]}/${filamentCSVData[2]}/$tagUID'"
  mv $outputDirectory/$filePrefix* "$outputDirectory/${filamentCSVData[0]}/${filamentCSVData[1]}/${filamentCSVData[2]}/$tagUID/"
  echo -e "Done!\n"
done
