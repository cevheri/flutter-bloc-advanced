/// Non-web build of the browser storage adapters in `oidc_key_value.dart`: there is no browser storage, so both throw.
library;

import 'oidc_key_value.dart';

OidcKeyValue browserLocalStorage() => throw UnsupportedError('localStorage exists only in a web build');

OidcKeyValue browserSessionStorage() => throw UnsupportedError('sessionStorage exists only in a web build');
