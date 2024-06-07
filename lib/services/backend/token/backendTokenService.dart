import "package:dio/dio.dart";
import 'package:ownerchip_whitelabel/domain/phygitalTradeTypes.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:retrofit/retrofit.dart';

part 'backendTokenService.g.dart';

@RestApi()
abstract class BackendTokenService {
  static BackendTokenService _instance = BackendTokenService();

  static BackendTokenService get instance => _instance;

  static void recreate(String? jwt) {
    _instance = BackendTokenService(
      jwt: jwt,
    );
  }

  factory BackendTokenService({
    String? jwt,
  }) {
    final dio = Backend.getBackendClient(
      jwt: jwt,
    );
    return _BackendTokenService(dio, baseUrl: "${dio.options.baseUrl}/token");
  }

  @GET("/{tokenIdHex}/purchase/unredeemed")
  // TODO: Fix the type of the response once json serialization changes are in
  Future<HttpResponse> getUnredeemedPurchases(
      @Path("tokenIdHex") String tokenIdHex);

  @POST("/{tokenIdHex}/purchase/{purchaseTxHash}/shippingInfo")
  Future<void> postShippingInfoToBackend(
    @Path("tokenIdHex") String tokenIdHex,
    @Path("purchaseTxHash") String purchaseTxHash,
    @Body() ShippingInfo shippingInfo,
  );

  @POST("/{tokenIdHex}/purchase/{purchaseTxHash}/manualHandover")
  Future<void> postManualHandoverToBackend(
    @Path("tokenIdHex") String tokenIdHex,
    @Path("purchaseTxHash") String purchaseTxHash,
  );

}
