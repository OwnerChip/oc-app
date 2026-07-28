# The `standalone` branch

Branched from `dev` at `f84ea87`. This document describes what the branch is,
what was removed, and — most importantly — **exactly which external services it
still depends on**.

Read [Remaining external dependencies](#remaining-external-dependencies) first
if that is why you are here. The short version: this build is decoupled from the
**web app**, not from the **OwnerChip API**. It cannot run without
`api.ownerchip.com`.

---

## What "standalone" means here

The goal was to remove the mobile app's coupling to the OwnerChip web app — the
QR/deeplink login where the phone authenticated a browser session, the
creator-dashboard hand-off, and the marketplace — plus a set of features the
operator no longer wants.

It explicitly does **not** mean self-hosted or offline. Auth, collections,
attachments, analytics and the version gate are all still served by the OwnerChip
backend, and that was a deliberate decision, not an oversight.

### What the app does now

Scan an NFC chip → verify its authenticity on-chain → mint a digital twin
on-device → view / transfer / burn it → check and withdraw an ERC-20 balance.

Wallets: **WalletConnect** (via Reown AppKit) and **OwnerCard** (a physical NFC
card acting as the wallet). Chains: **Ethereum mainnet** and **Polygon mainnet**.

---

## Removed in this branch

| Feature | Why it went |
|---|---|
| Firebase / FCM push | Its only three notification types existed to wake the app for the web dashboard's draft-twin flow |
| Web-dashboard twin creation ("creations", path A) | Creators drafted twins in the web app; the phone finished the mint. The web app is gone |
| QR / deeplink login | The phone acted as an authenticator for a browser session |
| Marketplace / offer-for-sale | Rarible consignment, escrow, vouchers, shipping, purchase records |
| Web3Auth | Already dead code since the Privy migration (`4e75aae`) |
| Tutorial / onboarding | Operator decision. ~10 MB of bundled video |
| All gasless transactions | Both the EIP-2771 forwarder path (already dead) and the Alchemy ERC-4337/7702 bundler |
| Privy email login | Operator decision |
| CertificateCard wallet type | The "card that IS the token" product |
| `stilami` + `ownerchip_infineon` brands | Legacy; only `ownerchip` and `stebo` are built |
| `WEB_APP_URI` / "Sign up as certifier" | The last webapp link — it passed the raw JWT to the web app as a URL query parameter |

Roughly 166 files deleted, ~19,600 lines removed, 8 pub dependencies dropped
(`firebase_core`, `firebase_messaging`, `video_player`, `app_links`,
`info_popup`, `country_picker`, `privy_flutter`, and the never-referenced
`eth_sig_util` was already unused).

---

## Remaining external dependencies

### 1. OwnerChip API — **required, the app will not function without it**

`OC_BACKEND_URL` (`https://api.ownerchip.com`) or `OC_BACKEND_URL_TEST`
(`https://testapi.ownerchip.com`) when `IS_INTERNAL='true'`.

Every request carries `app_id: <BITRISEIO_PACKAGE_NAME>`, `lang: en`, and a
bearer JWT. Configured in `lib/services/backend/backend.services.dart`.

Six Retrofit services survive:

| Base path | Endpoints | What breaks without it |
|---|---|---|
| `/auth` | `GET /`, `POST /`, `POST /session/guest`, `GET /session/terminate`, `GET /me`, `GET`/`POST`/`DELETE /deletionRequest` | **Everything.** No session, no JWT, no app |
| `/collection` | `GET ""`, `POST /{hex}/recovery`, `POST /{hex}/tx/record` | The server-driven collection list (`lib/config/collections.dart` is a fallback only) |
| `/attachments` | `POST /`, `PUT /`, `DELETE /{uuid}`, `GET /{uuid}/public`, `POST /owner/view-all`, `DELETE /` | Digital-content attachments on twins |
| `/creator` | `GET /{tokenId}` | Creator data shown on the scan-result and detail screens |
| `/customer` | `POST /{customerId}/ownercard`, `GET /{customerId}/creator/{walletAddress}` | OwnerCard provisioning (admin screen) |
| `/app` | `POST /{packageName}/action`, `GET /{packageName}` | Analytics, and the **blocking minimum-version gate** |

A guest session is created at startup (`main.dart` → `BackendAuth.initGuestSession`),
so the app talks to this host before the user does anything.

### 2. OwnerChip API websocket — required for session lifecycle

socket.io to the same host, URL derived by rewriting `https`→`wss`
(`lib/services/providers/websocket/websocketNotifier.dart`).

Three events survive: `ping` (`'1'`), `newJwt` (`'3'`, **server-initiated forced
logout** — the server can invalidate the mobile session), `refreshGallery`
(`'4'`, now repointed at the NFT providers). Event `'2'` was the QR-login
confirmation; the number is deliberately left absent rather than renumbered, to
stay protocol-compatible.

### 3. Alchemy — required for all chain reads

- **RPC:** `eth-mainnet.g.alchemy.com` and `polygon-mainnet.g.alchemy.com`, keyed
  by `ALCHEMY_API_KEY_ETH` / `ALCHEMY_API_KEY_POLYGON` (`lib/config/chains.dart`)
- **NFT data API:** `lib/services/alchemy.services.dart` — gallery contents,
  metadata refresh

Note the deleted *bundler* (`alchemy_bundler.services.dart`) was a different
thing: ERC-4337 gas sponsorship. The RPC and NFT API remain load-bearing.

### 4. Pinata / IPFS — required for minting

`IPFS_GATEWAY_API` (`api.pinata.cloud`) with `IPFS_API_KEY` for pinning, plus
`IPFS_GATEWAY` (a dedicated mypinata.cloud gateway) and
`IPFS_ALTERNATIVE_GATEWAY` (`nftstorage.link`) for reads. Twin and voucher
metadata are pinned here at mint time.

⚠️ `.env` ships as a bundled Flutter asset (`pubspec.yaml` `assets:`), so
`IPFS_API_KEY` is extractable from any release APK/IPA. Pre-existing, unchanged
by this branch, but worth knowing.

### 5. AWS S3 (indirect) — attachment file storage

`POST /attachments` returns a presigned S3 URL; the app uploads directly to it
(`lib/services/images.services.dart`, `BackendAttachments.uploadFileToAWS`). The
bucket is the backend's, so this is an implementation detail of the API rather
than an independent dependency.

### 6. WalletConnect / Reown relay — required for the WalletConnect wallet

`WC_PROJECT_ID`. Pairing metadata still advertises `https://www.ownerchip.com`
as the dApp URL and a GitHub avatar as its icon
(`lib/services/wallet.services.dart`) — cosmetic, shown in the user's wallet.

### 7. Sentry — telemetry

`SENTRY_DSN`, `environment` set from `BITRISEIO_PACKAGE_NAME`. Disabled in debug.

### 8. cryptocompare — fiat conversion

`min-api.cryptocompare.com/data/price` for the MyBalance fiat display. Non-fatal
if unreachable.

### 9. `item.ownerchip.com` — burned into the physical chips

`NDEF_URL` / `NDEF_URL_TEST`. Written onto the NFC chip at initialisation and,
on non-internal builds, the NDEF file is **permanently locked**
(`lib/services/secora.services.dart`). This is not a runtime dependency of the
app, but chips already in the field point at this host forever. Android claims
`https://item.ownerchip.com` via an NDEF intent filter.

### 10. `certificate.ownerchip.com` — outbound link

`getCertificateUrl` / `getEnvCertificateUrl` in `lib/utils/utils.dart`, opened
from the NFT detail screen and the scan result. A separate web property that was
deliberately **kept** — it is the chip's own certificate viewer, not the web app.

### 11. Cosmetic outbound links

opensea.io, polygonscan.com, etherscan.com (block explorers), `www.ownerchip.com`
support/legal pages (as literals in the ARB files, **not** from env),
`www.steboart.com` for the stebo brand, and app-store links from the version gate.

### What is definitively gone

No `app.ownerchip.com` / `testapp.ownerchip.com` reference of any kind. No
Firebase, Rarible, Privy, Web3Auth/torus, forwarder or bundler — in **Dart code,
`pubspec.yaml`, the Android project or the Xcode project**.

⚠️ **Two tracked iOS lockfiles are still stale** and were not regenerated,
because this machine has neither working CocoaPods (`cocoapods-core` gem missing)
nor a selected Xcode (CommandLineTools only):

- `ios/Podfile.lock` — still pins `Firebase/CoreOnly` 11.10.0,
  `firebase_core` 3.13.0, `firebase_messaging` 15.1.0, `privy_flutter` /
  `PrivySDK` 2.10.1
- `ios/Runner.xcodeproj/.../swiftpm/Package.resolved` — still references
  `firebase-ios-sdk`, `flutterfire`, `leveldb`, `nanopb`, `privy-ios`

These should self-heal: `ios/Podfile` is Flutter-generated from `pubspec.yaml`,
and those packages are no longer in pubspec, so the next `pod install` (which
`flutter build ios` runs) will resolve without them and rewrite both files. They
were deliberately **not** hand-edited — both carry checksums and are generated
artifacts.

**Do this on a machine with Xcode before the first iOS release:** run
`flutter build ios --no-codesign` (or `cd ios && pod install`) and commit the
regenerated lockfiles. Watch the first iOS CI run in particular: a stale
`Package.resolved` pointing at removed SwiftPM packages is the most likely place
an iOS build trips.

---

## Things learned the hard way

Notes for whoever works on this next. Each of these cost real time or nearly
caused a regression.

**`build_runner` is broken in this repo.** `retrofit_generator` 10.0.0 switches
on `Parser` without handling `Parser.DartMappable`, which `retrofit` 4.9.2 added.
Exit code 78. Consequence: `.g.dart` files **cannot be regenerated**, so removing
a Retrofit endpoint means hand-editing the generated file. `flutter gen-l10n`
works fine. Fixing the pin would be a worthwhile chore.

**The local build was broken before this branch, and Firebase was why.**
`firebase_options.dart` contained unsubstituted `${API_KEY_ANDROID}` placeholders
that only `setFirebaseApp.sh` filled in on CI. That was the sole cause of all 8
pre-existing `flutter analyze` errors *and* of `flutter build apk` failing
locally. Deleting Firebase repaired it. This is why Firebase was removed first —
it unlocked a real compile gate for every later phase.

**Trust analyzer errors over any inventory, including your own.** The reliable
method for a large removal: delete the files, run `flutter analyze`, and let the
error list enumerate every edit site. Line numbers from an earlier survey drift
badly after the first phase.

**Deleting is not always the same as trimming.** Two large UI blocks
(`NFTDetailsScreen`'s action grid, `UserScanResultsScreen`'s ownership body)
were nested `.when()` trees where, once the marketplace branches were removed,
*every remaining leaf returned the same thing*. ~235 lines collapsed to `[]` and
a single `Text`. Worth checking for this before carefully preserving structure
that no longer branches.

**Things that were nearly deleted by mistake:**

- `ocCollection.dart` / `dateTimeJsonConverter.dart` — reported as dying with
  `digitalTwinMetadata`, actually imported by `nftData.dart` and both NFT list
  notifiers. Deleting them would have broken the gallery.
- `makeCardSignature` — reported as deletable with the gasless path, actually
  what signs the OwnerCard's raw transaction hash in `makeAndSendNormalTx`.
  Only `makeTwoCardSignatures` (Alchemy-only) was dead.
- `QRCodeScannerScreen` / `mobile_scanner` — live in `lib/screens/qrCode/` and
  look like part of QR login, but serve wallet-address scanning in
  `AddressInputField`.

**Two traps in repointing `makeAndSendGaslessTx` → `makeAndSendNormalTx`** that
the analyzer could not catch: the parameter order is `(ref, context)` vs
`(context, ref)`, and `makeAndSendNormalTx` hardcoded `enableRecovery: false`
where `approveToken` passes `isOwnerCard`. That bool goes into `transferFrom`
calldata, so the second one would have silently changed on-chain behaviour. It is
now a parameter.

**`(loc as dynamic)` hides missing l10n keys from the analyzer.** The stilami
`MoreInfoButtons` branch reached for four keys through a dynamic cast, so a
missing key would only surface as a runtime `NoSuchMethodError`, on one brand.
Avoid the pattern.

**The websocket wire numbers are positional strings, not enum indices.** Events
are `'1'`, `'3'`, `'4'` — removing `'2'` and renumbering would have broken
`ping` / `newJwt` / `refreshGallery` against the server.

**`EWalletType` was persisted by `index`.** Tail-removing `privy` and
`certificateCard` was safe (indices 0 and 1 unchanged), and `certificateCard`
turned out never to be persisted at all — `backendAuth` guards persistence with
`if (!isCertificateCard)`. The type is now persisted by **name**, with
`parseWalletTypeJson` accepting both forms and raising `StaleWalletTypeException`
for anything unrecognised, so a stale session becomes a clean logout instead of
an unhandled `RangeError`. Covered by `test/wallet_type_test.dart`.

**Bumping `VERSION_NUMBER` logs everyone out.** `HomeScreen` wipes the persisted
`walletType` and `userSession` whenever it differs from the stored `appVersion`.
Desirable for 2.0 given the session-shape changes, but know it happens.

**Version lived in three disagreeing places** — `pubspec.yaml` (`1.6.3+1`),
`sample.env` (`1.5.7`), Bitrise (`1.7.9`). Now `2.0.0` / `2.0.0+765`. Note the
Bitrise steps `change-android-versioncode-and-versionname` and
`set-xcode-build-number` **override** pubspec and fall back to
`$BITRISE_BUILD_NUMBER` for the build number, which is what actually decides the
uploaded `CFBundleVersion`.

**A latent App Store blocker was found and fixed.** The delete-account button was
gated on `EWalletType.privy`, so no OwnerCard or WalletConnect user could ever
delete their account — and with Privy removed it would have been unreachable for
everyone. App Store Guideline 5.1.1(v). Now gated on `session != null`.

---

## Gate status

| Gate | At `f84ea87` | Now |
|---|---|---|
| `flutter analyze` errors | **8** | **0** |
| `flutter analyze` issues | 1140 | 747 |
| `flutter build apk --debug` | **failed** | ✓ (`2.0.0+765`) |
| `flutter test` | 5 passed / 4 failed | 19 passed / 1 failed |
| `dart run build_runner build` | broken (78) | broken (78) — pre-existing |

The one remaining test failure is pre-existing and unrelated: `Collection` has no
`==`/`hashCode`, so `utils_test.dart` compares two equal-but-distinct instances
by identity. Adding value equality would fix it; `Collection` is never used as a
`Map` key or in a `Set`, so it is safe to do.

---

## Not verified — do this before releasing

**No device or NFC hardware was available.** The following are compile-checked
only and are the actual risk surface of this branch:

1. **OwnerCard login** (SIWE challenge signed by the card)
2. **OwnerCard transaction signing** (raw-RLP self-signing, now the only card
   path — fund the card address so it can pay its own gas)
3. **A real WalletConnect mint / burn / transfer**

Also worth a visual check: the app targets **API 36**, so edge-to-edge is
enforced with no opt-out, and there are only 2 `SafeArea` usages against 9
`extendBodyBehindAppBar: true`. Pre-existing, but this is the first release that
will meet the enforcement on a modern device.

## Outstanding operational work

- **Bitrise: remove the "Configure Firebase" step from all workflows.** It calls
  `setFirebaseApp.sh`, which no longer exists — every workflow will fail there.
  Also drop the `FIREBASE_*` envs and the `*_GOOGLESERVICE_INFO_PLIST` /
  `*_GOOGLE_SERVICES_JSON` base64 secrets.
- **Bitrise env:** `VERSION_NUMBER: '2.0.0'` everywhere, and a build number above
  764. Removable keys: `LANDING_PAGE_URL`, `WALLETCONNECT_ICON`,
  `LEGAL_PAGE_URL`, `SUPPORT_PAGE_URL`, `TUTORIAL_PAGE_URL`, `TERMS_PAGE_URL`,
  `ORDER_CHIPS_URL`, `PROJECTS_PAGE_URL`, `WEB_APP_URI`,
  `CERTIFICATE_CARD_BASE_ID`, `ALCHEMY_API_KEY_SEPOLIA`, the two Rarible keys,
  `WEB3_AUTH_CLIENT_ID`, `PRIVY_*`, `ALCHEMY_GAS_POLICY_ID`.
- **Backend team:** these endpoints now receive no traffic from mobile —
  `/creation/*`, `/fcm`, `/offer/*`, `/rarible/*`, `/token/*/purchase/*`,
  `/auth/qrCode/*`, `/collection/{id}/metaTx*`, `/creator/web3auth*`. Nothing
  server-side must change, but the mobile app is no longer an authenticator for
  any web session.
- **Regenerate the iOS lockfiles** on a machine with Xcode + CocoaPods —
  `ios/Podfile.lock` and `Package.resolved` still pin Firebase and PrivySDK. See
  [What is definitively gone](#what-is-definitively-gone).
- **Check Google Play's current `versionCode`** — if it is above 765, Android
  uploads will hit the same wall Apple did.
