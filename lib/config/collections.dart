class Collections {
  late Map<int, List<Map<String, String>>> collections;

  Collections(String app_environment) {
    switch (app_environment) {
      case 'ownerchip':
        // ownerchip collections
        collections = {
          137: [
            {
              "id": '0x6fe0Fd3f6430DcFF517Cd939815Fab115B033679',
              "name": "Ownerchip Demo"
            },
          ],
          80001: [
            {
              "id": '0x46f4Cd7c9c6Aca27BECF45Cc5d836dDDac204d32',
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
              "id": "0xE587fb76509550a72Eb120b941F9235488aB6AEe",
              "name": "Stebo Art"
            },
          ],
          137: [
            {
              "id": "0xE95232cdA853989B86fF8beC94EaEfA78cF35668",
              "name": "Stebo Art Prints"
            },
            {
              "id": "0x5326064FD9a82EC2a095104E7c37c25D36155034",
              "name": "Stebo Workshop 1"
            }
          ],
          80001: [
            {
              "id": '0x163a80d5D7E2e1d256D7083E4b04Cd873e30f6d2',
              "name": "Stebo Demo App"
            }
          ]
        };
        break;
    }
  }
}
// access using: Collections(dotenv.get('APP_ID')).collections,