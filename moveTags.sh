#!/bin/bash
# Variables
binRootDirectory="$HOME/output-bins"
libraryDirectory="$HOME/Bambu-Lab-RFID-Library"
filamentCSVDataFile="$HOME/FilamentList.csv"

# Ensure that the library directory is correct
if [ -d "$libraryDirectory" ]; then
  if [ ! -d "$libraryDirectory/ABS" ]; then
    echo "Library Directory is not correct. Exiting."
    exit 1
  fi
else
  echo "Library Directory is not correct. Exiting."
  exit 1
fi

echo "Library Directory found!"
echo -e "$libraryDirectory\n"

declare -a dumpJSONFiles
if [ -d $binRootDirectory ]; then
  # Gather Dump JSON files
  mapfile -d '' dumpJSONFiles < <(find $binRootDirectory -type f -name "hf-mf-*-dump.json" -print0)

  # Check that there are files to process
  if (( ("${#dumpJSONFiles}") <= 0 )); then
    echo "No dump files to process. Exiting."
    exit 0
  fi
fi
echo -e "Processing ${#dumpJSONFiles[@]} file(s)\n"

# Ensuring that Filament Data CSV is available
if [ ! -f "$filamentCSVDataFile" ]; then
  echo "Filament CSV Data is not valid. Exiting."
  exit 1
fi

for dumpJSONFile in "${dumpJSONFiles[@]}"
do
  echo "================================================================================="
  echo "Processing $dumpJSONFile..."

  # Moving to Proper Folder
  echo "Preparing to move to proper folder..."

  # Parse Block 0 for TagUID
  block0=$(jq -r '."blocks"."0"' "$dumpJSONFile")
  tagUID=$(echo "$block0" | cut -b1-8)
  echo -e "Tag UID: $(echo $tagUID)\n"

  # Parsing CSV Filament Data for Tag
  IFS=','
  read -r -a filamentCSVData <<< $(./lookupTag.sh "$filamentCSVDataFile" "$tagUID")
  unset IFS

  if [[ "$filamentCSVData" == *"not found" ]]; then
    echo "$filamentCSVData. Exiting."
    continue
  fi

  # Checking Filament Type Directory Exists
  if ! [ -d "$libraryDirectory/${filamentCSVData[0]}" ]; then
    echo "Making Filament Type Directory '${filamentCSVData[0]}'..."
    mkdir "$libraryDirectory/${filamentCSVData[0]}"
    echo -e "Done!\n"
  fi

  # Checking Filament Variant Directory Exists
  if ! [ -d "$libraryDirectory/${filamentCSVData[0]}/${filamentCSVData[1]}" ]; then
    echo "Making Filament Type Directory '${filamentCSVData[1]}'..."
    mkdir "$libraryDirectory/${filamentCSVData[0]}/${filamentCSVData[1]}"
    echo -e "Done!\n"
  fi

  # Checking Filament Color Directory Exists
  if ! [ -d "$libraryDirectory/${filamentCSVData[0]}/${filamentCSVData[1]}/${filamentCSVData[2]}" ]; then
    echo "Making Filament Type Directory '${filamentCSVData[2]}'..."
    mkdir "$libraryDirectory/${filamentCSVData[0]}/${filamentCSVData[1]}/${filamentCSVData[2]}"
    echo -e "Done!\n"
  fi

  # Checking UID Directory Exists
  if ! [ -d "$libraryDirectory/${filamentCSVData[0]}/${filamentCSVData[1]}/${filamentCSVData[2]}/$tagUID" ]; then
    echo "Making Filament Type Directory '$tagUID'..."
    mkdir "$libraryDirectory/${filamentCSVData[0]}/${filamentCSVData[1]}/${filamentCSVData[2]}/$tagUID"
    echo -e "Done!\n"
  fi

  # Determining File Path Prefix for Move Operation
  filePathPrefix="${dumpJSONFile%-*}"
  echo -e "Moving: '$filePathPrefix*'\nto: '$libraryDirectory/${filamentCSVData[0]}/${filamentCSVData[1]}/${filamentCSVData[2]}/$tagUID'"

  # Moving Tag Files
  mv "$filePathPrefix"* "$libraryDirectory/${filamentCSVData[0]}/${filamentCSVData[1]}/${filamentCSVData[2]}/$tagUID/"

  # If file move was successful...
  if [ $? -eq 0 ]; then
    echo "Tag files were moved files successfully!"
  else
    # Notify the user that tags were not moved successfully and exit
    echo "Tag files were not moved successfully. Exiting."
    exit 1
  fi
done

echo "Done processing files!"
