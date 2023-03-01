import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:cross_file/cross_file.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
  Response response = await ipfs.post(dotenv.get('IPFS_PIN_COMMAND'),
      data: formData, onSendProgress: (int sent, int total) {
    print('$sent / $total');
  });
  return response.data[dotenv.get('IPFS_CID_RESPONSE_PATH')];
}

/// download a file from IPFS
Future<dynamic> downloadMetadataFromIPFS(String cid) async {
  try {
    var ipfs = getIpfsGatewayClient(false);
    Response response = await ipfs.get(
      cid,
      options: Options(
          responseType: ResponseType.json,
          followRedirects: false,
          validateStatus: (status) {
            return status! < 500;
          }),
    );

    return response.data;
  } catch (e) {
    print("ERROR while downloading metadata from IPFS: $e");
  }
}

Future<Map<String, String>> getIpfsProviderImageUrl(String cid) async {
  try {
    var ipfs = getIpfsGatewayClient(false);
    Response response = await ipfs.get(
      cid,
      options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) {
            return status! < 500;
          }),
    );

    final Directory directory = Directory.systemTemp;
    final File imageFile = File("${directory.path}/$cid");
    await imageFile.writeAsBytes(response.data);
    final String imagePath = imageFile.path;
    String imageUri = "${dotenv.get('IPFS_GATEWAY')}$cid";
    Map<String, String> result = {"imagePath": imagePath, "imageUri": imageUri};
    return result;
  } catch (e) {
    print("ERROR while downloading image file from IPFS...");
    print(e);
    return {};
  }
}

/// delete file from IPFS
Future<bool> upinFileFromIPFS(String cid) async {
  try {
    var ipfs = getIpfsGatewayClient(true);
    final String deletePath = "${dotenv.get('IPFS_UNPIN_COMMAND')}$cid";
    Response response = await ipfs.delete(deletePath);
    print(response.data);
    return (response.statusCode! < 201);
  } catch (e) {
    print("ERROR while deleting file from IPFS: $e");
    return false;
  }
}
