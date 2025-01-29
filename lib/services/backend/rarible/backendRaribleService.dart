

import 'package:dio/dio.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/rarible/payloads/makeRaribleRequestPayload.dart';
import 'package:retrofit/http.dart';
import 'package:retrofit/retrofit.dart';

part 'backendRaribleService.g.dart';

@RestApi()
abstract class BackendRaribleService {

  static BackendRaribleService _instance = BackendRaribleService();

  static BackendRaribleService get instance => _instance;

  static void recreate(String? jwt) {
    _instance = BackendRaribleService(
      jwt: jwt,
    );
  }

  factory BackendRaribleService({
    String? jwt,
  }) {
    final dio = Backend.getBackendClient(
      jwt: jwt,
    );
    return _BackendRaribleService(dio, baseUrl: "${dio.options.baseUrl}/rarible");
  }

  @POST("/request")
  Future<HttpResponse> makeRaribleRequest(@Body() MakeRaribleRequestPayload data);




}