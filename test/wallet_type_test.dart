import 'package:ownerchip_whitelabel/config/wallets.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:test/test.dart';

/// These tests guard the persisted-wallet-type contract.
///
/// `walletType` is written to SharedPreferences and read back on every cold
/// start. Older builds persisted `EWalletType.index`; this build persists
/// `EWalletType.name`. Both forms must be readable, and anything unreadable
/// must raise [StaleWalletTypeException] so the caller clears the session —
/// never an unhandled RangeError, and never a silently wrong wallet type.
void main() {
  group('EWalletType index stability', () {
    test('ownerCard and walletConnect keep their historical indices', () {
      // Legacy installs hold these integers on disk. Reordering the enum would
      // silently rehydrate an OwnerCard user as WalletConnect.
      expect(EWalletType.ownerCard.index, 0);
      expect(EWalletType.walletConnect.index, 1);
    });

    test('only the two supported wallet types exist', () {
      expect(EWalletType.values, hasLength(2));
    });
  });

  group('parseWalletTypeJson', () {
    test('reads the current name form', () {
      expect(parseWalletTypeJson('ownerCard'), EWalletType.ownerCard);
      expect(parseWalletTypeJson('walletConnect'), EWalletType.walletConnect);
    });

    test('reads the legacy index form written by older builds', () {
      expect(parseWalletTypeJson(0), EWalletType.ownerCard);
      expect(parseWalletTypeJson(1), EWalletType.walletConnect);
    });

    test('rejects indices of dropped wallet types instead of throwing RangeError',
        () {
      // 2 was privy, 3 was certificateCard.
      expect(() => parseWalletTypeJson(2),
          throwsA(isA<StaleWalletTypeException>()));
      expect(() => parseWalletTypeJson(3),
          throwsA(isA<StaleWalletTypeException>()));
    });

    test('rejects names of dropped wallet types', () {
      expect(() => parseWalletTypeJson('privy'),
          throwsA(isA<StaleWalletTypeException>()));
      expect(() => parseWalletTypeJson('certificateCard'),
          throwsA(isA<StaleWalletTypeException>()));
    });

    test('rejects negative indices, null and unexpected types', () {
      expect(() => parseWalletTypeJson(-1),
          throwsA(isA<StaleWalletTypeException>()));
      expect(() => parseWalletTypeJson(null),
          throwsA(isA<StaleWalletTypeException>()));
      expect(() => parseWalletTypeJson(1.5),
          throwsA(isA<StaleWalletTypeException>()));
      expect(() => parseWalletTypeJson(<String, dynamic>{}),
          throwsA(isA<StaleWalletTypeException>()));
    });
  });

  group('WalletType JSON round-trip', () {
    test('persists the type by name, not by index', () {
      final json = WalletType('OwnerCard', 'icon.png', EWalletType.ownerCard)
          .toJson();
      expect(json['type'], 'ownerCard');
    });

    test('round-trips through toJson/fromJson', () {
      for (final type in EWalletType.values) {
        final original = WalletType('n', 'i', type);
        final restored = WalletType.fromJson(original.toJson());
        expect(restored.type, type);
        expect(restored.name, 'n');
        expect(restored.iconUri, 'i');
      }
    });

    test('rehydrates a session persisted by an older build', () {
      final legacy = {'name': 'OwnerCard', 'iconUri': 'i', 'type': 0};
      expect(WalletType.fromJson(legacy).type, EWalletType.ownerCard);
    });

    test('a session from a build that used Privy fails loudly', () {
      final privySession = {'name': 'privy', 'iconUri': 'i', 'type': 2};
      expect(() => WalletType.fromJson(privySession),
          throwsA(isA<StaleWalletTypeException>()));
    });
  });
}
