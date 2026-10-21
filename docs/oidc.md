# Single Sign-On with OpenID Connect

The template signs users in one of two ways, chosen once at build time with `AUTH_PROVIDER`.
`jwt`, the default, is the password and OTP sign-in against the template's own backend, which issues its own JWT.
`oidc` signs the user in through any OpenID Connect provider, such as Keycloak, Zitadel, Auth0 or Microsoft Entra ID.
In `oidc` mode the app is a public client: it uses the Authorization Code flow with PKCE (S256), holds the provider's tokens itself, and sends the provider's access token to the backend as the bearer.
There is no client secret anywhere in the app.

Part 1 is the setup guide.
Part 2 describes how it works inside.

How far each provider was verified:

| Provider | Status |
| --- | --- |
| Keycloak | Walked through by hand with the demo in `tool/oidc-demo` (Keycloak 26.8.1) on web, the Android emulator and the Linux desktop, where every check passed; not run on iOS, macOS or Windows (see [Tests](#tests)) |
| Zitadel | Written from Zitadel's documentation; not yet run against a live tenant |
| Auth0 | Written from Auth0's documentation; not yet run against a live tenant |
| Microsoft Entra ID | Written from Microsoft's documentation; not yet run against a live tenant |

The provider sections below are a starting point for those three, and a report from a real tenant is welcome.

# Part 1: Setup

## Quick start

1. Register a public client (no client secret) at your provider, with PKCE S256 and the redirect URIs of the platforms you build for (see [Redirect URIs](#redirect-uris)).
2. Make the provider put your role claim in both the ID token and the access token.
3. Build the app with the issuer and the client id:

```shell
fvm flutter run --target lib/main/main_prod.dart \
  --dart-define=AUTH_PROVIDER=oidc \
  --dart-define=OIDC_ISSUER=https://id.example.com/realms/acme \
  --dart-define=OIDC_CLIENT_ID=acme-app \
  --dart-define=OIDC_ROLE_CLAIM=realm_access.roles
```

A file of `KEY=value` lines works too, through `--dart-define-from-file=oidc.env`, as `tool/oidc-demo/oidc-demo.env` shows.
Every value is compiled in, so a change needs a new build.

The login page then shows a single "Sign in with SSO" button.
Registration, forgot password, OTP sign-in and change password belong to the provider, so their routes are not registered in `oidc` mode and their entry points are hidden.

### Redirect URIs

With the default scheme `com.example.flutterblocadvance` (`OIDC_REDIRECT_SCHEME`), the app uses these URIs:

| Platform | Sign-in surface | Redirect URI | Post-logout redirect URI |
| --- | --- | --- | --- |
| Android | Custom Tab | `com.example.flutterblocadvance:/oauth2redirect` | `com.example.flutterblocadvance:/oauth2redirect` |
| iOS, macOS | `ASWebAuthenticationSession`, shared browser session | `com.example.flutterblocadvance:/oauth2redirect` | `com.example.flutterblocadvance:/oauth2redirect` |
| Web | The same tab, which reloads on return | `<origin><base href>redirect.html` | `<origin><base href>` |
| Linux, Windows | The system browser and a loopback listener | `http://127.0.0.1:<port>/oauth2redirect` | `http://127.0.0.1:<port>/logout` |

For a web build served at `https://app.example.com/` that is `https://app.example.com/redirect.html` and `https://app.example.com/`.
The web build also needs the provider to allow the app's origin for CORS on its discovery, JWKS and token endpoints, because the browser calls them directly.
On Linux and Windows the port is `OIDC_LOOPBACK_PORT`, and `0`, the default, takes any free port.
A provider that ignores the port of a loopback redirect URI (Keycloak and Entra ID do, for `127.0.0.1`) accepts `http://127.0.0.1/oauth2redirect` registered once.
A provider that compares the port exactly needs a fixed `OIDC_LOOPBACK_PORT` and that port in the registered URI.
The desktop redirect always uses the literal `127.0.0.1`, never `localhost`.

## Try it locally with Keycloak

`tool/oidc-demo/docker-compose.yml` starts Keycloak 26.8.1 on `http://localhost:8080` with a realm for the app, and `tool/oidc-demo/oidc-demo.env` points a dev build at it.
The app runs `main_local.dart`, whose mock API accepts any bearer, so no backend is needed.
The demo needs Docker Compose v2.23.1 or newer.

```shell
docker compose -f tool/oidc-demo/docker-compose.yml up -d --wait
fvm flutter run -d chrome --web-port 8081 --target lib/main/main_local.dart --dart-define-from-file=tool/oidc-demo/oidc-demo.env
docker compose -f tool/oidc-demo/docker-compose.yml down -v
```

The first command waits until Keycloak is healthy, and the last one removes it with all its state.
Sign in as `admin` / `admin` (realm role `admin`) or `user` / `user` (realm role `user`), the same pairs as the template's demo credentials.
The Keycloak admin console is at `http://localhost:8080/admin/` with `kcadmin` / `kcadmin`.

What the walkthrough shows:
- `admin` opens the user list, and `user` gets the forbidden page on it; the sidebar still lists User Management for `user`, because `assets/mock/menus.json` grants those entries to `ROLE_USER` too.
- With the default `OIDC_PROMPT=login`, every sign-in asks for the password, even while the Keycloak session lives.
- Add `--dart-define=OIDC_PROMPT=omit` and the next sign-in completes without a form while the Keycloak session lives.
- The realm gives access tokens a 60 second life, so an API call a minute after sign-in gets a 401 from the mock API, which answers 401 to an expired JWT bearer in dev mode, and the app refreshes at Keycloak and retries without signing out.
- Logout ends the Keycloak session as well: the next sign-in asks for the password again.

The realm contains one public client, `flutter-bloc-advance`, with PKCE S256 required, the standard flow only, direct access grants off, Web Origins `+`, and a redirect URI and post-logout redirect URI for every platform.
A protocol mapper writes the realm roles to `realm_access.roles` in the ID token, the access token and the UserInfo answer.

The walkthrough has three rules about addresses:
- **Web on port 8081 and `localhost`:** Keycloak compares the web redirect URI exactly, and the realm registers `http://localhost:8081/redirect.html`.
  Pass `--web-port 8081` and open the app at `http://localhost:8081`, never at `http://127.0.0.1:8081`, whose redirect URI is not registered.
- **Desktop on `127.0.0.1`:** Keycloak ignores the port only for a `127.0.0.1` loopback redirect URI, so the realm's `http://127.0.0.1/*` accepts any port the listener takes, and `localhost` with a random port is refused.
  The app always uses `127.0.0.1` there.
- **One issuer:** Keycloak runs with the fixed hostname `http://localhost:8080`, so discovery names the issuer `http://localhost:8080/realms/flutter-bloc-advance` whatever address a request used.

### Android emulator

Run this once per emulator boot, while the emulator is running:

```shell
adb reverse tcp:8080 tcp:8080
```

With more than one device attached, name it, for example `adb -s emulator-5554 reverse tcp:8080 tcp:8080`.
`adb reverse --list` shows the active rule.
The emulator's `localhost:8080` then reaches Keycloak on the host, so the issuer stays `http://localhost:8080/...` in the app and in the Custom Tab.
The iOS simulator shares the host's loopback and needs no step.

Keycloak binds only `127.0.0.1:8080`, so its admin console, whose password is committed in the compose file, is not offered to the network.
The demo is unfit for production on purpose: `start-dev` with the embedded H2 store, plain http, and committed passwords.
`docs/REAL_API_INFO.md` describes a real backend on `http://localhost:8080/` as well; stop it while the demo runs, since only one of them can hold the port.

## Keycloak

1. In the admin console, open your realm and create a client under **Clients**, then **Create client**:
   - Client type: OpenID Connect.
   - Client authentication: Off, which makes it a public client.
   - Authentication flow: Standard flow only; switch Direct access grants off.
2. In the client's settings:
   - **Valid redirect URIs:** `com.example.flutterblocadvance:/oauth2redirect` for Android, iOS and macOS, `https://app.example.com/redirect.html` for web, and `http://127.0.0.1/*` for Linux and Windows.
   - **Valid post logout redirect URIs:** `com.example.flutterblocadvance:/oauth2redirect`, `https://app.example.com/` and `http://127.0.0.1/*`.
   - **Web origins:** `+`, which allows the origins of the redirect URIs.
3. Under **Advanced**, set **Proof Key for Code Exchange Code Challenge Method** to `S256`.
4. Roles: the realm-role mapper writes `realm_access.roles` to the access token by default, but not to the ID token.
   Open **Client scopes**, then **roles**, then **Mappers**, then **realm roles**, switch **Add to ID token** on, and save.
   The role claim must be in both tokens: the app reads it from the ID token for its UI, and your backend from the access token.
5. Audience: Keycloak's access token carries `aud: account`, not your API.
   Add an **Audience** mapper to the client's dedicated scope (**Client scopes** tab of the client, then the `-dedicated` scope, then **Add mapper**, **By configuration**, **Audience**), with **Included Client Audience** set to your backend's client and **Add to access token** on.
   Your backend then checks that audience.

```env
AUTH_PROVIDER=oidc
OIDC_ISSUER=https://keycloak.example.com/realms/acme
OIDC_CLIENT_ID=acme-app
OIDC_ROLE_CLAIM=realm_access.roles
OIDC_ADMIN_ROLES=admin
OIDC_USER_ROLES=user
```

Keycloak issues a refresh token without `offline_access`, so the default scope is enough.
The logout sends the ID token as `id_token_hint`, so Keycloak ends the session without asking the user to confirm it.
Keycloak gives the ID token the access token's lifespan, and accepts an expired `id_token_hint` at its logout endpoint (checked against 26.8.1).

## Zitadel

Not yet run against a live tenant; this section follows Zitadel's documentation.

1. In the console, create a project, then add the applications:
   - For Android, iOS, macOS, Linux and Windows, an application of type **Native** with the **PKCE** authentication method.
   - For web, a separate application of type **User Agent** with the **PKCE** authentication method.

   Web and native need separate applications in Zitadel, so a web build and a native build get different `OIDC_CLIENT_ID` values.
2. Redirect URIs:
   - Native application: `com.example.flutterblocadvance:/oauth2redirect`, and `http://127.0.0.1:<port>/oauth2redirect` for Linux and Windows; post logout URIs `com.example.flutterblocadvance:/oauth2redirect` and `http://127.0.0.1:<port>/logout`.
   - User Agent application: `https://app.example.com/redirect.html`, with the post logout URI `https://app.example.com/`.
   - If Zitadel refuses an `http` redirect URI, switch **Development Mode** on for that application, and use it for local runs only.
   - Use a fixed `OIDC_LOOPBACK_PORT` unless your Zitadel version documents that it ignores the loopback port.
3. Grant types: switch **Refresh Token** on, and add `offline_access` to `OIDC_SCOPE`, or Zitadel issues no refresh token.
4. Roles: create the project roles, grant them to users, and request them with the scope `urn:zitadel:iam:org:project:roles`.
   In the application's token settings, switch on the option that adds the user roles to the ID token (**User roles inside ID Token**); the app sends no UserInfo request, so roles that are only in the UserInfo answer never reach it.
   The claim is an object whose keys are the role names (`{"admin": {"<org id>": "<org domain>"}}`), which the app's role mapping reads as the roles `admin` (see [Role mapping](#role-mapping)).
   The role claim must be in both tokens, so check that your backend sees it in the access token too.
5. Audience: set the application's **Auth Token Type** to **JWT**, because the default bearer token is opaque and a backend cannot verify it against the JWKS.
   Add the scope `urn:zitadel:iam:org:project:id:<project id>:aud`, so the project id is in the access token's `aud`.

```env
AUTH_PROVIDER=oidc
OIDC_ISSUER=https://acme.zitadel.cloud
OIDC_CLIENT_ID=<native or user agent client id>
OIDC_SCOPE=openid profile email offline_access urn:zitadel:iam:org:project:roles urn:zitadel:iam:org:project:id:<project id>:aud
OIDC_ROLE_CLAIM=urn:zitadel:iam:org:project:roles
OIDC_ADMIN_ROLES=admin
OIDC_USER_ROLES=user
```

Zitadel advertises its `end_session_endpoint` through discovery, so the provider logout needs no special case.

## Auth0

Not yet run against a live tenant; this section follows Auth0's documentation.

1. Create the applications under **Applications**:
   - For Android, iOS, macOS, Linux and Windows, an application of type **Native**.
   - For web, a separate application of type **Single Page Application**.

   Web and native need separate applications in Auth0, so a web build and a native build get different `OIDC_CLIENT_ID` values.
   Both are public clients: their token endpoint authentication method is **None**.
2. Settings of each application:
   - **Allowed Callback URLs:** `com.example.flutterblocadvance:/oauth2redirect` and `http://127.0.0.1:<port>/oauth2redirect` (Native), or `https://app.example.com/redirect.html` (Single Page Application).
   - **Allowed Logout URLs:** `com.example.flutterblocadvance:/oauth2redirect` and `http://127.0.0.1:<port>/logout`, or `https://app.example.com/`.
   - **Allowed Web Origins** and **Allowed Origins (CORS)** of the Single Page Application: `https://app.example.com`.
   - Set a fixed `OIDC_LOOPBACK_PORT` for Linux and Windows and use that port in both lists, since Auth0 does not document a loopback match that ignores the port.
   - Under **Advanced Settings**, **OAuth**, keep the JSON Web Token signature algorithm at **RS256**: an HS256 ID token needs the client secret to verify, and the app fails closed on it.
3. Audience: create an API under **Applications**, **APIs**, and set `OIDC_AUDIENCE` to its identifier.
   Without an audience, Auth0 issues an opaque access token that your backend cannot verify against the JWKS.
4. Refresh: switch **Allow Offline Access** on for that API and add `offline_access` to `OIDC_SCOPE`; refresh token rotation is recommended.
5. Roles: Auth0 puts no roles in the tokens by default.
   Add a post-login Action that writes them to both tokens under a namespaced claim:

```javascript
exports.onExecutePostLogin = async (event, api) => {
  const claim = 'https://example.com/roles';
  const roles = event.authorization?.roles ?? [];
  api.idToken.setCustomClaim(claim, roles);
  api.accessToken.setCustomClaim(claim, roles);
};
```

```env
AUTH_PROVIDER=oidc
OIDC_ISSUER=https://acme.eu.auth0.com/
OIDC_CLIENT_ID=<native or single page application client id>
OIDC_SCOPE=openid profile email offline_access
OIDC_AUDIENCE=https://api.example.com
OIDC_ROLE_CLAIM=https://example.com/roles
OIDC_ADMIN_ROLES=admin
OIDC_USER_ROLES=user
```

Use the issuer exactly as the `issuer` of your tenant's discovery document, which for Auth0 ends with a slash.
The claim name `https://example.com/roles` contains dots, and the app first looks it up as one literal top-level key, so it works as it is.
Auth0 advertises an `end_session_endpoint` only when **RP-Initiated Logout End Session Endpoint Discovery** is on in the tenant's advanced settings.
Without it, for an issuer on `auth0.com` or a subdomain of it, the app falls back to Auth0's `/v2/logout` with `client_id` and `returnTo`.
That fallback is the only provider-specific code path; a custom domain needs the discovery setting on.

## Microsoft Entra ID

Not yet run against a live tenant; this section follows Microsoft's documentation.

1. Register one application under **App registrations**, **New registration**.
   One registration serves every platform, so web and native builds share one `OIDC_CLIENT_ID`; add a platform configuration for each surface under **Authentication**.
2. Platforms and redirect URIs:
   - **Mobile and desktop applications:** `com.example.flutterblocadvance:/oauth2redirect` and `http://127.0.0.1/oauth2redirect`; Entra ID ignores the port of a loopback redirect URI, so `OIDC_LOOPBACK_PORT=0` works.
   - **Single-page application:** `https://app.example.com/redirect.html`.
     This platform type enables CORS on the token endpoint and PKCE for the web build.
   - Register the post-logout URIs (`com.example.flutterblocadvance:/oauth2redirect`, `http://127.0.0.1/logout` and `https://app.example.com/`) as redirect URIs of the same platforms too, so Entra ID accepts them as `post_logout_redirect_uri`.
3. Audience: under **Expose an API**, set the application ID URI (`api://<application id>`) and add a scope, for example `access_as_user`.
   Put `api://<application id>/access_as_user` in `OIDC_SCOPE`.
   Without a scope of your own API, the access token is for Microsoft Graph, and your backend cannot verify it.
   Set `requestedAccessTokenVersion` (`accessTokenAcceptedVersion` in the older manifest) to `2`, so the access token's `iss` is the v2.0 issuer that your backend expects.
4. Refresh: add `offline_access` to `OIDC_SCOPE`, or Entra ID issues no refresh token and the session ends when the access token expires.
   Refresh tokens of the single-page application platform live at most 24 hours.
5. Roles: define **App roles** on the registration and assign them to users or groups under **Enterprise applications**.
   Entra ID writes them to the `roles` claim of the ID token, and of the access token for an API exposed by the same registration, so both tokens carry them.

```env
AUTH_PROVIDER=oidc
OIDC_ISSUER=https://login.microsoftonline.com/<tenant id>/v2.0
OIDC_CLIENT_ID=<application id>
OIDC_SCOPE=openid profile email offline_access api://<application id>/access_as_user
OIDC_ROLE_CLAIM=roles
OIDC_ADMIN_ROLES=Admin
OIDC_USER_ROLES=User
```

Role names are compared case-insensitively.
Entra ID advertises its `end_session_endpoint` through discovery.

## Configuration reference

All values are compile-time defines, read once at bootstrap (`lib/infrastructure/config/auth_config.dart`).
Strings are trimmed; flags and `OIDC_PROMPT` are also lower-cased.

| Variable | Required | Default | Meaning |
| --- | --- | --- | --- |
| `AUTH_PROVIDER` | No | `jwt` | `jwt` or `oidc`, trimmed and lower-cased. Any other value stops the app at bootstrap with an error that names the variable |
| `OIDC_ISSUER` | Yes | none | Issuer URL, with discovery at `/.well-known/openid-configuration` under it. `https` in any case, or `http` on `localhost`, `127.0.0.1` or `[::1]`. No query and no fragment |
| `OIDC_CLIENT_ID` | Yes | none | The public client id. It may differ between the web build and the native builds when the provider needs separate applications (Zitadel, Auth0) |
| `OIDC_SCOPE` | No | `openid profile email` | Space-separated, and must contain `openid`. Zitadel, Auth0 and Entra ID need `offline_access` for a refresh token |
| `OIDC_AUDIENCE` | No | unset | Sent as `audience` on the authorization request (Auth0) |
| `OIDC_ROLE_CLAIM` | No | unset | Name or dot path of the role claim in the ID token, such as `realm_access.roles` |
| `OIDC_ADMIN_ROLES` | No | `admin` | Comma list, trimmed and compared case-insensitively |
| `OIDC_USER_ROLES` | No | unset | Comma list. When set, an account with neither an admin nor a user role is refused. Needs `OIDC_ROLE_CLAIM` |
| `OIDC_PROMPT` | No | `login` | `login`, `consent`, `select_account`, or `omit` to send none. Any other value, `none` included, is a configuration error |
| `OIDC_AUTO_REDIRECT` | No | off | `true`, `1`, `on` or `yes` turn it on; `false`, `0`, `off`, `no` or empty leave it off. Any other value is a configuration error |
| `OIDC_LOGOUT_HINT` | No | on | The same spellings. Off sends no `id_token_hint` at logout |
| `OIDC_REDIRECT_SCHEME` | No | `com.example.flutterblocadvance` | Custom URI scheme for Android, iOS and macOS: a lower-case letter, then lower-case letters, digits, `+`, `-` or `.`. It must equal the Android manifest placeholder |
| `OIDC_LOOPBACK_PORT` | No | `0` (any free port) | Port of the loopback redirect on Linux and Windows, from 0 to 65535 |

An empty role list, or one made only of commas, counts as unset.
There is no `OIDC_CLIENT_SECRET`: the app is a public client, and a guard test fails when anything in `lib/` names a client secret or builds a client authentication other than `OidcClientAuthentication.none`.

An invalid `oidc` configuration does not stop the app.
It starts, the login page shows "Single sign-on is not configured correctly in this app. Contact your administrator." in place of the button, and the log names the variable and the rule it breaks.
Such a build fails closed on a session that an earlier, correctly configured build stored: it never restores it, so the user starts signed out with that sentence, and it never refreshes through the backend's `jwt` refresh endpoint, so the provider's refresh token never reaches the backend.
The stored session stays on the device unread, and is wiped if this build ends a session.

To change the redirect scheme, change it in three places together:
- `OidcSettings.defaultRedirectScheme` in `lib/infrastructure/config/auth_config.dart`;
- `manifestPlaceholders["oidcRedirectScheme"]` in `android/app/build.gradle.kts`, which `test/architecture/oidc_platform_setup_test.dart` ties to the default;
- the redirect URIs registered at your provider, and `redirectUris` and `post.logout.redirect.uris` in `tool/oidc-demo/docker-compose.yml` for the demo.

On Android the scheme the app sends must equal the manifest placeholder, so an Android build changes it only through the default and the placeholder together.
`OIDC_REDIRECT_SCHEME` at build time overrides the scheme the app sends, which is enough on iOS and macOS, where `ASWebAuthenticationSession` takes the scheme from the redirect URI; an Android build given a value other than the placeholder never receives its redirect.
Web, Linux and Windows do not use the scheme.

### Automatic redirect

With `OIDC_AUTO_REDIRECT` on, a signed-out cold start that lands on the login page starts the sign-in without a tap.
It fires at most once per app run, and never after a sign-in error, the configuration error, a cancel at the provider, or a logout the user started in the same run.
The SSO button stays available in every case.
On web the return from a provider logout is a fresh page load, so the automatic redirect applies there again.

## Role mapping

The app maps the ID token's claims to one app role with a port of LibreDB Studio's `mapOIDCRole` (`lib/core/security/oidc_role_mapping.dart`):

1. Without `OIDC_ROLE_CLAIM`, every account is a `user`, unless `OIDC_USER_ROLES` is set, which refuses it.
2. When the claim name exists as a top-level key of the claims, that key's value is used as it is, dots and all, so Auth0's `https://example.com/roles` works.
3. Otherwise the name is walked as a dot path, such as `realm_access.roles`.
   A missing value, or a step through a value that is not an object, means no match.
4. The value becomes a list of role names:
   - an object contributes its keys, which is Zitadel's shape (`{"admin": {"<org id>": "<org domain>"}}`);
   - an array contributes its elements, where an object element contributes its keys (`[{"user": {...}}]`) and any other element becomes a string;
   - any other value becomes one name.
5. Any case-insensitive match with `OIDC_ADMIN_ROLES` gives `admin`, so admin wins when the claim holds both.
6. Otherwise a match with `OIDC_USER_ROLES` gives `user`.
7. Anything else is a `user` while `OIDC_USER_ROLES` is unset, and is refused once it is set.

`admin` grants `ROLE_ADMIN` and `ROLE_USER`, and `user` grants `ROLE_USER`, the roles `GET /account` returns for those users in `jwt` mode.
A refused account sees "Your account has no role that allows access to this app. Ask your administrator.", and nothing is stored.

| Claims | `OIDC_ROLE_CLAIM` | Admin / user roles | Result |
| --- | --- | --- | --- |
| `{"realm_access": {"roles": ["admin", "offline_access"]}}` | `realm_access.roles` | `admin` / `user` | `admin` |
| `{"https://example.com/roles": ["User"]}` | `https://example.com/roles` | `admin` / `user` | `user` |
| `{"urn:zitadel:iam:org:project:roles": {"admin": {"1": "acme"}}}` | `urn:zitadel:iam:org:project:roles` | `admin` / unset | `admin` |
| `{"roles": ["guest"]}` | `roles` | `admin` / unset | `user` |
| `{"roles": ["guest"]}` | `roles` | `admin` / `user` | refused |

Roles are fixed at sign-in.
A role changed at the provider shows in the app at the next sign-in, and the backend, which checks the roles of every access token, stays the authorization boundary.
The app's roles only shape the UI: menus, routes and admin pages.

## Backend contract

In `oidc` mode every API request carries `Authorization: Bearer <access token>` from the provider.
The backend must:
- verify the access token's signature against the issuer's JWKS, and check `iss`, `aud` (its own audience) and `exp`;
- map roles from the access token for its own authorization decisions, which is why each provider section puts the role claim in both tokens;
- answer 401 to a missing, invalid or expired token, after which the app refreshes once at the provider and retries, and a second 401 ends the session;
- answer 403 to a valid token without permission, which the app already handles.

The app calls the same endpoints as in `jwt` mode, minus `/authenticate*`, `/register`, `/account/reset-password/*`, `/account/change-password` and `/api/token/refresh`.
The template's account repository calls `GET /account` after sign-in for the profile; an app on another backend replaces that repository, for example with LibreDB Studio's `GET /api/auth/me`.
The account fetch runs after sign-in, and its failure does not end the session.
User management pages keep calling the backend as they do today; managing users in `oidc` mode is out of scope, and users and roles live at the provider.

How to get an access token with the right audience:

| Provider | How |
| --- | --- |
| Keycloak | An audience mapper or a client scope |
| Auth0 | `OIDC_AUDIENCE` |
| Entra ID | A scope of the exposed API (`api://<application id>/<scope>`) in `OIDC_SCOPE` |
| Zitadel | The JWT access token type and the project audience scope |

### Next.js with `jose`

```ts
// lib/bearer.ts
import { createRemoteJWKSet, jwtVerify, type JWTPayload } from 'jose';

const issuer = process.env.OIDC_ISSUER!; // http://localhost:8080/realms/flutter-bloc-advance
const audience = process.env.OIDC_API_AUDIENCE!; // the audience your provider puts in the access token
const jwks = createRemoteJWKSet(new URL(process.env.OIDC_JWKS_URI!)); // jwks_uri of the discovery document

export type Caller = { subject: string; roles: Set<string> };

// Returns the caller of a valid bearer, or null, which the route answers with 401.
export async function verifyBearer(request: Request): Promise<Caller | null> {
  const [scheme, token] = (request.headers.get('authorization') ?? '').split(' ');
  if (scheme?.toLowerCase() !== 'bearer' || !token) return null;
  try {
    // jwtVerify checks the signature, iss, aud and exp.
    const { payload } = await jwtVerify(token, jwks, { issuer, audience });
    return { subject: payload.sub!, roles: appRoles(payload) };
  } catch {
    return null;
  }
}

// The same mapping as the app: admin grants ROLE_ADMIN and ROLE_USER, user grants ROLE_USER.
function appRoles(payload: JWTPayload): Set<string> {
  const realmAccess = payload.realm_access as { roles?: string[] } | undefined;
  const names = (realmAccess?.roles ?? []).map((role) => role.toLowerCase());
  if (names.includes('admin')) return new Set(['ROLE_ADMIN', 'ROLE_USER']);
  if (names.includes('user')) return new Set(['ROLE_USER']);
  return new Set();
}
```

```ts
// app/api/users/route.ts
import { NextResponse } from 'next/server';
import { verifyBearer } from '@/lib/bearer';

export async function GET(request: Request) {
  const caller = await verifyBearer(request);
  if (!caller) return NextResponse.json({ code: 'AUTH_REQUIRED' }, { status: 401 });
  if (!caller.roles.has('ROLE_ADMIN')) return NextResponse.json({ code: 'FORBIDDEN' }, { status: 403 });
  return NextResponse.json([]);
}
```

### Spring Boot resource server

With `spring-boot-starter-oauth2-resource-server`, Spring fetches discovery and the JWKS from the issuer, and checks the signature, `iss` and `exp`:

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: http://localhost:8080/realms/flutter-bloc-advance
          audiences: flutter-bloc-advance-api
```

A `JwtAuthenticationConverter` turns the role claim into the authorities the template's backend already uses:

```java
@Configuration
@EnableWebSecurity
class SecurityConfiguration {

  @Bean
  SecurityFilterChain api(HttpSecurity http) throws Exception {
    http.authorizeHttpRequests(auth -> auth
            .requestMatchers("/api/admin/**").hasAuthority("ROLE_ADMIN")
            .anyRequest().authenticated())
        .oauth2ResourceServer(oauth -> oauth.jwt(jwt -> jwt.jwtAuthenticationConverter(roleConverter())));
    return http.build();
  }

  // Maps Keycloak's realm_access.roles: admin grants ROLE_ADMIN and ROLE_USER, user grants ROLE_USER.
  private JwtAuthenticationConverter roleConverter() {
    JwtAuthenticationConverter converter = new JwtAuthenticationConverter();
    converter.setJwtGrantedAuthoritiesConverter(jwt -> {
      Map<String, Object> realmAccess = jwt.getClaimAsMap("realm_access");
      Collection<?> roles = realmAccess == null ? List.of() : (Collection<?>) realmAccess.getOrDefault("roles", List.of());
      if (roles.contains("admin")) {
        return List.of(new SimpleGrantedAuthority("ROLE_ADMIN"), new SimpleGrantedAuthority("ROLE_USER"));
      }
      if (roles.contains("user")) return List.of(new SimpleGrantedAuthority("ROLE_USER"));
      return List.of();
    });
    return converter;
  }
}
```

The resource server answers 401 to a missing or invalid bearer and 403 to a missing authority, which is what the app expects.

### Which 401 ends the session

By default every 401 means the bearer is no longer valid: the app refreshes the session, and ends it when the refresh cannot fix the 401.
A backend that also answers 401 for other reasons needs that rule narrowed, or a refused database password would sign the user out.
LibreDB Studio is such a backend: it answers 401 with `AUTH_ERROR` when a database refuses its credentials and with `LLM_AUTH` when a model key is rejected, and only its `code: "AUTH_REQUIRED"` means the session ended.
The rule is one getter, `AppDependencies.sessionExpiredPredicate` in `lib/app/di/app_dependencies.dart`.
For Studio, replace it with this, with `dart:convert` and `package:dio/dio.dart` imported:

```dart
SessionExpiredPredicate get sessionExpiredPredicate => _studioSessionEnded;

/// Only Studio's AUTH_REQUIRED 401 means that the bearer is no longer valid. The client reads bodies as text.
bool _studioSessionEnded(DioException error) {
  final response = error.response;
  if (response?.statusCode != 401) return false;
  final body = response!.data;
  if (body is! String) return false;
  try {
    final decoded = jsonDecode(body);
    return decoded is Map && decoded['code'] == 'AUTH_REQUIRED';
  } on FormatException {
    return false;
  }
}
```

The predicate applies in both modes, and a 401 it does not match reaches the caller as an ordinary error.

## Troubleshooting

The log lines below come from `AppLogger`.
A `main_local.dart` build uses its development filter, which prints nothing once asserts are off, so a release build of the demo shows no app log line and the sign-in and refresh lines are seen only in a debug build; a `main_prod.dart` build prints info and above.

**The app stops at startup with "AUTH_PROVIDER is ..., but it must be jwt or oidc".**
`AUTH_PROVIDER` has a value other than `jwt` or `oidc`; an unknown value is never read as `jwt`.

**The login page says "Single sign-on is not configured correctly in this app."**
The `oidc` settings break a rule.
The log line `OIDC configuration is invalid: <reason>` names the variable, such as an `http` issuer that is not on a loopback host, `OIDC_PROMPT=none`, an unknown flag spelling, or `OIDC_USER_ROLES` without `OIDC_ROLE_CLAIM`.
Fix the defines and build again; trying again cannot help.

**"The identity provider could not be reached."**
Discovery, the JWKS or the token endpoint could not be fetched, or did not validate.
Check that the issuer answers at `<issuer>/.well-known/openid-configuration`, and that its `issuer` value equals `OIDC_ISSUER` (Auth0's ends with a slash).
On the Android emulator, run `adb reverse tcp:8080 tcp:8080` again after every emulator boot.
On web, check the provider's CORS setting for the app's origin (Keycloak: Web Origins).

**The provider shows "Invalid parameter: redirect_uri".**
The redirect URI the app sent is not registered.
On web, open the app on the exact origin and port registered (`http://localhost:8081` for the demo, not `127.0.0.1`).
On Android, iOS and macOS, check that the scheme equals `OIDC_REDIRECT_SCHEME` and the Android manifest placeholder.

**"Your account has no role that allows access to this app."**
`OIDC_USER_ROLES` is set, and the ID token holds neither an admin nor a user role under `OIDC_ROLE_CLAIM`.
Most often the role claim is only in the access token: in Keycloak switch **Add to ID token** on, and in Zitadel **User roles inside ID Token**.
The app sends no UserInfo request, so roles must be in the ID token itself.

**Everyone is a `user`, even admins.**
`OIDC_ROLE_CLAIM` is unset or names a claim the ID token does not carry, or `OIDC_ADMIN_ROLES` does not match the role names; decode an ID token and compare.

**"Sign-in failed. Please try again."**
The provider answered with an error, or its answer failed a check: a `state` mismatch, a refused code exchange, an ID token whose signature, `iss`, `aud`, `exp` or `nonce` does not verify, or a token answer without `expires_in`.
The log names the error type and the provider's error code, never its text.
An Auth0 application that signs with HS256 fails here; switch it to RS256.

**Every sign-in asks for the password.**
That is `OIDC_PROMPT=login`, the default; set `OIDC_PROMPT=omit` to reuse the provider session.

**The session ends after a few minutes or right at expiry.**
The provider issued no refresh token, or refused the refresh.
Entra ID, Auth0 and Zitadel need `offline_access` in `OIDC_SCOPE`; Keycloak refuses a refresh after the realm's SSO Session Idle (30 minutes by default).
Every refresh request sends the configured scope, as the `oidc` package does; a provider that refuses that on a refresh ends the session.

**Logout leaves the provider session active.**
The provider advertises no `end_session_endpoint`, such as Google, so only the app session ends; that is expected.
When a provider logout fails, the app still signs out and says "You are signed out of this app, but your session at the identity provider may still be active."
The app signs out on this device first and runs the provider logout after that, so the sentence can appear after the login page shows: on Linux and Windows a provider logout whose browser page is left alone ends only after the 5 minute flow timeout.
With `OIDC_LOGOUT_HINT=false` Keycloak asks the user to confirm each logout.

**Keycloak says "Restart login cookie not found" on iOS or macOS.**
See [Known limitations](#known-limitations): `ASWebAuthenticationSession` over plain http is unverified with Keycloak's login cookies.

**The SSO button stays busy on Linux or Windows after the browser tab was closed.**
The loopback listener waits up to 5 minutes, and the sign-in then ends as a cancel with no message; see [Known limitations](#known-limitations).
A sign-in started while a provider logout's page is left alone stays busy the same way, because the client runs one operation at a time and the sign-in waits behind that logout.

**The Android build fails in the manifest merger.**
The `oidc_android` plugin needs the `oidcRedirectScheme` placeholder in `android/app/build.gradle.kts`, in every build, `jwt` included.

**Port 8080 is in use.**
Another server holds it, such as the real backend of `docs/REAL_API_INFO.md`; stop it while the demo runs.

## Switching modes

`AUTH_PROVIDER` decides only how the user signs in.
The entry point still decides between the mock API and the real one, so both entry points accept both modes:

| | `AUTH_PROVIDER=jwt` | `AUTH_PROVIDER=oidc` |
| --- | --- | --- |
| `main_local.dart` (mock API) | Today's demo | Sign-in at a real provider (the local Keycloak demo), API calls answered by the mock |
| `main_prod.dart` (real API) | Password sign-in and the backend's JWT | A real provider and a real backend |

There is no mock identity provider: the Keycloak demo plays that part.
In `jwt` mode the app constructs and calls nothing from the OIDC path: no discovery request, no OIDC client and no OIDC storage key.
The `oidc` package stays in `pubspec.yaml` in both modes, so every Android build merges its redirect activity.

Sign out before a device switches from one build mode to the other.
The two modes share the bearer slot of secure storage, so an `oidc` build reads a `jwt` session it finds as signed in, without an expiry, until its first 401 ends it.

## Known limitations

- **The web redirect page:** `web/redirect.html` is the `oidc` package's page with three documented changes: an error redirect never shows the provider's error text or its `error_uri` link, only fixed English copy; a `state` the page cannot find is logged without its value; and the page returns to the app with `location.replace`, so the callback URL leaves the tab history and Back skips it.
  Its other text is English only.
  `test/architecture/oidc_platform_setup_test.dart` compares the page with the package's copy and re-checks it after every `oidc` upgrade; copy the new page and re-apply those three changes when it fails.
- **Front-channel logout is not supported:** the page's front-channel handler writes a marker that the app's store never reads, so do not register `redirect.html?requestType=front-channel-logout` as a front-channel logout URL.
- **Keycloak's ID token is short-lived:** Keycloak gives the ID token the access token's lifespan, 60 seconds in the demo, so the stored ID token is usually expired.
  A refresh and a logout still work with it: the refresh does not check its expiry, and Keycloak 26.8.1 accepts an expired `id_token_hint` and ends the session.
- **Linux and Windows wait for a closed browser tab:** the package has no way to cancel the loopback listener, so after the user closes the provider's tab the SSO button works again only after the 300 second flow timeout, which ends the sign-in as a cancel with no message.
- **A desktop provider logout can end late:** the app signs out on this device before the provider logout runs, so the login page shows at once.
  On Linux and Windows a provider logout whose page is left alone ends only after the same 300 second flow timeout, and then shows "You are signed out of this app, but your session at the identity provider may still be active."
- **One client operation at a time:** sign-in, the web completion, refresh and provider logout run one after another, so a pending interactive sign-in or provider logout holds back the others until it ends: a sign-in started while a desktop provider logout waits for its timeout waits behind it.
- **The desktop end-session page is blank:** after a provider logout on Linux and Windows the browser shows an empty page, since a provider logout takes no message.
- **Keycloak's cookies on Apple platforms:** Keycloak 26.8.1 chooses its cookie attributes by user agent: a Safari user agent gets its login cookies with `SameSite=Lax` and without `Secure`, and Chrome gets `Secure; SameSite=None`, even over plain http.
  A sign-in in WebKit, driven through Playwright, worked over `http://localhost`; `ASWebAuthenticationSession` on iOS and macOS, whose user agent and cookie handling may differ, is unverified.
  If it fails there with "Restart login cookie not found", the demo on Apple platforms needs TLS.
- **iOS shows its system alert:** iOS and macOS use the shared browser session, so iOS asks "... Wants to Use ... to Sign In" on every sign-in and every logout.
- **Roles are fixed at sign-in:** a role changed at the provider shows at the next sign-in.
- **No user management:** the user list, the user editor and account editing still call the backend; with single sign-on, manage users at the provider.

# Part 2: Internals

## Flows

### Bootstrap

`AppBootstrap.run` reads `AuthMode.fromDefines(const AuthDefines())` once.
An unknown `AUTH_PROVIDER` throws `AuthProviderConfigError`, which is logged and stops the app before any screen.
`oidc` becomes `OidcAuthMode(settings)`, or `OidcMisconfiguredAuthMode(reason)` when the settings break a rule; the reason is logged at error.
The mode is injected through `AppDependencies.authMode`, and `AppScope` provides it as `AuthMode`.
Only `OidcAuthMode` builds the OIDC pieces: `IOidcClient`, `ISsoAuthRepository`, one `TokenRotation` shared by the startup step and the `ApiClient`, `SsoSignOutAuthRepository` and `SsoAutoRedirectGate`.
`OidcMisconfiguredAuthMode` builds no OIDC client and fails closed: `SessionCubit` gets `MisconfiguredSsoSessionStartup`, which answers `oidc_config` without reading the stored session, and the `ApiClient` gets `RefusingTokenRotation`, which refuses every refresh without a request, so a stored provider refresh token never reaches `BackendTokenRotation`.

### Sign-in on Android, iOS, macOS, Linux and Windows

1. The SSO button, or the automatic redirect, adds `SsoSignInRequested` to `LoginBloc`, whose handler drops a second request while one runs.
2. `SignInWithSsoUseCase` calls `SsoAuthRepository.signIn`, which calls `OidcClient.signIn`.
3. `OidcClient` fetches discovery (cached for 5 minutes, failures never cached), and the package builds the request with a PKCE S256 challenge, `state`, `nonce`, the platform's redirect URI, the scope, `prompt` unless it is `omit`, and `audience` when it is set.
4. The platform opens the provider's page: a Custom Tab, `ASWebAuthenticationSession`, or the system browser through `launchExternalUri` with a loopback listener on `127.0.0.1`.
5. On return the package checks `state`, exchanges the code with the verifier, and validates the ID token: its signature against the JWKS, `iss`, `aud`, `exp` and `nonce`.
6. `OidcClient` requires an access token, an ID token and `expires_in`, and strips `nonce`, `at_hash` and `c_hash` from the claims it hands on.
7. `SsoAuthRepository` requires a string `sub` and `iss` (`oidc_no_claims` otherwise), maps the role (`oidc_no_role` otherwise, with nothing written), and takes the username from `email`, else `preferred_username`, else `sub`.
8. The session is persisted through `AuthSessionRepository` with its rollback: the access token in the bearer slot (`SecureStorageKeys.jwtToken`), the refresh token when one was issued, the ID token under `oidcIdToken`, and the access token expiry under `accessTokenExpiresAt`; the username and roles go to local storage.
9. `LoginBloc` emits the same `LoginLoadedState(roles)` as a password sign-in, without the `GET /account` call; `AppSessionListeners`, `SessionCubit.markAuthenticated`, the account fetch and the idle observer run unchanged, and the page navigates to the safe return path.

A closed provider page is a cancel: no message, logged at info, and the automatic redirect gate closes.
On Android a closed Custom Tab tells the app nothing, so `OidcClient` cancels the pending flow whenever the app resumes; after a real redirect that cancel does nothing.
On Linux and Windows the loopback listener cannot see a closed tab either, so a sign-in left alone ends after the 300 second flow timeout, also as a cancel with no message (`AppOidcUserManager.browserFlowTimedOut`); the flag is reset at the start of each sign-in.
Every outcome ends with the transaction store cleared and the package's user manager forgetting its user, so the app's secure storage is the only place tokens live.

### Sign-in on web

The tab itself goes to the provider, so the sign-in completes after a page load:

1. `OidcClient.signIn` writes the transaction and navigates the tab away; `LoginBloc` stays loading on `SsoSignInNavigatedAway`.
   The return path travels as the fragment of the package's `original_uri` (`<origin><base href>#<safe path>`), never in `state`.
2. The provider redirects to `redirect.html`, which stores the redirect URL as the response of that `state` in `localStorage` and sends the tab back to the app with `location.replace`, so the callback URL does not stay in the tab history.
3. At startup `SessionCubit.restore` runs `SsoSessionStartup.run`, which calls `completePendingSignIn`.
   A new user manager runs `init()`, which exchanges the stored response, and the session is persisted as above, before the router picks the first screen, so the login page does not flash.
4. A rejected completion becomes `SessionUnauthenticated(reason: signInFailed, signInError: code)`, and the login page shows the sentence until the first SSO tap.
5. A tab that comes back without a response (the user pressed Back) holds a verifier with no response; the client reports a cancel, clears it, and the gate closes, so no redirect loop starts.
6. A browser may instead restore the page from its back-forward cache, with `LoginBloc` still loading.
   The first web sign-in of a run registers a `pageshow` listener (`oidc_page_restore.dart`) that reloads a page restored that way, so the reload's startup step reports the cancel and Back from the provider is a cancel in that case too.

### Startup in `oidc` mode

`SessionCubit.restore` runs the startup step first, under its own 15 second limit, and only then reads the stored session under the existing 10 second storage limit.
The step completes a pending web sign-in, then checks the stored access token expiry, never a JWT `exp`, so an opaque access token works too.
An expired access token with a stored refresh token is refreshed through the shared `TokenRotation`.
The refresh takes its turn at the lock that the token refreshes of every browser tab share (`ITokenRefreshLock`): the expiry is read first without the lock, so a valid session waits for no other tab, and once this tab holds the lock the expiry and the refresh token are read again, so a session another tab refreshed meanwhile is used as it is and no grant is sent.
A turn the lock cannot give keeps the stored session.
The step's 15 second limit counts the wait for the lock too.
The refresh follows the session-generation rules of `TokenRefreshInterceptor`: an answer that comes after the session ended is dropped, and what it stored while the session ended is taken back.
It records what it stored, so an end that another tab reports just then takes it back (`RotatedTokensTakeBack`).
A refused refresh, an expired access token without a refresh token, or a failed write of the refreshed tokens clears the session, and the user starts signed out.
An unreachable provider keeps the stored session.
A step that does not answer within 15 seconds is treated as an unreachable provider: the stored session is read as it is, and the automatic redirect gate closes.
What the step answers after its limit is acted on only while nothing has been emitted since the read after the limit: a late session end ends the session, and a late web sign-in is read from storage.

### Refresh

`TokenRefreshInterceptor` stays the only owner of refresh, with its single flight, its session-generation checks, its rollback, its cross-tab check of the stored refresh token, its turn at the cross-tab lock and the take-back when another tab ends the session.
On web the single flight holds across the browser tabs too: the refreshes of all tabs and the startup step take turns at one Web Lock, and the end of the session in one tab reaches the others over a `BroadcastChannel` (see "Token refresh" in [`mock-architecture.md`](mock-architecture.md)).
The package's own refresh timers are off (`AppOidcUserManager`).
In `oidc` mode the refresh goes through `OidcTokenRotation`:
1. Rotations run one at a time, across the browser tabs as well, and a refresh token that the provider has replaced or refused is never sent in a second grant, so a provider with refresh token reuse detection never sees a used token twice.
   `OidcClient.refresh` has no time limit of its own, so a grant that hangs holds the lock, and the other tabs' refreshes fail after `ApiClient.tokenRefreshLockWaitLimit`.
   A provider that does not rotate refresh tokens answers with no new one, or the same one, so that token stays the stored one and is sent again when the new access token expires.
2. A refresh token that the store no longer holds gets `RotationUnavailable` without a request, and the interceptor retries with the stored tokens.
3. `OidcClient.refresh` hands the stored access token, ID token and refresh token to the package for one `refresh_token` grant at the provider's token endpoint; the stored ID token may have expired.
4. A new ID token's signature is then verified against the provider's keys.
   When the token endpoint has answered but the JWKS cannot be fetched for that check, the grant is not thrown away: the answer keeps the new access and refresh tokens, drops the unchecked ID token so the stored one stays, and a warning is logged.
5. The interceptor stores the new access token and its expiry, the new refresh token when the provider rotates it, and the new ID token when one is returned and checked; roles are not re-mapped.

| Answer | Result | Effect |
| --- | --- | --- |
| New tokens | `TokensRotated` | Stored, and the request is retried |
| New tokens, but the JWKS for the new ID token could not be fetched | `TokensRotated` without an ID token | The new access and refresh tokens are stored, the stored ID token stays, and the request is retried |
| `invalid_grant`, `invalid_client` or another client or authentication error, or a new ID token whose signature or claims fail a check | `RotationRefused` | The session ends with reason expired, and the login page shows the button with no error |
| A token endpoint status of 429 or 5xx whatever its error code, `server_error`, `temporarily_unavailable`, discovery that cannot be fetched, or a transport failure | `RotationUnavailable` | The session is kept, the request fails as a network error, and the next 401 tries again |

`jwt` mode keeps `BackendTokenRotation`, today's `POST /api/token/refresh`, where any failure ends the session.

### Logout

A logout the user starts goes through `SsoSignOutUseCase` and `SsoSignOutAuthRepository.signOut`:
1. It reads the stored ID token.
2. It clears the local session exactly as in `jwt` mode, including the OIDC keys, and answers at once with that result and the provider logout started (`SsoSignOut`).
3. `MenuBloc` signs the app out on that answer, so the login page shows while the provider logout goes on.
4. `OidcClient.endProviderSession` uses the discovered `end_session_endpoint`, else Auth0's `/v2/logout` for an issuer on `auth0.com`, else no provider logout.
5. It opens that endpoint with `client_id`, the platform's `post_logout_redirect_uri`, and the ID token as `id_token_hint` while `OIDC_LOGOUT_HINT` is on.
6. A failed, cancelled or unopenable provider logout leaves the user signed out; `MenuBloc` then emits `providerSessionLeft`, and `AppSessionListeners` shows the `oidc_logout_incomplete` sentence as a notice over the login page; when the local clear failed, only the notice about stored data left behind shows.

On Linux and Windows a provider logout whose page is left alone ends after the 300 second flow timeout, as a failure with that sentence.
The client runs one operation at a time, so a sign-in started meanwhile waits behind it.

No automatic redirect fires in the same run after a user logout.
An idle timeout or an unrefreshable 401 clears the local session only, through `SessionCubit`, because a provider logout needs a browser and the user is not there.

## Module map

| Path | Role |
| --- | --- |
| `lib/infrastructure/config/auth_config.dart` | `AuthDefines`, the sealed `AuthMode` (`JwtAuthMode`, `OidcAuthMode`, `OidcMisconfiguredAuthMode`), `OidcSettings.parse` and its rules |
| `lib/core/security/oidc_role_mapping.dart` | `mapOidcRole` and `appRolesFor`, pure functions |
| `lib/core/security/safe_redirect.dart` | `safeReturnPath`: the return path rules on top of `safeRedirectTarget` |
| `lib/core/security/sensitive_data_scrubber.dart` | `sensitiveExactKeys`: `code`, `code_verifier`, `state`, `nonce`, `session_state`, `id_token_hint` |
| `lib/infrastructure/analytics/sentry_scrub.dart` | Masks those keys in breadcrumbs, keeping the navigation breadcrumb's `state` |
| `lib/core/errors/app_error_code.dart`, `lib/shared/l10n/app_error_code_l10n.dart` | The six `auth.oidc_*` codes and their sentences |
| `lib/l10n/intl_en.arb`, `lib/l10n/intl_tr.arb` (and `lib/generated/`) | The sentences, the SSO button, subtitle and desktop browser page text |
| `lib/infrastructure/storage/secure_storage.dart` | The `oidcIdToken` and `accessTokenExpiresAt` keys and the expiry encoding |
| `lib/features/auth/domain/entities/auth_session.dart` | `AuthSession.oidcIdToken` and `accessTokenExpiresAt` |
| `lib/features/auth/data/repositories/auth_session_repository_impl.dart` | Persist, rollback and clear of the OIDC keys, only with `oidcKeys: true` |
| `lib/infrastructure/http/token_rotation.dart` | `TokenRotation`, `TokenRotationResult`, `BackendTokenRotation`, `RefusingTokenRotation` for a misconfigured build, and the `SessionExpiredPredicate` seam |
| `lib/infrastructure/http/interceptors/token_refresh_interceptor.dart` | Refreshes through a `TokenRotation`, honors `RotationUnavailable`, stores the OIDC fields |
| `lib/infrastructure/http/api_client.dart` | Passes the rotation and the 401 predicate to the interceptor |
| `lib/infrastructure/http/interceptors/mock_interceptor.dart` | Answers 401 to an expired JWT bearer in dev mode |
| `lib/infrastructure/auth/oidc/oidc_client.dart` | `IOidcClient` and `OidcClient`: sign-in, web completion, refresh, provider logout, error classification |
| `lib/infrastructure/auth/oidc/oidc_page_restore.dart`, `oidc_page_restore_web.dart`, `oidc_page_restore_stub.dart` | The web `pageshow` listener that reloads a page restored from the back-forward cache; nothing on other platforms |
| `lib/infrastructure/auth/oidc/app_oidc_user_manager.dart` | The package's `OidcUserManager` with timers off, a 5 minute transaction life, session adoption, the refreshed ID token check and the desktop flow timeout flag |
| `lib/infrastructure/auth/oidc/oidc_transaction_store.dart` | The app-owned `OidcStore`, laid out as `redirect.html` expects |
| `lib/infrastructure/auth/oidc/oidc_key_value.dart`, `oidc_key_value_browser_web.dart`, `oidc_key_value_browser_stub.dart` | Key-value storage over `localStorage` and `sessionStorage`, or memory |
| `lib/infrastructure/auth/oidc/oidc_redirect_uris.dart` | The redirect and post-logout URIs per platform, and the web entry URI |
| `lib/infrastructure/auth/oidc/oidc_token_rotation.dart` | `OidcTokenRotation` |
| `lib/shared/utils/external_link.dart` | `launchExternalUri`, the desktop browser launcher, which throws instead of answering false |
| `lib/features/auth/domain/repositories/sso_auth_repository.dart`, `lib/features/auth/data/repositories/sso_auth_repository_impl.dart` | `ISsoAuthRepository` and `SsoAuthRepository`: claims, roles and persist |
| `lib/features/auth/domain/entities/sso_sign_in_result.dart` | The sealed `SsoSignInResult` |
| `lib/features/auth/application/usecases/sign_in_with_sso_usecase.dart` | `SignInWithSsoUseCase` |
| `lib/features/auth/application/login_bloc.dart`, `login_event.dart` | `SsoSignInRequested` and its handler |
| `lib/features/auth/domain/services/sso_session_startup.dart`, `lib/features/auth/data/services/sso_session_startup_impl.dart` | The startup step and its sealed result |
| `lib/features/auth/domain/services/sso_auto_redirect_gate.dart` | `SsoAutoRedirectGate` |
| `lib/features/auth/domain/repositories/sso_sign_out_repository.dart`, `lib/features/auth/application/usecases/sso_sign_out_usecase.dart` | `ISsoSignOutRepository`, `SsoSignOut` (the local clear and the pending provider logout) and `SsoSignOutUseCase` |
| `lib/features/auth/data/repositories/sso_sign_out_auth_repository.dart` | `SsoSignOutAuthRepository`: the local clear, then the provider logout |
| `lib/features/auth/data/services/misconfigured_sso_session_startup.dart` | `MisconfiguredSsoSessionStartup`, which answers `oidc_config` without reading the stored session |
| `lib/app/session/session_cubit.dart` | Runs the startup step under its own limit, `SessionUnauthenticated.signInError` |
| `lib/app/bootstrap/app_bootstrap.dart` | Reads the mode, stops on an unknown `AUTH_PROVIDER` |
| `lib/app/bootstrap/app_session_listeners.dart` | Closes the gate on sign-in, logout and a restore past the storage limit, and shows the logout notice, also when it follows the sign-out |
| `lib/app/di/app_dependencies.dart`, `lib/app/di/app_scope.dart` | Builds and provides the OIDC pieces in `OidcAuthMode` only, the fail-closed startup and rotation of `OidcMisconfiguredAuthMode`, and `sessionExpiredPredicate` |
| `lib/app/shell/menu_bloc/menu_bloc.dart`, `menu_state.dart` | Signs out on the local clear, then `MenuStateStatus.providerSessionLeft` when the provider logout fails |
| `lib/features/auth/presentation/pages/login_page.dart` | The SSO variant of the login page, its error line and the automatic redirect |
| `lib/features/auth/navigation/auth_routes.dart` | Only the `login` route in the `oidc` modes |
| `lib/app/router/app_router.dart`, `lib/app/app.dart` | Routes by mode, and `/oauth2redirect` and `/logout` to `/login` with no `returnUrl` |
| `lib/features/settings/presentation/pages/settings_screen.dart`, `lib/app/shell/command_palette/command_palette_widget.dart` | Change password hidden outside `jwt` mode |
| `android/app/build.gradle.kts` | The `oidcRedirectScheme` manifest placeholder |
| `web/redirect.html` | The package's redirect page with its three patches |
| `linux/flutter/`, `macos/Flutter/`, `windows/flutter/` | Generated plugin registrants |
| `pubspec.yaml`, `pubspec.lock` | `oidc` 5.0.2, `web` 1.1.1, `http` 1.6.0, and `logging` 1.3.0 for tests |
| `tool/oidc-demo/docker-compose.yml`, `tool/oidc-demo/oidc-demo.env` | The local Keycloak demo |

## Security model

- **Public client:** PKCE S256 on every sign-in, and no client secret in the binary; a guard test fails on any `client_secret`, `OIDC_CLIENT_SECRET` or `clientSecret` spelling in `lib/`, and on any client authentication other than `.none`.
- **State and nonce:** always sent and checked by the package.
- **ID token validation:** the package verifies the signature against the JWKS, never hand-written code.
  A refreshed ID token is verified against the provider's keys too, because the package re-verifies it only with the keys of the user it replaces.
- **Issuer:** `https`, except on a loopback host.
- **`prompt=none`** is refused at bootstrap.
- **Tokens:** only in the app's secure storage.
  The package's store keeps no token: the manager's copy of the tokens, the discovery document and the request live in memory for one operation.
  The web build has the same exposure as `jwt` mode's tokens.
- **Web transactions:** `state` and the provider's response are in `localStorage` (`oidc.state.<id>`, `oidc.response.state.<id>`, indexed by `oidc.keys.<namespace>`), where `redirect.html` reads and writes them.
  The PKCE verifier is in the tab's `sessionStorage` only, so a sign-in stays with its tab, and one tab never consumes or deletes another tab's response.
  The nonce is in `sessionStorage` too, but the package also keeps it inside the state entry in `localStorage`, and checks the ID token's nonce against that copy.
  A transaction expires after 5 minutes and is deleted on every outcome.
- **Provider text:** never on screen.
  The error code picks a fixed sentence, classification goes by error type, and the log gets only the type, the provider's error code and the HTTP status.
  `redirect.html` shows fixed copy for an error redirect, logs a `state` it cannot find without its value, and returns to the app with `location.replace`, so the callback URL with its code and `state` does not stay in the tab history.
- **Logs:** no token, authorization code, verifier, `state`, `nonce`, `session_state` or `id_token_hint` reaches a log line, the dev console or Sentry.
  The scrubber masks the exact keys `code`, `code_verifier`, `state`, `nonce`, `session_state` and `id_token_hint` in bodies and query strings, while names such as `statusCode` keep their values.
  The package's own `package:logging` records do not reach the app's dev console, but go_router's root logging subscription (`debugLogDiagnostics` is on) sends them, unscrubbed, to `dart:developer`, which is the IDE and DevTools log, and a SEVERE one to `FlutterError.dumpErrorToConsole`.
  So the client avoids every record that carries a secret: UserInfo is off, and the desktop launcher never answers false, which would make the package log the authorization URL.
  `AuthInterceptor`'s request log keeps its existing masked preview of the bearer, the first and last four characters through `maskToken`, which predates this feature and applies in both modes.
- **Router:** `/oauth2redirect` and `/logout` always go to `/login` with no `returnUrl`, so a callback URL never becomes a router location or a return path.
- **Misconfigured build:** fails closed on a stored session: it never restores it and never refreshes, so a provider refresh token never reaches the backend's `jwt` refresh endpoint.
- **Return path:** checked on the way in and on the way out with `safeReturnPath`: a local path only, at most 1024 UTF-8 bytes, no control characters, and not the login route; an unsafe value becomes `/`.
- **`id_token_hint`:** always the current session's ID token, because it is written, rolled back and wiped together with the session it belongs to.
- **Front-channel logout:** not supported; the `oidc.request.front-channel-logout` marker that `redirect.html` writes is never read, so a crafted link cannot make a pending sign-in skip its response.
- **Credentials in `toString`:** `OidcTokens`, `TokensRotated` and `OidcTokenRotation` print tokens only through `maskToken` or `secretMask`.

### Where the build differs from the design

- The startup step has its own 15 second limit, before the 10 second storage limit, and a timeout keeps the stored session and disables the automatic redirect.
- The `id_token_hint` is the current session's stored ID token by construction; there is no comparison of its `sub` with a stored subject.
- A logout the user starts signs the app out before the provider logout runs, instead of after it, so the login page shows at once and the `oidc_logout_incomplete` sentence can follow it.
- A refresh whose new ID token cannot be checked because the JWKS cannot be fetched keeps the new access and refresh tokens and the stored ID token, since the provider has already traded the refresh token.
- A sign-in whose token response has no `expires_in` fails with `oidc_failed`, because the session could never be refreshed in time.
- The scrubber's exact OIDC keys apply in `jwt` mode too: a `state=` or `code=` value in a logged URL and a `{"code": ...}` member in a logged body now print `[REDACTED]`.
  Sentry navigation breadcrumbs keep their `didPush`, `didPop` or `didReplace` state.

## Error codes

Each code is an `AppErrorCode` in the `auth.` namespace, with one sentence in each ARB file.

| Code | When | Sentence (English) |
| --- | --- | --- |
| `auth.oidc_config` | Invalid configuration, checked at bootstrap; such a build starts signed out, whatever session is stored | Single sign-on is not configured correctly in this app. Contact your administrator. |
| `auth.oidc_discovery` | Discovery, the JWKS or the token endpoint unreachable, a TLS failure, a response that is not JSON, or a discovery document naming another issuer | The identity provider could not be reached. Try again later, or contact your administrator if this continues. |
| `auth.oidc_no_role` | Role mapping refused the account | Your account has no role that allows access to this app. Ask your administrator. |
| `auth.oidc_no_claims` | The ID token has no string `sub` or `iss` | Sign-in failed. Please try again. |
| `auth.oidc_failed` | Any other failure after the provider answered: a `state` mismatch, a failed code exchange, an invalid ID token, an answer without `expires_in`, or an error from the provider | Sign-in failed. Please try again. |
| `auth.oidc_logout_incomplete` | The provider logout failed, was cancelled or could not be opened, or on Linux and Windows reached the 300 second flow timeout; shown after the app has signed out, so it can follow the login page | You are signed out of this app, but your session at the identity provider may still be active. |
| (none) | The user closed or left the provider page: a closed Custom Tab or system sheet, Back on web (also from the back-forward cache), or a Linux or Windows sign-in left alone until the 300 second flow timeout | No message |

A sign-in whose session cannot be stored shows the existing `auth.session_persist_failed` sentence.

## Tests

Each test file below names the behavior it pins.
`test/infrastructure/auth/oidc/support/fake_provider.dart` is an OpenID provider behind `MockClient`, with discovery, JWKS and a token endpoint that sign RS256 ID tokens, so the client tests run the real package end to end without a network.

| Test | What it pins |
| --- | --- |
| `test/infrastructure/config/auth_config_test.dart` | Every variable, default and spelling, and every refusal |
| `test/app/di/app_dependencies_test.dart`, `test/app/di/app_scope_test.dart`, `test/app/di/app_scope_oidc_test.dart` | The mode's injection; a `jwt` build creates no OIDC client and touches no OIDC key; a misconfigured build restores signed out with `oidc_config`, leaves the stored session alone and refreshes through a rotation that refuses |
| `test/core/security/oidc_role_mapping_test.dart` | LibreDB Studio's `mapOIDCRole` cases, the literal key, the object and array-wrapped shapes |
| `test/core/security/safe_redirect_test.dart` | Each return path rule |
| `test/core/security/sensitive_data_scrubber_test.dart`, `test/infrastructure/analytics/sentry_scrub_test.dart` | The exact OIDC keys, and the navigation breadcrumb's `state` |
| `test/shared/l10n/app_error_code_l10n_test.dart` | Each code's sentence in English and Turkish |
| `test/features/auth/data/repositories/auth_session_repository_impl_test.dart`, `test/infrastructure/storage/secure_storage_test.dart`, `test/features/auth/domain/entities/auth_session_test.dart` | The OIDC keys are written, rolled back and cleared with the session, and never touched in `jwt` mode |
| `test/infrastructure/http/interceptors/mock_interceptor_test.dart` | An expired JWT bearer gets a 401, and `MOCK_TOKEN` still passes |
| `test/infrastructure/http/token_rotation_test.dart`, `test/infrastructure/http/interceptors/token_refresh_interceptor_test.dart` | The rotation seam, `RotationUnavailable`, `RefusingTokenRotation`, the narrowed 401 predicate, and `jwt` refresh unchanged |
| `test/infrastructure/auth/oidc/oidc_transaction_store_test.dart`, `oidc_redirect_uris_test.dart` | The store layout, two tabs, the 5 minute life, and the URIs per platform |
| `test/infrastructure/auth/oidc/oidc_client_test.dart`, `oidc_token_rotation_test.dart` | Sign-in, web completion, Android cancel on resume, the desktop flow timeout as a cancel, the back-forward cache listener registered once on web, refresh classification (a 429 or 5xx token answer keeps the session, an unreachable JWKS after the grant keeps the new tokens and the stored ID token), a provider that does not rotate refresh tokens, one operation at a time, provider logout and the Auth0 fallback |
| `test/infrastructure/auth/oidc/oidc_page_restore_test.dart` | A page restored from the back-forward cache is reloaded, and a fresh load is not |
| `test/features/auth/data/repositories/sso_auth_repository_impl_test.dart`, `test/features/auth/application/login_bloc_test.dart`, `test/features/auth/application/usecases/sign_in_with_sso_usecase_test.dart` | Claims, roles and persist; the production log names the role but not the username; each outcome in `LoginBloc`; dropped concurrent taps |
| `test/features/auth/data/services/sso_session_startup_impl_test.dart`, `test/features/auth/domain/services/sso_auto_redirect_gate_test.dart`, `test/app/session/session_cubit_test.dart` | The startup step, its time limit and late answers, and the gate |
| `test/features/auth/data/repositories/sso_sign_out_auth_repository_test.dart`, `test/app/shell/menu_bloc/menu_bloc_test.dart`, `test/app/bootstrap/app_session_listeners_test.dart`, `test/app/bootstrap/app_session_listeners_sso_test.dart` | Provider logout; the sign-out answers before the provider logout ends, so the login page opens while it is pending; the incomplete-logout notice, also when it comes later; the gate after logout and after a restore past the storage limit |
| `test/shared/utils/external_link_test.dart` | `launchExternalUri` throws instead of answering false |
| `test/features/auth/presentation/pages/login_screen_test.dart`, `login_screen_golden_test.dart` | The SSO page, each error sentence, the Turkish text, the automatic redirect and the `login_screen_sso_light` golden |
| `test/app/router/app_router_test.dart` | The password routes are absent in `oidc` mode, and a callback URL, with or without a trailing slash, lands on `/login` with no `returnUrl` |
| `test/features/settings/presentation/pages/settings_screen_test.dart`, `test/app/shell/command_palette/command_palette_widget_test.dart` | Change password offered only in `jwt` mode |
| `test/features/auth/sso_log_hygiene_test.dart` | A full sign-in, refresh, logout and pushed callback route print no token, code, verifier, `state` or `nonce` |
| `test/architecture/oidc_platform_setup_test.dart` | The Android placeholder equals the default scheme, `web/redirect.html` is the package page plus its patches, no client secret in `lib/` and only `.none` client authentication, and no intent filter for the scheme or its placeholder in any app manifest |

The Keycloak 26.8.1 demo was also walked through by hand on three platforms: web (Chromium, plus one sign-in in WebKit, both driven through Playwright), the Android emulator (a Pixel 3a image with API 36, under KVM) and the Linux desktop.
Every check passed on each of them:
- sign-in as `admin` and as `user`, with the route guard sending `user` to the forbidden page on the admin routes;
- a refresh at Keycloak after the 60 second token life, with the app still signed in;
- single sign-on with `OIDC_PROMPT=omit`, and a logout that really ends the Keycloak session, so the next sign-in shows the form again;
- `OIDC_PROMPT=login` asking for the password every time, even while the Keycloak session lives;
- leaving the provider page (web Back, a closed Custom Tab, a Linux sign-in left alone until the flow timeout) as a cancel, with the button usable, no sentence and no redirect loop;
- a logout with an expired ID token, which Keycloak accepts;
- the Android redirect returning to the running app instead of starting a new one;
- no secret in any app log line.

iOS, macOS and Windows were not run.
The sidebar still lists User Management for `user` in the demo, because `assets/mock/menus.json` grants those entries to `ROLE_USER` as well, in `jwt` mode too; the route guard denies the routes.
