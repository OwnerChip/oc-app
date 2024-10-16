import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/services/backend/auth/backendAuth.dart';
import 'package:ownerchip_whitelabel/services/backend/auth/backendAuthService.dart';
import 'package:ownerchip_whitelabel/services/providers/accountDeletionRequest/accountDeletionRequestData.dart';

class AccountDeletionRequestNotifier
    extends Notifier<AccountDeletionRequestData> {
  @override
  AccountDeletionRequestData build() {
    return const AccountDeletionRequestData(
      initialized: false,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(
      loading: true,
      response: null,
    );

    // Call the backend service to get the data
    final response = await BackendAuth.getDeletionRequest();

    state = state.copyWith(
      response: response,
      loading: false,
      initialized: true,
    );
  }

  Future<void> deleteAccount() async {
    state = state.copyWith(
      loading: true,
      response: null,
    );

    // Call the backend service to delete the account
    final response = await BackendAuth.createDeletionRequest();
    state = state.copyWith(
      response: response,
      loading: false,
    );
  }

  Future<void> cancelAccountDeletion() async {
    state = state.copyWith(
      loading: true,
    );

    // Call the backend service to cancel the account deletion
    try {
      final res = await BackendAuth.cancelDeletionRequest();
      final newState = state.copyWith(
        loading: false,
      );
      if (res) {
        state = newState.setResponse(null);
      } else {
        state = newState;
      }
    } catch (e) {
      state = state.copyWith(
        response: null,
        loading: false,
      );
    }
  }
}

final accountDeletionRequestProvider = NotifierProvider<
    AccountDeletionRequestNotifier, AccountDeletionRequestData>(() {
  return AccountDeletionRequestNotifier();
});
