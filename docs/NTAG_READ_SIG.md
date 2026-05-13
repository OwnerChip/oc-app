# Plan: Add NTAG21x (NTAG213/216) Authenticity Check via READ_SIG

## Goal
When scanning an NFC tag, verify it is a genuine **NXP NTAG213/215/216** by reading the factory-programmed **ECC originality signature** using `READ_SIG (0x3C)` and verifying it (preferably in backend for v1).

**Important:** `READ_SIG` is **not ISO7816 APDU**. It is an **NTAG Type 2 command** sent over **NfcA / ISO14443-A**.

---

## References (from datasheet)
- NTAG21x uses ISO14443 Type A and supports NTAG commands including `GET_VERSION` and `READ_SIG`.
- `GET_VERSION (0x60)` returns 8 bytes including storage size (213=0x0F, 215=0x11, 216=0x13).
- `READ_SIG` command: `0x3C 0x00` returns **32-byte ECC signature**.
- Signature is ECDSA on **secp128r1**, bound to UID, produced by NXP in manufacturing.
- Verification uses NXP public key (can be offline if embedded, but backend verify recommended first).

---

## High-level Flow Integration

### Where to integrate
Integrate into existing NFC scan pipeline: `scanClosure(...)` inside `onDiscovered`.

### New scan order (recommended)
1. Create `NFCPlatform nfc`
2. **Update capability gate**: accept **NfcA (ISO14443-A)** for NTAG21x (do not require IsoDep/Iso7816)
3. `GET_VERSION` → confirm tag is NTAG21x
4. `READ_SIG` → fetch 32-byte signature
5. Verify authenticity (backend recommended)
6. Only if genuine: proceed with existing logic:
   - `createFirstKeypairOnChip(...)`
   - `verifySignatureAuthenticity(...)`
   - navigation

**Reason:** Avoid initializing/continuing flows on clones/emulators.

---

## Implementation Tasks

## 1) Update NFC platform check to allow NfcA
### Current issue
`nfcPlatformCheck(...)` appears to require IsoDep/Iso7816. That will block NTAG21x authenticity verification.

### Required change
- Accept tags that support **NfcA** as valid for authenticity check.
- Keep IsoDep/Iso7816 logic as-is for other chip types, but do not treat their absence as fatal for NTAG21x path.

Acceptance criterion:
- NTAG213/216 scanned by Android/iOS passes gating and can transceive NfcA commands.

---

## 2) Add NTAG command primitives

### 2.1 `GET_VERSION` primitive
Create:
- `Future<Uint8List> ntagGetVersion(NFCPlatform nfc)`

Behavior:
- Send bytes: `[0x60]`
- Expect 8-byte response
- Validate response length == 8

Parse/Check:
- Verify vendor/product family indicates NTAG21x
- Use storage size byte to distinguish:
  - NTAG213: 0x0F
  - NTAG215: 0x11
  - NTAG216: 0x13

If not NTAG21x:
- Mark `originalitySupported=false` and return early (skip READ_SIG path)

---

### 2.2 `READ_SIG` primitive
Create:
- `Future<Uint8List> ntagReadSig(NFCPlatform nfc)`

Behavior:
- Send bytes: `[0x3C, 0x00]`
- Expect 32-byte response
- Validate response length == 32

Error handling:
- If NAK/no response/tag lost: treat as `originalitySupported=false` or `unknown` depending on product decision.

Notes:
- Mobile NFC stacks typically handle CRC internally. Don’t append CRC unless your `transceive` abstraction explicitly requires it.

---

## 3) Verification Strategy (Backend-first)

### 3.1 Data collected in app
- `uid` (from NFC tag identifier)
- `getVersion` (8 bytes, optional but recommended for guardrails + telemetry)
- `signature` (32 bytes from READ_SIG)

### 3.2 Backend endpoint
Add or extend backend API:
- `POST /nfc/ntag/verify-originality`

Request JSON:
- `uidHex`
- `getVersionHex` (optional)
- `sigHex`

Response JSON:
- `supported: bool`
- `genuine: bool`
- `reason: string` (e.g., "not_ntag21x", "read_sig_failed", "verify_failed", "ok")

### 3.3 Backend verification logic
- Verify ECDSA signature on **secp128r1** using NXP public key.
- Message to verify is based on UID per NXP scheme (agent should consult NXP appnote / official key/verification method already used in ecosystem).
- Return `genuine=true` only if signature verifies.

Acceptance criteria:
- Known genuine NTAG213/216 passes.
- Cloned tag with copied NDEF but no valid signature fails.

---

## 4) App State + UX plumbing

### 4.1 Add provider / model
Add an `NtagOriginalityState` (or similar):
- `supported: bool?`
- `genuine: bool?`
- `reason: String?`
- raw debug:
  - `uid: Uint8List`
  - `getVersion: Uint8List`
  - `sig: Uint8List`

### 4.2 Policy decisions
Decide behavior when verification is:
- `genuine == false` → hard fail (treat as non-authentic, route to negative path)
- `supported == false` (not NTAG21x) → fall back to existing flow (if relevant), or reject depending on product needs
- `unknown` due to read errors → either block or warn and continue (choose one for v1)

---

## 5) Hook into `scanClosure` and call sites

### 5.1 Add authenticity pre-check inside `onDiscovered`
Pseudo-sequence:
- `uid = nfc.uid` (or from tag data)
- `version = await ntagGetVersion(nfc)`
- if isNTAG21x:
  - `sig = await ntagReadSig(nfc)`
  - `verify = await Backend.verifyOriginality(uid, version, sig)`
  - store to provider
  - if `verify.genuine != true`: stop session with error + do not proceed
- else:
  - store supported=false, continue (or abort depending on policy)

### 5.2 Ensure existing workflows still work
Paths that call `scanClosure`:
- `initializeItem`
- `scanItem`
- `generateKeyOnChip`
- etc.

They should all benefit automatically if authenticity check is embedded in `scanClosure`.

---

## 6) Telemetry / analytics
Add traces for:
- `GET_VERSION` success/fail
- `READ_SIG` success/fail
- backend verify result (supported/genuine/reason)

Attach tags:
- device platform (iOS/Android)
- `storageSize` if available
- `uid` (optional; consider privacy)

---

## Acceptance Tests (Minimum)
1. Scan genuine NTAG213/216:
   - GET_VERSION OK
   - READ_SIG returns 32 bytes
   - backend verify returns genuine=true
   - app proceeds to existing token flows

2. Scan non-NTAG tag:
   - GET_VERSION fails or indicates not NTAG21x
   - app sets supported=false and follows chosen policy

3. Simulate clone (NDEF copied to non-genuine tag):
   - READ_SIG missing/invalid or backend verify fails
   - app blocks with "chip not authentic" (or routes negative)

4. NFC reliability:
   - Tag lost / no response:
     - app shows "please hold longer" style messaging
     - sets state unknown or fails per policy

---

## Notes for Agent
- Do NOT implement READ_SIG via ISO7816 APDUs. Use NfcA transceive.
- Keep changes minimal: add NfcA support, implement GET_VERSION + READ_SIG, wire backend verify, and gate existing flows on result.
- If crypto verification is moved on-device later, ensure Dart library supports ECDSA secp128r1; backend-first is recommended for v1.