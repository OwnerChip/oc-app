import 'package:web3dart/web3dart.dart';

//ATTENTION! NEW collections have to be added to the correct app environment *AND* to the "ALL" case!

class Collections {
  late Map<int, List<Map<String, dynamic>>> collections;

  Collections(String app_environment) {
    switch (app_environment) {
      case 'ownerchip':
        // ownerchip collections
        collections = {
          137: [
            {
              "id": EthereumAddress.fromHex(
                  '0x1787f9469238E2113CdF83e15F169FBA15F884f5'),
              "name": "OC Demo Collection"
            }
          ],
          80001: [
            {
              "id": EthereumAddress.fromHex(
                  '0x91930a50a20625f1eb2c2Ce04535fDFF657B5b8a'),
              "name": "INFINEON Demo Collection"
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
              "name": "Stebo Art"
            },
          ],
          137: [
            {
              "id": EthereumAddress.fromHex(
                  "0xE95232cdA853989B86fF8beC94EaEfA78cF35668"),
              "name": "Stebo Art Prints"
            },
            {
              "id": EthereumAddress.fromHex(
                  "0x5326064FD9a82EC2a095104E7c37c25D36155034"),
              "name": "Stebo Workshop 1"
            }
          ],
          80001: [
            {
              "id": EthereumAddress.fromHex(
                  '0x163a80d5D7E2e1d256D7083E4b04Cd873e30f6d2'),
              "name": "Stebo Demo App"
            }
          ]
        };
        break;
      case 'all':
        collections = {
          1: [
            {
              "id": EthereumAddress.fromHex(
                  "0xE587fb76509550a72Eb120b941F9235488aB6AEe"),
              "name": "Stebo Art"
            },
          ],
          137: [
            {
              "id": EthereumAddress.fromHex(
                  '0x1787f9469238E2113CdF83e15F169FBA15F884f5'),
              "name": "OC Demo Collection"
            },
            {
              "id": "0xE95232cdA853989B86fF8beC94EaEfA78cF35668",
              "name": "Stebo Art Prints"
            },
            {
              "id": EthereumAddress.fromHex(
                  "0x5326064FD9a82EC2a095104E7c37c25D36155034"),
              "name": "Stebo Workshop 1"
            }
          ],
          80001: [
            {
              "id": EthereumAddress.fromHex(
                  '0x91930a50a20625f1eb2c2Ce04535fDFF657B5b8a'),
              "name": "INFINEON Demo Collection"
            },
            {
              "id": EthereumAddress.fromHex(
                  '0x163a80d5D7E2e1d256D7083E4b04Cd873e30f6d2'),
              "name": "Stebo Demo App"
            }
          ]
        };
        break;
    }
  }
}
// access using: Collections(dotenv.get('STYLE_ID')).collections,