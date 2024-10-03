
# check if environment variables are set
if [ -z "$1" ]; then
  echo "GoogleService-Info.plist is not set"
  exit 1
fi

if [ -z "$2" ]; then
  echo "google-services.json is not set"
  exit 1
fi


googleServiceInfoPlistVariableName=$1
googleServiceInfoPlist=${!googleServiceInfoPlistVariableName}

googleServicesJsonVariableName=$2
googleServicesJson=${!googleServicesJsonVariableName}

# get googleServiceInfoPlistVariableName-Info.plist from environment variable decoded from base64
echo "$googleServiceInfoPlist" | base64 --decode > ios/Runner/GoogleService-Info.plist

# get google-services.json from environment variable decoded from base64
echo "$googleServicesJson" | base64 --decode > android/app/google-services.json

# get appIdAndroid from environment variable and replace ${$FIREBASE_APP_ID_ANDROID} in lib/firebase_options.dart with it
sed -i '' "s/\${APP_ID_ANDROID}/$FIREBASE_APP_ID_ANDROID/g" lib/firebase_options.dart

# get appIdIos from environment variable and replace ${$FIREBASE_APP_ID_IOS} in lib/firebase_options.dart with it
sed -i '' "s/\${APP_ID_IOS}/$FIREBASE_APP_ID_IOS/g" lib/firebase_options.dart

# get apiKeyAndroid from environment variable and replace ${$FIREBASE_API_KEY_ANDROID} in lib/firebase_options.dart with it
sed -i '' "s/\${API_KEY_ANDROID}/$FIREBASE_API_KEY_ANDROID/g" lib/firebase_options.dart

# get apiKeyIos from environment variable and replace ${$FIREBASE_API_KEY_IOS} in lib/firebase_options.dart with it
sed -i '' "s/\${API_KEY_IOS}/$FIREBASE_API_KEY_IOS/g" lib/firebase_options.dart