import 'package:ownerchip_whitelabel/domain/openSea/openSeaListingParams/openSeaListingParams.dart';

class OpenSeaV2ListingRequest {
  final OpenSeaListingParams listingParams; // Represents listing parameters.
  final String
  signature; // Signed type data represented by the parameters field.
  final String protocolAddress = "0x00000000000000adc04c56bf30ac9d3c0aaf14dc";

  OpenSeaV2ListingRequest({
    required this.listingParams,
    required this.signature,
  });
}
