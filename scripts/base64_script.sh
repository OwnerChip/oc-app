# Encode all files in a directory to base64
# and save them in a file with the same name as the original file,
# but add _base64 suffix to the file name.

# Usage: base64_script.sh <directory>
# Example: base64_script.sh /path/to/directory /path/to/directory
#

# Check if source directory is provided
if [ -z "$1" ]; then
  echo "Please provide a directory"
  exit 1
fi

# Check if destination directory is provided
if [ -z "$2" ]; then
  echo "Please provide a destination directory"
  exit 1
fi

# Check if the directory exists
if [ ! -d "$1" ]; then
  echo "Directory does not exist"
  exit 1
fi

# Check if the destination directory exists and create it if it does not
if [ ! -d "$2" ]; then
  mkdir -p "$2"
fi

# delete all files with _base64 suffix
rm -f $1/*_base64
rm -f $2/*_base64

# Loop through all files in the directory
for file in $1/*; do
  # Check if the file is a regular file
  if [ -f "$file" ]; then
    # Get the file name without the extension
    file_name=$(basename "$file" | cut -d. -f1)
    echo "Encoding $file to base64 and saving it in $2/${file_name}_base64"
    # Encode the file to base64 and save it in a new file
    openssl base64 -in "$file" -out "$2/${file_name}_base64"
  fi
done


echo "All files in the directory have been encoded to base64 and saved in a new file with _base64 suffix."