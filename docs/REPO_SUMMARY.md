# Repository Summary: OwnerChip Whitelabel Flutter App

## High-Level Purpose
This repo contains a Flutter mobile app that connects physical items (NFC-enabled chips/cards) to blockchain-backed “digital twins.” It is built as a **whitelabel app**, so branding, assets, and identifiers can be swapped via environment variables and logo config files.

## Core Capabilities (from code and config)
- **NFC workflows** for initializing and scanning OwnerChip cards, verifying authenticity, and routing users based on token existence or ownership.
- **Blockchain/Web3 integration** via `web3dart` using contract ABIs in `assets/contracts/` (collection, registry, voucher, controller, forwarder, ERC-20). Includes gas estimation and contract queries.
- **Wallet connectivity** with **Reown AppKit (WalletConnect)** and **Web3Auth**, plus support for OwnerCard/certificate-card signing.
- **Gasless/meta-tx flow** that prepares typed data, requests signatures, and submits through backend services.
- **Backend API integration** (Dio + Sentry interceptors) for authentication, collections, creators, offers, tokens, attachments, FCM, etc.
- **Push notifications** using Firebase Messaging with in-app routing when relevant notifications arrive.
- **Marketplace and offer flows** (offer creation, listing on marketplace, sales and transfers).
- **Content and attachments** handling (image/file picker, IPFS services, attachments screens).
- **QR code scanning** and related flows.
- **Localization** via Flutter gen-l10n and `lib/l10n/`.
- **Error monitoring/logging** with Sentry and Talker.

## Key Entry Points
- `lib/main.dart`: App bootstrap, Firebase init, Sentry setup, Riverpod `ProviderScope`, localization, routing, and FCM handlers.
- `pubspec.yaml`: Dependencies (NFC, web3, Firebase, Sentry, Riverpod, WalletConnect, Web3Auth, etc.) and asset configuration.
- `README.md`: Setup and whitelabel customization instructions.

## Project Structure Overview
- `lib/screens/`: UI pages and flows (home, onboarding, NFT details, metadata input, transfer, offers, balance, QR, gallery, attachments, admin init, card lost, PIN/PUK, etc.).
- `lib/services/`: Core logic for NFC, wallet, web3, marketplace, backend APIs, gas station/meta-tx, IPFS, QR code, images, attachments.
- `lib/services/providers/`: Riverpod state and data providers (user, collections, NFTs, creations, websocket, onboarding, etc.).
- `lib/domain/`: Data models, converters, and domain types (blockchain tokens, JWT, collections, creations, wallet signatures, etc.).
- `lib/widgets/`: Reusable UI components, popups, animations, and layout helpers.
- `lib/themes/`: Theme and color specs.
- `lib/config/`: App and blockchain configuration (chains, wallets, constants, ownercard setup).
- `assets/`: Whitelabel image sets, contract ABIs, fonts.
- `android/` and `ios/`: Native project scaffolding.
- `scripts/`: Utility scripts (localization customization, base64 helper).

## Whitelabeling
Whitelabel behavior is controlled by environment variables in `.env` (see `README.md`). Important knobs include:
- `APP_ID`
- `IMAGE_ASSETS_BASE_URL`
- `BITRISEIO_PACKAGE_NAME`
- `IS_INTERNAL`

Splash screens are generated via dedicated YAML configs in the repo root (e.g., `flutter_logo_config_ownerchip.yaml`).

## Notable Integrations
- **Firebase**: core + messaging.
- **Sentry**: app-level error monitoring.
- **Web3**: `web3dart` + contract ABIs.
- **Wallets**: WalletConnect/Reown AppKit and Web3Auth.
- **NFC**: `nfc_manager` for chip scanning/verification.
- **Localization**: Flutter gen-l10n.

## Files Reviewed for This Summary
- `README.md`
- `pubspec.yaml`
- `lib/main.dart`
- `lib/services/nfc.services.dart`
- `lib/services/backend/backend.services.dart`
- `lib/services/web3.services.dart`
- `lib/services/wallet.services.dart`
- Directory listings for `lib/`, `lib/screens/`, and `lib/services/`
