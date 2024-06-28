import 'package:dio/dio.dart' hide Headers;
import 'package:ownerchip_whitelabel/domain/oc/creatorDto.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/customer/payload/cardInitPayload.dart';
import 'package:retrofit/retrofit.dart';

part 'backendCustomerService.g.dart';

@RestApi()
abstract class BackendCustomerService {
  static BackendCustomerService _instanceProd = BackendCustomerService();
  static BackendCustomerService get instanceProd => _instanceProd;

  static BackendCustomerService _instance = BackendCustomerService();

  static BackendCustomerService get instance => _instance;

  static void recreate(String? jwt) {
    _instanceProd = BackendCustomerService(
      jwt: jwt,
      forceProduction: true,
    );
    _instance = BackendCustomerService(
      jwt: jwt,
      forceProduction: false,
    );
  }

  factory BackendCustomerService({
    String? jwt,
    bool forceProduction = false,
  }) {
    final dio = Backend.getBackendClient(
      jwt: jwt,
      forceProduction: forceProduction
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

  @GET(
    "/{customerId}/creator/{walletAddress}",
  )
  Future<CreatorDto> getCreator({
    @Path("customerId") required String customerId,
    @Path("walletAddress") required String walletAddress,
  });
}
