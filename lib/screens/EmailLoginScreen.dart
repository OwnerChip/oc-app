import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ownerchip_whitelabel/config/wallets.dart';
import 'package:ownerchip_whitelabel/domain/classDefinition.dart';
import 'package:ownerchip_whitelabel/domain/jwt/jwt_token.dart';
import 'package:ownerchip_whitelabel/services/backend/app/backendApp.dart';
import 'package:ownerchip_whitelabel/services/backend/auth/backendAuth.dart';
import 'package:ownerchip_whitelabel/services/backend/backend.services.dart';
import 'package:ownerchip_whitelabel/services/backend/fcm/backendFcm.dart';
import 'package:ownerchip_whitelabel/services/providers/accountDeletionRequest/accountDeletionRequestNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/creations/creationsNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/myBalance/myBalanceNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/nftData.dart';
import 'package:ownerchip_whitelabel/services/providers/collectionsData.dart';
import 'package:ownerchip_whitelabel/services/providers/privy/privyNotifier.dart';
import 'package:ownerchip_whitelabel/services/providers/userData.dart';
import 'package:ownerchip_whitelabel/services/providers/walletconnectData.dart';
import 'package:ownerchip_whitelabel/services/providers/websocket/websocketNotifier.dart';
import 'package:ownerchip_whitelabel/services/privyService.dart';
import 'package:ownerchip_whitelabel/services/signature.services.dart';
import 'package:ownerchip_whitelabel/services/wallet.services.dart';
import 'package:ownerchip_whitelabel/themes/colorSpecs.dart';
import 'package:ownerchip_whitelabel/utils/localization.helper.dart';
import 'package:ownerchip_whitelabel/utils/logger.dart';
import 'package:ownerchip_whitelabel/widgets/ui/CustomRoundedButton.dart';
import 'package:privy_flutter/privy_flutter.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _Step { email, otp }

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  static const routeName = '/email-login';

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();

  _Step _step = _Step.email;
  bool _isLoading = false;
  String? _errorMessage;
  String _email = '';

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _setError(String? msg) => setState(() => _errorMessage = msg);
  void _setLoading(bool v) => setState(() => _isLoading = v);

  Future<void> _sendCode() async {
    if (!_emailFormKey.currentState!.validate()) return;
    _setError(null);
    _setLoading(true);

    final email = _emailController.text.trim();
    final result = await privyInstance.email.sendCode(email);

    result.fold(
      onSuccess: (_) {
        setState(() {
          _email = email;
          _step = _Step.otp;
          _isLoading = false;
        });
      },
      onFailure: (error) {
        talker.error('Privy: failed to send OTP', error.message);
        _setLoading(false);
        _setError(context.loc.errorConnectingWallet);
      },
    );
  }

  Future<void> _resendCode() async {
    _setError(null);
    _setLoading(true);
    _otpController.clear();
    final result = await privyInstance.email.sendCode(_email);
    result.fold(
      onSuccess: (_) => _setLoading(false),
      onFailure: (error) {
        _setLoading(false);
        _setError(context.loc.errorConnectingWallet);
      },
    );
  }

  Future<void> _verifyOtp() async {
    if (!_otpFormKey.currentState!.validate()) return;
    _setError(null);
    _setLoading(true);

    final otp = _otpController.text.trim();

    // 1. Verify OTP
    final loginResult = await privyInstance.email.loginWithCode(
      code: otp,
      email: _email,
    );

    PrivyUser? privyUser;
    loginResult.fold(
      onSuccess: (user) => privyUser = user,
      onFailure: (error) {
        talker.error('Privy: OTP verification failed', error.message);
        _setLoading(false);
        _setError(context.loc.errorConnectingWallet);
      },
    );

    if (privyUser == null) return;

    // 2. Ensure embedded wallet exists
    EmbeddedEthereumWallet? wallet;
    if (privyUser!.embeddedEthereumWallets.isEmpty) {
      final walletResult = await privyUser!.createEthereumWallet();
      walletResult.fold(
        onSuccess: (w) => wallet = w,
        onFailure: (error) {
          talker.error('Privy: failed to create wallet', error.message);
          _setLoading(false);
          _setError(context.loc.errorConnectingWallet);
        },
      );
    } else {
      wallet = privyUser!.embeddedEthereumWallets.first;
    }

    if (wallet == null) return;

    // 3. Store privy user in provider
    ref.read(privyNotifierProvider.notifier).setPrivyUser(privyUser);
    ref.read(walletTypeProvider.notifier).state = walletConfig[EWalletType.privy];

    final storage = await SharedPreferences.getInstance();
    await storage.setString(
        'walletType', jsonEncode(walletConfig[EWalletType.privy]!.toJson()));

    final userWalletAddress = EthereumAddress.fromHex(wallet!.address);
    ref.read(userAddressProvider.notifier).state = userWalletAddress;

    // 4. Auto-sign SIWE and authenticate with backend
    final walletType = walletConfig[EWalletType.privy]!;
    final sessionId = await BackendAuth.getSessionId();
    final String statement =
        "Sign this message to confirm that you are the owner of your wallet (SessionId: $sessionId)";
    final siweMessage = BackendAuth.createSiweMessage(
      address: userWalletAddress,
      statement: statement,
      nonce: sessionId,
    );

    late final JwtToken token;
    late final MsgSignature sig;
    try {
      final hexSignature = await sendPersonalSignRequest(
        ref,
        siweMessage[1],
        userWalletAddress,
        walletType,
        siweMessage: true,
      );
      final jwt = await BackendAuth.validateSiwe(
        message: siweMessage[0],
        signature: hexSignature,
      );
      token = JwtToken.decode(jwt);
      sig = hexSignatureToRSV(hexSignature);
    } catch (e, st) {
      Sentry.captureException(e, stackTrace: st);
      talker.error('Privy: error during auto-sign', e, st);
      _setLoading(false);
      _setError(context.loc.errorConnectingWallet);
      return;
    }

    // 5. Recreate services and build session
    Backend.recreateServices(token.raw);

    final userSession = UserSession(
      sessionId,
      sig,
      userWalletAddress,
      false,
      false,
      token,
      await BackendFCM.getAndSaveFCMToken(sessionId),
    );

    ref.read(userSessionProvider.notifier).state = userSession;
    ref.read(websocketProvider.notifier).init();
    ref.read(creationsNotifierProvider.notifier).load();
    ref.read(accountDeletionRequestProvider.notifier).refresh();

    final String jsonUserSession = jsonEncode(userSession.toJson());
    storage.setString('userSession', jsonUserSession);
    storage.setString('walletType', jsonEncode(walletType.toJson()));

    ref.refresh(findAllMinterRolesProvider);
    ref.refresh(ocNFTsForOwnerProvider);
    ref.refresh(ocNFTsMintedByUserNotifierProvider);
    ref.refresh(myBalanceNotifierProvider);

    BackendApp.sendAnalyticsTrace(sessionId, "", "LOGIN_SUCCESS", tags: {
      'connectedWallet': userWalletAddress.hex,
      'walletType': walletType.name,
    });

    if (!mounted) return;
    // Pop back twice: EmailLoginScreen + WalletPopup (if still on stack)
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = CustomColors(dotenv.get('APP_ID'));
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: colors.secondaryColor),
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
        ),
        title: Text(
          _step == _Step.email
              ? context.loc.loginWithEmail_EnterEmailText
              : 'Verify your email',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
              child: _step == _Step.email
                  ? _buildEmailStep(colors)
                  : _buildOtpStep(colors),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep(CustomColors colors) {
    return Form(
      key: _emailFormKey,
      child: Column(
        key: const ValueKey('email-step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Icon(Icons.email_outlined, size: 72, color: colors.accentColor),
          const SizedBox(height: 32),
          Text(
            'Enter your email address',
            style: Theme.of(context).textTheme.displayLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll send you a 6-digit verification code.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _isLoading ? null : _sendCode(),
            decoration: InputDecoration(
              hintText: context.loc.loginWithEmail_Hint,
              prefixIcon: Icon(Icons.email, color: colors.secondaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return context.loc.loginWithEmail_ValidationError;
              }
              final regex = RegExp(
                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
              if (!regex.hasMatch(value.trim())) {
                return context.loc.loginWithEmail_ValidationError;
              }
              return null;
            },
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(
                  color: colors.errorColor, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          CustomRoundedButton(
            text: 'Send Code',
            height: 52,
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _sendCode,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpStep(CustomColors colors) {
    return Form(
      key: _otpFormKey,
      child: Column(
        key: const ValueKey('otp-step'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Icon(Icons.mark_email_read_outlined,
              size: 72, color: colors.accentColor),
          const SizedBox(height: 32),
          Text(
            'Check your inbox',
            style: Theme.of(context).textTheme.displayLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'A 6-digit code was sent to\n$_email',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _isLoading ? null : _verifyOtp(),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .displayLarge
                ?.copyWith(letterSpacing: 12),
            decoration: InputDecoration(
              hintText: '— — — — — —',
              hintStyle: const TextStyle(letterSpacing: 8, color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Please enter the code';
              if (v.trim().length != 6) return 'Code must be 6 digits';
              return null;
            },
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(color: colors.errorColor, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 32),
          CustomRoundedButton(
            text: 'Verify',
            height: 52,
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _verifyOtp,
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton.icon(
              onPressed: _isLoading ? null : _resendCode,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Resend code'),
              style: TextButton.styleFrom(
                foregroundColor: colors.secondaryColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _isLoading
                  ? null
                  : () => setState(() {
                        _step = _Step.email;
                        _errorMessage = null;
                        _otpController.clear();
                      }),
              child: Text(
                'Change email',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

