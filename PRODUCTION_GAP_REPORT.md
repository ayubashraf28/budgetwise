# Production Gap Report

## Scope
- Repository: `budgetwise`
- Target: Android-first production hardening
- Date: 2026-02-14

## Ownership Checklist
- [ ] Tooling and CI owner assigned
- [ ] Service-layer error model owner assigned
- [ ] Onboarding flow owner assigned
- [ ] Router/auth flow owner assigned
- [ ] Data-layer migration owner assigned
- [ ] Test hardening owner assigned

## Confirmed Gaps
1. Local verification was blocked by disk exhaustion during tests (`OS Error 112`).
2. No in-repo CI workflow existed.
3. Multiple oversized screens/providers increased regression and maintenance risk.
4. Onboarding UI orchestrated services directly (layering breach).
5. Generic string exceptions and raw `toString()` error rendering were widespread.
6. Missing forgot-password behavior and placeholder widget smoke test.
7. Analyzer/lint configuration was minimal for production.
8. Unused dependencies and stale constraints were present.
9. Default profile locale/currency values were inconsistent across code/config.
10. Router redirect executed repeated onboarding profile checks.
11. Dynamic typing remained in critical UI flow (`home_screen.dart`).

## Baseline Commands (Pre-hardening Snapshot)
```bash
flutter analyze
dart format --output=none --set-exit-if-changed lib test
flutter test
flutter build apk --debug
```

### Observed Baseline Results
- `flutter analyze`: no hard errors, 14 warnings/info issues.
- `dart format --set-exit-if-changed`: failed (format drift in 3 files).
- `flutter test`: unstable in local environment due disk exhaustion on `C:` temp path.
- `flutter build apk --debug`: pending in hardened quality gate run.

## Hardening Controls Added
- `tool/quality_gate.ps1` (forces `TEMP/TMP` to `D:` on Windows).
- `tool/quality_gate.sh` (cross-platform CI/local checks).
- `.github/workflows/flutter-ci.yml` with analyze/test/build gates.
- New typed error framework:
  - `lib/utils/errors/app_error.dart`
  - `lib/utils/errors/error_mapper.dart`
- New onboarding orchestration layer:
  - `lib/providers/onboarding_provider.dart`

## Additional Hardening Progress (2026-02-14)
- Screen-level raw exception rendering removed in active UX flows; UI now maps to safe messages via `ErrorMapper`.
- Auth error handling updated to consume typed app errors (technical parsing + user-safe fallback) instead of direct exception string usage.
- Shared actual-value computation extracted to `lib/utils/actual_calculation_utils.dart` and reused by category/income providers.
- Large screen decomposition started with part files:
  - `lib/screens/subscriptions/subscriptions_screen_helpers.dart`
  - `lib/screens/settings/settings_screen_helpers.dart`
- Additional large-screen decomposition completed:
  - `lib/screens/home/home_screen_helpers.dart`
  - `lib/screens/analysis/analysis_screen_components.dart`
  - `lib/screens/expenses/category_detail_screen_helpers.dart`
- Further decomposition in this cycle:
  - Transaction form helpers split into focused parts:
    - `lib/screens/transactions/transaction_form_sheet_ui.dart`
    - `lib/screens/transactions/transaction_form_sheet_calculator.dart`
    - `lib/screens/transactions/transaction_form_sheet_pickers.dart`
    - `lib/screens/transactions/transaction_form_sheet_submit.dart`
  - Analysis helpers split into focused parts:
    - `lib/screens/analysis/analysis_screen_controls.dart`
    - `lib/screens/analysis/analysis_screen_modes.dart`
- Additional decomposition and dead-code removal:
  - Replaced monolithic home helper with focused parts:
    - `lib/screens/home/home_screen_header_overview.dart`
    - `lib/screens/home/home_screen_sections.dart`
    - `lib/screens/home/home_screen_recent.dart`
  - Replaced monolithic category-detail helper with focused parts:
    - `lib/screens/expenses/category_detail_screen_year_mode.dart`
    - `lib/screens/expenses/category_detail_screen_content.dart`
    - `lib/screens/expenses/category_detail_screen_actions.dart`
  - Removed unused home chart helper block that was no longer rendered.
- Remaining raw `'Error: $e'`/direct exception interpolation in screen UX paths removed (accounts, account form, item detail, category detail).
- `tool/quality_gate.ps1` now explicitly fails when any external command returns non-zero exit code.
- Auth widget coverage expanded:
  - `test/widgets/auth_flows_test.dart` (forgot-password dialog entry point + register render controls).
- Onboarding provider tests expanded:
  - `test/providers/onboarding_provider_test.dart` now covers template creation and idempotent retry behavior when categories already exist.
- Provider mutation/state tests expanded:
  - `test/providers/subscription_notifier_test.dart` covers duplicate in-flight `markAsPaid` protection and in-flight cleanup after failure.
  - `test/providers/profile_notifier_test.dart` covers update success/error mapping, onboarding completion, and refresh state transitions.
- Transaction mutation tests expanded:
  - `test/providers/transaction_notifier_test.dart` covers month derivation, cross-month category/item ID resolution, and unauthenticated guard behavior.
- Provider DI/testability hardening:
  - `lib/providers/transaction_provider.dart` now resolves month/category services via providers instead of constructing services internally.
  - `lib/providers/subscription_provider.dart` now resolves month/category/item services via providers for subscription-item sync.
  - `lib/providers/transaction_provider.dart` async mutation methods now capture provider dependencies before awaits to avoid stale `ref` reads.
- Supabase migration validation completed against active project `zqccesfvwhqytwlddmwq` on `2026-02-14`:
  - Applied: `add_non_empty_name_constraints`
  - Applied: `add_transactions_user_month_date_index`
  - Applied: `harden_security_definer_search_path`
  - Verified constraints, index, and function `search_path=public` settings via SQL checks.
- Router reliability hardening:
  - Redirect decision logic extracted to testable functions in `lib/config/routes.dart`:
    - `resolveAppRedirect(...)`
    - `resolveOnboardingCompletedForRedirect(...)`
  - Redirect now consumes cached onboarding provider state when available, reducing repeated async waits and avoiding unnecessary profile checks during navigation.
  - Added router regression tests in `test/config/routes_redirect_logic_test.dart` for auth/onboarding gating and fail-open behavior.
- Profile reset hardening:
  - Added `lib/providers/profile_reset_provider.dart` to orchestrate delete-all-data + sign-out outside UI layer.
  - Updated settings danger-zone flow to call provider orchestration instead of direct service/auth calls.
  - Added regression tests in `test/providers/profile_reset_notifier_test.dart` for success path, invalidation behavior, and mapped failure propagation.

## Post-hardening Verification
Commands executed successfully after implementation:

```bash
flutter analyze
dart format --output=none --set-exit-if-changed lib test
flutter test -j 1
flutter build apk --debug
```

Notes:
- Android build required Windows env override to avoid `C:` exhaustion:
  - `TEMP=D:\budgetwise_temp`
  - `TMP=D:\budgetwise_temp`
  - `GRADLE_USER_HOME=D:\gradle_cache`
- Current full test suite status after this phase: `54 passed`.
