import 'package:web3dart/web3dart.dart';

//ATTENTION! NEW collections have to be added to the correct app environment *AND* to the "ALL" case!

class Collections {
  late Map<int, List<Map<String, dynamic>>> collections;

  Collections(String app_environment) {
    switch (app_environment) {
      case 'ownerchip':
        // ownerchip collections
        collections = {
          1: [
            {
              "id": EthereumAddress.fromHex(
                  '0xD0a61ca8F851e70AC50f7C33c943018A47104763'),
              "name": "OwnerChip Collection"
            }
          ],
          137: [
            {
              "id": EthereumAddress.fromHex(
                  '0x1787f9469238E2113CdF83e15F169FBA15F884f5'),
              "name": "OwnerChip Demo"
            },
            {
              "id": EthereumAddress.fromHex(
                  '0xEF5B50BB76B416e7435C22A0c1Dec829da9839d1'),
              "name": "OwnerChip Community"
            }
          ],
          80001: [
            {
              "id": EthereumAddress.fromHex(
                  '0x91930a50a20625f1eb2c2Ce04535fDFF657B5b8a'),
              "name": "Demo Collection"
            }
          ]
        };
        break;
      case 'ownerchip_infineon':
        // ownerchip infineon demo collections
        collections = {
          80001: [
            {
              "id": EthereumAddress.fromHex(
                  '0x91930a50a20625f1eb2c2Ce04535fDFF657B5b8a'),
              "name": "Demo Collection"
            }
          ]
        };
        break;
      case 'stebo':
        // stebo collections
        collections = {
          1: [
            {
              "id": EthereumAddress.fromHex(
                  "0xE587fb76509550a72Eb120b941F9235488aB6AEe"),
              "name": "SteboArt"
            },
            {
              "id": EthereumAddress.fromHex(
                  "0x5C058D97C3d088114c913caEE134807a0b5c0852"),
              "name": "ArtsyApes"
            },
          ],
          137: [
            {
              "id": EthereumAddress.fromHex(
                  "0xE95232cdA853989B86fF8beC94EaEfA78cF35668"),
              "name": "SteboArt"
            },
            {
              "id": EthereumAddress.fromHex(
                  "0x5326064FD9a82EC2a095104E7c37c25D36155034"),
              "name": "SteboArt Workshop 1"
            },
            {
              "id": EthereumAddress.fromHex(
                  "0x5662E8b29a8131Bd7A281a43BcfEfce1e369aa7C"),
              "name": "SteboArt Workshop Heroes"
            },
            {
              "id": EthereumAddress.fromHex(
                  "0x9F0F89f4949B6ca233aB38F0FD1d5eFEE97aeF66"),
              "name": "SteboArt Workshop CoolPeople"
            },
            {
              "id": EthereumAddress.fromHex(
                  "0x6366cf5b9caEA13D4a04Bb6fEb67dE293810C786"),
              "name": "SteboArt Workshop Superstars"
            },
            {
              "id": EthereumAddress.fromHex(
                  "0xFA4c465D82B8419f3A8AF0ec615E1bcA1D86Ac63"),
              "name": "ArtsyApes"
            },
          ],
          80001: [
            {
              "id": EthereumAddress.fromHex(
                  '0x82a225C01F70828A415bB576f1C334928aE32b29'),
              "name": "Stebo Demo"
            },
            {
              "id": EthereumAddress.fromHex(
                  '0x163a80d5D7E2e1d256D7083E4b04Cd873e30f6d2'),
              "name": "Stebo Demo (old)"
            },
          ]
        };
        break;
      case 'all':
        collections = {
          1: [
            {
              "id": EthereumAddress.fromHex(
                  '0xD0a61ca8F851e70AC50f7C33c943018A47104763'),
              "name": "OwnerChip Collection"
            },
            {
              "id": EthereumAddress.fromHex(
                  "0xE587fb76509550a72Eb120b941F9235488aB6AEe"),
              "name": "SteboArt"
            },
            {
              "id": EthereumAddress.fromHex(
                  "0x5C058D97C3d088114c913caEE134807a0b5c0852"),
              "name": "ArtsyApes"
            },
          ],
          137: [
            {
              "id": EthereumAddress.fromHex(
                  '0x1787f9469238E2113CdF83e15F169FBA15F884f5'),
              "name": "OwnerChip Demo"
            },
            {
              "id": EthereumAddress.fromHex(
                  '0xEF5B50BB76B416e7435C22A0c1Dec829da9839d1'),
              "name": "OwnerChip Community"
            },
            {
              "id": EthereumAddress.fromHex(
                  "0xE95232cdA853989B86fF8beC94EaEfA78cF35668"),
              "name": "SteboArt"
            },
            {
              "id": EthereumAddress.fromHex(
                  "0x5326064FD9a82EC2a095104E7c37c25D36155034"),
              "name": "SteboArt Workshop 1"
            },
            {
              "id": EthereumAddress.fromHex(
                  "0x5662E8b29a8131Bd7A281a43BcfEfce1e369aa7C"),
              "name": "SteboArt Workshop Heroes"
            },
            {
              "id": EthereumAddress.fromHex(
                  "0x9F0F89f4949B6ca233aB38F0FD1d5eFEE97aeF66"),
              "name": "SteboArt Workshop CoolPeople"
            },
            {
              "id": EthereumAddress.fromHex(
                  "0x6366cf5b9caEA13D4a04Bb6fEb67dE293810C786"),
              "name": "SteboArt Workshop Superstars"
            },
            {
              "id": EthereumAddress.fromHex(
                  "0xFA4c465D82B8419f3A8AF0ec615E1bcA1D86Ac63"),
              "name": "ArtsyApes"
            },
          ],
          80001: [
            {
              "id": EthereumAddress.fromHex(
                  '0x91930a50a20625f1eb2c2Ce04535fDFF657B5b8a'),
              "name": "Demo Collection"
            },
            {
              "id": EthereumAddress.fromHex(
                  '0x82a225C01F70828A415bB576f1C334928aE32b29'),
              "name": "Stebo Demo"
            },
            {
              "id": EthereumAddress.fromHex(
                  '0x163a80d5D7E2e1d256D7083E4b04Cd873e30f6d2'),
              "name": "Stebo Demo (old)"
            },
          ]
        };
        break;
    }
  }
}
// access using: Collections(dotenv.get('APP_ID')).collections,