# OwnerChip Whitelabel Flutter App

## Setup

1. Install Flutter https://docs.flutter.dev/get-started/install
2. Run ```flutter doctor``` and install all missing requirements (e.g. Android Studio, etc.)
3. Clone this repository
4. Install dependencies with
    ```
   cd oc-app
   flutter pub get
    ```

5. Create .env file in ```oc-app``` folder based on .sample-env. Contact Ferdinand Regner or David Hauser to get necessary API keys.
6. Create localization files with ```flutter gen-10n```
7. Make sure you have a device connected and run ```flutter run``` to start the app


## Whitelabel customization

The OwnerChip app is designed as a whitelabel app. Below is a list of env variables that have to be adjusted to switch between apps: 
1. OC Internal
This is our internal app for testing.
APP_ID='ownerchip'
IMAGE_ASSETS_BASE_URL='./assets/images/ownerchip'
BITRISEIO_PACKAGE_NAME='com.ownerchip.internal'
IS_INTERNAL='true'

3. OwnerChip
This is the main OwnerChip app.
APP_ID='ownerchip'
IMAGE_ASSETS_BASE_URL='./assets/images/ownerchip'
BITRISEIO_PACKAGE_NAME='com.ownerchip.user'
IS_INTERNAL='false'

5. OwnerChip Discovery
   APP_ID='ownerchip'
   IMAGE_ASSETS_BASE_URL='./assets/images/ownerchip_infineon'
   BITRISEIO_PACKAGE_NAME='com.ownerchipinfineon.demo'
   IS_INTERNAL='false'
7. SteboArt
   APP_ID='stebo'
   IMAGE_ASSETS_BASE_URL='./assets/images/stebo'
   BITRISEIO_PACKAGE_NAME='com.steboart.user'
   IS_INTERNAL='false'
9. Stilami
   APP_ID='stilami'
   IMAGE_ASSETS_BASE_URL='./assets/images/stilami'
   BITRISEIO_PACKAGE_NAME='com.stilami.identity'
   IS_INTERNAL='false'

To generate the correct splash screen run ```flutter pub run flutter_native_splash:create --path=$LOGO_CONFIG_YAML``` where ```$LOGO_CONFIG_YAML``` is replaced with the corresponding yaml file in the app root folder. (e.g. ```flutter_logo_config_ownerchip.yaml```)

Note that for ```BITRISEIO_PACKAGE_NAME``` there are five options. 
