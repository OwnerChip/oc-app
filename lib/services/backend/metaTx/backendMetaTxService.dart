import 'package:dio/dio.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/metaTx/payloads/sendGaslessRequestPayload.dart';
import 'package:retrofit/http.dart';

part 'backendMetaTxService.g.dart';

@RestApi()
abstract class BackendMetaTxService {
  static BackendMetaTxService _instance = BackendMetaTxService();

  static BackendMetaTxService get instance => _instance;

  static void recreate(String? jwt) {
    _instance = BackendMetaTxService(
      jwt: jwt,
    );
  }

  factory BackendMetaTxService({
    String? jwt,
  }) {
    final dio = Backend.getBackendClient(
      jwt: jwt,
    );
    return _BackendMetaTxService(dio, baseUrl: dio.options.baseUrl);
  }

  @GET("/collection/{collectionId}/metaTx/{functionSignatureHash}")
  Future<String> checkMetaTx({
    @Path("collectionId") required String collectionId,
    @Path("functionSignatureHash") required String functionSignatureHash,
  });

  @POST("/collection/{collectionId}/metaTx")
  Future<String> sendGaslessRequest({
    @Path("collectionId") required String collectionId,
    @Body() required SendGaslessRequestPayload body,
  });

  @POST("/collection/{collectionId}/metaTx/hash")
  Future<String> getEthSignTypedDataSignature({
    @Path("collectionId") required String collectionId,
    @Body() required Map<String, dynamic> body,
  });
}
