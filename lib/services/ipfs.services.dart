import 'dart:io';

import 'package:cross_file/cross_file.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http_parser/http_parser.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Raised when no configured gateway could serve a CID. Carries every attempt so
/// the log says which gateway failed and why, rather than just "not found".
class IpfsFetchException implements Exception {
  final String cid;
  final List<String> attempts;

  IpfsFetchException(this.cid, this.attempts);

  @override
  String toString() =>
      'No IPFS gateway could serve $cid (${attempts.join('; ')})';
}

/// Raised when pinning fails. `reason` is the provider's own message, not a
/// generic code — a pin can fail because the account is at its plan file limit,
/// and that is not diagnosable from "upload failed".
class IpfsPinException implements Exception {
  final int? statusCode;
  final String reason;

  /// True when the response looks like a plan/quota rejection rather than a
  /// transient error. Heuristic on the provider's wording: treat it as a hint
  /// for the operator, never as a control-flow guarantee.
  final bool looksLikeQuotaLimit;

  IpfsPinException(this.statusCode, this.reason, this.looksLikeQuotaLimit);

  @override
  String toString() => looksLikeQuotaLimit
      ? 'IPFS pin rejected (HTTP $statusCode): $reason — this looks like the '
          'pinning account has hit its plan file/storage limit, which needs an '
          'upgrade or a prune, not a retry.'
      : 'IPFS pin failed (HTTP $statusCode): $reason';
}

/// Read gateways in priority order: primary first, then the alternative.
///
/// The alternative is now genuinely used. It was previously configured and
/// `getAlternativeIpfsGatewayClient()` was defined but never called anywhere,
/// which left the app single-homed: any outage of the primary gateway showed up
/// as items with no metadata and no image.
List<String> ipfsReadGateways() {
  final primary = _normalizeGatewayBase(dotenv.env['IPFS_GATEWAY']);
  final alternative = _normalizeGatewayBase(dotenv.env['IPFS_ALTERNATIVE_GATEWAY']);
  final gateways = <String>[];
  if (primary.isNotEmpty) gateways.add(primary);
  if (alternative.isNotEmpty && alternative != primary) {
    gateways.add(alternative);
  }
  return gateways;
}

/// Guarantees exactly one trailing slash.
///
/// Both Dio's `baseUrl` joining and the string concatenation in [ipfsUrlForCid]
/// depend on it: `.../ipfs` + `Qm…` yields `.../ipfsQm…`, and Dio drops the last
/// path segment when baseUrl has no trailing slash. Either way the failure is
/// silent, so normalise instead of trusting the env value.
String _normalizeGatewayBase(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) return '';
  return value.endsWith('/') ? value : '$value/';
}

/// The gateway that last served a successful read.
///
/// Reused when building display URLs so that, if the primary is down and
/// metadata came from the alternative, the image URL points at the gateway
/// already known to be working — instead of costing an extra probe request or
/// handing the widget a URL that is currently failing.
String _lastGoodGateway = '';

/// Best known-working gateway base for building a URL.
String currentIpfsGateway() {
  if (_lastGoodGateway.isNotEmpty) return _lastGoodGateway;
  final gateways = ipfsReadGateways();
  return gateways.isEmpty ? '' : gateways.first;
}

/// Absolute URL for a bare CID on the best known-working gateway.
///
/// Bare CIDs are correct here: the pinning account keeps every referenced CID as
/// an individual pin, so `<gateway>/<cid>` resolves directly.
String ipfsUrlForCid(String cid) => '${currentIpfsGateway()}$cid';

String _shortReason(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;
    final body = error.response?.data;
    final detail = body is String && body.isNotEmpty
        ? body
        : (body != null ? body.toString() : error.message ?? 'no detail');
    return status != null
        ? 'HTTP $status ${detail.substring(0, detail.length.clamp(0, 120))}'
        : detail.substring(0, detail.length.clamp(0, 120));
  }
  return error.toString().substring(0, error.toString().length.clamp(0, 120));
}

/// get ipfsGatewayClient
Dio getIpfsGatewayClient(bool api) {
  if (api) {
    return Dio(BaseOptions(
        baseUrl: dotenv.get('IPFS_GATEWAY_API'),
        headers: {"Authorization": "Bearer ${dotenv.get('IPFS_API_KEY')}"}));
  } else {
    return Dio(BaseOptions(baseUrl: dotenv.get('IPFS_GATEWAY')));
  }
}

Dio getAlternativeIpfsGatewayClient() {
  return Dio(BaseOptions(baseUrl: dotenv.get('IPFS_ALTERNATIVE_GATEWAY')));
}

/// retrieve cid from IPFS link
String getCidFromIpfsLink(String ipfsLink) {
  return ipfsLink.toString().replaceFirst(r'ipfs://', '');
}

/// Fetches a CID, trying each configured gateway in order.
///
/// Throws [IpfsFetchException] listing every attempt when all gateways fail.
/// Deliberately does NOT swallow the error: returning null on failure made a
/// gateway outage indistinguishable from missing content, and callers typed for
/// a non-null result then failed with an opaque cast error instead.
Future<Response> _getFromAnyGateway(String cid, ResponseType responseType) async {
  final gateways = ipfsReadGateways();
  if (gateways.isEmpty) {
    throw IpfsFetchException(cid, ['no IPFS gateway configured']);
  }

  final attempts = <String>[];
  for (final base in gateways) {
    try {
      final dio = Dio(BaseOptions(baseUrl: base));
      dio.addSentry();
      final response = await dio.get(
        cid,
        options: Options(responseType: responseType),
      );
      _lastGoodGateway = base;
      return response;
    } catch (e) {
      attempts.add('$base -> ${_shortReason(e)}');
    }
  }

  final failure = IpfsFetchException(cid, attempts);
  await Sentry.captureException(failure);
  throw failure;
}

/// upload xfile and return CID
Future<String> uploadFileToIPFS(XFile xfile, String fileMimeType) async {
  File file = File(xfile.path);
  String fileName = file.path.split('/').last;
  FormData formData = FormData.fromMap(
    {
      "file": await MultipartFile.fromFile(file.path,
          filename: fileName, contentType: MediaType.parse(fileMimeType))
    },
  );
  var ipfs = getIpfsGatewayClient(true);
  ipfs.addSentry();

  try {
    Response response = await ipfs.post(dotenv.get('IPFS_PIN_COMMAND'),
        data: formData, onSendProgress: (int sent, int total) {
      print('$sent / $total');
    });
    return response.data[dotenv.get('IPFS_CID_RESPONSE_PATH')];
  } on DioException catch (e) {
    // Surface WHY the pin failed. Previously any failure propagated as a raw
    // DioException into a generic "mint error" toast, so a pinning account at
    // its plan file limit was indistinguishable from a network blip — and the
    // fix (upgrade or prune) was invisible to whoever had to diagnose it.
    final status = e.response?.statusCode;
    final body = e.response?.data;
    final reason = body is String && body.isNotEmpty
        ? body
        : (body?.toString() ?? e.message ?? 'no detail from provider');

    // Heuristic only — the provider's exact over-limit wording is not
    // documented, so match loosely and treat this as a hint, not a contract.
    final haystack = '$status $reason'.toLowerCase();
    final looksLikeQuotaLimit = status == 402 ||
        status == 403 ||
        haystack.contains('limit') ||
        haystack.contains('quota') ||
        haystack.contains('exceed') ||
        haystack.contains('plan') ||
        haystack.contains('payment');

    throw IpfsPinException(status, reason, looksLikeQuotaLimit);
  }
}

/// download a file from IPFS
///
/// Throws [IpfsFetchException] if no gateway can serve it. It used to catch and
/// return null, which callers typed as a non-null map, so an outage surfaced as
/// an opaque type error rather than "the gateway is unreachable".
Future<Map<String, dynamic>> downloadMetadataFromIPFS(String cid) async {
  final response = await _getFromAnyGateway(cid, ResponseType.json);
  final data = response.data;
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  throw IpfsFetchException(cid, ['served content is not a JSON object']);
}

Future<Map<String, String>> getIpfsProviderImageUrl(String cid) async {
  try {
    final response = await _getFromAnyGateway(cid, ResponseType.bytes);

    final Directory directory = Directory.systemTemp;
    final File imageFile = File("${directory.path}/$cid");
    await imageFile.writeAsBytes(response.data);
    final String imagePath = imageFile.path;
    // Build the URL from the gateway that actually served this, not blindly from
    // the primary — otherwise a fallback read hands back a URL that fails.
    String imageUri = ipfsUrlForCid(cid);
    Map<String, String> result = {"imagePath": imagePath, "imageUri": imageUri};
    return result;
  } catch (e) {
    Sentry.captureException(e);
    print("ERROR while downloading image file from IPFS: $e");
    return {};
  }
}

/// delete file from IPFS
Future<bool> upinFileFromIPFS(String cid) async {
  try {
    var ipfs = getIpfsGatewayClient(true);
    ipfs.addSentry();
    final String deletePath = "${dotenv.get('IPFS_UNPIN_COMMAND')}$cid";
    Response response = await ipfs.delete(deletePath);
    print(response.data);
    return (response.statusCode! < 201);
  } catch (e) {
    print("ERROR while deleting file from IPFS: $e");
    return false;
  }
}
