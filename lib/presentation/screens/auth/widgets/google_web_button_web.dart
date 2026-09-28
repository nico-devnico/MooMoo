import 'package:flutter/widgets.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

/// Google Identity Services button: signs in through an in-page popup and
/// reports the result on `GoogleSignIn.instance.authenticationEvents`.
Widget googleWebButton({required String locale, required bool dark}) =>
    web.renderButton(
      configuration: web.GSIButtonConfiguration(
        type: web.GSIButtonType.standard,
        theme: dark ? web.GSIButtonTheme.filledBlack : web.GSIButtonTheme.outline,
        size: web.GSIButtonSize.large,
        text: web.GSIButtonText.continueWith,
        shape: web.GSIButtonShape.pill,
        logoAlignment: web.GSIButtonLogoAlignment.center,
        minimumWidth: 320,
        locale: locale,
      ),
    );
