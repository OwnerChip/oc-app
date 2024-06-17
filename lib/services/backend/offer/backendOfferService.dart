import 'package:dio/dio.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/offer/payloads/offerItemPayload.dart';
import 'package:retrofit/dio.dart';
import 'package:retrofit/http.dart';

part 'backendOfferService.g.dart';

@RestApi()
abstract class BackendOfferService {
  static BackendOfferService _instance = BackendOfferService();

  static BackendOfferService get instance => _instance;

  static void recreate(String? jwt) {
    _instance = BackendOfferService(
      jwt: jwt,
    );
  }

  factory BackendOfferService({
    String? jwt,
  }) {
    final dio = Backend.getBackendClient(
      jwt: jwt,
    );
    return _BackendOfferService(dio, baseUrl: "${dio.options.baseUrl}/offer");
  }

  @POST("/")
  Future<void> sendOfferItem(@Body() OfferItemPayload dto);

  @POST('/cancel/{offerHash}')
  Future<void> cancelOffer(@Path('offerHash') String offerHash);

  @POST('/hash/rarible')
  // TODO: Fix the type of the response once json serialization changes are in
  Future<HttpResponse> getRaribleOfferTypedDataHashAndEncodedData(
    @Body() Map<String, dynamic> data,
  );
}
