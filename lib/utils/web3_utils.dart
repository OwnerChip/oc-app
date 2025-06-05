import 'package:reown_appkit/reown_appkit.dart';

bool isValidChainId(String value) {
  if (value.contains(":")) {
    final split = value.split(":");
    return split.length == 2;
  }
  return false;
}

bool isValidNamespacesChainId({
  required Map<String, Namespace> namespaces,
  required String chainId,
}) {
  if (!isValidChainId(chainId)) return false;
  final chains = getNamespacesChains(namespaces);
  if (!chains.contains(chainId)) return false;

  return true;
}

List<String> getAccountsChains(List<String> accounts) {
  final List<String> chains = [];
  accounts.forEach((account) {
    final split = account.split(":");
    chains.add('${split[0]}:${split[1]}');
  });

  return chains;
}

List<String> getNamespacesChains(Map<String, Namespace> namespaces) {
  final List<String> chains = [];
  namespaces.values.forEach((namespace) {
    chains.addAll(getAccountsChains(namespace.accounts));
  });

  return chains;
}
