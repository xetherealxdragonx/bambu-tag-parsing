#!/bin/bash
# Proxmark Variables
proxmarkPort="/dev/ttyACM0"
proxmarkDirectory="/home/dragon/proxmark3"

# RFID Project Variables
rfidProjectDirectory="/home/dragon/Bambu-Lab-RFID-Tag-Guide"
outputDirectory="/home/dragon/output-bins"

# Gather UID
echo "Reading Tag UID..."
tagUID=$("$proxmarkDirectory/pm3" -p "$proxmarkPort" -c 'hf mf info' | grep "UID: " | grep -o3 '[0-9A-F]\{2\}\s[0-9A-F]\{2\}\s[0-9A-F]\{2\}\s[0-9A-F]\{2\}' | tr -d ' ')
if [ -z "$tagUID" ]; then
  echo "Unable to reach the Tag UID. Exiting Script." >&2
  exit 1
fi
echo -e "Done!\n\n"

# Activate Python Virtual Environment
echo "Activating Python Virtual Environment..."
source "$rfidProjectDirectory/.venv/bin/activate"
echo -e "Done!\n"

# Derive Keys
echo "Deriving Keys for UID: $tagUID..."
tagKeys=$(python3 "$rfidProjectDirectory/deriveKeys.py" "$tagUID")
if [ -z "$tagKeys" ]; then
  echo "Unable to generate the Tag Keys. Exiting Script." >&2
  exit 1
fi
echo -e "Tag Keys:\n$tagKeys"
echo -e "Done!\n"

# Write Dictionary File
echo "Writing keys to file..."
echo "$tagKeys" > "$outputDirectory/keys.dic"
if ! [ -f "$outputDirectory/keys.dic" ]; then
  echo "Key File does not exist. Exiting Script." >&2
  exit 1
fi
echo -e "Done!\n"

# Dump NFC Contents
echo "Dumping NFC Contents..."
"$proxmarkDirectory/pm3" -p "$proxmarkPort" -c "hf mf autopwn -f $outputDirectory/keys.dic"
mv ~/hf-mf* "$outputDirectory/"
rm "$outputDirectory/keys.dic"
echo "Done!"
