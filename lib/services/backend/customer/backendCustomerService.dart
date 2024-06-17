import 'package:dio/dio.dart' hide Headers;
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/customer/payload/cardInitPayload.dart';
import 'package:retrofit/retrofit.dart';

part 'backendCustomerService.g.dart';

@RestApi()
abstract class BackendCustomerService {
  static BackendCustomerService _instance = BackendCustomerService();

  static BackendCustomerService get instance => _instance;

  static void recreate(String? jwt) {
    _instance = BackendCustomerService(
      jwt: jwt,
    );
  }

  factory BackendCustomerService({
    String? jwt,
  }) {
    final dio = Backend.getBackendClient(
      jwt: jwt,
      forceProduction: true,
    );
    return _BackendCustomerService(dio,
        baseUrl: "${dio.options.baseUrl}/customer");
  }

  @POST(
    "/{customerId}/ownercard",
  )
  @Headers({
    "lang": "en",
  })
  Future<void> sendCardInitToBackend({
    @Path("customerId") required String customerId,
    @Header("app_id") required String appId,
    @Body() required CardInitPayload payload,
  });
}
