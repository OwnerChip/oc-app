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
                  '0x6fe0Fd3f6430DcFF517Cd939815Fab115B033679'),
              "name": "Ownerchip Demo"
            },
          ],
          80001: [
            {
              "id": EthereumAddress.fromHex(
                  '0x46f4Cd7c9c6Aca27BECF45Cc5d836dDDac204d32'),
              "name": "Demo Collection"
            },
            {
              "id": EthereumAddress.fromHex(
                  '0x9c61BDF9D7ddad20706F830770DDd386A433685F'),
              "name": "Unrestricted Demo Collection"
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
                  '0x9c61BDF9D7ddad20706F830770DDd386A433685F'),
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
                  '0x6fe0Fd3f6430DcFF517Cd939815Fab115B033679'),
              "name": "Ownerchip Demo"
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
                  '0x46f4Cd7c9c6Aca27BECF45Cc5d836dDDac204d32'),
              "name": "Demo Collection"
            },
            {
              "id": EthereumAddress.fromHex(
                  '0x163a80d5D7E2e1d256D7083E4b04Cd873e30f6d2'),
              "name": "Stebo Demo App"
            },
            {
              "id": EthereumAddress.fromHex(
                  '0x9c61BDF9D7ddad20706F830770DDd386A433685F'),
              "name": "Gasless Demo Collection"
            }
          ]
        };
        break;
    }
  }
}
// access using: Collections(dotenv.get('STYLE_ID')).collections,