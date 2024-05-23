class AlchemyNFTAsset {
  AlchemyContract contract;
  String tokenId;
  String tokenType;
  String name;
  String? description;
  String tokenUri;
  AlchemyNftAssetImage image;
  AlchemyRaw raw;
  dynamic collection; // Since the type is not specified
  Mint mint;
  dynamic owners; // Since the type is not specified
  DateTime timeLastUpdated;
  int balance;
  AcquiredAt acquiredAt;

  AlchemyNFTAsset({
    required this.contract,
    required this.tokenId,
    required this.tokenType,
    required this.name,
    this.description,
    required this.tokenUri,
    required this.image,
    required this.raw,
    this.collection,
    required this.mint,
    this.owners,
    required this.timeLastUpdated,
    required this.balance,
    required this.acquiredAt,
  });

  factory AlchemyNFTAsset.fromJson(Map<String, dynamic> json) {
    return AlchemyNFTAsset(
      contract: AlchemyContract.fromJson(json['contract'] ?? {}),
      tokenId: json['tokenId']?.toString() ?? '',
      tokenType: json['tokenType'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      tokenUri: json['tokenUri'] ?? '',
      image: AlchemyNftAssetImage.fromJson(json['image'] ?? {}),
      raw: AlchemyRaw.fromJson(json['raw'] ?? {}),
      collection: json['collection'],
      mint: Mint.fromJson(json['mint'] ?? {}),
      owners: json['owners'],
      timeLastUpdated: json['timeLastUpdated'] != null
          ? DateTime.parse(json['timeLastUpdated'])
          : DateTime.now(),
      balance: json['balance'] != null ? int.parse(json['balance']) : 0,
      acquiredAt: AcquiredAt.fromJson(json['acquiredAt'] ?? {}),
    );
  }
}

class AlchemyContract {
  String address;
  String name;
  String symbol;
  dynamic totalSupply;
  String tokenType;
  String contractDeployer;
  int deployedBlockNumber;
  OpenSeaMetadata openSeaMetadata;
  dynamic isSpam;
  List<dynamic> spamClassifications;

  AlchemyContract({
    required this.address,
    required this.name,
    required this.symbol,
    this.totalSupply,
    required this.tokenType,
    required this.contractDeployer,
    required this.deployedBlockNumber,
    required this.openSeaMetadata,
    this.isSpam,
    required this.spamClassifications,
  });

  factory AlchemyContract.fromJson(Map<String, dynamic> json) {
    return AlchemyContract(
      address: json['address'],
      name: json['name'],
      symbol: json['symbol'],
      totalSupply: json['totalSupply'],
      tokenType: json['tokenType'],
      contractDeployer: json['contractDeployer'],
      deployedBlockNumber: json['deployedBlockNumber'],
      openSeaMetadata: OpenSeaMetadata.fromJson(json['openSeaMetadata']),
      isSpam: json['isSpam'],
      spamClassifications: json['spamClassifications'] as List<dynamic>,
    );
  }
}

// Define other classes like OpenSeaMetadata, Image, Raw, Mint, and AcquiredAt similarly

class AlchemyNftAssetImage {
  String cachedUrl;
  String? thumbnailUrl;
  String pngUrl;
  String contentType;
  dynamic size; // Using dynamic since the type is not specified
  String originalUrl;

  AlchemyNftAssetImage({
    required this.cachedUrl,
    this.thumbnailUrl,
    required this.pngUrl,
    required this.contentType,
    this.size,
    required this.originalUrl,
  });

  factory AlchemyNftAssetImage.fromJson(Map<String, dynamic> json) {
    return AlchemyNftAssetImage(
      cachedUrl: json['cachedUrl'] ?? '',
      thumbnailUrl: json['thumbnailUrl'],
      pngUrl: json['pngUrl'] ?? '',
      contentType: json['contentType'] ?? '',
      size: json['size'],
      originalUrl: json['originalUrl'] ?? '',
    );
  }
}

class AlchemyRaw {
  String tokenUri;
  Metadata metadata;
  dynamic error; // Using dynamic since the type is not specified

  AlchemyRaw({
    required this.tokenUri,
    required this.metadata,
    this.error,
  });

  factory AlchemyRaw.fromJson(Map<String, dynamic> json) {
    return AlchemyRaw(
      tokenUri: json['tokenUri'],
      metadata: Metadata.fromJson(json['metadata']),
      error: json['error'],
    );
  }
}

class Metadata {
  String name;
  String image;
  List<dynamic>
      traits; // Using dynamic since the structure of traits is not specified

  Metadata({
    required this.name,
    required this.image,
    required this.traits,
  });

  factory Metadata.fromJson(Map<String, dynamic> json) {
    return Metadata(
      name: json['name'],
      image: json['image'],
      traits: json['traits'] as List<dynamic>,
    );
  }
}

class OpenSeaMetadata {
  dynamic floorPrice;
  dynamic collectionName;
  dynamic collectionSlug;
  dynamic safelistRequestStatus;
  dynamic imageUrl;
  dynamic description;
  dynamic externalUrl;
  dynamic twitterUsername;
  dynamic discordUrl;
  dynamic bannerImageUrl;
  DateTime? lastIngestedAt;

  OpenSeaMetadata({
    this.floorPrice,
    this.collectionName,
    this.collectionSlug,
    this.safelistRequestStatus,
    this.imageUrl,
    this.description,
    this.externalUrl,
    this.twitterUsername,
    this.discordUrl,
    this.bannerImageUrl,
    this.lastIngestedAt,
  });

  factory OpenSeaMetadata.fromJson(Map<String, dynamic> json) {
    return OpenSeaMetadata(
      floorPrice: json['floorPrice'],
      collectionName: json['collectionName'],
      collectionSlug: json['collectionSlug'],
      safelistRequestStatus: json['safelistRequestStatus'],
      imageUrl: json['imageUrl'],
      description: json['description'],
      externalUrl: json['externalUrl'],
      twitterUsername: json['twitterUsername'],
      discordUrl: json['discordUrl'],
      bannerImageUrl: json['bannerImageUrl'],
      lastIngestedAt: json['lastIngestedAt'] == null
          ? null
          : DateTime.parse(json['lastIngestedAt']),
    );
  }
}

class AcquiredAt {
  DateTime? blockTimestamp;
  int? blockNumber;

  AcquiredAt({
    this.blockTimestamp,
    this.blockNumber,
  });

  factory AcquiredAt.fromJson(Map<String, dynamic> json) {
    return AcquiredAt(
      blockTimestamp: json['blockTimestamp'] == null
          ? null
          : DateTime.parse(json['blockTimestamp']),
      blockNumber: json['blockNumber'],
    );
  }
}

class Mint {
  String? mintAddress;
  int? blockNumber;
  DateTime? timestamp;
  String? transactionHash;

  Mint({
    required this.mintAddress,
    required this.blockNumber,
    required this.timestamp,
    required this.transactionHash,
  });

  factory Mint.fromJson(Map<String, dynamic> json) {
    return Mint(
      mintAddress: json['mintAddress'],
      blockNumber: json['blockNumber'],
      timestamp:
          json['timestamp'] != null ? DateTime.parse(json['timestamp']) : null,
      transactionHash: json['transactionHash'],
    );
  }
}
