// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

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
  String get initializeChip => 'Digital Twin erstellen';

  @override
  String get walletAddress => 'Wallet-Adresse';

  @override
  String get getWalletAddress => 'Wallet-Adresse finden';

  @override
  String get youAreOwner => 'Du bist der Eigentümer';

  @override
  String get youAreNftOwner => 'Du bist der Digital Twin Eigentümer';

  @override
  String get theOwnerIs => 'Der Eigentümer ist';

  @override
  String get burnToken => 'Digital Twin löschen';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get authenticate => 'Authentifizieren';

  @override
  String get walletAuthenticated => 'Wallet authentifiziert';

  @override
  String get successCardLogin => 'Erfolgreich mit OwnerCard verbunden.';

  @override
  String get scanning => 'Chip scannen';

  @override
  String get nfcError => 'Fehler beim Scannen des NFC-Chips.';

  @override
  String get noNfc => 'Bitte NFC einschalten';

  @override
  String get isoDepError => 'IsoDep wird nicht unterstützt.';

  @override
  String get ownerError => 'Fehler bei der Eigentumsprüfung';

  @override
  String get burning => 'Digital Twin wird gelöscht';

  @override
  String get burnedSuccess => 'Digital Twin erfolgreich gelöscht';

  @override
  String get burnedError => 'Fehler beim Löschen des Digital Twin';

  @override
  String get mintSuccess => 'Digital Twin erfolgreich erstellt';

  @override
  String get mintError => 'Fehler beim Erstellen des Digital Twin';

  @override
  String get alreadyLinked =>
      'Dieser NFC-Chip ist bereits mit einem Digital Twin verbunden.';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get save => 'Speichern';

  @override
  String get allFunctions => 'Alle Funktionen';

  @override
  String get burnAndMint => 'Löschen & neu erstellen';

  @override
  String get showOnExplorer => 'Blockchain-Details ansehen';

  @override
  String get showOnOpenSea => 'Auf OpenSea ansehen';

  @override
  String get showOnRarible => 'Auf Rarible ansehen';

  @override
  String get openWebLink => 'Weblink öffnen';

  @override
  String get itemName => 'Name';

  @override
  String get itemDescription => 'Beschreibung';

  @override
  String get nftDetails => 'Digital Twin Details';

  @override
  String get itemData => 'Gespeicherte Daten';

  @override
  String get loadingData =>
      'Digital Twin Daten werden von IPFS geladen. \nBitte um einen Moment Geduld.';

  @override
  String get tapItem => 'Gegenstand scannen';

  @override
  String get searchChip => 'Suche nach NFC-Chip';

  @override
  String get scanHint =>
      'Halte dein Smartphone näher an den Chip bis der nächste Screen erscheint.';

  @override
  String get home => 'Home';

  @override
  String get moreInfo => 'Weitere Informationen';

  @override
  String get uploadImage => 'Bitte lade ein Bild des Gegenstands hoch';

  @override
  String get selectImage => 'Bild auswählen';

  @override
  String get takePicture => 'Foto machen';

  @override
  String get selectedImage => 'Bild wählen';

  @override
  String get enterMetadata => 'Bitte gib Daten zum Gegenstand ein';

  @override
  String get enterText => 'Bitte Text eingeben';

  @override
  String get title => 'Titel';

  @override
  String get description => 'Beschreibung';

  @override
  String get traits => 'Merkmale';

  @override
  String get addTraits => 'Neue Merkmale';

  @override
  String get addKey => 'Tag eingeben';

  @override
  String get addValue => 'Wert eingeben';

  @override
  String get processing => 'Daten werden verarbeitet';

  @override
  String get mintNft => 'Digital Twin erstellen';

  @override
  String get tapResults => 'Ergebnis';

  @override
  String get viewNftDetails => 'Digital Twin Details ansehen';

  @override
  String get addressCopied => 'Wallet-Adresse kopiert!';

  @override
  String get noWalletConnected => 'Keine Wallet verbunden!';

  @override
  String get walletConnected => 'Wallet verbunden';

  @override
  String get walletIsConnected => 'Deine Wallet ist verbunden';

  @override
  String get connectWallet => 'Wallet verbinden';

  @override
  String get disconnectWallet => 'Wallet trennen';

  @override
  String get openWalletToView => 'Wallet öffnen';

  @override
  String get showTxHistory => 'Transaktionshistorie anzeigen';

  @override
  String get noNftInWallet => 'Kein Digital Twin in deiner Wallet gefunden.';

  @override
  String get nftCheck => 'Digital Twin Überprüfung';

  @override
  String get uploadingMetadata => 'Metadaten werden hochladen';

  @override
  String get mintingToken => 'Erstelle Digital Twin';

  @override
  String get pleaseEnterText => 'Bitte Text eingeben';

  @override
  String get warning => 'Achtung';

  @override
  String get showNftInWallet => 'Digital Twin in Wallet ansehen';

  @override
  String get successHeadingSnackbar => 'Erfolg!';

  @override
  String get errorHeadingSnackBar => 'Fehler!';

  @override
  String get loadingNFTDataError => 'Daten konnten nicht geladen werden.';

  @override
  String get errorConnectingWallet => 'Fehler beim Verbinden der Wallet.';

  @override
  String get errorNoInternetConnection => 'Keine Internetverbindung.';

  @override
  String get errorNoNfcReader => 'NFC ist deaktiviert!';

  @override
  String get congrats => 'Herzlichen Glückwunsch!';

  @override
  String get ownershipCheck => 'Eigentumsprüfung';

  @override
  String get authenticityNftFound => 'Digital Twin auf Blockchain gefunden.';

  @override
  String get authenticityNftNotFound =>
      'Digital Twin nicht auf Blockchain gefunden.';

  @override
  String get authenticityCheck => 'Echtheitszertifikat';

  @override
  String get nfcCheck => 'NFC-Prüfung';

  @override
  String get whoops => 'Ups!';

  @override
  String get youAreNotNftOwner => 'Dieser Gegenstand gehört dir nicht.';

  @override
  String get youAreNFTOwner => 'Dieser Gegenstand gehört dir';

  @override
  String get loading => 'Lädt...';

  @override
  String get authentic => 'Authentisch';

  @override
  String get ownershipCouldNotBeVerified =>
      'Eigentum konnte nicht verifiziert werden.';

  @override
  String get disconnect => 'Logout';

  @override
  String get connect => 'Login';

  @override
  String get remove => 'Entfernen';

  @override
  String get add => 'Merkmal hinzufügen';

  @override
  String get type => 'Typ';

  @override
  String get value => 'Wert';

  @override
  String get showTraits => 'Merkmale anzeigen';

  @override
  String get showDescription => 'Beschreibung anzeigen';

  @override
  String get continueInBackground => 'Im Hintergrund laden';

  @override
  String get unknownCollection => 'Unbekannte Collection';

  @override
  String get chooseChain => 'Wähle \n Blockchain + Collection';

  @override
  String get legal => 'Rechtliche Information';

  @override
  String get support => 'Support';

  @override
  String get selectChain => 'Auswahl';

  @override
  String get selectBlockchain => 'Blockchain';

  @override
  String get selectCollection => 'Collection';

  @override
  String get troubleshoot => 'Ich brauche Hilfe';

  @override
  String get more => 'Mehr...';

  @override
  String get watchTutorial => 'Tutorial ansehen';

  @override
  String get viewProjects => 'Unsere Projekte';

  @override
  String get orderChips => 'Chips bestellen';

  @override
  String get signupAsCertifier => 'Als Zertifizierer registrieren';

  @override
  String get scanNow => 'Jetzt scannen';

  @override
  String get pleaseSelect => '- bitte auswählen -';

  @override
  String get pleaseSelectChainAndCollection =>
      'Bitte Blockchain & Collection auswählen';

  @override
  String get digitalTwin => 'Zertifikat';

  @override
  String get authenticity => 'Echtheit';

  @override
  String get ownership => 'Eigentum';

  @override
  String get unconfirmed => 'Nicht bestätigt';

  @override
  String get confirmed => 'Bestätigt';

  @override
  String get externalLinks => 'Weblinks';

  @override
  String get transferToken => 'Transferieren';

  @override
  String get transferInProgress => 'Digital Twin wird transferiert';

  @override
  String get transferSuccess => 'Digital Twin transferiert';

  @override
  String get transferError => 'Fehler beim Transfer des Digital Twins';

  @override
  String get enterWalletAddress => 'Wallet-Adresse eingeben';

  @override
  String get pleaseEnterValidWalletAddress =>
      'Bitte eine gültige Wallet-Adresse eingeben.';

  @override
  String get creationOfTwin => 'Erstelle deinen Digital Twin';

  @override
  String get warningPublicData =>
      'Alle eingegebenen Digital Twin Daten sind öffentlich.';

  @override
  String get infoScreenText =>
      'Überprüfe die Echtheit und das Eigentum von Objekten mit deinem Smartphone.';

  @override
  String get transferScreenText =>
      'Sende den Digital Twin an eine andere Wallet.';

  @override
  String get chooseWallet => 'Login-Methode auswählen';

  @override
  String get agreeToWhenConnecting =>
      'Beim Verbinden deiner Wallet stimmst du unseren ';

  @override
  String get generalTerms => 'AGB';

  @override
  String get and => 'und';

  @override
  String get privacyPolicy => 'Datenschutzbestimmungen';

  @override
  String get zu => ' zu';

  @override
  String get step => 'Schritt';

  @override
  String get viewGallery => 'Gallerie ansehen';

  @override
  String get chooseFile => 'Datei auswählen';

  @override
  String get addDigitalContent => 'Digital Content hinzufügen';

  @override
  String get titleTooLong => 'Titel zu lange.';

  @override
  String get titleCannotBeEmpty => 'Titel kann nicht leer sein.';

  @override
  String get maxAttachmentsReached =>
      'Maximale Anzahl von 50 Anhängen erreicht.';

  @override
  String get enterValidUrl => 'Bitte gib eine URL mit \'https://\' ein.';

  @override
  String get urlCannotBeEmpty => 'URL darf nicht leer sein.';

  @override
  String get public => 'Öffentlich';

  @override
  String get private => 'Privat';

  @override
  String get contentCanBeViewedPublic =>
      'Diese Anhänge können von jedem gesehen werden.';

  @override
  String get contentCanOnlyBeViewedPrivate =>
      'Diese Anhänge können nur vom Eigentümer gesehen werden.';

  @override
  String get addFile => 'Datei hinzufügen';

  @override
  String get addUrl => 'URL hinzufügen';

  @override
  String get editAttachment => 'Anhang bearbeiten';

  @override
  String get selectAttachmentYouWantToEdit =>
      'Anhang zum Bearbeiten oder Entfernen auswählen.';

  @override
  String get uploadDigitalContent => 'Digital Content hochladen';

  @override
  String get creatorContent => 'Creator-Inhalt';

  @override
  String get ownerContent => 'Eigentümer-Inhalt';

  @override
  String get fileEdited => 'Datei bearbeitet.';

  @override
  String get errorUpdatingData => 'Fehler beim Aktualisieren der Daten.';

  @override
  String get errorUploadingFile => 'Fehler beim Hochladen der Datei.';

  @override
  String get fileAttached => 'Anhang hinzugefügt.';

  @override
  String get savingUrl => 'URL wird gespeichert...';

  @override
  String get urlAttached => 'URL hinzugefügt.';

  @override
  String get errorSavingUrl => 'Fehler beim Speichern der URL.';

  @override
  String get errorDeletingAttachment => 'Fehler beim Löschen des Anhangs.';

  @override
  String get attachmentDeleted => 'Anhang gelöscht.';

  @override
  String get pressConnectToSignIn =>
      'Zum Einloggen mit der OwnerCard auf Login drücken.';

  @override
  String get youCanUseThisPukToResetYourPin =>
      'Verwende den PUK, um deinen PIN zurückzusetzen.';

  @override
  String get pukCopied => 'PUK kopiert';

  @override
  String get setUpOwnerCard => 'Neue OwnerCard einrichten';

  @override
  String get confirmYourIdentity => 'Authentifiziere deine Wallet';

  @override
  String get errorSettingPin => 'Fehler beim Setzen des PIN Codes.';

  @override
  String get holdPhoneToCard => 'Halte das Smartphone an die OwnerCard.';

  @override
  String get errorAuthenticatingCard =>
      'Fehler beim Authentifizieren der OwnerCard.';

  @override
  String get errorMakingSignature => 'Fehler beim Signieren.';

  @override
  String get holdPhoneToNfcChip => 'Halte dein Smartphone vor den NFC-Chip.';

  @override
  String get setUpPin => 'Neuen PIN für OwnerCard einrichten';

  @override
  String get enterPinToAuth => 'PIN eingeben zum Authentifizieren';

  @override
  String get connectOwnerCard => 'OwnerCard verbinden';

  @override
  String get enterPinToConfirmTx =>
      'PIN eingeben, um Transaktion zu bestätigen';

  @override
  String get confirmTx => 'Transaktion bestätigen';

  @override
  String get enterPuk => 'PUK eingeben';

  @override
  String get successfullySetUpPin => 'PIN erfolgreich eingerichtet';

  @override
  String get transferOwnership => 'Transfer';

  @override
  String get transferringOwnership => 'Eigentum wird übertragen';

  @override
  String get claimOwnership => 'Eigentum beanspruchen';

  @override
  String get claimingOwnership => 'Eigentum wird transferiert';

  @override
  String get tokenWasTransferred => 'Eigentum wurde transferiert an ';

  @override
  String get tokenNotYetClaimed => ' und wurde noch nicht beansprucht.';

  @override
  String get holdPhoneCloseToOwnerCardToInit =>
      'Halte das Smartphone zur OwnerCard.';

  @override
  String get chipIsNoCard => 'Chip ist KEINE OwnerCard.';

  @override
  String get twoSlotsInitSuccess => 'Zwei Public Keys erfolgreich gesetzt.';

  @override
  String get twoSlotsInitError =>
      '\'Fehler beim Initialisieren der zwei Slots.';

  @override
  String get tokenIdCopiedToClipboard => 'Digital Twin ID kopiert!';

  @override
  String get walletAddressCopiedToClipboard => 'Wallet-Adresse kopiert!';

  @override
  String get isNotOwnerCard => 'NFC-Chip ist keine OwnerCard.';

  @override
  String get whenSigningInWithMetamask =>
      'Wenn du Metamask verwendest, stelle sicher, dass du mit dem Ethereum Mainnet verbunden bist.';

  @override
  String get pinResetSuccess => 'PIN zurückgesetzt. PUK bitte speichern!';

  @override
  String get enterFourDigitPin => 'Neuen 4-stelligen PIN eingeben';

  @override
  String get enterPUK => 'PUK eingeben';

  @override
  String get done => 'Fertig';

  @override
  String get submit => 'Senden';

  @override
  String get errorSigningTx => 'Fehler beim Bestätigen der Transaktion.';

  @override
  String get errorReadingChip => 'Fehler beim Lesen des Chips.';

  @override
  String get receivingToken => 'Digital Twin empfangen';

  @override
  String get transferToAddress => 'An Adresse schicken';

  @override
  String get cardLost => 'OwnerCard verloren';

  @override
  String get cardLostContacted =>
      'Vielen Dank für deine Anfrage. Unser Kundendienst wird dich in Kürze kontaktieren.';

  @override
  String get scanToTriggerCardLost =>
      'Halte dein Handy an den NFC-Chip des Objekts, das mit deiner verlorenen OwnerCard verknüpft ist.';

  @override
  String get enterEmailToTriggerCardLost =>
      'E-Mail-Adresse eingeben, um den Prozess für eine neue OwnerCard zu starten.';

  @override
  String get tokenDoesNotExist => 'Digital Twin existiert nicht.';

  @override
  String get pleaseEnterValidEmailAddress =>
      'Bitte gib eine gültige E-Mail-Adresse ein.';

  @override
  String get chipAddress => 'Chip-Adresse';

  @override
  String get transferOnlyToOwnerCard =>
      'Transfer nur zu initialisierter OwnerCard möglich.';

  @override
  String get digitalContentWillBeTransferred =>
      'Öffentlicher und privater Digital Content wird zusammen mit dem Digital Twin transferiert.';

  @override
  String get ownercard => 'OwnerCard';

  @override
  String get certificatecard => 'Zertifikatskarte';

  @override
  String get or => 'oder';

  @override
  String get cardNotInitializedByAdmin =>
      'OwnerCard noch nicht vom Admin initialisiert.';

  @override
  String get deletingAttachment => 'Anhang löschen';

  @override
  String get enterPIN => 'PIN eingeben';

  @override
  String get transferToOwnerCard => 'An OwnerCard transferieren';

  @override
  String get resetPIN => 'PIN zurücksetzen';

  @override
  String get toRequestNewCard =>
      'Um eine neue Karte anzufordern, gib bitte unten deine Kontaktdaten ein.';

  @override
  String get uploadingAttachment => 'Anhang hochladen...';

  @override
  String get creatorData => 'Creator-Profil';

  @override
  String get digitalTwinVerifiedBy => 'Digital Twin verifiziert von ';

  @override
  String get pleaseScanItem => 'Bitte scanne das Objekt';

  @override
  String get scanItemToTriggerCardLost =>
      'Scanne im nächsten Schritt das Objekt, welches mit deiner verlorenen OwnerCard verknüpft ist. \n\nSo können wir den digitalen Inhalt auf deiner Ersatzkarte wiederherstellen.';

  @override
  String get pleaseEnterValidTel =>
      'Bitte eine gültige Telefonnummer eingeben.';

  @override
  String get pleaseEnterValidName => 'Bitte einen gültigen Namen eingeben.';

  @override
  String get pleaseTryAgainLater => 'Bitte versuche es später erneut.';

  @override
  String get showCreatorData => 'Creator-Daten anzeigen';

  @override
  String get next => 'Weiter';

  @override
  String get requestSent => 'Anfrage versendet!';

  @override
  String get phoneNumber => 'Telefonnummer';

  @override
  String get emailAddress => 'E-Mail-Adresse';

  @override
  String get setPin => 'Einrichten';

  @override
  String get createdAt => 'Erstellt am';

  @override
  String get pleaseHoldPhoneLonger =>
      'Bitte Smartphone länger zum Chip halten.';

  @override
  String get unableToReadChip => 'Fehler beim Lesen des Chips.';

  @override
  String get offerOnOpenSea => 'Auf OpenSea zum Verkauf anbieten';

  @override
  String get offerOnRarible => 'Auf Rarible zum Verkauf anbieten';

  @override
  String get offeringToken => 'Digital Twin wird angeboten...';

  @override
  String get itemOffered => 'Objekt angeboten';

  @override
  String get itemOfferedOnMP => 'Objekt auf Marktplatz angeboten';

  @override
  String get viewOnMP => 'Auf Marktplatz ansehen';

  @override
  String get errorOfferingToken => 'Fehler beim Anbieten des Digital Twins';

  @override
  String get offerItem => 'Objekt anbieten';

  @override
  String get enterWalletAddressForPayout =>
      'Wallet-Adresse für Auszahlung eingeben';

  @override
  String get price => 'Preis';

  @override
  String get enterSalePrice => 'Verkaufspreis eingeben';

  @override
  String get listOnRarible => 'Auf Rarible anbieten';

  @override
  String get offerNow => 'Auf Rarible anbieten';

  @override
  String get offerForSale => 'Verkaufen';

  @override
  String get offerCanceled => 'Angebot entfernt';

  @override
  String get errorCancellingSale => 'Fehler beim Entfernen des Angebots.';

  @override
  String get redeemingtoken => 'Digital Twin erhalten';

  @override
  String get tokenRedeemed => 'Digital Twin erhalten';

  @override
  String get errorRedeemingToken => 'Fehler beim Erhalten des Digital Twins.';

  @override
  String get redeemToken => 'Digital Twin beanspruchen';

  @override
  String get claimPhysicalItem =>
      'Beanspruche ein physisches Objekt, das mit einem Digital Twin in deiner Wallet verknüpft ist.';

  @override
  String get enterShippingAddress => 'Versandadresse eingeben';

  @override
  String get shippingDataSuccessfullySent =>
      'Versanddaten erfolgreich übermittelt.';

  @override
  String get youWillReceiveFurtherInformationViaEmail =>
      'Du erhältst weitere Informationen per E-Mail.';

  @override
  String get firstName => 'Vorname';

  @override
  String get lastName => 'Nachname';

  @override
  String get pleaseEnterFirstName => 'Bitte Vorname angeben.';

  @override
  String get pleaseEnterLastName => 'Bitte Nachname angeben.';

  @override
  String get company => 'Unternehmen';

  @override
  String get streetAddress => 'Straße';

  @override
  String get pleaseEnterStreetAddress => 'Bitte Straße angeben.';

  @override
  String get streetAddress1 => 'Straße 1';

  @override
  String get city => 'Stadt';

  @override
  String get pleaseEnterCity => 'Bitte Stadt angeben.';

  @override
  String get zip => 'PLZ';

  @override
  String get pleaseEnterZip => 'Bitte PLZ angeben.';

  @override
  String get stateProvince => 'Bundesland';

  @override
  String get shippingAddress => 'Versandadresse';

  @override
  String get selectCountry => 'Land auswählen';

  @override
  String get search => 'Suche';

  @override
  String get startTypingToSearch => 'Tippen um zu Suchen';

  @override
  String get country => 'Land';

  @override
  String get pleaseEnterCountry => 'Bitte Land angeben.';

  @override
  String get contact => 'Kontakt';

  @override
  String get sendShippingData => 'Versanddaten absenden';

  @override
  String get cancelOffer => 'Angebot entfernen';

  @override
  String get tokenCurrentlyOfferedForSale =>
      'Digital Twin wird auf Marktplatz angeboten.';

  @override
  String get payoutWalletAddress => 'Auszahlungs-Wallet-Adresse';

  @override
  String get youAreTheNewOwner =>
      'Du bist der neue Eigentümer. Der Digital Twin kann jetzt in deine Wallet transferiert werden.';

  @override
  String get transfer => 'Transferieren';

  @override
  String get ownerChipWillNotifyYouOnceTheItemIsPurchased =>
      'OwnerChip wird dich per E-Mail benachrichtigen, sobald der Artikel gekauft wurde. Du bist verantwortlich für das Verpacken und Versenden des Artikels an den Käufer.';

  @override
  String get thisItemHasBeenSold =>
      'Dieses Objekt wurde verkauft. Du hast Versandanweisungen per E-Mail erhalten.';

  @override
  String get pleaseScanChipAgainToCancel =>
      'Chip erneut scannen, um das Angebot abzubrechen.';

  @override
  String get pleaseScanChipAgainToBurn =>
      'Chip erneut scannen, um Digital Twin zu löschen.';

  @override
  String get attention => 'Achtung!';

  @override
  String get mintingVoucherToken => 'Digital Twin erstellen...';

  @override
  String get requestShipment => 'Versand jetzt anfordern.';

  @override
  String get manualHandover => 'Manuelle Übergabe';

  @override
  String get feesInfo =>
      '5% Protokollgebühr + Marktplatzgebühr werden vom Verkaufspreis abgezogen. \n \n EUR-Wert variiert mit dem Wechselkurs.';

  @override
  String get successManualHandover =>
      'Chip scannen, um Digital Twin zu beanspruchen.';

  @override
  String get itemAvailableForSale => 'Dieser Gegenstand steht zum Verkauf.';

  @override
  String get buyOnRarible => 'Auf Rarible kaufen';

  @override
  String get voucherNftDescriptionGeneral =>
      'Dieser Digital Twin beinhaltet das Eigentum eines physischen Kunstwerks, das nach dem Kauf des Digital Twins eingelöst werden kann.';

  @override
  String voucherNftDescriptionAppSpecific(Object CERTIFICATE_LINK) {
    return 'über die Ownerchip-App, herunterladbar im Google Playstore und Apple AppStore. Du kannst das digitale Zertifikat unter diesem Link einsehen: $CERTIFICATE_LINK\nFür weitere Informationen besuche https://ownerchip.com/redeem';
  }

  @override
  String get transferred => 'Transferiert';

  @override
  String get errorWhenOffering =>
      'Beim Anbieten des Digital Twins ist ein Fehler passiert. Bitte drücke \'Digital Twin wiederherstellen\' oder kontaktiere den Support.';

  @override
  String get recoverToken => 'Digital Twin wiederherstellen';

  @override
  String get enterDetails => 'Details eingeben';

  @override
  String get myCollection => 'Meine Sammlung';

  @override
  String get pleaseConnectWalletToViewItems =>
      'Verbinde deine Wallet, um Digital Twins zu sehen.';

  @override
  String get ownedByMe => 'In meinem Besitz';

  @override
  String get createdByMe => 'Von mir erstellt';

  @override
  String get youHaveNotMintedAnyItems =>
      'Du hast bisher keinen Digital Twin erstellt.';

  @override
  String get youDoNotOwnAnyItems => 'Du besitzt noch keine Digital Twins.';

  @override
  String get legalHintTerrorismFinancing =>
      'Ich habe all meine Sorgfaltspflichten in Hinblick auf die Verhinderung von Geldwäsche und Terrorismusfinanzierung nach den für mich anwendbaren Rechtsvorschriften erfüllt.';

  @override
  String get shippingHint =>
      'Ich bin verantwortlich für die Bearbeitung, Verpackung und Versandkosten im Zusammenhang mit dem Angebot.';

  @override
  String get appBarProfileTitle => 'Profil';

  @override
  String get appBarWalletIdTitle => 'Wallet ID';

  @override
  String get copiedAddressToClipboard => 'Adresse kopiert.';

  @override
  String get appbarMyBalanceButton => 'Mein Guthaben';

  @override
  String get myBalanceTitle => 'Mein Guthaben';

  @override
  String get myBalanceTotalBalance => 'Gesamtes Guthaben';

  @override
  String get myBalanceChoseCrypto =>
      'Wähle eine Kryptowährung, die du übertragen möchtest';

  @override
  String get myBalanceReceivingWalletAddress => 'Empfangs-Wallet-Adresse';

  @override
  String get myBalanceCryptoAmount => 'Betrag';

  @override
  String get myBalanceSendMaxButton => 'Max. Betrag senden';

  @override
  String get myBalanceSendButton => 'Senden';

  @override
  String get myBalanceConfirmationDialogTitle => 'Bestätigung';

  @override
  String get myBalanceConfirmationRecipient => 'Empfänger:';

  @override
  String get myBalanceConfirmationAmount => 'Betrag:';

  @override
  String get myBalanceConfirmationCurrency => 'Kryptowährung:';

  @override
  String get myBalanceConfirmationChain => 'Chain:';

  @override
  String get myBalanceConfirmationConfirmButton => 'Bestätigen';

  @override
  String get myBalanceConfirmationCancelButton => 'Abbrechen';

  @override
  String get myBalancePullToRefresh => 'Zum Aktualisieren ziehen';

  @override
  String get myBalanceRefreshing => 'Laden...';

  @override
  String get myBalanceError => 'Fehler beim Laden des Guthabens';

  @override
  String get myBalanceRetry => 'Neu versuchen';

  @override
  String get myBalanceWithdrawSufficientFunds =>
      'Nicht genügend Kryptowährung!';

  @override
  String get myBalanceWithdrawLoadingText => 'Krypto senden...';

  @override
  String get myBalanceWithdrawSuccessText => 'Übertrag erfolgreich';

  @override
  String get myBalanceWithdrawErrorText => 'Fehler beim Senden von Krypto';

  @override
  String get myBalanceWithdrawBackButton => 'Zurück';

  @override
  String get myBalanceWithdrawPasteAddressButton => 'Einfügen';

  @override
  String get myBalanceWithdrawWrongAddress =>
      'Bitte gib eine gültige Wallet Addresse ein';

  @override
  String myBalanceWithdrawMaxAmount(Object amount) {
    return 'Max: $amount';
  }

  @override
  String get onboardingTitle => 'Schön, dass du da bist!';

  @override
  String get onboardingFeatureAuthenticityTitle => 'Echtheit verifizieren';

  @override
  String get onboardingFeatureAuthenticitySubtitle =>
      'Scanne den NFC-Chip, um die Echtheit zu verifizieren.';

  @override
  String get onboardingFeatureDigitalExperiencesTitle =>
      'Zugang zu digitalen Inhalten';

  @override
  String get onboardingFeatureDigitalExperiencesSubtitle =>
      'Erhalte Zugriff auf digitale Inhalte, die mit realen Gegenständen verbunden sind.';

  @override
  String get onboardingFeatureSellTitle => 'Verkaufen & Wiederverkaufen';

  @override
  String get onboardingFeatureSellSubtitle =>
      'Handle das physische und digitale Kunstwerk gemeinsam als Paket auf Web3-Marktplätzen.';

  @override
  String get onboardingStartButton => 'Tutorial starten';

  @override
  String get onboardingUserPageTitle => 'So verwendest du die App';

  @override
  String onboardingPagination(Object current) {
    return 'Schritt $current/';
  }

  @override
  String get onboardingUserPageStep1Title => 'NFC-Chip scannen';

  @override
  String get onboardingUserPageStep1Subtitle =>
      'Drücke \"Jetzt Scannen\" und halte dein Smartphone zum Chip.';

  @override
  String get onboardingUserPageStep2Title => 'Mit deiner Wallet einloggen';

  @override
  String get onboardingUserPageStep2Subtitle =>
      'Verbinde dich mit deiner OwnerCard oder Krypto-Wallet, um deinen Besitz nachzuweisen, zu übertragen oder private digitale Inhalte freizuschalten.';

  @override
  String get onboardingUsePageNextButtonTitle => 'Weiter';

  @override
  String get onboardingUserPageCompleteButtonTitle => 'Weiter';

  @override
  String get onboardingUserCompleteCreatorPageTitle => 'Bist du ein Creator?';

  @override
  String get onboardingUserCompleteCreatorPageSubtitle =>
      'Lerne, wie du einen Digital Twin erstellst.';

  @override
  String get onboardingUserCompleteCreatorButtonTitle =>
      'Creator-Tutorial starten';

  @override
  String get onboardingCreatorPageTitle => 'So erstellst du einen Digital Twin';

  @override
  String get onboardingCreatorStep1Title => 'Hast du NFC-Chips?';

  @override
  String get onboardingCreatorStep1SubTitle =>
      'Bestelle dein StarterKit und registriere dich als Creator.';

  @override
  String get onboardingCreatorStep1OrderButtonTitle => 'Jetzt bestellen';

  @override
  String get onboardingCreatorStep2Title => 'NFC-Chip anbringen';

  @override
  String get onboardingCreatorStep2SubTitle =>
      'Integriere den Chip in dein Objekt, zum Beispiel mit Hilfe von Klebefolien, Klebstoff oder Aufklebern.';

  @override
  String get onboardingCreatorStep3Title => 'Video-Tutorial ansehen';

  @override
  String get onboardingCreatorStep3SubTitle =>
      'Sieh dir unsere App-Demo an, um in wenigen Minuten deinen ersten Digital Twin zu erstellen.';

  @override
  String get onboardingCreatorStep3YoutubeVideoURL =>
      'https://youtube.com/watch?v=iB8g9QLSvw0';

  @override
  String get onboardingCreatorCompleteButtonTitle => 'Digital Twin erstellen';

  @override
  String get onboardingUserCompleteTitle => 'Fertig!';

  @override
  String get onboardingUserCompleteSubtitle =>
      'Du hast das Tutorial erfolgreich abgeschlossen.';

  @override
  String get onboardingUserCompleteButtonTitle => 'Jetzt scannen!';

  @override
  String get onboardingCheckboxShowAgainTitle => 'Beim nächsten Mal anzeigen';

  @override
  String get onboardingMoreInfoShowTutorialButtonTitle => 'Tutorial anzeigen';

  @override
  String get galleryPullToRefresh => 'Zum Aktualisieren herunterziehen';

  @override
  String get galleryRefreshing => 'Neu laden...';

  @override
  String get galleryLoadMore => 'Mehr laden';

  @override
  String get galleryLoadingMore => 'Laden...';

  @override
  String get galleryNoMoreItems => 'Alle Digital Twins geladen';

  @override
  String get errorLoadingOwnedItems => 'Fehler beim Laden der Digital Twins';

  @override
  String get errorLoadingCreatedItems => 'Fehler beim Laden der Digital Twins';

  @override
  String get galleryErrorLoadingMore => 'Fehler beim Laden der Digital Twins';

  @override
  String get offerForSaleCreatedTokenAppBarTitle => '';

  @override
  String get offerForSaleCreatedTokenTitle => 'Digital Twin erstellt';

  @override
  String get offerForSaleCreatedTokenSubtitle =>
      'Du hast erfolgreich einen Digital Twin für dein Objekt erstellt.';

  @override
  String get offerForSaleCreatedTokenButton => 'Jetzt anbieten';

  @override
  String get offerForSaleCreatedTokenViewTokenButton => 'Token ansehen';

  @override
  String get offerOnMpDiscoverDialogTitle => 'Offer on Marketplace';

  @override
  String get offerOnMpDiscoveryDialogMessage =>
      'Die Funktion “Augf Marktplatz anbieten” ist nicht verfügbar in der app “OwnerChip Discovery”, welche nur für Demozwecke der Infineon NFC chips gedacht ist, aber nicht zum Handeln von Gütern.Verwenden Sie die app “OwnerChip” und registrieren sie sich als Zertifizierer im Menü “Mehr…';

  @override
  String get offerOnMpEmailHint =>
      'Deine Email Adresse wird verwendet, um dich über den Status des Angebots zu informieren.';

  @override
  String get offerOnMpPriceHint =>
      '5% Protokollgebühr + Marktplatzgebühr wird vom Verkaufspreis abgezogen. EUR Wert variiert mit Wechselkurs.';

  @override
  String offerOnMpEstimatedPriceInEur(Object price) {
    return 'Geschätzter EUR Wert ~$price';
  }

  @override
  String get offerOnMpFetchingPrice => 'Aktuelle Kurse werden geladen...';

  @override
  String get offerOnMpErrorFetchingPrice => 'Fehler beim Laden aktueller Kurse';

  @override
  String get offerOnMpPublishedDialogTitle => 'Auf Marktplatz veröffentlicht';

  @override
  String get offerOnMpPublishedDialogSubtitle =>
      'Dein Gegenstand steht nun zum Verkauf!';

  @override
  String get newVersionTitle => 'App aktualisieren';

  @override
  String get newVersionAvailable =>
      'Eine neue Version der App ist verfügbar! Bitte aktualisiere auf die neueste Version.';

  @override
  String get newVersionUpdateButton => 'Aktualisieren';

  @override
  String get scanResultPageShowCertificateButton =>
      'Zertifikatsdetails anzeigen';

  @override
  String get scanResultPage_ownershipCheck => 'Eigentumsprüfung';

  @override
  String get scanResultPage_ownershipOwnerOffered =>
      'Sie sind der Eigentümer dieses Gegenstands. Der Digitale Zwilling wird auf einem Marktplatz angeboten.';

  @override
  String get scanResultPage_ownershipOwnerNotOffered =>
      'Sie sind der Eigentümer dieses Gegenstands.';

  @override
  String get scanResultPage_ownershipNotOwnerOffered =>
      'Sie sind nicht der Eigentümer dieses Gegenstands. Der Digitale Zwilling wird auf einem Marktplatz angeboten.';

  @override
  String get scanResultPage_ownershipNotOwnerNotOffered =>
      'Sie sind nicht der Eigentümer dieses Gegenstands.';

  @override
  String get scanResultPage_buttonOwnerOffered => 'Angebot anzeigen';

  @override
  String get scanResultPage_buttonNotOwnerOffered => 'Angebot anzeigen';

  @override
  String get scanResultPage_chipHasNotYetBeenInitialized =>
      'Dieser NFC Chip wurde noch nicht aktiviert.';

  @override
  String get nftDetailsPageShowCertificateButton =>
      'Zertifikatsdetails anzeigen';

  @override
  String get nftDetailsPageAuthenticityCertified => 'Zertifiziert';

  @override
  String get nftDetailsPageAuthenticityNotCertified => 'Nicht zertifiziert';

  @override
  String get nftDetailsPageCertifier => 'Zertifizierer';

  @override
  String get nftDetailsPageCreationDate => 'Datum der Erstellung';

  @override
  String get nftDetailsPageCollection => 'Sammlung';

  @override
  String get nftDetailsErrorFetchingCertificateData => 'unbekannt';

  @override
  String get nftCreationsPageTitle => 'Digitale Zwillinge';

  @override
  String get nftCreationsPagePullToRefresh => 'Zum Aktualisieren ziehen';

  @override
  String get nftCreationsPageRefreshing => 'Aktualisierung...';

  @override
  String get nftCreationsHomeScreenButtonTitle => 'Transaktionen bestätigen';

  @override
  String get nftCreationsPageToBeBurned => 'Löschung ausstehend';

  @override
  String get nftCreationsPagePending => 'Aktivierung ausstehend';

  @override
  String get nftCreationsPageToBeTransferred => 'Transfer ausstehend';

  @override
  String get nftCreationsPageError => 'Fehler';

  @override
  String get nftCreationsPageChipMismatchError => 'Chip-Störung';

  @override
  String get nftCreationsPagePullToLoadMore => 'Zum Laden ziehen';

  @override
  String get nftCreationsPageLoading => 'Wird geladen...';

  @override
  String get nftCreationsLoggedInWithDifferentWalletTitle => 'Wallet';

  @override
  String get nftCreationsLoggedInWithDifferentWalletDescription =>
      'Sie sind mit einem anderen Wallet angemeldet. Bitte melden Sie sich mit dem Wallet an, mit dem Sie den Digitalen Zwilling erstellt haben.';

  @override
  String get nftCreationsLoggedInWidthDifferentWalletButton => 'Schließen';

  @override
  String get nftCreationsNotLoggedInTitle => 'Wallet';

  @override
  String get nftCreationsNotLoggedInDescription =>
      'Bitte melden Sie sich mit dem Wallet an, mit dem Sie den Digitalen Zwilling erstellt haben.';

  @override
  String get nftCreationsNotLoggedInButton => 'Schließen';

  @override
  String get nftCreationsAlreadyMintedToken =>
      'Der gescannte Chip ist bereits mit einem anderen digitalen Zwilling initialisiert';

  @override
  String get nftCreationRestoreTokenPopupTitle =>
      'Digitalen Zwilling wiederherstellen';

  @override
  String get nftCreationRestoreTokenPopupMessage =>
      'Der gescannte Chip ist bereits mit einem anderen digitalen Zwilling aktiviert. Möchten Sie den digitalen Zwilling wiederherstellen?';

  @override
  String get nftCreationRestoreTokenPopupCancelButton => 'Abbrechen';

  @override
  String get nftCreationRestoreTokenPopupRestoreButton => 'Wiederherstellen';

  @override
  String get nftCreationRestoreTokenPopupViewTokenButton =>
      'Digitalen Zwilling anzeigen';

  @override
  String get nftCreationRestoreTokenPopupSuccessTitle =>
      'Digitaler Zwilling wiederhergestellt';

  @override
  String get nftCreationMultiSeriesTitle => 'Serien-Aktivierung';

  @override
  String nftCreationMultiSeriesDescription(Object number) {
    return 'Serie - $number Zwillinge';
  }

  @override
  String nftCreationMultiSeriesStatus(Object current, Object total) {
    return '$current von $total aktiviert';
  }

  @override
  String get nftCreationMultiSeriesActivateButton =>
      'Nächsten NFC-Chip scannen';

  @override
  String get nftCreationMultiSeriesPause => 'Pause und später fortfahren';

  @override
  String get nftCreationMultiSeriesBadge => 'Serie';

  @override
  String nftCreationMultiSeriesItemsCount(String count) {
    return '$count Artikel';
  }

  @override
  String nftCreationMultiSeriesItemsActivated(String current, String total) {
    return '$current von $total Artikeln aktiviert';
  }

  @override
  String get nftCreationSeriesStatusActivationPending =>
      'Aktivierung ausstehend';

  @override
  String get nftCreationSeriesStatusDraft => 'Entwurf';

  @override
  String get nftCreationSeriesStatusActive => 'Aktiv';

  @override
  String get nftCreationSeriesStatusToBeBurned => 'Zu löschen';

  @override
  String get nftCreationSeriesStatusToBeTransferred => 'Zu übertragen';

  @override
  String get nftCreationSeriesActionStartScanning => 'Tippen um zu scannen';

  @override
  String get nftCreationSeriesActionConnectNFC =>
      'Tippen um NFC-Chip zu verbinden';

  @override
  String get nftCreationSingleItemBadge => 'Einzelartikel';

  @override
  String get nftCreationSingleActionConnectNFC =>
      'Tippen um NFC-Chip zu verbinden';

  @override
  String get nftCreationSingleActionBurnToken => 'Tippen um Token zu löschen';

  @override
  String get nftCreationSingleActionTransferToken =>
      'Tippen um Token zu übertragen';

  @override
  String get nft_cancel_confirmation_dialog_title => 'Abbrechen';

  @override
  String nft_cancel_confirmation_dialog_description(Object title) {
    return 'Möchtest du die Aktivierung für \"$title\" wirklich abbrechen?';
  }

  @override
  String get nft_cancel_confirmation_dialog_cancel_cancel_button =>
      'Ja, Aktivierung abbrechen';

  @override
  String get nft_cancel_confirmation_dialog_cancel_keep_button =>
      'Nein, fortfahren';

  @override
  String get nft_burn_cancel_confirmation_dialog_title => 'Löschen abbrechen';

  @override
  String nft_burn_cancel_confirmation_dialog_description(Object title) {
    return 'Sind Sie sicher, dass Sie das Löschen von \"$title\" abbrechen wollen?';
  }

  @override
  String get nft_burn_cancel_confirmation_dialog_cancel_cancel_button =>
      'Ja, Abbrechen';

  @override
  String get nft_burn_cancel_confirmation_dialog_cancel_keep_button =>
      'Nein, behalten';

  @override
  String get nft_transfer_cancel_confirmation_dialog_title =>
      'Transfer abbrechen';

  @override
  String nft_transfer_cancel_confirmation_dialog_description(Object title) {
    return 'Sind Sie sicher, dass der Transfer von \"$title\" abgebrochen werden soll?';
  }

  @override
  String get nft_transfer_cancel_confirmation_dialog_cancel_cancel_button =>
      'Ja, abbrechen';

  @override
  String get nft_transfer_cancel_confirmation_dialog_cancel_keep_button =>
      'Nein, behalten';

  @override
  String get certificateCardLoginSuccess =>
      'Erfolgreich mit der Zertifikatskarte verbunden.';

  @override
  String get cannotSetPinOnCertificateCard =>
      'PIN kann auf der Zertifikatskarte nicht gesetzt werden.';

  @override
  String get cannotResetPinOnCertificateCard =>
      'PIN kann auf der Zertifikatskarte nicht zurückgesetzt werden.';

  @override
  String get cardIsNotCertificateCard => 'NFC-Chip ist keine Zertifikatskarte.';

  @override
  String get cardIsNotOwnerCard => 'NFC-Chip ist keine OwnerCard.';

  @override
  String get holdPhoneCloseToCertificateCardToInit =>
      'Halten Sie Ihr Telefon nahe an die Zertifikatskarte.';

  @override
  String get cannotCardLostOnCertificateCard =>
      'Zertifikatskarte kann nicht für Kartenverlust verwendet werden.';

  @override
  String get scanQRCode => 'QR-Code scannen';

  @override
  String get noConnection => 'Keine Verbindung';

  @override
  String get invalidQRCode => 'Ungültiger QR-Code';

  @override
  String get reconnectWebSocketButtonText => 'Neu versuchen';

  @override
  String get reconnectWebSocketErrorText =>
      'Fehler beim Verbinden mit dem Server';

  @override
  String get reconnectWebSocketSuccessText => 'Verbindung wiederhergestellt';

  @override
  String get loginWithEmail_EnterEmailText =>
      'Bitte geben Sie Ihre E-Mail-Adresse ein';

  @override
  String get loginWithEmail_Hint => 'E-Mail';

  @override
  String get loginWithEmail_okButton => 'Ok';

  @override
  String get loginWithEmail_cancelButton => 'Abbrechen';

  @override
  String get loginWithEmail_ValidationError =>
      'Bitte geben Sie eine gltige E-Mail-Adresse ein';

  @override
  String get loginWithEmail_otpTitle => 'Bestätigungscode eingeben';

  @override
  String loginWithEmail_otpSubtitle(String email) {
    return 'Ein 6-stelliger Code wurde an $email gesendet';
  }

  @override
  String get loginWithEmail_otpHint => '6-stelliger Code';

  @override
  String get loginWithEmail_otpEmptyError => 'Bitte geben Sie den Code ein';

  @override
  String get loginWithEmail_otpLengthError => 'Der Code muss 6 Stellen haben';

  @override
  String get loginWithEmail_otpStepTitle => 'E-Mail verifizieren';

  @override
  String get loginWithEmail_emailStepHeading =>
      'Geben Sie Ihre E-Mail-Adresse ein';

  @override
  String get loginWithEmail_emailStepSubtitle =>
      'Wir senden Ihnen einen 6-stelligen Bestätigungscode.';

  @override
  String get loginWithEmail_sendCodeButton => 'Code senden';

  @override
  String get loginWithEmail_otpStepHeading =>
      'Überprüfen Sie Ihren Posteingang';

  @override
  String get loginWithEmail_verifyButton => 'Bestätigen';

  @override
  String get loginWithEmail_resendCodeButton => 'Code erneut senden';

  @override
  String get loginWithEmail_changeEmailButton => 'E-Mail ändern';

  @override
  String get accountDeletionButton => 'Profil löschen';

  @override
  String get accountDeletionPopupTitle => 'Profil löschen';

  @override
  String get accountDeletionPopupMessage =>
      'Sind Sie sicher, dass Sie Ihr Profil löschen möchten? Dies kann bis zu 10 Werktage dauern. Sie erhalten eine E-Mail-Bestätigung, sobald der Vorgang abgeschlossen ist. Alle Ihre Daten werden gelöscht, und Sie können sie nicht wiederherstellen.';

  @override
  String get accountDeletionPopupCancelButton => 'Abbrechen';

  @override
  String get accountDeletionPopupDeleteButton => 'Löschen';

  @override
  String get accountDeletionSentNotificationTitle => 'Profillöschung';

  @override
  String get accountDeletionSentNotificationMessage =>
      'Profillöschung in Bearbeitung. Sie erhalten eine E-Mail-Bestätigung, sobald der Vorgang abgeschlossen ist.';

  @override
  String get accountDeletionInProgressPopupTitle => 'Profillöschung';

  @override
  String get accountDeletionInProgressPopupMessage =>
      'Die Löschung ihres Profils ist in Bearbeitung. Sie erhalten eine E-Mail-Bestätigung, sobald der Vorgang abgeschlossen ist.';

  @override
  String get accountDeletionInProgressPopupOkButton => 'OK';

  @override
  String get accountDeletionInProgressPopupCancelButton => 'Abbrechen';

  @override
  String get accountDeletionCanceledNotificationTitle => 'Profillöschung';

  @override
  String get accountDeletionCanceledNotificationMessage =>
      'Löschen abgebrochen.';

  @override
  String get transferToOwnerCardMessage =>
      'Halte das Smartphone zur OwnerCard.';

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

  @override
  String get web3authExistingAccountTitle => 'Konto existiert bereits';

  @override
  String get web3authExistingAccountDescription =>
      'Ein Konto mit dieser E-Mail-Adresse existiert bereits.\nBitte melde dich mit der gleichen Anmeldemethode an, die du bei der Erstellung deines Kontos verwendet hast.';

  @override
  String get web3authExistingAccountLogout => 'Abmelden';
}
