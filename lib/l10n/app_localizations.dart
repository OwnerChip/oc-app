import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en')
  ];

  /// No description provided for @termsAndConditionsUrl.
  ///
  /// In en, this message translates to:
  /// **'https://ownerchip.com/en/general-terms.html'**
  String get termsAndConditionsUrl;

  /// No description provided for @projectsUrl.
  ///
  /// In en, this message translates to:
  /// **'http://www.ownerchip.com/projects'**
  String get projectsUrl;

  /// No description provided for @orderChipsUrl.
  ///
  /// In en, this message translates to:
  /// **'http://www.ownerchip.com/orderchips'**
  String get orderChipsUrl;

  /// No description provided for @supportUrl.
  ///
  /// In en, this message translates to:
  /// **'https://www.ownerchip.com/creators-corner/'**
  String get supportUrl;

  /// No description provided for @legalUrl.
  ///
  /// In en, this message translates to:
  /// **'https://www.ownerchip.com/en/app-support-legal-information.html'**
  String get legalUrl;

  /// No description provided for @privacyUrl.
  ///
  /// In en, this message translates to:
  /// **'https://www.ownerchip.com/privacy/'**
  String get privacyUrl;

  /// No description provided for @initializeChip.
  ///
  /// In en, this message translates to:
  /// **'Create Digital Twin'**
  String get initializeChip;

  /// No description provided for @walletAddress.
  ///
  /// In en, this message translates to:
  /// **'Wallet address'**
  String get walletAddress;

  /// No description provided for @getWalletAddress.
  ///
  /// In en, this message translates to:
  /// **'Get Wallet Address'**
  String get getWalletAddress;

  /// No description provided for @youAreOwner.
  ///
  /// In en, this message translates to:
  /// **'You are the owner'**
  String get youAreOwner;

  /// No description provided for @youAreNftOwner.
  ///
  /// In en, this message translates to:
  /// **'You are the owner of the Digital Twin'**
  String get youAreNftOwner;

  /// No description provided for @theOwnerIs.
  ///
  /// In en, this message translates to:
  /// **'the owner is'**
  String get theOwnerIs;

  /// No description provided for @burnToken.
  ///
  /// In en, this message translates to:
  /// **'Delete Digital Twin'**
  String get burnToken;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @authenticate.
  ///
  /// In en, this message translates to:
  /// **'Authenticate'**
  String get authenticate;

  /// No description provided for @walletAuthenticated.
  ///
  /// In en, this message translates to:
  /// **'Wallet authenticated'**
  String get walletAuthenticated;

  /// No description provided for @successCardLogin.
  ///
  /// In en, this message translates to:
  /// **'Successfully connected with OwnerCard.'**
  String get successCardLogin;

  /// No description provided for @scanning.
  ///
  /// In en, this message translates to:
  /// **'Tap an item'**
  String get scanning;

  /// No description provided for @nfcError.
  ///
  /// In en, this message translates to:
  /// **'Error tapping NFC chip.'**
  String get nfcError;

  /// No description provided for @noNfc.
  ///
  /// In en, this message translates to:
  /// **'Please turn on NFC.'**
  String get noNfc;

  /// No description provided for @isoDepError.
  ///
  /// In en, this message translates to:
  /// **'IsoDep is not supported.'**
  String get isoDepError;

  /// No description provided for @ownerError.
  ///
  /// In en, this message translates to:
  /// **'Error fetching owner'**
  String get ownerError;

  /// No description provided for @burning.
  ///
  /// In en, this message translates to:
  /// **'Deleting Digital Twin'**
  String get burning;

  /// No description provided for @burnedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Digital Twin deleted.'**
  String get burnedSuccess;

  /// No description provided for @burnedError.
  ///
  /// In en, this message translates to:
  /// **'Error when deleting Digital Twin.'**
  String get burnedError;

  /// No description provided for @mintSuccess.
  ///
  /// In en, this message translates to:
  /// **'Digital Twin created successfully'**
  String get mintSuccess;

  /// No description provided for @mintError.
  ///
  /// In en, this message translates to:
  /// **'Error creating Digital Twin'**
  String get mintError;

  /// No description provided for @alreadyLinked.
  ///
  /// In en, this message translates to:
  /// **'This NFC chip is already linked to a Digital Twin.'**
  String get alreadyLinked;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @allFunctions.
  ///
  /// In en, this message translates to:
  /// **'All Functions'**
  String get allFunctions;

  /// No description provided for @burnAndMint.
  ///
  /// In en, this message translates to:
  /// **'delete and create new'**
  String get burnAndMint;

  /// No description provided for @showOnExplorer.
  ///
  /// In en, this message translates to:
  /// **'Show Blockchain Details'**
  String get showOnExplorer;

  /// No description provided for @showOnOpenSea.
  ///
  /// In en, this message translates to:
  /// **'Show on OpenSea'**
  String get showOnOpenSea;

  /// No description provided for @openWebLink.
  ///
  /// In en, this message translates to:
  /// **'Open Web Link'**
  String get openWebLink;

  /// No description provided for @itemName.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get itemName;

  /// No description provided for @itemDescription.
  ///
  /// In en, this message translates to:
  /// **'Item description'**
  String get itemDescription;

  /// No description provided for @nftDetails.
  ///
  /// In en, this message translates to:
  /// **'Digital Twin Details'**
  String get nftDetails;

  /// No description provided for @itemData.
  ///
  /// In en, this message translates to:
  /// **'Item Data'**
  String get itemData;

  /// No description provided for @loadingData.
  ///
  /// In en, this message translates to:
  /// **'Loading Digital Twin data from IPFS. \nThis can take a few seconds.'**
  String get loadingData;

  /// No description provided for @tapItem.
  ///
  /// In en, this message translates to:
  /// **'Tap an item'**
  String get tapItem;

  /// No description provided for @searchChip.
  ///
  /// In en, this message translates to:
  /// **'searching for NFC chip'**
  String get searchChip;

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'Place your phone closer to the chip. \nHold until the next screen appears.'**
  String get scanHint;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @moreInfo.
  ///
  /// In en, this message translates to:
  /// **'More Info'**
  String get moreInfo;

  /// No description provided for @uploadImage.
  ///
  /// In en, this message translates to:
  /// **'Please upload an image of the object'**
  String get uploadImage;

  /// No description provided for @selectImage.
  ///
  /// In en, this message translates to:
  /// **'Select image'**
  String get selectImage;

  /// No description provided for @takePicture.
  ///
  /// In en, this message translates to:
  /// **'Take picture'**
  String get takePicture;

  /// No description provided for @selectedImage.
  ///
  /// In en, this message translates to:
  /// **'Selected image'**
  String get selectedImage;

  /// No description provided for @enterMetadata.
  ///
  /// In en, this message translates to:
  /// **'Please enter your metadata'**
  String get enterMetadata;

  /// No description provided for @enterText.
  ///
  /// In en, this message translates to:
  /// **'Please enter text'**
  String get enterText;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @traits.
  ///
  /// In en, this message translates to:
  /// **'Traits'**
  String get traits;

  /// No description provided for @addTraits.
  ///
  /// In en, this message translates to:
  /// **'Add traits'**
  String get addTraits;

  /// No description provided for @addKey.
  ///
  /// In en, this message translates to:
  /// **'Enter a key'**
  String get addKey;

  /// No description provided for @addValue.
  ///
  /// In en, this message translates to:
  /// **'Enter a value'**
  String get addValue;

  /// No description provided for @processing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get processing;

  /// No description provided for @mintNft.
  ///
  /// In en, this message translates to:
  /// **'Create Digital Twin'**
  String get mintNft;

  /// No description provided for @tapResults.
  ///
  /// In en, this message translates to:
  /// **'Tap Results'**
  String get tapResults;

  /// No description provided for @viewNftDetails.
  ///
  /// In en, this message translates to:
  /// **'Show Digital Twin details'**
  String get viewNftDetails;

  /// No description provided for @addressCopied.
  ///
  /// In en, this message translates to:
  /// **'Wallet address copied to clipboard'**
  String get addressCopied;

  /// No description provided for @noWalletConnected.
  ///
  /// In en, this message translates to:
  /// **'You have no wallet connected!'**
  String get noWalletConnected;

  /// No description provided for @walletConnected.
  ///
  /// In en, this message translates to:
  /// **'Wallet connected'**
  String get walletConnected;

  /// No description provided for @walletIsConnected.
  ///
  /// In en, this message translates to:
  /// **'Your wallet is connected'**
  String get walletIsConnected;

  /// No description provided for @connectWallet.
  ///
  /// In en, this message translates to:
  /// **'Connect Wallet'**
  String get connectWallet;

  /// No description provided for @disconnectWallet.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Wallet'**
  String get disconnectWallet;

  /// No description provided for @openWalletToView.
  ///
  /// In en, this message translates to:
  /// **'Open wallet to view Digital Twin'**
  String get openWalletToView;

  /// No description provided for @showTxHistory.
  ///
  /// In en, this message translates to:
  /// **'Transaction History'**
  String get showTxHistory;

  /// No description provided for @noNftInWallet.
  ///
  /// In en, this message translates to:
  /// **'There is no Digital Twin in your wallet.'**
  String get noNftInWallet;

  /// No description provided for @nftCheck.
  ///
  /// In en, this message translates to:
  /// **'Digital Twin Check'**
  String get nftCheck;

  /// No description provided for @uploadingMetadata.
  ///
  /// In en, this message translates to:
  /// **'Uploading metadata'**
  String get uploadingMetadata;

  /// No description provided for @mintingToken.
  ///
  /// In en, this message translates to:
  /// **'Creating Digital Twin'**
  String get mintingToken;

  /// No description provided for @pleaseEnterText.
  ///
  /// In en, this message translates to:
  /// **'Please enter text'**
  String get pleaseEnterText;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @showNftInWallet.
  ///
  /// In en, this message translates to:
  /// **'Show Digital Twin in Wallet'**
  String get showNftInWallet;

  /// No description provided for @successHeadingSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get successHeadingSnackbar;

  /// No description provided for @errorHeadingSnackBar.
  ///
  /// In en, this message translates to:
  /// **'Oh Snap!'**
  String get errorHeadingSnackBar;

  /// No description provided for @loadingNFTDataError.
  ///
  /// In en, this message translates to:
  /// **'Error loading Digital Twin data from IPFS.'**
  String get loadingNFTDataError;

  /// No description provided for @errorConnectingWallet.
  ///
  /// In en, this message translates to:
  /// **'Error when connecting wallet.'**
  String get errorConnectingWallet;

  /// No description provided for @errorNoInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection.'**
  String get errorNoInternetConnection;

  /// No description provided for @errorNoNfcReader.
  ///
  /// In en, this message translates to:
  /// **'NFC Reader is not activated'**
  String get errorNoNfcReader;

  /// No description provided for @congrats.
  ///
  /// In en, this message translates to:
  /// **'Congrats!'**
  String get congrats;

  /// No description provided for @ownershipCheck.
  ///
  /// In en, this message translates to:
  /// **'Ownership Check'**
  String get ownershipCheck;

  /// No description provided for @authenticityNftFound.
  ///
  /// In en, this message translates to:
  /// **'Digital Twin exists on blockchain.'**
  String get authenticityNftFound;

  /// No description provided for @authenticityNftNotFound.
  ///
  /// In en, this message translates to:
  /// **'Digital Twin does not exist on blockchain.'**
  String get authenticityNftNotFound;

  /// No description provided for @authenticityCheck.
  ///
  /// In en, this message translates to:
  /// **'Authenticity Check'**
  String get authenticityCheck;

  /// No description provided for @nfcCheck.
  ///
  /// In en, this message translates to:
  /// **'NFC Check'**
  String get nfcCheck;

  /// No description provided for @whoops.
  ///
  /// In en, this message translates to:
  /// **'Whoops!'**
  String get whoops;

  /// No description provided for @youAreNotNftOwner.
  ///
  /// In en, this message translates to:
  /// **'This Digital Twin is not in your wallet.'**
  String get youAreNotNftOwner;

  /// No description provided for @youAreNFTOwner.
  ///
  /// In en, this message translates to:
  /// **'This item is yours.'**
  String get youAreNFTOwner;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @authentic.
  ///
  /// In en, this message translates to:
  /// **'Authentic'**
  String get authentic;

  /// No description provided for @ownershipCouldNotBeVerified.
  ///
  /// In en, this message translates to:
  /// **'Ownership could not be verified.'**
  String get ownershipCouldNotBeVerified;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get disconnect;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get connect;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add trait'**
  String get add;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @showTraits.
  ///
  /// In en, this message translates to:
  /// **'Show Traits'**
  String get showTraits;

  /// No description provided for @showDescription.
  ///
  /// In en, this message translates to:
  /// **'Show Description'**
  String get showDescription;

  /// No description provided for @continueInBackground.
  ///
  /// In en, this message translates to:
  /// **'Continue in background'**
  String get continueInBackground;

  /// No description provided for @unknownCollection.
  ///
  /// In en, this message translates to:
  /// **'Unknown collection'**
  String get unknownCollection;

  /// No description provided for @chooseChain.
  ///
  /// In en, this message translates to:
  /// **'Choose \n Chain + Collection'**
  String get chooseChain;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal Information'**
  String get legal;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @selectChain.
  ///
  /// In en, this message translates to:
  /// **'Select Chain'**
  String get selectChain;

  /// No description provided for @selectBlockchain.
  ///
  /// In en, this message translates to:
  /// **'Blockchain'**
  String get selectBlockchain;

  /// No description provided for @selectCollection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get selectCollection;

  /// No description provided for @troubleshoot.
  ///
  /// In en, this message translates to:
  /// **'I need help'**
  String get troubleshoot;

  /// No description provided for @more.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// No description provided for @viewProjects.
  ///
  /// In en, this message translates to:
  /// **'View our Projects'**
  String get viewProjects;

  /// No description provided for @orderChips.
  ///
  /// In en, this message translates to:
  /// **'Order NFC Chips'**
  String get orderChips;

  /// No description provided for @signupAsCertifier.
  ///
  /// In en, this message translates to:
  /// **'SignUp as Certifier'**
  String get signupAsCertifier;

  /// No description provided for @scanNow.
  ///
  /// In en, this message translates to:
  /// **'Tap Now'**
  String get scanNow;

  /// No description provided for @pleaseSelect.
  ///
  /// In en, this message translates to:
  /// **'- please select -'**
  String get pleaseSelect;

  /// No description provided for @pleaseSelectChainAndCollection.
  ///
  /// In en, this message translates to:
  /// **'Please select a Blockchain & Collection'**
  String get pleaseSelectChainAndCollection;

  /// No description provided for @digitalTwin.
  ///
  /// In en, this message translates to:
  /// **'Certificate'**
  String get digitalTwin;

  /// No description provided for @authenticity.
  ///
  /// In en, this message translates to:
  /// **'Authenticity'**
  String get authenticity;

  /// No description provided for @ownership.
  ///
  /// In en, this message translates to:
  /// **'Ownership'**
  String get ownership;

  /// No description provided for @unconfirmed.
  ///
  /// In en, this message translates to:
  /// **'Not confirmed'**
  String get unconfirmed;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @externalLinks.
  ///
  /// In en, this message translates to:
  /// **'Web Links'**
  String get externalLinks;

  /// No description provided for @transferToken.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transferToken;

  /// No description provided for @transferInProgress.
  ///
  /// In en, this message translates to:
  /// **'Transferring Digital Twin'**
  String get transferInProgress;

  /// No description provided for @transferSuccess.
  ///
  /// In en, this message translates to:
  /// **'Digital Twin transferred'**
  String get transferSuccess;

  /// No description provided for @transferError.
  ///
  /// In en, this message translates to:
  /// **'Error transferring Digital Twin'**
  String get transferError;

  /// No description provided for @enterWalletAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter wallet address'**
  String get enterWalletAddress;

  /// No description provided for @pleaseEnterValidWalletAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid wallet address.'**
  String get pleaseEnterValidWalletAddress;

  /// No description provided for @creationOfTwin.
  ///
  /// In en, this message translates to:
  /// **'Create your Digital Twin'**
  String get creationOfTwin;

  /// No description provided for @warningPublicData.
  ///
  /// In en, this message translates to:
  /// **'All entered data is publicly visible.'**
  String get warningPublicData;

  /// No description provided for @infoScreenText.
  ///
  /// In en, this message translates to:
  /// **'Check items for authenticity and ownership using your smartphone.'**
  String get infoScreenText;

  /// No description provided for @transferScreenText.
  ///
  /// In en, this message translates to:
  /// **'Transfer your Digital Twin to another wallet.'**
  String get transferScreenText;

  /// No description provided for @chooseWallet.
  ///
  /// In en, this message translates to:
  /// **'Select login method'**
  String get chooseWallet;

  /// No description provided for @agreeToWhenConnecting.
  ///
  /// In en, this message translates to:
  /// **'By connecting you agree to our '**
  String get agreeToWhenConnecting;

  /// No description provided for @generalTerms.
  ///
  /// In en, this message translates to:
  /// **'general terms'**
  String get generalTerms;

  /// No description provided for @and.
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get and;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'privacy policy'**
  String get privacyPolicy;

  /// No description provided for @zu.
  ///
  /// In en, this message translates to:
  /// **''**
  String get zu;

  /// No description provided for @step.
  ///
  /// In en, this message translates to:
  /// **'Step'**
  String get step;

  /// No description provided for @viewGallery.
  ///
  /// In en, this message translates to:
  /// **'View Gallery'**
  String get viewGallery;

  /// No description provided for @chooseFile.
  ///
  /// In en, this message translates to:
  /// **'Choose File'**
  String get chooseFile;

  /// No description provided for @addDigitalContent.
  ///
  /// In en, this message translates to:
  /// **'Add Digital Content'**
  String get addDigitalContent;

  /// No description provided for @titleTooLong.
  ///
  /// In en, this message translates to:
  /// **'Title too long.'**
  String get titleTooLong;

  /// No description provided for @titleCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Title cannot be empty.'**
  String get titleCannotBeEmpty;

  /// No description provided for @maxAttachmentsReached.
  ///
  /// In en, this message translates to:
  /// **'You can add max. 50 attachments.'**
  String get maxAttachmentsReached;

  /// No description provided for @enterValidUrl.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid URL starting with https://.'**
  String get enterValidUrl;

  /// No description provided for @urlCannotBeEmpty.
  ///
  /// In en, this message translates to:
  /// **'URL cannot be empty.'**
  String get urlCannotBeEmpty;

  /// No description provided for @public.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get public;

  /// No description provided for @private.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get private;

  /// No description provided for @contentCanBeViewedPublic.
  ///
  /// In en, this message translates to:
  /// **'This content can be viewed by everyone who taps the item.'**
  String get contentCanBeViewedPublic;

  /// No description provided for @contentCanOnlyBeViewedPrivate.
  ///
  /// In en, this message translates to:
  /// **'This content can only be viewed by the verified owner.'**
  String get contentCanOnlyBeViewedPrivate;

  /// No description provided for @addFile.
  ///
  /// In en, this message translates to:
  /// **'Add File'**
  String get addFile;

  /// No description provided for @addUrl.
  ///
  /// In en, this message translates to:
  /// **'Add URL'**
  String get addUrl;

  /// No description provided for @editAttachment.
  ///
  /// In en, this message translates to:
  /// **'Edit Attachment'**
  String get editAttachment;

  /// No description provided for @selectAttachmentYouWantToEdit.
  ///
  /// In en, this message translates to:
  /// **'Select attachment you want to edit or remove.'**
  String get selectAttachmentYouWantToEdit;

  /// No description provided for @uploadDigitalContent.
  ///
  /// In en, this message translates to:
  /// **'Upload Digital Content'**
  String get uploadDigitalContent;

  /// No description provided for @creatorContent.
  ///
  /// In en, this message translates to:
  /// **'Creator Content'**
  String get creatorContent;

  /// No description provided for @ownerContent.
  ///
  /// In en, this message translates to:
  /// **'Owner Content'**
  String get ownerContent;

  /// No description provided for @fileEdited.
  ///
  /// In en, this message translates to:
  /// **'File edited.'**
  String get fileEdited;

  /// No description provided for @errorUpdatingData.
  ///
  /// In en, this message translates to:
  /// **'Error updating data.'**
  String get errorUpdatingData;

  /// No description provided for @errorUploadingFile.
  ///
  /// In en, this message translates to:
  /// **'Error uploading file.'**
  String get errorUploadingFile;

  /// No description provided for @fileAttached.
  ///
  /// In en, this message translates to:
  /// **'File attached.'**
  String get fileAttached;

  /// No description provided for @savingUrl.
  ///
  /// In en, this message translates to:
  /// **'Saving URL...'**
  String get savingUrl;

  /// No description provided for @urlAttached.
  ///
  /// In en, this message translates to:
  /// **'URL attached.'**
  String get urlAttached;

  /// No description provided for @errorSavingUrl.
  ///
  /// In en, this message translates to:
  /// **'Error saving URL.'**
  String get errorSavingUrl;

  /// No description provided for @errorDeletingAttachment.
  ///
  /// In en, this message translates to:
  /// **'Error deleting attachment.'**
  String get errorDeletingAttachment;

  /// No description provided for @attachmentDeleted.
  ///
  /// In en, this message translates to:
  /// **'Attachment deleted.'**
  String get attachmentDeleted;

  /// No description provided for @pressConnectToSignIn.
  ///
  /// In en, this message translates to:
  /// **'Press connect to sign in with your OwnerCard.'**
  String get pressConnectToSignIn;

  /// No description provided for @youCanUseThisPukToResetYourPin.
  ///
  /// In en, this message translates to:
  /// **'You can use the PUK in case you forget your PIN code.'**
  String get youCanUseThisPukToResetYourPin;

  /// No description provided for @pukCopied.
  ///
  /// In en, this message translates to:
  /// **'PUK copied to clipboard'**
  String get pukCopied;

  /// No description provided for @setUpOwnerCard.
  ///
  /// In en, this message translates to:
  /// **'Set up new OwnerCard'**
  String get setUpOwnerCard;

  /// No description provided for @confirmYourIdentity.
  ///
  /// In en, this message translates to:
  /// **'Confirm your identity by authenticating your wallet.'**
  String get confirmYourIdentity;

  /// No description provided for @errorSettingPin.
  ///
  /// In en, this message translates to:
  /// **'Error setting OwnerCard PIN.'**
  String get errorSettingPin;

  /// No description provided for @holdPhoneToCard.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone close to your OwnerCard.'**
  String get holdPhoneToCard;

  /// No description provided for @errorAuthenticatingCard.
  ///
  /// In en, this message translates to:
  /// **'Error authenticating OwnerCard.'**
  String get errorAuthenticatingCard;

  /// No description provided for @errorMakingSignature.
  ///
  /// In en, this message translates to:
  /// **'Error making signature.'**
  String get errorMakingSignature;

  /// No description provided for @holdPhoneToNfcChip.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone close to the NFC chip'**
  String get holdPhoneToNfcChip;

  /// No description provided for @setUpPin.
  ///
  /// In en, this message translates to:
  /// **'Set up new PIN for OwnerCard'**
  String get setUpPin;

  /// No description provided for @enterPinToAuth.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN to authenticate'**
  String get enterPinToAuth;

  /// No description provided for @connectOwnerCard.
  ///
  /// In en, this message translates to:
  /// **'Connect OwnerCard'**
  String get connectOwnerCard;

  /// No description provided for @enterPinToConfirmTx.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN to confirm transaction'**
  String get enterPinToConfirmTx;

  /// No description provided for @confirmTx.
  ///
  /// In en, this message translates to:
  /// **'Confirm Transaction'**
  String get confirmTx;

  /// No description provided for @enterPuk.
  ///
  /// In en, this message translates to:
  /// **'Enter PUK'**
  String get enterPuk;

  /// No description provided for @successfullySetUpPin.
  ///
  /// In en, this message translates to:
  /// **'Successfully set up PIN'**
  String get successfullySetUpPin;

  /// No description provided for @transferOwnership.
  ///
  /// In en, this message translates to:
  /// **'Transfer Ownership'**
  String get transferOwnership;

  /// No description provided for @transferringOwnership.
  ///
  /// In en, this message translates to:
  /// **'Ownership is being transferred'**
  String get transferringOwnership;

  /// No description provided for @claimOwnership.
  ///
  /// In en, this message translates to:
  /// **'Claim Ownership'**
  String get claimOwnership;

  /// No description provided for @claimingOwnership.
  ///
  /// In en, this message translates to:
  /// **'Ownership is being claimed'**
  String get claimingOwnership;

  /// No description provided for @tokenWasTransferred.
  ///
  /// In en, this message translates to:
  /// **'Ownership was transferred to '**
  String get tokenWasTransferred;

  /// No description provided for @tokenNotYetClaimed.
  ///
  /// In en, this message translates to:
  /// **' but has not yet been claimed.'**
  String get tokenNotYetClaimed;

  /// No description provided for @holdPhoneCloseToOwnerCardToInit.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone close to the OwnerCard you want to initialize.'**
  String get holdPhoneCloseToOwnerCardToInit;

  /// No description provided for @chipIsNoCard.
  ///
  /// In en, this message translates to:
  /// **'Chip is not an OwnerCard.'**
  String get chipIsNoCard;

  /// No description provided for @twoSlotsInitSuccess.
  ///
  /// In en, this message translates to:
  /// **'First two public keys initialized.'**
  String get twoSlotsInitSuccess;

  /// No description provided for @twoSlotsInitError.
  ///
  /// In en, this message translates to:
  /// **'\'Error initializing first two public key slots.'**
  String get twoSlotsInitError;

  /// No description provided for @tokenIdCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Digital Twin ID copied to clipboard'**
  String get tokenIdCopiedToClipboard;

  /// No description provided for @walletAddressCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Wallet address copied to clipboard'**
  String get walletAddressCopiedToClipboard;

  /// No description provided for @isNotOwnerCard.
  ///
  /// In en, this message translates to:
  /// **'NFC chip is not an OwnerCard.'**
  String get isNotOwnerCard;

  /// No description provided for @whenSigningInWithMetamask.
  ///
  /// In en, this message translates to:
  /// **'When signing in via Metamask make sure to connect with Ethereum Mainnet.'**
  String get whenSigningInWithMetamask;

  /// No description provided for @pinResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'PIN reset. Save your new PUK!'**
  String get pinResetSuccess;

  /// No description provided for @enterFourDigitPin.
  ///
  /// In en, this message translates to:
  /// **'Enter new 4 digit PIN'**
  String get enterFourDigitPin;

  /// No description provided for @enterPUK.
  ///
  /// In en, this message translates to:
  /// **'Enter PUK'**
  String get enterPUK;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @errorSigningTx.
  ///
  /// In en, this message translates to:
  /// **'Error signing transaction.'**
  String get errorSigningTx;

  /// No description provided for @errorReadingChip.
  ///
  /// In en, this message translates to:
  /// **'Error reading chip.'**
  String get errorReadingChip;

  /// No description provided for @receivingToken.
  ///
  /// In en, this message translates to:
  /// **'Receiving Digital Twin'**
  String get receivingToken;

  /// No description provided for @transferToAddress.
  ///
  /// In en, this message translates to:
  /// **'Transfer to address'**
  String get transferToAddress;

  /// No description provided for @cardLost.
  ///
  /// In en, this message translates to:
  /// **'OwnerCard lost'**
  String get cardLost;

  /// No description provided for @cardLostContacted.
  ///
  /// In en, this message translates to:
  /// **'Thank you for submitting your request. Our support team will get in touch with you shortly.'**
  String get cardLostContacted;

  /// No description provided for @scanToTriggerCardLost.
  ///
  /// In en, this message translates to:
  /// **'Now hold your phone close to the NFC chip on the item linked to your lost OwnerCard.'**
  String get scanToTriggerCardLost;

  /// No description provided for @enterEmailToTriggerCardLost.
  ///
  /// In en, this message translates to:
  /// **'Enter email to trigger process for receiving new card.'**
  String get enterEmailToTriggerCardLost;

  /// No description provided for @tokenDoesNotExist.
  ///
  /// In en, this message translates to:
  /// **'Digital Twin does not exist.'**
  String get tokenDoesNotExist;

  /// No description provided for @pleaseEnterValidEmailAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid email address.'**
  String get pleaseEnterValidEmailAddress;

  /// No description provided for @chipAddress.
  ///
  /// In en, this message translates to:
  /// **'Chip address'**
  String get chipAddress;

  /// No description provided for @transferOnlyToOwnerCard.
  ///
  /// In en, this message translates to:
  /// **'Transfer only possible to initialized OwnerCard.'**
  String get transferOnlyToOwnerCard;

  /// No description provided for @digitalContentWillBeTransferred.
  ///
  /// In en, this message translates to:
  /// **'Public and private digital content will be transferred together with the Digital Twin.'**
  String get digitalContentWillBeTransferred;

  /// No description provided for @ownercard.
  ///
  /// In en, this message translates to:
  /// **'OwnerCard'**
  String get ownercard;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @cardNotInitializedByAdmin.
  ///
  /// In en, this message translates to:
  /// **'OwnerCard not yet initialized by admin.'**
  String get cardNotInitializedByAdmin;

  /// No description provided for @deletingAttachment.
  ///
  /// In en, this message translates to:
  /// **'Deleting attachment'**
  String get deletingAttachment;

  /// No description provided for @enterPIN.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPIN;

  /// No description provided for @transferToOwnerCard.
  ///
  /// In en, this message translates to:
  /// **'Transfer to OwnerCard'**
  String get transferToOwnerCard;

  /// No description provided for @resetPIN.
  ///
  /// In en, this message translates to:
  /// **'Reset PIN'**
  String get resetPIN;

  /// No description provided for @toRequestNewCard.
  ///
  /// In en, this message translates to:
  /// **'To request a new card, please enter your contact details below.'**
  String get toRequestNewCard;

  /// No description provided for @uploadingAttachment.
  ///
  /// In en, this message translates to:
  /// **'Uploading Attachment...'**
  String get uploadingAttachment;

  /// No description provided for @creatorData.
  ///
  /// In en, this message translates to:
  /// **'Creator Profile'**
  String get creatorData;

  /// No description provided for @digitalTwinVerifiedBy.
  ///
  /// In en, this message translates to:
  /// **'Digital Twin verified by '**
  String get digitalTwinVerifiedBy;

  /// No description provided for @pleaseScanItem.
  ///
  /// In en, this message translates to:
  /// **'Tap the item'**
  String get pleaseScanItem;

  /// No description provided for @scanItemToTriggerCardLost.
  ///
  /// In en, this message translates to:
  /// **'In the next step, please tap the item that is associated with your lost OwnerCard. \n\nThis will allow us to restore its digital counterpart on to your replacement card.'**
  String get scanItemToTriggerCardLost;

  /// No description provided for @pleaseEnterValidTel.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid phone number'**
  String get pleaseEnterValidTel;

  /// No description provided for @pleaseEnterValidName.
  ///
  /// In en, this message translates to:
  /// **'Please enter valid name'**
  String get pleaseEnterValidName;

  /// No description provided for @pleaseTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again later.'**
  String get pleaseTryAgainLater;

  /// No description provided for @showCreatorData.
  ///
  /// In en, this message translates to:
  /// **'Show Creator Data'**
  String get showCreatorData;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @requestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent!'**
  String get requestSent;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @setPin.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get setPin;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created at'**
  String get createdAt;

  /// No description provided for @pleaseHoldPhoneLonger.
  ///
  /// In en, this message translates to:
  /// **'Please hold phone to chip a bit longer.'**
  String get pleaseHoldPhoneLonger;

  /// No description provided for @unableToReadChip.
  ///
  /// In en, this message translates to:
  /// **'Unable to read NFC chip'**
  String get unableToReadChip;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @pleaseEnterFirstName.
  ///
  /// In en, this message translates to:
  /// **'Please enter first name.'**
  String get pleaseEnterFirstName;

  /// No description provided for @pleaseEnterLastName.
  ///
  /// In en, this message translates to:
  /// **'Please enter last name.'**
  String get pleaseEnterLastName;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @streetAddress.
  ///
  /// In en, this message translates to:
  /// **'Street Address'**
  String get streetAddress;

  /// No description provided for @pleaseEnterStreetAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter street address.'**
  String get pleaseEnterStreetAddress;

  /// No description provided for @streetAddress1.
  ///
  /// In en, this message translates to:
  /// **'Street Address 1'**
  String get streetAddress1;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @pleaseEnterCity.
  ///
  /// In en, this message translates to:
  /// **'Please enter city.'**
  String get pleaseEnterCity;

  /// No description provided for @zip.
  ///
  /// In en, this message translates to:
  /// **'Zip'**
  String get zip;

  /// No description provided for @pleaseEnterZip.
  ///
  /// In en, this message translates to:
  /// **'Please enter zip.'**
  String get pleaseEnterZip;

  /// No description provided for @stateProvince.
  ///
  /// In en, this message translates to:
  /// **'State/Province'**
  String get stateProvince;

  /// No description provided for @selectCountry.
  ///
  /// In en, this message translates to:
  /// **'Select country'**
  String get selectCountry;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @startTypingToSearch.
  ///
  /// In en, this message translates to:
  /// **'Start typing to search'**
  String get startTypingToSearch;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @pleaseEnterCountry.
  ///
  /// In en, this message translates to:
  /// **'Please enter country.'**
  String get pleaseEnterCountry;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @youAreTheNewOwner.
  ///
  /// In en, this message translates to:
  /// **'You are the new owner. The Digital Twin can now be transferred into your wallet.'**
  String get youAreTheNewOwner;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @pleaseScanChipAgainToBurn.
  ///
  /// In en, this message translates to:
  /// **'Please tap NFC chip again to delete Digital Twin.'**
  String get pleaseScanChipAgainToBurn;

  /// No description provided for @attention.
  ///
  /// In en, this message translates to:
  /// **'Attention!'**
  String get attention;

  /// No description provided for @voucherNftDescriptionGeneral.
  ///
  /// In en, this message translates to:
  /// **'This Digital Twin includes the ownership of a physical artwork which can be redeemed after the purchase'**
  String get voucherNftDescriptionGeneral;

  /// No description provided for @voucherNftDescriptionAppSpecific.
  ///
  /// In en, this message translates to:
  /// **'via the OwnerChip-App, downloadable in the Google Playstore and Apple AppStore. You can view the digital certificate at this link: {CERTIFICATE_LINK}\nFor more information visit https://ownerchip.com/redeem'**
  String voucherNftDescriptionAppSpecific(Object CERTIFICATE_LINK);

  /// No description provided for @transferred.
  ///
  /// In en, this message translates to:
  /// **'Transferred'**
  String get transferred;

  /// No description provided for @enterDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter details'**
  String get enterDetails;

  /// No description provided for @myCollection.
  ///
  /// In en, this message translates to:
  /// **'My collection'**
  String get myCollection;

  /// No description provided for @pleaseConnectWalletToViewItems.
  ///
  /// In en, this message translates to:
  /// **'Please connect your wallet to view items.'**
  String get pleaseConnectWalletToViewItems;

  /// No description provided for @ownedByMe.
  ///
  /// In en, this message translates to:
  /// **'Owned by me'**
  String get ownedByMe;

  /// No description provided for @createdByMe.
  ///
  /// In en, this message translates to:
  /// **'Created by me'**
  String get createdByMe;

  /// No description provided for @youHaveNotMintedAnyItems.
  ///
  /// In en, this message translates to:
  /// **'You have not created any Digital Twins.'**
  String get youHaveNotMintedAnyItems;

  /// No description provided for @youDoNotOwnAnyItems.
  ///
  /// In en, this message translates to:
  /// **'You do not own any Digital Twins.'**
  String get youDoNotOwnAnyItems;

  /// No description provided for @appBarProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get appBarProfileTitle;

  /// No description provided for @appBarWalletIdTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet ID'**
  String get appBarWalletIdTitle;

  /// No description provided for @copiedAddressToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Address copied to clipboard'**
  String get copiedAddressToClipboard;

  /// No description provided for @appbarMyBalanceButton.
  ///
  /// In en, this message translates to:
  /// **'My Balance'**
  String get appbarMyBalanceButton;

  /// No description provided for @myBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'My Balance'**
  String get myBalanceTitle;

  /// No description provided for @myBalanceTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get myBalanceTotalBalance;

  /// No description provided for @myBalanceChoseCrypto.
  ///
  /// In en, this message translates to:
  /// **'Choose a crypto currency you want to transfer'**
  String get myBalanceChoseCrypto;

  /// No description provided for @myBalanceReceivingWalletAddress.
  ///
  /// In en, this message translates to:
  /// **'Receiving wallet address'**
  String get myBalanceReceivingWalletAddress;

  /// No description provided for @myBalanceCryptoAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get myBalanceCryptoAmount;

  /// No description provided for @myBalanceSendMaxButton.
  ///
  /// In en, this message translates to:
  /// **'Send max. amount'**
  String get myBalanceSendMaxButton;

  /// No description provided for @myBalanceSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get myBalanceSendButton;

  /// No description provided for @myBalanceConfirmationDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirmation'**
  String get myBalanceConfirmationDialogTitle;

  /// No description provided for @myBalanceConfirmationRecipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient:'**
  String get myBalanceConfirmationRecipient;

  /// No description provided for @myBalanceConfirmationAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount:'**
  String get myBalanceConfirmationAmount;

  /// No description provided for @myBalanceConfirmationCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency:'**
  String get myBalanceConfirmationCurrency;

  /// No description provided for @myBalanceConfirmationChain.
  ///
  /// In en, this message translates to:
  /// **'Chain:'**
  String get myBalanceConfirmationChain;

  /// No description provided for @myBalanceConfirmationConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get myBalanceConfirmationConfirmButton;

  /// No description provided for @myBalanceConfirmationCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get myBalanceConfirmationCancelButton;

  /// No description provided for @myBalancePullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get myBalancePullToRefresh;

  /// No description provided for @myBalanceRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get myBalanceRefreshing;

  /// No description provided for @myBalanceError.
  ///
  /// In en, this message translates to:
  /// **'Error occurred while loading balance'**
  String get myBalanceError;

  /// No description provided for @myBalanceRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get myBalanceRetry;

  /// No description provided for @myBalanceWithdrawSufficientFunds.
  ///
  /// In en, this message translates to:
  /// **'Insufficient crypto!'**
  String get myBalanceWithdrawSufficientFunds;

  /// No description provided for @myBalanceWithdrawLoadingText.
  ///
  /// In en, this message translates to:
  /// **'Sending crypto...'**
  String get myBalanceWithdrawLoadingText;

  /// No description provided for @myBalanceWithdrawSuccessText.
  ///
  /// In en, this message translates to:
  /// **'Sending successfully'**
  String get myBalanceWithdrawSuccessText;

  /// No description provided for @myBalanceWithdrawErrorText.
  ///
  /// In en, this message translates to:
  /// **'Error sending crypto'**
  String get myBalanceWithdrawErrorText;

  /// No description provided for @myBalanceWithdrawBackButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get myBalanceWithdrawBackButton;

  /// No description provided for @myBalanceWithdrawPasteAddressButton.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get myBalanceWithdrawPasteAddressButton;

  /// No description provided for @myBalanceWithdrawWrongAddress.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid address'**
  String get myBalanceWithdrawWrongAddress;

  /// No description provided for @myBalanceWithdrawMaxAmount.
  ///
  /// In en, this message translates to:
  /// **'Max: {amount}'**
  String myBalanceWithdrawMaxAmount(Object amount);

  /// No description provided for @galleryPullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get galleryPullToRefresh;

  /// No description provided for @galleryRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get galleryRefreshing;

  /// No description provided for @galleryLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get galleryLoadMore;

  /// No description provided for @galleryLoadingMore.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get galleryLoadingMore;

  /// No description provided for @galleryNoMoreItems.
  ///
  /// In en, this message translates to:
  /// **'No more Digital Twins to load'**
  String get galleryNoMoreItems;

  /// No description provided for @errorLoadingOwnedItems.
  ///
  /// In en, this message translates to:
  /// **'Error loading owned Digital Twins'**
  String get errorLoadingOwnedItems;

  /// No description provided for @errorLoadingCreatedItems.
  ///
  /// In en, this message translates to:
  /// **'Error loading created Digital Twins'**
  String get errorLoadingCreatedItems;

  /// No description provided for @galleryErrorLoadingMore.
  ///
  /// In en, this message translates to:
  /// **'Error loading more Digital Twins'**
  String get galleryErrorLoadingMore;

  /// No description provided for @tokenCreatedAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **''**
  String get tokenCreatedAppBarTitle;

  /// No description provided for @tokenCreatedTitle.
  ///
  /// In en, this message translates to:
  /// **'Token created'**
  String get tokenCreatedTitle;

  /// No description provided for @tokenCreatedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You have successfully created a digital twin for your physical object.'**
  String get tokenCreatedSubtitle;

  /// No description provided for @tokenCreatedViewTokenButton.
  ///
  /// In en, this message translates to:
  /// **'View token'**
  String get tokenCreatedViewTokenButton;

  /// No description provided for @newVersionTitle.
  ///
  /// In en, this message translates to:
  /// **'Update App'**
  String get newVersionTitle;

  /// No description provided for @newVersionAvailable.
  ///
  /// In en, this message translates to:
  /// **'A new version of the app is available! Please update to the latest version.'**
  String get newVersionAvailable;

  /// No description provided for @newVersionUpdateButton.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get newVersionUpdateButton;

  /// No description provided for @scanResultPageShowCertificateButton.
  ///
  /// In en, this message translates to:
  /// **'Show Certificate Details'**
  String get scanResultPageShowCertificateButton;

  /// No description provided for @scanResultPage_ownershipCheck.
  ///
  /// In en, this message translates to:
  /// **'Ownership Check'**
  String get scanResultPage_ownershipCheck;

  /// No description provided for @scanResultPage_ownershipOwnerNotOffered.
  ///
  /// In en, this message translates to:
  /// **'You are the owner of this item.'**
  String get scanResultPage_ownershipOwnerNotOffered;

  /// No description provided for @scanResultPage_ownershipNotOwnerNotOffered.
  ///
  /// In en, this message translates to:
  /// **'Your are not the owner of this item.'**
  String get scanResultPage_ownershipNotOwnerNotOffered;

  /// No description provided for @scanResultPage_chipHasNotYetBeenInitialized.
  ///
  /// In en, this message translates to:
  /// **'The NFC chip has not yet been activated.'**
  String get scanResultPage_chipHasNotYetBeenInitialized;

  /// No description provided for @nftDetailsPageShowCertificateButton.
  ///
  /// In en, this message translates to:
  /// **'Show Certificate Details'**
  String get nftDetailsPageShowCertificateButton;

  /// No description provided for @nftDetailsPageAuthenticityCertified.
  ///
  /// In en, this message translates to:
  /// **'Certified'**
  String get nftDetailsPageAuthenticityCertified;

  /// No description provided for @nftDetailsPageAuthenticityNotCertified.
  ///
  /// In en, this message translates to:
  /// **'Not certified'**
  String get nftDetailsPageAuthenticityNotCertified;

  /// No description provided for @nftDetailsPageCertifier.
  ///
  /// In en, this message translates to:
  /// **'Certifier'**
  String get nftDetailsPageCertifier;

  /// No description provided for @nftDetailsPageCreationDate.
  ///
  /// In en, this message translates to:
  /// **'Creation date'**
  String get nftDetailsPageCreationDate;

  /// No description provided for @nftDetailsPageCollection.
  ///
  /// In en, this message translates to:
  /// **'Collection'**
  String get nftDetailsPageCollection;

  /// No description provided for @nftDetailsErrorFetchingCertificateData.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get nftDetailsErrorFetchingCertificateData;

  /// No description provided for @nft_cancel_confirmation_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Cancel NFT'**
  String get nft_cancel_confirmation_dialog_title;

  /// No description provided for @nft_cancel_confirmation_dialog_description.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel activation for \"{title}\"?'**
  String nft_cancel_confirmation_dialog_description(Object title);

  /// No description provided for @nft_cancel_confirmation_dialog_cancel_cancel_button.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel activation'**
  String get nft_cancel_confirmation_dialog_cancel_cancel_button;

  /// No description provided for @nft_cancel_confirmation_dialog_cancel_keep_button.
  ///
  /// In en, this message translates to:
  /// **'No, continue'**
  String get nft_cancel_confirmation_dialog_cancel_keep_button;

  /// No description provided for @nft_burn_cancel_confirmation_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Cancel Burn'**
  String get nft_burn_cancel_confirmation_dialog_title;

  /// No description provided for @nft_burn_cancel_confirmation_dialog_description.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel burning \"{title}\"?'**
  String nft_burn_cancel_confirmation_dialog_description(Object title);

  /// No description provided for @nft_burn_cancel_confirmation_dialog_cancel_cancel_button.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel'**
  String get nft_burn_cancel_confirmation_dialog_cancel_cancel_button;

  /// No description provided for @nft_burn_cancel_confirmation_dialog_cancel_keep_button.
  ///
  /// In en, this message translates to:
  /// **'No, keep'**
  String get nft_burn_cancel_confirmation_dialog_cancel_keep_button;

  /// No description provided for @nft_transfer_cancel_confirmation_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'Cancel Transfer'**
  String get nft_transfer_cancel_confirmation_dialog_title;

  /// No description provided for @nft_transfer_cancel_confirmation_dialog_description.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel transferring \"{title}\"?'**
  String nft_transfer_cancel_confirmation_dialog_description(Object title);

  /// No description provided for @nft_transfer_cancel_confirmation_dialog_cancel_cancel_button.
  ///
  /// In en, this message translates to:
  /// **'Yes, cancel'**
  String get nft_transfer_cancel_confirmation_dialog_cancel_cancel_button;

  /// No description provided for @nft_transfer_cancel_confirmation_dialog_cancel_keep_button.
  ///
  /// In en, this message translates to:
  /// **'No, keep'**
  String get nft_transfer_cancel_confirmation_dialog_cancel_keep_button;

  /// No description provided for @cardIsNotOwnerCard.
  ///
  /// In en, this message translates to:
  /// **'NFC chip is not an OwnerCard.'**
  String get cardIsNotOwnerCard;

  /// No description provided for @holdPhoneCloseToCardToInit.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone close to the Certificate Card'**
  String get holdPhoneCloseToCardToInit;

  /// No description provided for @loginWithEmail_EnterEmailText.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get loginWithEmail_EnterEmailText;

  /// No description provided for @loginWithEmail_Hint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get loginWithEmail_Hint;

  /// No description provided for @loginWithEmail_okButton.
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get loginWithEmail_okButton;

  /// No description provided for @loginWithEmail_cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get loginWithEmail_cancelButton;

  /// No description provided for @loginWithEmail_ValidationError.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get loginWithEmail_ValidationError;

  /// No description provided for @loginWithEmail_otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter verification code'**
  String get loginWithEmail_otpTitle;

  /// No description provided for @loginWithEmail_otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A 6-digit code was sent to {email}'**
  String loginWithEmail_otpSubtitle(String email);

  /// No description provided for @loginWithEmail_otpHint.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get loginWithEmail_otpHint;

  /// No description provided for @loginWithEmail_otpEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Please enter the code'**
  String get loginWithEmail_otpEmptyError;

  /// No description provided for @loginWithEmail_otpLengthError.
  ///
  /// In en, this message translates to:
  /// **'Code must be 6 digits'**
  String get loginWithEmail_otpLengthError;

  /// No description provided for @loginWithEmail_otpStepTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your email'**
  String get loginWithEmail_otpStepTitle;

  /// No description provided for @loginWithEmail_emailStepHeading.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get loginWithEmail_emailStepHeading;

  /// No description provided for @loginWithEmail_emailStepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send you a 6-digit verification code.'**
  String get loginWithEmail_emailStepSubtitle;

  /// No description provided for @loginWithEmail_sendCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get loginWithEmail_sendCodeButton;

  /// No description provided for @loginWithEmail_otpStepHeading.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox'**
  String get loginWithEmail_otpStepHeading;

  /// No description provided for @loginWithEmail_verifyButton.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get loginWithEmail_verifyButton;

  /// No description provided for @loginWithEmail_resendCodeButton.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get loginWithEmail_resendCodeButton;

  /// No description provided for @loginWithEmail_changeEmailButton.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get loginWithEmail_changeEmailButton;

  /// No description provided for @accountDeletionButton.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get accountDeletionButton;

  /// No description provided for @accountDeletionPopupTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get accountDeletionPopupTitle;

  /// No description provided for @accountDeletionPopupMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This may take up to 10 business days. You will receive an email confirmation once the process is completed. All your data will be deleted, and you will be no able to recover it.'**
  String get accountDeletionPopupMessage;

  /// No description provided for @accountDeletionPopupCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get accountDeletionPopupCancelButton;

  /// No description provided for @accountDeletionPopupDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get accountDeletionPopupDeleteButton;

  /// No description provided for @accountDeletionSentNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Deletion'**
  String get accountDeletionSentNotificationTitle;

  /// No description provided for @accountDeletionSentNotificationMessage.
  ///
  /// In en, this message translates to:
  /// **'Account deletion in progress. You will receive an email confirmation once the process is completed.'**
  String get accountDeletionSentNotificationMessage;

  /// No description provided for @accountDeletionInProgressPopupTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Deletion'**
  String get accountDeletionInProgressPopupTitle;

  /// No description provided for @accountDeletionInProgressPopupMessage.
  ///
  /// In en, this message translates to:
  /// **'Your account deletion is in progress. You will receive an email confirmation once the process is completed.'**
  String get accountDeletionInProgressPopupMessage;

  /// No description provided for @accountDeletionInProgressPopupOkButton.
  ///
  /// In en, this message translates to:
  /// **'Ok'**
  String get accountDeletionInProgressPopupOkButton;

  /// No description provided for @accountDeletionInProgressPopupCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get accountDeletionInProgressPopupCancelButton;

  /// No description provided for @accountDeletionCanceledNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Account Deletion'**
  String get accountDeletionCanceledNotificationTitle;

  /// No description provided for @accountDeletionCanceledNotificationMessage.
  ///
  /// In en, this message translates to:
  /// **'Account deletion canceled.'**
  String get accountDeletionCanceledNotificationMessage;

  /// No description provided for @transferToOwnerCardMessage.
  ///
  /// In en, this message translates to:
  /// **'Hold your phone close to the OwnerCard'**
  String get transferToOwnerCardMessage;

  /// No description provided for @errorSendingCardInitToBackend.
  ///
  /// In en, this message translates to:
  /// **'Error sending card init to backend'**
  String get errorSendingCardInitToBackend;

  /// No description provided for @unsaved_attachments_popup_title.
  ///
  /// In en, this message translates to:
  /// **'Unsaved Attachments'**
  String get unsaved_attachments_popup_title;

  /// No description provided for @unsaved_attachments_popup_message.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved attachments. If you leave this page, your attachments will be lost. Are you sure you want to leave?'**
  String get unsaved_attachments_popup_message;

  /// No description provided for @unsaved_attachments_popup_cancel_button.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get unsaved_attachments_popup_cancel_button;

  /// No description provided for @unsaved_attachments_popup_leave_button.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get unsaved_attachments_popup_leave_button;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
