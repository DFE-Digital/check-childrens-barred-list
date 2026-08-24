# Authentication and authorisation

Most pages in CBL sit behind DfE Sign-in, and the support interface applies a further check on top. This document covers the three layers and the records sign-in creates. For where these sit in the service, see [architecture](architecture.md).

## The three layers

### 1. The basic auth gate

While the `service_open` feature flag is off, `ApplicationController#http_basic_authenticate` puts HTTP basic auth in front of every page, using `SUPPORT_USERNAME` and `SUPPORT_PASSWORD`. It closes an environment to the public, and the DfE Sign-in checks below still apply once you're past it.

You manage the flag at `/support/features`, which is itself inside the support interface.

### 2. DfE Sign-in

Users sign in through DfE Sign-in over OpenID Connect. The strategy lives in `lib/omniauth/strategies/dfe_openid_connect.rb` and `config/initializers/omniauth.rb` wires it up, requesting the `email`, `organisation` and `profile` scopes with discovery enabled.

Signing in does two things beyond authenticating the user:

- **Authorisation.** The callback (`OmniauthCallbacksController#dfe`) asks the DfE Sign-in API which organisations the user belongs to, checks that the organisation they signed in as is one of them, then asks which role they hold for this service. A user with no role for the service ends up at `/401`. `DfESignInApi::GetUserAccessToService` prefers an enabled internal role over an enabled external one, so a user holding both gets support access.
- **Record keeping.** `DsiUser.create_or_update_from_dsi` upserts the user by their DfE Sign-in UID and, when a role came back, writes a `DsiUserSession` row capturing the role and the organisation they signed in as. Search logs hang off the `DsiUser`, which is what makes a search attributable to a person and an organisation.

The session expires two hours after sign-in. `handle_expired_session!` runs before every action on the controllers that require sign-in, redirects to sign-out once the expiry has passed, and treats a missing expiry the same way.

Users must also accept the terms and conditions before they can use the service — `enforce_terms_and_conditions_acceptance!` sends them to `/terms-and-conditions` until they've accepted the current version, and acceptance lapses after 12 months.

`DfESignInApi::Client` signs each API call with a JWT from `DFE_SIGN_IN_API_SECRET` and times out after five seconds.

### 3. Support interface access

`SupportInterface::SupportInterfaceController` skips the usual sign-in filter and applies its own: `authorize_internal_user!` renders a 403 unless the current user's most recent session carries a role code that appears in the `roles` table as both `enabled` and `internal`.

Role codes live in the `roles` table and you manage them at `/support/roles`, so granting support access doesn't need a deploy. `rake db:seed_role_codes` bootstraps an environment, creating an internal role from `DFE_SIGN_IN_API_INTERNAL_USER_ROLE_CODE` and external roles from the comma-separated `DFE_SIGN_IN_API_ROLE_CODES`.

## When DfE Sign-in is bypassed

`DfESignIn.bypass?` (`app/lib/dfe_sign_in.rb`) swaps the real strategy for OmniAuth's developer strategy: a form to type a UID, email and name into, no API calls, and `DsiUser#internal?` returning true for everyone, so the support interface is open to whoever signs in.

| Environment         | Bypassed?                                     |
| ------------------- | --------------------------------------------- |
| Local (`local`)     | Yes — `BYPASS_DSI=true` in `.env.development` |
| Review apps         | Always                                        |
| Test, preproduction | Only if `BYPASS_DSI=true` is set              |
| Production          | Never                                         |

Review apps bypass unconditionally because each pull request gets an ephemeral hostname that real DfE Sign-in has no redirect URI for. **The bypass path runs no role checks at all** — it skips organisation membership, the role lookup and the internal-role check — so only production, or a test environment with the bypass switched off, exercises real authorisation.
