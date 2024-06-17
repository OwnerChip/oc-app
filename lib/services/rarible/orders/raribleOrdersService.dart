import 'package:dio/dio.dart';
import 'package:ownerchip_whitelabel/domain/rarible/raribleV2Order/raribleV2Order.dart';
import 'package:ownerchip_whitelabel/services/rarible/rarible.dart';
import 'package:retrofit/retrofit.dart';

part 'raribleOrdersService.g.dart';

@RestApi()
abstract class RaribleOrdersService {
  static Map<int, RaribleOrdersService> _instances = {};

  static RaribleOrdersService instance(int chainId) {
    if (_instances[chainId] == null) {
      _instances[chainId] = RaribleOrdersService(chainId: chainId);
    }
    return _instances[chainId]!;
  }

  factory RaribleOrdersService({
    required int chainId,
  }) {
    final client = Rarible.getRaribleClient(
      chainId: chainId,
    );
    client.options.baseUrl = "${client.options.baseUrl}/orders";
    return _RaribleOrdersService(client);
  }

  // @POST("/{id}/prepareTx")
  // Future<RariblePrepareOrderTransactionResponse> prepareOrder({
  //   @Path("id") required String id,
  //   @Body() required RariblePrepareOrderTransactionPayload payload,
  // });

  @POST("/")
  Future<HttpResponse> createOrder({
    @Body() required RaribleV2Order payload,
  });
}
