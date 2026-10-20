/// IO (mobile/desktop) build of the dart:io checks in `transport_errors.dart`.
library;

import 'dart:io';

bool isLostConnection(Object? error) =>
    error is SocketException || error is OSError || (error is HttpException && error is! RedirectException);
