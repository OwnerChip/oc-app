import 'package:dio/dio.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/metaTx/payloads/sendGaslessRequestPayload.dart';
import 'package:retrofit/http.dart';

part 'backendMetaTxService.g.dart';

@RestApi()
abstract class BackendMetaTxService {
  static final BackendMetaTxService _instance = BackendMetaTxService();

  static BackendMetaTxService get instance => _instance;

  factory BackendMetaTxService() {
    final dio = Backend.getBackendClient();
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
}
