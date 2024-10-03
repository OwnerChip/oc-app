
if [ -v "$1"]; then
  echo "GoogleService-Info.plist is not set"
  exit 1
fi

file_name=$1
plist=${!file_name‘}

#echo "$plist" | base64 --decode > test.plist

#declare GOOGLE_SERVICE_INFO_PLIST=${!$1}

#echo ${!GOOGLE_SERVICE_INFO_PLIST}

echo $TEST