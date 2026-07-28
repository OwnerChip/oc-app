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
6. Localizations
   - Flutter automatically generate localization files during `flutter pub get` or `flutter run`. You do not need to run `flutter gen-l10n` manually.
7. Make sure you have a device connected and run ```flutter run``` to start the app


## Whitelabel customization

The OwnerChip app is designed as a whitelabel app. Below is a list of env variables that have to be adjusted to switch between apps: 
1. OC Internal
This is our internal app for testing.
```dotenv
APP_ID='ownerchip'
IMAGE_ASSETS_BASE_URL='./assets/images/ownerchip'
BITRISEIO_PACKAGE_NAME='com.ownerchip.internal'
IS_INTERNAL='true'
```

2. OwnerChip
This is the main OwnerChip app.
```dotenv
    APP_ID='ownerchip'
    IMAGE_ASSETS_BASE_URL='./assets/images/ownerchip'
    BITRISEIO_PACKAGE_NAME='com.ownerchip.user'
    IS_INTERNAL='false'
```

3. SteboArt
```dotenv
   APP_ID='stebo'
   IMAGE_ASSETS_BASE_URL='./assets/images/stebo'
   BITRISEIO_PACKAGE_NAME='com.steboart.user'
   IS_INTERNAL='false'
```

To generate the correct splash screen run ```flutter pub run flutter_native_splash:create --path=$LOGO_CONFIG_YAML``` where ```$LOGO_CONFIG_YAML``` is replaced with the corresponding yaml file in the app root folder. (e.g. ```flutter_logo_config_ownerchip.yaml```)
