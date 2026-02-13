#!/bin/bash
# Proxmark Variables
proxmarkPort="/dev/ttyACM0"
proxmarkDirectory="/home/dragon/proxmark3"
outputDirectory="/home/dragon/output-bins"

# Dump NFC Contents
echo "Dumping NFC Contents..."
"$proxmarkDirectory/pm3" -p "$proxmarkPort" -c "hf mf info"
"$proxmarkDirectory/pm3" -p "$proxmarkPort" -c "hf mf keygen -r -d -k 4"
"$proxmarkDirectory/pm3" -p "$proxmarkPort" -c "hf mf dump"
mv ~/hf-mf* "$outputDirectory/"
echo "Done!"
