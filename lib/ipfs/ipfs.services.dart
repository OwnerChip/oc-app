import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
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

/// retrieve cid from IPFS link
String getCidFromIpfsLink(String ipfsLink) {
  return ipfsLink.toString().replaceFirst(r'ipfs://', '');
}

/// upload xfile and return CID
Future<String> uploadFileToIPFS(XFile xfile, String fileMimeType) async {
  File file = File(xfile.path);
  String fileName = file.path.split('/').last;
  FormData formData = FormData.fromMap({
    "file": await MultipartFile.fromFile(file.path,
        filename: fileName, contentType: MediaType.parse(fileMimeType)),
  });
  var ipfs = getIpfsGatewayClient(true);
  Response response = await ipfs.post("upload/", data: formData,
      onSendProgress: (int sent, int total) {
    print('$sent / $total');
  });
  return response.data['value']['cid'];
}

/// download a file from IPFS
Future downloadFileFromIPFS(String cid, String savePath) async {
  try {
    // get filename
    var ipfs_api = getIpfsGatewayClient(true);
    Response response = await ipfs_api.get(
      cid,
      options: Options(
          responseType: ResponseType.json,
          followRedirects: false,
          validateStatus: (status) {
            return status! < 500;
          }),
    );
    String filename = response.data['value']['files'][0]['name'];

    //download content
    final ipfs = getIpfsGatewayClient(false);
    Response res = await ipfs.download(
      "$cid/$filename",
      savePath,
      options: Options(
          responseType: ResponseType.json,
          followRedirects: true,
          validateStatus: (status) {
            return status! < 500;
          }),
    );
  } catch (e) {
    print("ERROR while downloading from IPFS...");
    print(e);
  }
}

/// download an image file from IPFS and return file path
Future<String> downloadImageFileFromIPFS(String cid) async {
  try {
    // get filename
    var ipfs_api = getIpfsGatewayClient(true);
    Response response = await ipfs_api.get(
      cid,
      options: Options(
          responseType: ResponseType.json,
          followRedirects: false,
          validateStatus: (status) {
            return status! < 500;
          }),
    );
    String filename = response.data['value']['files'][0]['name'];

    //download content
    final Directory directory = Directory.systemTemp;
    final File imageFile = File("${directory.path}/${cid}.${filename}");
    final String imagePath = imageFile.path;
    final ipfs = getIpfsGatewayClient(false);
    Response res = await ipfs.download(
      "$cid/$filename",
      imagePath,
      options: Options(
          responseType: ResponseType.stream,
          followRedirects: true,
          validateStatus: (status) {
            return status! < 500;
          }),
    );
    return imagePath;
  } catch (e) {
    print("ERROR while downloading from IPFS...");
    print(e);
    return "";
  }
}
