final EIP712DomainWithChainId = [
  {'name': 'name', 'type': 'string'},
  {'name': 'version', 'type': 'string'},
  {'name': 'chainId', 'type': 'uint256'},
  {'name': 'verifyingContract', 'type': 'address'},
];

final AssetType = [
  {"name": "assetClass", "type": "bytes4"},
  {"name": "data", "type": "bytes"}
];

final Asset = [
  {"name": "assetType", "type": "AssetType"},
  {"name": "value", "type": "uint256"}
];

final Order = [
  {"name": "maker", "type": "address"},
  {"name": "makeAsset", "type": "Asset"},
  {"name": "taker", "type": "address"},
  {"name": "takeAsset", "type": "Asset"},
  {"name": "salt", "type": "uint256"},
  {"name": "start", "type": "uint256"},
  {"name": "end", "type": "uint256"},
  {"name": "dataType", "type": "bytes4"},
  {"name": "data", "type": "bytes"}
];
