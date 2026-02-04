#!/bin/bash

# Variables
outputDirectory="/home/dragon/output-bins"

function hexToString() {
  echo $1 | fold -w2 | grep -v '00' | tr -d '\n' | xxd -r -p
}

function hexToUInt32() {
  echo "0x$(echo $1 | fold -w2 | tac | tr -d '\n')"
}

function hexToFloat() {
  echo -n $1 | xxd -r -p | hexdump -e '1/4 "%f\n"'
}

dumpJSONFiles="$1"
if ! [ -f "$dumpJSONFiles" ]; then
  echo "Gathering..."
  # Gather Dump JSON Files
  dumpJSONFiles=$(ls $outputDirectory/hf-mf*.json)
fi
echo -e "Found the following files to Process...\n$dumpJSONFiles\n"

for dumpJSONFile in $dumpJSONFiles
do
  echo "================================================================================="
  echo "Processing $dumpJSONFile..."

  # Parse Block 0
  block0=$(jq -r '."blocks"."0"' $dumpJSONFile)
  echo "Block 0: $block0"
  tagUID=$(echo "$block0" | cut -b1-8)
  tagManufacturerData=$(echo "$block0" | cut -b9-32)
  echo "Tag UID: $(echo $tagUID)"
  echo -e "Tag Manufacturer Data: $(echo $tagManufacturerData)\n"

  # Parse Block 1
  block1=$(jq -r '."blocks"."1"' $dumpJSONFile)
  echo "Block 1: $block1"
  materialVariantId=$(hexToString $(echo "$block1" | cut -b1-16))
  materialId=$(hexToString $(echo "$block1" | cut -b17-32))
  echo "Tray Info Index - Material Variant ID: $materialVariantId"
  echo -e "Tray Info Index - Material ID: $materialId\n"

  # Parse Block 4
  block4=$(jq -r '."blocks"."4"' $dumpJSONFile)
  echo "Block 4: $block4"
  detailedFilamentType=$(hexToString $(echo "$block4" | cut -b1-32))
  echo -e "Detailed Filament Type: $detailedFilamentType\n"

  # Parse Block 5
  block5=$(jq -r '."blocks"."5"' $dumpJSONFile)
  echo "Block 5: $block5"
  rgba=$(echo "$block5" | cut -b1-8)
  spoolWeight=$(hexToUInt32 $(echo "$block5" | cut -b9-12))
  filamentDiameter=$(hexToFloat $(echo "$block5" | cut -b17-24))
  echo "RGBA: $(echo $rgba)"
  printf "Spool Weight: %ug\n" $spoolWeight
  printf "Filament Diameter: %.2fmm\n\n" $filamentDiameter

  # Parse Block 6
  block6=$(jq -r '."blocks"."6"' $dumpJSONFile)
  echo "Block 6: $block6"
  dryingTemp=$(hexToUInt32 $(echo "$block6" | cut -b1-4))
  dryingTime=$(hexToUInt32 $(echo "$block6" | cut -b5-8))
  bedTemp=$(hexToUInt32 $(echo "$block6" | cut -b9-12))
  bedTempC=$(hexToUInt32 $(echo "$block6" | cut -b13-16))
  maxHotendTemp=$(hexToUInt32 $(echo "$block6" | cut -b17-20))
  minHotendTemp=$(hexToUInt32 $(echo "$block6" | cut -b21-24))
  printf "Drying Temp: %uC\n" $dryingTemp
  printf "Drying Time: %uh\n" $dryingTime
  printf "Bed Tempurature: %u\n" $bedTemp
  printf "Bed Tempurature: %uC\n" $bedTempC
  printf "Max Hotend Tempurature: %uC\n" $maxHotendTemp
  printf "Min Hotend Tempurature: %uC\n\n" $minHotendTemp

  # Parse Block 8
  block8=$(jq -r '."blocks"."8"' $dumpJSONFile)
  echo "Block 8: $block8"
  xCamInfo=$(echo "$block8" | cut -b1-24)
  minNozzleDiameter=$(hexToFloat $(echo "$block8" | cut -b25-32))
  echo "X Cam Info: $xCamInfo"
  printf "Minimum Nozzle Diameter: %.2fmm\n\n" $minNozzleDiameter

  # Parse Block 9
  block9=$(jq -r '."blocks"."8"' $dumpJSONFile)
  echo "Block 9: $block9"
  trayUID=$(echo "$block9" | cut -b1-32)
  echo -e "Tray UID: $trayUID\n"

  # Parse Block 10
  block10=$(jq -r '."blocks"."10"' $dumpJSONFile)
  echo "Block 10: $block10"
  spoolWidth=$(hexToUInt32 $(echo "$block10" | cut -b9-12))
  spoolWidth100=$(printf "%.2f" $spoolWidth)
  spoolWidthCalculated=$(echo "scale=2; $spoolWidth100 / 100.00" | bc)
  printf "Spool Width: %.2fmm\n\n" $spoolWidthCalculated

  # Parse Block 12
  block12=$(jq -r '."blocks"."12"' $dumpJSONFile)
  echo "Block 12: $block12"
  productionDate=$(hexToString $(echo "$block12" | cut -b1-32))
  echo -e "Production Date: $productionDate\n"

  # Parse Block 14
  block14=$(jq -r '."blocks"."14"' $dumpJSONFile)
  echo "Block 14: $block14"
  filamentLength=$(hexToUInt32 $(echo "$block14" | cut -b9-12))
  printf "Filament Length: %um\n\n" $filamentLength

  # Parse Block 16
  block16=$(jq -r '."blocks"."16"' $dumpJSONFile)
  echo "Block 16: $block16"
  formatIdentifier=$(hexToUInt32 $(echo "$block16" | cut -b1-4))
  colorCount=$(hexToUInt32 $(echo "$block16" | cut -b5-8))
  rgba=$(echo "$block16" | cut -b9-16)
  echo "Format Identifier: $formatIdentifier"
  echo "Color Format: $colorFormat"
  echo -e "RGBA: $rgba\n"

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

  echo -e "Done Processing!\n"
done
