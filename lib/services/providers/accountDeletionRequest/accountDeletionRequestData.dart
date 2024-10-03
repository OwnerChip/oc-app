import 'package:ownerchip_whitelabel/services/backend/auth/responses/userAccountDeletionRequestResponse.dart';

class AccountDeletionRequestData {
  final UserAccountDeletionRequestResponse? response;
  final bool initialized;
  final bool loading;

  const AccountDeletionRequestData({
    this.response,
    this.loading = false,
    required this.initialized,
  });

  AccountDeletionRequestData copyWith({
    UserAccountDeletionRequestResponse? response,
    bool? initialized,
    bool? loading,
  }) {
    return AccountDeletionRequestData(
      response: response ?? this.response,
      initialized: initialized ?? this.initialized,
      loading: loading ?? this.loading,
    );
  }

  AccountDeletionRequestData setResponse(UserAccountDeletionRequestResponse? response) {
    return AccountDeletionRequestData(
      response: response,
      initialized: initialized,
      loading: loading,
    );
  }
}
