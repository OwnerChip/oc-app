// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get termsAndConditionsUrl =>
      'https://ownerchip.com/en/general-terms.html';

  @override
  String get tutorialUrl => 'http://www.ownerchip.com/tutorial';

  @override
  String get projectsUrl => 'http://www.ownerchip.com/projects';

  @override
  String get orderChipsUrl => 'http://www.ownerchip.com/orderchips';

  @override
  String get supportUrl => 'https://www.ownerchip.com/creators-corner/';

  @override
  String get legalUrl =>
      'https://www.ownerchip.com/en/app-support-legal-information.html';

  @override
  String get privacyUrl => 'https://www.ownerchip.com/privacy/';

  @override
  String get initializeChip => 'Create Digital Twin';

  @override
  String get walletAddress => 'Wallet address';

  @override
  String get getWalletAddress => 'Get Wallet Address';

  @override
  String get youAreOwner => 'You are the owner';

  @override
  String get youAreNftOwner => 'You are the owner of the Digital Twin';

  @override
  String get theOwnerIs => 'the owner is';

  @override
  String get burnToken => 'Delete Digital Twin';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get authenticate => 'Authenticate';

  @override
  String get walletAuthenticated => 'Wallet authenticated';

  @override
  String get successCardLogin => 'Successfully connected with OwnerCard.';

  @override
  String get scanning => 'Tap an item';

  @override
  String get nfcError => 'Error tapping NFC chip.';

  @override
  String get noNfc => 'Please turn on NFC.';

  @override
  String get isoDepError => 'IsoDep is not supported.';

  @override
  String get ownerError => 'Error fetching owner';

  @override
  String get burning => 'Deleting Digital Twin';

  @override
  String get burnedSuccess => 'Digital Twin deleted.';

  @override
  String get burnedError => 'Error when deleting Digital Twin.';

  @override
  String get mintSuccess => 'Digital Twin created successfully';

  @override
  String get mintError => 'Error creating Digital Twin';

  @override
  String get alreadyLinked =>
      'This NFC chip is already linked to a Digital Twin.';

  @override
  String get cancel => 'Cancel';

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';

  @override
  String get allFunctions => 'All Functions';

  @override
  String get burnAndMint => 'delete and create new';

  @override
  String get showOnExplorer => 'Show Blockchain Details';

  @override
  String get showOnOpenSea => 'Show on OpenSea';

  @override
  String get showOnRarible => 'Show on Rarible';

  @override
  String get openWebLink => 'Open Web Link';

  @override
  String get itemName => 'Item name';

  @override
  String get itemDescription => 'Item description';

  @override
  String get nftDetails => 'Digital Twin Details';

  @override
  String get itemData => 'Item Data';

  @override
  String get loadingData =>
      'Loading Digital Twin data from IPFS. \nThis can take a few seconds.';

  @override
  String get tapItem => 'Tap an item';

  @override
  String get searchChip => 'searching for NFC chip';

  @override
  String get scanHint =>
      'Place your phone closer to the chip. \nHold until the next screen appears.';

  @override
  String get home => 'Home';

  @override
  String get moreInfo => 'More Info';

  @override
  String get uploadImage => 'Please upload an image of the object';

  @override
  String get selectImage => 'Select image';

  @override
  String get takePicture => 'Take picture';

  @override
  String get selectedImage => 'Selected image';

  @override
  String get enterMetadata => 'Please enter your metadata';

  @override
  String get enterText => 'Please enter text';

  @override
  String get title => 'Title';

  @override
  String get description => 'Description';

  @override
  String get traits => 'Traits';

  @override
  String get addTraits => 'Add traits';

  @override
  String get addKey => 'Enter a key';

  @override
  String get addValue => 'Enter a value';

  @override
  String get processing => 'Processing';

  @override
  String get mintNft => 'Create Digital Twin';

  @override
  String get tapResults => 'Tap Results';

  @override
  String get viewNftDetails => 'Show Digital Twin details';

  @override
  String get addressCopied => 'Wallet address copied to clipboard';

  @override
  String get noWalletConnected => 'You have no wallet connected!';

  @override
  String get walletConnected => 'Wallet connected';

  @override
  String get walletIsConnected => 'Your wallet is connected';

  @override
  String get connectWallet => 'Connect Wallet';

  @override
  String get disconnectWallet => 'Disconnect Wallet';

  @override
  String get openWalletToView => 'Open wallet to view Digital Twin';

  @override
  String get showTxHistory => 'Transaction History';

  @override
  String get noNftInWallet => 'There is no Digital Twin in your wallet.';

  @override
  String get nftCheck => 'Digital Twin Check';

  @override
  String get uploadingMetadata => 'Uploading metadata';

  @override
  String get mintingToken => 'Creating Digital Twin';

  @override
  String get pleaseEnterText => 'Please enter text';

  @override
  String get warning => 'Warning';

  @override
  String get showNftInWallet => 'Show Digital Twin in Wallet';

  @override
  String get successHeadingSnackbar => 'Success!';

  @override
  String get errorHeadingSnackBar => 'Oh Snap!';

  @override
  String get loadingNFTDataError =>
      'Error loading Digital Twin data from IPFS.';

  @override
  String get errorConnectingWallet => 'Error when connecting wallet.';

  @override
  String get errorNoInternetConnection => 'No internet connection.';

  @override
  String get errorNoNfcReader => 'NFC Reader is not activated';

  @override
  String get congrats => 'Congrats!';

  @override
  String get ownershipCheck => 'Ownership Check';

  @override
  String get authenticityNftFound => 'Digital Twin exists on blockchain.';

  @override
  String get authenticityNftNotFound =>
      'Digital Twin does not exist on blockchain.';

  @override
  String get authenticityCheck => 'Authenticity Check';

  @override
  String get nfcCheck => 'NFC Check';

  @override
  String get whoops => 'Whoops!';

  @override
  String get youAreNotNftOwner => 'This Digital Twin is not in your wallet.';

  @override
  String get youAreNFTOwner => 'This item is yours.';

  @override
  String get loading => 'Loading...';

  @override
  String get authentic => 'Authentic';

  @override
  String get ownershipCouldNotBeVerified => 'Ownership could not be verified.';

  @override
  String get disconnect => 'Logout';

  @override
  String get connect => 'Login';

  @override
  String get remove => 'Remove';

  @override
  String get add => 'Add trait';

  @override
  String get type => 'Type';

  @override
  String get value => 'Value';

  @override
  String get showTraits => 'Show Traits';

  @override
  String get showDescription => 'Show Description';

  @override
  String get continueInBackground => 'Continue in background';

  @override
  String get unknownCollection => 'Unknown collection';

  @override
  String get chooseChain => 'Choose \n Chain + Collection';

  @override
  String get legal => 'Legal Information';

  @override
  String get support => 'Support';

  @override
  String get selectChain => 'Select Chain';

  @override
  String get selectBlockchain => 'Blockchain';

  @override
  String get selectCollection => 'Collection';

  @override
  String get troubleshoot => 'I need help';

  @override
  String get more => 'More';

  @override
  String get watchTutorial => 'Watch Tutorial';

  @override
  String get viewProjects => 'View our Projects';

  @override
  String get orderChips => 'Order NFC Chips';

  @override
  String get signupAsCertifier => 'SignUp as Certifier';

  @override
  String get scanNow => 'Tap Now';

  @override
  String get pleaseSelect => '- please select -';

  @override
  String get pleaseSelectChainAndCollection =>
      'Please select a Blockchain & Collection';

  @override
  String get digitalTwin => 'Certificate';

  @override
  String get authenticity => 'Authenticity';

  @override
  String get ownership => 'Ownership';

  @override
  String get unconfirmed => 'Not confirmed';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get externalLinks => 'Web Links';

  @override
  String get transferToken => 'Transfer';

  @override
  String get transferInProgress => 'Transferring Digital Twin';

  @override
  String get transferSuccess => 'Digital Twin transferred';

  @override
  String get transferError => 'Error transferring Digital Twin';

  @override
  String get enterWalletAddress => 'Enter wallet address';

  @override
  String get pleaseEnterValidWalletAddress =>
      'Please enter a valid wallet address.';

  @override
  String get creationOfTwin => 'Create your Digital Twin';

  @override
  String get warningPublicData => 'All entered data is publicly visible.';

  @override
  String get infoScreenText =>
      'Check items for authenticity and ownership using your smartphone.';

  @override
  String get transferScreenText =>
      'Transfer your Digital Twin to another wallet.';

  @override
  String get chooseWallet => 'Select login method';

  @override
  String get agreeToWhenConnecting => 'By connecting you agree to our ';

  @override
  String get generalTerms => 'general terms';

  @override
  String get and => 'and';

  @override
  String get privacyPolicy => 'privacy policy';

  @override
  String get zu => '';

  @override
  String get step => 'Step';

  @override
  String get viewGallery => 'View Gallery';

  @override
  String get chooseFile => 'Choose File';

  @override
  String get addDigitalContent => 'Add Digital Content';

  @override
  String get titleTooLong => 'Title too long.';

  @override
  String get titleCannotBeEmpty => 'Title cannot be empty.';

  @override
  String get maxAttachmentsReached => 'You can add max. 50 attachments.';

  @override
  String get enterValidUrl =>
      'Please enter a valid URL starting with https://.';

  @override
  String get urlCannotBeEmpty => 'URL cannot be empty.';

  @override
  String get public => 'Public';

  @override
  String get private => 'Private';

  @override
  String get contentCanBeViewedPublic =>
      'This content can be viewed by everyone who taps the item.';

  @override
  String get contentCanOnlyBeViewedPrivate =>
      'This content can only be viewed by the verified owner.';

  @override
  String get addFile => 'Add File';

  @override
  String get addUrl => 'Add URL';

  @override
  String get editAttachment => 'Edit Attachment';

  @override
  String get selectAttachmentYouWantToEdit =>
      'Select attachment you want to edit or remove.';

  @override
  String get uploadDigitalContent => 'Upload Digital Content';

  @override
  String get creatorContent => 'Creator Content';

  @override
  String get ownerContent => 'Owner Content';

  @override
  String get fileEdited => 'File edited.';

  @override
  String get errorUpdatingData => 'Error updating data.';

  @override
  String get errorUploadingFile => 'Error uploading file.';

  @override
  String get fileAttached => 'File attached.';

  @override
  String get savingUrl => 'Saving URL...';

  @override
  String get urlAttached => 'URL attached.';

  @override
  String get errorSavingUrl => 'Error saving URL.';

  @override
  String get errorDeletingAttachment => 'Error deleting attachment.';

  @override
  String get attachmentDeleted => 'Attachment deleted.';

  @override
  String get pressConnectToSignIn =>
      'Press connect to sign in with your OwnerCard.';

  @override
  String get youCanUseThisPukToResetYourPin =>
      'You can use the PUK in case you forget your PIN code.';

  @override
  String get pukCopied => 'PUK copied to clipboard';

  @override
  String get setUpOwnerCard => 'Set up new OwnerCard';

  @override
  String get confirmYourIdentity =>
      'Confirm your identity by authenticating your wallet.';

  @override
  String get errorSettingPin => 'Error setting OwnerCard PIN.';

  @override
  String get holdPhoneToCard => 'Hold your phone close to your OwnerCard.';

  @override
  String get errorAuthenticatingCard => 'Error authenticating OwnerCard.';

  @override
  String get errorMakingSignature => 'Error making signature.';

  @override
  String get holdPhoneToNfcChip => 'Hold your phone close to the NFC chip';

  @override
  String get setUpPin => 'Set up new PIN for OwnerCard';

  @override
  String get enterPinToAuth => 'Enter PIN to authenticate';

  @override
  String get connectOwnerCard => 'Connect OwnerCard';

  @override
  String get enterPinToConfirmTx => 'Enter PIN to confirm transaction';

  @override
  String get confirmTx => 'Confirm Transaction';

  @override
  String get enterPuk => 'Enter PUK';

  @override
  String get successfullySetUpPin => 'Successfully set up PIN';

  @override
  String get transferOwnership => 'Transfer Ownership';

  @override
  String get transferringOwnership => 'Ownership is being transferred';

  @override
  String get claimOwnership => 'Claim Ownership';

  @override
  String get claimingOwnership => 'Ownership is being claimed';

  @override
  String get tokenWasTransferred => 'Ownership was transferred to ';

  @override
  String get tokenNotYetClaimed => ' but has not yet been claimed.';

  @override
  String get holdPhoneCloseToOwnerCardToInit =>
      'Hold your phone close to the OwnerCard you want to initialize.';

  @override
  String get chipIsNoCard => 'Chip is not an OwnerCard.';

  @override
  String get twoSlotsInitSuccess => 'First two public keys initialized.';

  @override
  String get twoSlotsInitError =>
      '\'Error initializing first two public key slots.';

  @override
  String get tokenIdCopiedToClipboard => 'Digital Twin ID copied to clipboard';

  @override
  String get walletAddressCopiedToClipboard =>
      'Wallet address copied to clipboard';

  @override
  String get isNotOwnerCard => 'NFC chip is not an OwnerCard.';

  @override
  String get whenSigningInWithMetamask =>
      'When signing in via Metamask make sure to connect with Ethereum Mainnet.';

  @override
  String get pinResetSuccess => 'PIN reset. Save your new PUK!';

  @override
  String get enterFourDigitPin => 'Enter new 4 digit PIN';

  @override
  String get enterPUK => 'Enter PUK';

  @override
  String get done => 'Done';

  @override
  String get submit => 'Submit';

  @override
  String get errorSigningTx => 'Error signing transaction.';

  @override
  String get errorReadingChip => 'Error reading chip.';

  @override
  String get receivingToken => 'Receiving Digital Twin';

  @override
  String get transferToAddress => 'Transfer to address';

  @override
  String get cardLost => 'OwnerCard lost';

  @override
  String get cardLostContacted =>
      'Thank you for submitting your request. Our support team will get in touch with you shortly.';

  @override
  String get scanToTriggerCardLost =>
      'Now hold your phone close to the NFC chip on the item linked to your lost OwnerCard.';

  @override
  String get enterEmailToTriggerCardLost =>
      'Enter email to trigger process for receiving new card.';

  @override
  String get tokenDoesNotExist => 'Digital Twin does not exist.';

  @override
  String get pleaseEnterValidEmailAddress =>
      'Please enter valid email address.';

  @override
  String get chipAddress => 'Chip address';

  @override
  String get transferOnlyToOwnerCard =>
      'Transfer only possible to initialized OwnerCard.';

  @override
  String get digitalContentWillBeTransferred =>
      'Public and private digital content will be transferred together with the Digital Twin.';

  @override
  String get ownercard => 'OwnerCard';

  @override
  String get certificatecard => 'Certificate Card';

  @override
  String get or => 'or';

  @override
  String get cardNotInitializedByAdmin =>
      'OwnerCard not yet initialized by admin.';

  @override
  String get deletingAttachment => 'Deleting attachment';

  @override
  String get enterPIN => 'Enter PIN';

  @override
  String get transferToOwnerCard => 'Transfer to OwnerCard';

  @override
  String get resetPIN => 'Reset PIN';

  @override
  String get toRequestNewCard =>
      'To request a new card, please enter your contact details below.';

  @override
  String get uploadingAttachment => 'Uploading Attachment...';

  @override
  String get creatorData => 'Creator Profile';

  @override
  String get digitalTwinVerifiedBy => 'Digital Twin verified by ';

  @override
  String get pleaseScanItem => 'Tap the item';

  @override
  String get scanItemToTriggerCardLost =>
      'In the next step, please tap the item that is associated with your lost OwnerCard. \n\nThis will allow us to restore its digital counterpart on to your replacement card.';

  @override
  String get pleaseEnterValidTel => 'Please enter valid phone number';

  @override
  String get pleaseEnterValidName => 'Please enter valid name';

  @override
  String get pleaseTryAgainLater => 'Please try again later.';

  @override
  String get showCreatorData => 'Show Creator Data';

  @override
  String get next => 'Next';

  @override
  String get requestSent => 'Request sent!';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get emailAddress => 'Email address';

  @override
  String get setPin => 'Set PIN';

  @override
  String get createdAt => 'Created at';

  @override
  String get pleaseHoldPhoneLonger => 'Please hold phone to chip a bit longer.';

  @override
  String get unableToReadChip => 'Unable to read NFC chip';

  @override
  String get offerOnOpenSea => 'Offer on OpenSea';

  @override
  String get offerOnRarible => 'Offer on Rarible';

  @override
  String get offeringToken => 'Offering Digital Twin...';

  @override
  String get itemOffered => 'Item offered';

  @override
  String get itemOfferedOnMP => 'Item offered on marketplace';

  @override
  String get viewOnMP => 'View on Marketplace';

  @override
  String get errorOfferingToken => 'Error offering Digital Twin';

  @override
  String get offerItem => 'Offer item';

  @override
  String get enterWalletAddressForPayout =>
      'Enter wallet to receive the payment';

  @override
  String get price => 'Price';

  @override
  String get enterSalePrice => 'Enter sale price for your item';

  @override
  String get listOnRarible => 'List on Rarible';

  @override
  String get offerNow => 'Offer on Rarible';

  @override
  String get offerForSale => 'Sell';

  @override
  String get offerCanceled => 'Offer canceled';

  @override
  String get errorCancellingSale => 'Error canceling sale of Digital Twin.';

  @override
  String get redeemingtoken => 'Redeeming Digital Twin';

  @override
  String get tokenRedeemed => 'Digital Twin redeemed';

  @override
  String get errorRedeemingToken => 'Error redeeming Digital Twin.';

  @override
  String get redeemToken => 'Redeem Digital Twin';

  @override
  String get claimPhysicalItem =>
      'Claim physical item linked to an Digital Twin in your wallet';

  @override
  String get enterShippingAddress => 'Enter shipping address';

  @override
  String get shippingDataSuccessfullySent => 'Shipping data successfully sent.';

  @override
  String get youWillReceiveFurtherInformationViaEmail =>
      'You will receive further details via email.';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get pleaseEnterFirstName => 'Please enter first name.';

  @override
  String get pleaseEnterLastName => 'Please enter last name.';

  @override
  String get company => 'Company';

  @override
  String get streetAddress => 'Street Address';

  @override
  String get pleaseEnterStreetAddress => 'Please enter street address.';

  @override
  String get streetAddress1 => 'Street Address 1';

  @override
  String get city => 'City';

  @override
  String get pleaseEnterCity => 'Please enter city.';

  @override
  String get zip => 'Zip';

  @override
  String get pleaseEnterZip => 'Please enter zip.';

  @override
  String get stateProvince => 'State/Province';

  @override
  String get shippingAddress => 'Shipping address';

  @override
  String get selectCountry => 'Select country';

  @override
  String get search => 'Search';

  @override
  String get startTypingToSearch => 'Start typing to search';

  @override
  String get country => 'Country';

  @override
  String get pleaseEnterCountry => 'Please enter country.';

  @override
  String get contact => 'Contact';

  @override
  String get sendShippingData => 'Send shipping data';

  @override
  String get cancelOffer => 'Cancel offer';

  @override
  String get tokenCurrentlyOfferedForSale =>
      'Digital Twin is currently offered for sale on a marketplace.';

  @override
  String get payoutWalletAddress => 'Payout wallet address';

  @override
  String get youAreTheNewOwner =>
      'You are the new owner. The Digital Twin can now be transferred into your wallet.';

  @override
  String get transfer => 'Transfer';

  @override
  String get ownerChipWillNotifyYouOnceTheItemIsPurchased =>
      'OwnerChip will notify you via email once the item is purchased. You are responsible for packaging and shipping the item to the buyer.';

  @override
  String get thisItemHasBeenSold =>
      'This item has been sold. You have received shipping instructions via email.';

  @override
  String get pleaseScanChipAgainToCancel =>
      'Please tap NFC chip again to cancel offer.';

  @override
  String get pleaseScanChipAgainToBurn =>
      'Please tap NFC chip again to delete Digital Twin.';

  @override
  String get attention => 'Attention!';

  @override
  String get mintingVoucherToken => 'Creating Digital Twin...';

  @override
  String get requestShipment => 'Request the shipment now.';

  @override
  String get manualHandover => 'Manual handover';

  @override
  String get feesInfo =>
      '5% protocol fees + marketplace fees will be deducted from payout amount. \n \n EUR value may fluctuate with crypto exchange rates.';

  @override
  String get successManualHandover =>
      'Tap the NFC chip to claim your Digital Twin.';

  @override
  String get itemAvailableForSale => 'This item is available for sale.';

  @override
  String get buyOnRarible => 'Buy on Rarible';

  @override
  String get voucherNftDescriptionGeneral =>
      'This Digital Twin includes the ownership of a physical artwork which can be redeemed after the purchase';

  @override
  String voucherNftDescriptionAppSpecific(Object CERTIFICATE_LINK) {
    return 'via the OwnerChip-App, downloadable in the Google Playstore and Apple AppStore. You can view the digital certificate at this link: $CERTIFICATE_LINK\nFor more information visit https://ownerchip.com/redeem';
  }

  @override
  String get transferred => 'Transferred';

  @override
  String get errorWhenOffering =>
      'Something went wrong when offering your Digital Twin. Please recover Digital Twin or contact support.';

  @override
  String get recoverToken => 'Recover Digital Twin';

  @override
  String get enterDetails => 'Enter details';

  @override
  String get myCollection => 'My collection';

  @override
  String get pleaseConnectWalletToViewItems =>
      'Please connect your wallet to view items.';

  @override
  String get ownedByMe => 'Owned by me';

  @override
  String get createdByMe => 'Created by me';

  @override
  String get youHaveNotMintedAnyItems =>
      'You have not created any Digital Twins.';

  @override
  String get youDoNotOwnAnyItems => 'You do not own any Digital Twins.';

  @override
  String get legalHintTerrorismFinancing =>
      'I have fulfilled all my due diligence obligations with regard to the prevention of money laundering and terrorist financing in accordance with the laws applicable to me.';

  @override
  String get shippingHint =>
      'I am responsible for handling, packaging and shipping costs associated with the offer.';

  @override
  String get appBarProfileTitle => 'Profile';

  @override
  String get appBarWalletIdTitle => 'Wallet ID';

  @override
  String get copiedAddressToClipboard => 'Address copied to clipboard';

  @override
  String get appbarMyBalanceButton => 'My Balance';

  @override
  String get myBalanceTitle => 'My Balance';

  @override
  String get myBalanceTotalBalance => 'Total Balance';

  @override
  String get myBalanceChoseCrypto =>
      'Choose a crypto currency you want to transfer';

  @override
  String get myBalanceReceivingWalletAddress => 'Receiving wallet address';

  @override
  String get myBalanceCryptoAmount => 'Amount';

  @override
  String get myBalanceSendMaxButton => 'Send max. amount';

  @override
  String get myBalanceSendButton => 'Send';

  @override
  String get myBalanceConfirmationDialogTitle => 'Confirmation';

  @override
  String get myBalanceConfirmationRecipient => 'Recipient:';

  @override
  String get myBalanceConfirmationAmount => 'Amount:';

  @override
  String get myBalanceConfirmationCurrency => 'Currency:';

  @override
  String get myBalanceConfirmationChain => 'Chain:';

  @override
  String get myBalanceConfirmationConfirmButton => 'Confirm';

  @override
  String get myBalanceConfirmationCancelButton => 'Cancel';

  @override
  String get myBalancePullToRefresh => 'Pull to refresh';

  @override
  String get myBalanceRefreshing => 'Refreshing...';

  @override
  String get myBalanceError => 'Error occurred while loading balance';

  @override
  String get myBalanceRetry => 'Retry';

  @override
  String get myBalanceWithdrawSufficientFunds => 'Insufficient crypto!';

  @override
  String get myBalanceWithdrawLoadingText => 'Sending crypto...';

  @override
  String get myBalanceWithdrawSuccessText => 'Sending successfully';

  @override
  String get myBalanceWithdrawErrorText => 'Error sending crypto';

  @override
  String get myBalanceWithdrawBackButton => 'Back';

  @override
  String get myBalanceWithdrawPasteAddressButton => 'Paste';

  @override
  String get myBalanceWithdrawWrongAddress => 'Please enter a valid address';

  @override
  String myBalanceWithdrawMaxAmount(Object amount) {
    return 'Max: $amount';
  }

  @override
  String get onboardingTitle => 'Great that you\'re here!';

  @override
  String get onboardingFeatureAuthenticityTitle => 'Prove Authenticity';

  @override
  String get onboardingFeatureAuthenticitySubtitle =>
      'Tap items to verify authenticity.';

  @override
  String get onboardingFeatureDigitalExperiencesTitle =>
      'Access Digital Content';

  @override
  String get onboardingFeatureDigitalExperiencesSubtitle =>
      'Unlock digital content attached to physical items.';

  @override
  String get onboardingFeatureSellTitle => 'Sell & Re-Sell';

  @override
  String get onboardingFeatureSellSubtitle =>
      'Trade physical-digital package on web3 marketplaces.';

  @override
  String get onboardingStartButton => 'Start Tutorial';

  @override
  String get onboardingUserPageTitle => 'How to use this App';

  @override
  String onboardingPagination(Object current) {
    return 'Step $current/';
  }

  @override
  String get onboardingUserPageStep1Title => 'Tap NFC chip';

  @override
  String get onboardingUserPageStep1Subtitle =>
      'Press \"Tap Now\" and hold your phone close to the chip.';

  @override
  String get onboardingUserPageStep2Title => 'Login with your wallet';

  @override
  String get onboardingUserPageStep2Subtitle =>
      'Identify yourself using your OwnerCard or your crypto wallet to prove and transfer ownership and unlock private digital content.';

  @override
  String get onboardingUsePageNextButtonTitle => 'Next';

  @override
  String get onboardingUserPageCompleteButtonTitle => 'Next';

  @override
  String get onboardingUserCompleteCreatorPageTitle => 'Are you a Creator?';

  @override
  String get onboardingUserCompleteCreatorPageSubtitle =>
      'Learn how to create a Digital Twin.';

  @override
  String get onboardingUserCompleteCreatorButtonTitle =>
      'Start Creator Tutorial';

  @override
  String get onboardingCreatorPageTitle => 'How to create a Digital Twin';

  @override
  String get onboardingCreatorStep1Title => 'Got NFC Chips?';

  @override
  String get onboardingCreatorStep1SubTitle =>
      'Order our StarterKit and get registered as a Creator.';

  @override
  String get onboardingCreatorStep1OrderButtonTitle => 'Order now';

  @override
  String get onboardingCreatorStep2Title => 'Attach the NFC chip';

  @override
  String get onboardingCreatorStep2SubTitle =>
      'Incorporate the NFC chip into your item, for example by using adhesive foils, glue, or stickers.';

  @override
  String get onboardingCreatorStep3Title => 'Watch Video Tutorial';

  @override
  String get onboardingCreatorStep3SubTitle =>
      'Watch our App Demo to create your first Digital Twin in a few minutes.';

  @override
  String get onboardingCreatorStep3YoutubeVideoURL =>
      'https://youtube.com/watch?v=iB8g9QLSvw0';

  @override
  String get onboardingCreatorCompleteButtonTitle => 'Create Digital Twin';

  @override
  String get onboardingUserCompleteTitle => 'You\'re all done!';

  @override
  String get onboardingUserCompleteSubtitle =>
      'You have completed the tutorial.';

  @override
  String get onboardingUserCompleteButtonTitle => 'Start tapping now!';

  @override
  String get onboardingCheckboxShowAgainTitle => 'Show again next time';

  @override
  String get onboardingMoreInfoShowTutorialButtonTitle => 'Show Tutorial';

  @override
  String get galleryPullToRefresh => 'Pull to refresh';

  @override
  String get galleryRefreshing => 'Refreshing...';

  @override
  String get galleryLoadMore => 'Load more';

  @override
  String get galleryLoadingMore => 'Loading...';

  @override
  String get galleryNoMoreItems => 'No more Digital Twins to load';

  @override
  String get errorLoadingOwnedItems => 'Error loading owned Digital Twins';

  @override
  String get errorLoadingCreatedItems => 'Error loading created Digital Twins';

  @override
  String get galleryErrorLoadingMore => 'Error loading more Digital Twins';

  @override
  String get offerForSaleCreatedTokenAppBarTitle => '';

  @override
  String get offerForSaleCreatedTokenTitle => 'Token created';

  @override
  String get offerForSaleCreatedTokenSubtitle =>
      'You have successfully created a digital twin for your physical object.';

  @override
  String get offerForSaleCreatedTokenButton => 'Offer for sale';

  @override
  String get offerForSaleCreatedTokenViewTokenButton => 'View token';

  @override
  String get offerOnMpDiscoverDialogTitle => 'Offer on Marketplace';

  @override
  String get offerOnMpDiscoveryDialogMessage =>
      'The function “Offer on Marketplace” is not available in this “OwnerChip Discovery” app which is designed for NFC chip demo purposes only, not for real trading of goods. Use the app “OwnerChip” instead and request whitelisting in the “More…” menu.';

  @override
  String get offerOnMpEmailHint =>
      'We will use this email address to notify you about the status of the offer.';

  @override
  String get offerOnMpPriceHint =>
      '5% protocol fees + marketplace fees will be deducted from payout amount. Please check the support section for more details.';

  @override
  String offerOnMpEstimatedPriceInEur(Object price) {
    return 'Estimated EUR value as of today ~$price';
  }

  @override
  String get offerOnMpFetchingPrice => 'Fetching current price...';

  @override
  String get offerOnMpErrorFetchingPrice => 'Error fetching current price';

  @override
  String get offerOnMpPublishedDialogTitle => 'Published on Marketplace';

  @override
  String get offerOnMpPublishedDialogSubtitle =>
      'Your item is now available for sale!';

  @override
  String get newVersionTitle => 'Update App';

  @override
  String get newVersionAvailable =>
      'A new version of the app is available! Please update to the latest version.';

  @override
  String get newVersionUpdateButton => 'Update';

  @override
  String get scanResultPageShowCertificateButton => 'Show Certificate Details';

  @override
  String get scanResultPage_ownershipCheck => 'Ownership Check';

  @override
  String get scanResultPage_ownershipOwnerOffered =>
      'You are the owner of this item. Digital Twin is offered on a marketplace.';

  @override
  String get scanResultPage_ownershipOwnerNotOffered =>
      'You are the owner of this item.';

  @override
  String get scanResultPage_ownershipNotOwnerOffered =>
      'You are not the owner of this item. Digital Twin is offered on a marketplace.';

  @override
  String get scanResultPage_ownershipNotOwnerNotOffered =>
      'Your are not the owner of this item.';

  @override
  String get scanResultPage_buttonOwnerOffered => 'Show Offer';

  @override
  String get scanResultPage_buttonNotOwnerOffered => 'Show Offer';

  @override
  String get scanResultPage_chipHasNotYetBeenInitialized =>
      'The NFC chip has not yet been activated.';

  @override
  String get nftDetailsPageShowCertificateButton => 'Show Certificate Details';

  @override
  String get nftDetailsPageAuthenticityCertified => 'Certified';

  @override
  String get nftDetailsPageAuthenticityNotCertified => 'Not certified';

  @override
  String get nftDetailsPageCertifier => 'Certifier';

  @override
  String get nftDetailsPageCreationDate => 'Creation date';

  @override
  String get nftDetailsPageCollection => 'Collection';

  @override
  String get nftDetailsErrorFetchingCertificateData => 'unknown';

  @override
  String get nftCreationsPageTitle => 'Digital Twins';

  @override
  String get nftCreationsPagePullToRefresh => 'Pull to refresh';

  @override
  String get nftCreationsPageRefreshing => 'Refreshing...';

  @override
  String get nftCreationsHomeScreenButtonTitle => 'Sign Transactions';

  @override
  String get nftCreationsPageToBeBurned => 'Deletion pending';

  @override
  String get nftCreationsPagePending => 'Activation pending';

  @override
  String get nftCreationsPageToBeTransferred => 'Transfer pending';

  @override
  String get nftCreationsPageError => 'Error';

  @override
  String get nftCreationsPageChipMismatchError => 'Chip mismatch';

  @override
  String get nftCreationsPagePullToLoadMore => 'Pull to load more';

  @override
  String get nftCreationsPageLoading => 'Loading...';

  @override
  String get nftCreationsLoggedInWithDifferentWalletTitle => 'Wallet';

  @override
  String get nftCreationsLoggedInWithDifferentWalletDescription =>
      'You are logged in with a different wallet. Please log in with the wallet you used to create the Digital Twin.';

  @override
  String get nftCreationsLoggedInWidthDifferentWalletButton => 'Close';

  @override
  String get nftCreationsNotLoggedInTitle => 'Wallet';

  @override
  String get nftCreationsNotLoggedInDescription =>
      'Please log in with the wallet you used to create the Digital Twin.';

  @override
  String get nftCreationsNotLoggedInButton => 'Close';

  @override
  String get nftCreationsAlreadyMintedToken =>
      'The chip you scanned is already activated with another digital twin';

  @override
  String get nftCreationRestoreTokenPopupTitle => 'Restore Digital Twin';

  @override
  String get nftCreationRestoreTokenPopupMessage =>
      'The chip you scanned is already activated with another digital twin. Do you want to restore the Digital Twin?';

  @override
  String get nftCreationRestoreTokenPopupCancelButton => 'Cancel';

  @override
  String get nftCreationRestoreTokenPopupRestoreButton => 'Restore';

  @override
  String get nftCreationRestoreTokenPopupViewTokenButton => 'View Digital Twin';

  @override
  String get nftCreationRestoreTokenPopupSuccessTitle =>
      'Digital Twin restored';

  @override
  String get nftCreationMultiSeriesTitle => 'Series Activation';

  @override
  String nftCreationMultiSeriesDescription(Object number) {
    return 'Series - $number twins';
  }

  @override
  String nftCreationMultiSeriesStatus(Object current, Object total) {
    return '$current of $total activated';
  }

  @override
  String get nftCreationMultiSeriesActivateButton => 'Scan next NFC chip';

  @override
  String get nftCreationMultiSeriesPause => 'Pause and continue later';

  @override
  String get nftCreationMultiSeriesBadge => 'Series';

  @override
  String nftCreationMultiSeriesItemsCount(String count) {
    return '$count items';
  }

  @override
  String nftCreationMultiSeriesItemsActivated(String current, String total) {
    return '$current of $total items activated';
  }

  @override
  String get nftCreationSeriesStatusActivationPending => 'Activation pending';

  @override
  String get nftCreationSeriesStatusDraft => 'Draft';

  @override
  String get nftCreationSeriesStatusActive => 'Active';

  @override
  String get nftCreationSeriesStatusToBeBurned => 'To be burned';

  @override
  String get nftCreationSeriesStatusToBeTransferred => 'To be transferred';

  @override
  String get nftCreationSeriesActionStartScanning => 'Tap to start scanning';

  @override
  String get nftCreationSeriesActionConnectNFC =>
      'Tap to connect with NFC chip';

  @override
  String get nftCreationSingleItemBadge => 'Single item';

  @override
  String get nftCreationSingleActionConnectNFC =>
      'Tap to connect with NFC chip';

  @override
  String get nftCreationSingleActionBurnToken => 'Tap to burn token';

  @override
  String get nftCreationSingleActionTransferToken => 'Tap to transfer token';

  @override
  String get nft_cancel_confirmation_dialog_title => 'Cancel NFT';

  @override
  String nft_cancel_confirmation_dialog_description(Object title) {
    return 'Are you sure you want to cancel activation for \"$title\"?';
  }

  @override
  String get nft_cancel_confirmation_dialog_cancel_cancel_button =>
      'Yes, cancel activation';

  @override
  String get nft_cancel_confirmation_dialog_cancel_keep_button =>
      'No, continue';

  @override
  String get nft_burn_cancel_confirmation_dialog_title => 'Cancel Burn';

  @override
  String nft_burn_cancel_confirmation_dialog_description(Object title) {
    return 'Are you sure you want to cancel burning \"$title\"?';
  }

  @override
  String get nft_burn_cancel_confirmation_dialog_cancel_cancel_button =>
      'Yes, cancel';

  @override
  String get nft_burn_cancel_confirmation_dialog_cancel_keep_button =>
      'No, keep';

  @override
  String get nft_transfer_cancel_confirmation_dialog_title => 'Cancel Transfer';

  @override
  String nft_transfer_cancel_confirmation_dialog_description(Object title) {
    return 'Are you sure you want to cancel transferring \"$title\"?';
  }

  @override
  String get nft_transfer_cancel_confirmation_dialog_cancel_cancel_button =>
      'Yes, cancel';

  @override
  String get nft_transfer_cancel_confirmation_dialog_cancel_keep_button =>
      'No, keep';

  @override
  String get certificateCardLoginSuccess =>
      'Successfully connected with Certificate Card.';

  @override
  String get cannotSetPinOnCertificateCard =>
      'Cannot set PIN on Certificate Card';

  @override
  String get cannotResetPinOnCertificateCard =>
      'Cannot reset PIN on Certificate Card';

  @override
  String get cardIsNotCertificateCard => 'NFC chip is not a Certificate Card.';

  @override
  String get cardIsNotOwnerCard => 'NFC chip is not an OwnerCard.';

  @override
  String get holdPhoneCloseToCertificateCardToInit =>
      'Hold your phone close to the Certificate Card';

  @override
  String get cannotCardLostOnCertificateCard =>
      'Cannot use Certificate Card for card lost.';

  @override
  String get scanQRCode => 'Scan QR code';

  @override
  String get noConnection => 'No connection';

  @override
  String get invalidQRCode => 'Invalid QR code';

  @override
  String get reconnectWebSocketButtonText => 'Reconnect';

  @override
  String get reconnectWebSocketErrorText => 'Error reconnecting';

  @override
  String get reconnectWebSocketSuccessText => 'Reconnected';

  @override
  String get loginWithEmail_EnterEmailText => 'Please enter your email address';

  @override
  String get loginWithEmail_Hint => 'Email';

  @override
  String get loginWithEmail_okButton => 'Ok';

  @override
  String get loginWithEmail_cancelButton => 'Cancel';

  @override
  String get loginWithEmail_ValidationError =>
      'Please enter a valid email address';

  @override
  String get accountDeletionButton => 'Delete Account';

  @override
  String get accountDeletionPopupTitle => 'Delete Account';

  @override
  String get accountDeletionPopupMessage =>
      'Are you sure you want to delete your account? This may take up to 10 business days. You will receive an email confirmation once the process is completed. All your data will be deleted, and you will be no able to recover it.';

  @override
  String get accountDeletionPopupCancelButton => 'Cancel';

  @override
  String get accountDeletionPopupDeleteButton => 'Delete';

  @override
  String get accountDeletionSentNotificationTitle => 'Account Deletion';

  @override
  String get accountDeletionSentNotificationMessage =>
      'Account deletion in progress. You will receive an email confirmation once the process is completed.';

  @override
  String get accountDeletionInProgressPopupTitle => 'Account Deletion';

  @override
  String get accountDeletionInProgressPopupMessage =>
      'Your account deletion is in progress. You will receive an email confirmation once the process is completed.';

  @override
  String get accountDeletionInProgressPopupOkButton => 'Ok';

  @override
  String get accountDeletionInProgressPopupCancelButton => 'Cancel';

  @override
  String get accountDeletionCanceledNotificationTitle => 'Account Deletion';

  @override
  String get accountDeletionCanceledNotificationMessage =>
      'Account deletion canceled.';

  @override
  String get transferToOwnerCardMessage =>
      'Hold your phone close to the OwnerCard';

  @override
  String get errorSendingCardInitToBackend =>
      'Error sending card init to backend';

  @override
  String get unsaved_attachments_popup_title => 'Unsaved Attachments';

  @override
  String get unsaved_attachments_popup_message =>
      'You have unsaved attachments. If you leave this page, your attachments will be lost. Are you sure you want to leave?';

  @override
  String get unsaved_attachments_popup_cancel_button => 'Cancel';

  @override
  String get unsaved_attachments_popup_leave_button => 'Leave';
}
