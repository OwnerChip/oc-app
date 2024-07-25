
# get GoogleService-Info.plist from environment variable decoded from base64
echo $GOOGLESERVICE_INFO_PLIST | base64 --decode > ios/Runner/GoogleService-Info.plist

# get google-services.json from environment variable decoded from base64
echo $GOOGLE_SERVICES_JSON | base64 --decode > android/app/google-services.json

# get appIdAndroid from environment variable and replace ${$FIREBASE_APP_ID_ANDROID} in lib/firebase_options.dart with it
sed -i '' "s/\${APP_ID_ANDROID}/$FIREBASE_APP_ID_ANDROID/g" lib/firebase_options.dart

# get appIdIos from environment variable and replace ${$FIREBASE_APP_ID_IOS} in lib/firebase_options.dart with it
sed -i '' "s/\${APP_ID_IOS}/$FIREBASE_APP_ID_IOS/g" lib/firebase_options.dart

# get apiKeyAndroid from environment variable and replace ${$FIREBASE_API_KEY_ANDROID} in lib/firebase_options.dart with it
sed -i '' "s/\${API_KEY_ANDROID}/$FIREBASE_API_KEY_ANDROID/g" lib/firebase_options.dart

# get apiKeyIos from environment variable and replace ${$FIREBASE_API_KEY_IOS} in lib/firebase_options.dart with it
sed -i '' "s/\${API_KEY_IOS}/$FIREBASE_API_KEY_IOS/g" lib/firebase_options.dart