# housing_core

Shared, **framework-agnostic** plumbing for the Itersapiens housing apps:
session, networking, secure storage, roles, error mapping, and compile-time
config. It depends only on [`dio`](https://pub.dev/packages/dio) and
[`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) — it
holds **no UI and no state-management opinions** (Riverpod / Bloc / GetIt all
live in the consumers). The goal is to be the single source of truth for
auth/session/roles/networking so every app behaves consistently.

## Who uses it

| Consumer | What it relies on `housing_core` for |
| --- | --- |
| `householder-mobile-app` › `shell_app` | Roles, session, the shared `Dio`, role-switch UI hook |
| `householder-mobile-app` › `householder_app` + `auth` package | The full stack: storage, `Dio` + auth interceptor, session, errors |
| `student_lib` | The shared `Dio` + auth-meta opt-out, roles, session |

Because all of these resolve to the **same** package, fixing token refresh,
error mapping, or role rules here fixes it everywhere.

## Features

The public surface is the barrel export
[`lib/housing_core.dart`](lib/housing_core.dart). Import it as:

```dart
import 'package:housing_core/housing_core.dart';
```

### Config — `AppConfig`

Compile-time configuration via `String.fromEnvironment`, so values are baked in
at build time with `--dart-define` (see [Configuration](#configuration)).

- `baseUrl` (default `http://localhost:5065`), `webBaseUrl`
  (default `http://localhost:5173`)
- `googleWebClientId`, `googleServerClientId`, `mapsWebApiKey`,
  `mapsCloudMapId`, `passwordPublicKey`
- `*OrNull` getters (e.g. `googleWebClientIdOrNull`) return `null` instead of an
  empty string when a define was not provided — handy for "configure only if
  present" wiring.

### Networking — `DioClient`, `AuthInterceptor`, `AuthMeta`

- **`DioClient`** builds the shared `Dio` with common `BaseOptions`
  (15s connect / 20s receive timeouts, JSON content type, and
  `validateStatus: status < 400`).
  - `DioClient.createRefreshClient()` — a bare client used **only** to perform
    the token refresh (so the refresh call itself is never intercepted).
  - `DioClient.create(tokenStorage:, refreshClient:, onSessionExpired:)` — the
    app-facing client. Adds the `AuthInterceptor`, plus a `LogInterceptor`
    **in debug builds only**.
- **`AuthInterceptor`** (a `QueuedInterceptor`, so refreshes are serialized):
  - On each request that requires auth, attaches `Authorization: Bearer <token>`.
  - On a `401`, attempts a **single** refresh against
    `POST /api/login/refresh-token`, persists the new tokens, retries the
    original request once, and resolves it transparently.
  - If there is no refresh token, or the refresh fails, it clears storage and
    calls `onSessionExpired` — the hook the app uses to drop the user back to
    sign-in.
- **`AuthMeta` / `requiresAuth`** — by default every request requires auth. Opt
  a public endpoint out with:

  ```dart
  final options = Options(extra: {AuthMeta.requiresAuthKey: false});
  await dio.post('/api/login', data: {...}, options: options);
  ```

### Storage — `TokenStorage`, `SecureTokenStorage`

- **`TokenStorage`** — the interface the rest of the package depends on:
  `saveTokens`, `readAccessToken`, `readRefreshToken`, `hasTokens`, `clear`.
- **`SecureTokenStorage`** — the production implementation backed by
  `flutter_secure_storage` (Android uses `encryptedSharedPreferences`). Swap in
  a fake that implements `TokenStorage` for tests.

### Auth model — `Credentials`

A small DTO holding `accessToken` / `refreshToken`, with
`Credentials.fromJson(...)` that tolerates missing fields.

### Session — `SessionNotifier`, `CurrentUserService`

- **`SessionNotifier`** — a `ChangeNotifier` wrapping a single
  `isAuthenticated` flag with `signedIn()` / `signedOut()` / `set(...)`. Wire
  `onSessionExpired` to `signedOut()` so a failed refresh flips the whole app.
- **`CurrentUserService`** — decodes the access-token JWT to expose
  `currentUserId()` and `currentRoles()`. It caches by token, and
  `rolesFromToken(...)` is tolerant of malformed tokens and of single-string vs
  array `role` claims (including the Microsoft schema claim URI).

### Roles — `AppRole`, `RoleApi`, `RoleService`, `RoleHierarchy`, `RoleErrorCodes`, `RoleSwitchController`

- **`AppRole`** — `student` / `householder` / `admin`, each with a backend
  `wire` name. Parse with `AppRole.fromWire(...)` / `AppRole.fromWireList(...)`
  (case-insensitive, unknown values dropped).
- **`RoleApi.assignRole(role)`** — `POST /api/user/roles`, returns fresh
  `Credentials`.
- **`RoleService.acquireRole(role)`** — assigns the role **and persists** the
  returned tokens to `TokenStorage` in one step (use this, not `RoleApi`
  directly, so the new role lands in the active session).
- **`RoleHierarchy`** — the role rules:
  - `student` and `householder` are self-assignable; **`admin` never is**.
  - `assignableFor(held)` — which roles a user can still acquire.
  - `defaultActive(held)` — the role to activate by default (priority
    `householder` → `student` → `admin`).
- **`RoleErrorCodes`** — backend error code constants
  (`user.role.already.assigned`, `user.role.not.assignable`,
  `user.role.invalid`, `user.role.assignment.failed`).
- **`RoleSwitchController`** — an abstract `ChangeNotifier` UI hook
  (`canChangeRole`, `open(context)`). The shell provides the concrete
  implementation; `housing_core` only defines the contract so it stays
  UI-agnostic.

### Errors — `Failure`, `ErrorMapper`

- **`Failure`** — a sealed hierarchy: `NetworkFailure`, `ValidationFailure`
  (with a `fieldErrors` map), `BusinessFailure`, `UnauthorizedFailure`,
  `RateLimitFailure`, `ServerFailure` (with an optional `traceId` from the
  `X-Trace-Id` header), and `UnknownFailure`.
- **`ErrorMapper.map(error)`** — turns any `Object` / `DioException` into a
  `Failure`. Because it is sealed, you get exhaustive `switch` handling at the
  presentation layer:

  ```dart
  try {
    await repository.doThing();
  } catch (e) {
    final failure = ErrorMapper.map(e);
    final text = switch (failure) {
      NetworkFailure() => 'No connection',
      ValidationFailure(:final fieldErrors) => fieldErrors.values.first,
      ServerFailure(:final traceId) => 'Server error ($traceId)',
      _ => failure.message ?? failure.code,
    };
  }
  ```

## Installation

`housing_core` is **not published to pub.dev** (`publish_to: 'none'`); consumers
reference it directly. Two patterns are in use:

**Path dependency** (as in `householder-mobile-app`):

```yaml
dependencies:
  housing_core:
    path: ../housing-core
```

**Git ref + local override** (as in `student_lib`) — pin a published ref for CI,
but resolve the sibling clone locally so you can edit `housing_core` live
without pushing:

```yaml
dependencies:
  housing_core:
    git:
      url: https://github.com/rafael1199v/housing-core-mobile.git

# Local co-dev: resolve housing_core from the sibling clone so it can be edited
# live. Remove this block to use the pinned git ref above.
dependency_overrides:
  housing_core:
    path: ../housing-core
```

> Remove the `dependency_overrides` block to build against the pinned git ref
> (e.g. in CI). Keep it while developing `housing_core` alongside an app.

## Quick start: wiring it up

`housing_core` owns no DI container — you register its pieces in whatever
container the app uses. The following is the canonical order (distilled from the
householder app's `injector.dart`); here shown with `get_it`:

```dart
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:housing_core/housing_core.dart';

Future<void> configureCore(GetIt getIt) async {
  // 1. Secure storage is the foundation everything else reads from.
  getIt.registerLazySingleton<TokenStorage>(SecureTokenStorage.new);
  getIt.registerLazySingleton<CurrentUserService>(
    () => CurrentUserService(getIt<TokenStorage>()),
  );

  // 2. Seed the session flag from whether we already have tokens on disk.
  final hasSession = await getIt<TokenStorage>().hasTokens();
  getIt.registerLazySingleton<SessionNotifier>(
    () => SessionNotifier(isAuthenticated: hasSession),
  );

  // 3. A bare refresh client + the app-facing Dio. onSessionExpired drops the
  //    user back to sign-in when a refresh ultimately fails.
  final refreshClient = DioClient.createRefreshClient();
  getIt.registerLazySingleton<Dio>(
    () => DioClient.create(
      tokenStorage: getIt<TokenStorage>(),
      refreshClient: refreshClient,
      onSessionExpired: () => getIt<SessionNotifier>().signedOut(),
    ),
  );

  // 4. Roles.
  getIt
    ..registerLazySingleton<RoleApi>(() => RoleApi(getIt<Dio>()))
    ..registerLazySingleton<RoleService>(
      () => RoleService(
        api: getIt<RoleApi>(),
        tokenStorage: getIt<TokenStorage>(),
      ),
    );
}
```

**Calling a public (no-auth) endpoint** — opt out of the bearer header:

```dart
final res = await dio.post(
  '/api/login',
  data: {'email': email, 'password': password},
  options: Options(extra: {AuthMeta.requiresAuthKey: false}),
);
final credentials = Credentials.fromJson(res.data as Map<String, dynamic>);
await tokenStorage.saveTokens(
  accessToken: credentials.accessToken,
  refreshToken: credentials.refreshToken,
);
```

**Switching / acquiring a role** — `acquireRole` assigns and persists the new
tokens, so the active session immediately carries the new role:

```dart
final roles = AppRole.fromWireList(await currentUser.currentRoles());
final canAdd = RoleHierarchy.assignableFor(roles); // e.g. [AppRole.householder]

if (canAdd.contains(AppRole.householder)) {
  await roleService.acquireRole(AppRole.householder);
  sessionNotifier.signedIn();
}
```

## Configuration

All config is provided at build time with `--dart-define`. Defaults make a
local backend work out of the box.

| Key | `AppConfig` field | Default |
| --- | --- | --- |
| `BASE_URL` | `baseUrl` | `http://localhost:5065` |
| `WEB_BASE_URL` | `webBaseUrl` | `http://localhost:5173` |
| `GOOGLE_WEB_CLIENT_ID` | `googleWebClientId` | _(empty → `…OrNull` is `null`)_ |
| `GOOGLE_SERVER_CLIENT_ID` | `googleServerClientId` | _(empty)_ |
| `MAPS_WEB_API_KEY` | `mapsWebApiKey` | _(empty)_ |
| `MAPS_CLOUD_MAP_ID` | `mapsCloudMapId` | _(empty)_ |
| `PASSWORD_PUBLIC_KEY` | `passwordPublicKey` | _(empty)_ |

Example:

```bash
flutter run \
  --dart-define=BASE_URL=https://api.example.com \
  --dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com
```

For many defines, prefer a `--dart-define-from-file=config.json` to keep the
command short.

## Testing

```bash
cd housing-core
flutter test
```

[`test/role_test.dart`](test/role_test.dart) covers the pure logic:
`AppRole.fromWire` / `fromWireList`, `RoleHierarchy.assignableFor` /
`defaultActive` (including that `admin` is never self-assignable), and
`CurrentUserService.rolesFromToken` (single-string, array, missing, and
malformed JWTs).

## Design notes & conventions

- **Framework-agnostic.** No Riverpod / Bloc / GetIt is baked in — consumers own
  their DI and just register these types. `RoleSwitchController` is intentionally
  abstract so the UI lives in the shell.
- **One shared `Dio`.** Build it once via `DioClient.create` and inject it
  everywhere; the `AuthInterceptor` handles bearer-token attachment and 401
  refresh centrally.
- **Tokens are the source of truth for roles.** `CurrentUserService` reads roles
  from the JWT, and `RoleService.acquireRole` rewrites the tokens — so role
  state always follows the access token, never a separate cache.
- **Keep it aligned with the backend contract.** The endpoints
  (`/api/login/refresh-token`, `/api/user/roles`), the refresh payload shape,
  and the `RoleErrorCodes` constants must match the API. Change them here, in
  one place, and every app picks it up.
