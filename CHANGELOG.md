# Changelog

All notable changes to this project will be documented in this file.

## [1.0.4] - 2026-04-10

### Bug Fixes

- **Fixed `AppModule` lifecycle state machine**: Added `@mustCallSuper` to `onBind()` and `onInit()`. Subclasses that omitted `super` calls left the module permanently in `unloaded` state, silently breaking lifecycle tracking.
- **Fixed `SecureServiceRegistry._safeNotify()` crash in headless environments**: The unconditional `SchedulerBinding.instance.addPostFrameCallback()` call threw in tests and background isolates where no binding is attached. Now falls back to direct `notifyListeners()` if `SchedulerBinding` is unavailable.
- **Fixed `EventBus.dispose()` subscription leak in release builds**: `dispose()` previously delegated to `clearAll()`, which is guarded by `kDebugMode` and returns early in release — leaving all subscriptions alive. Now cancels subscriptions directly on dispose, bypassing the debug guard.
- **Fixed `GeneratedInjection.inject<T>()` always throwing `UnimplementedError`**: Now delegates to `AirDI().get<T>()` as intended. This was shipped as public API with no implementation.
- **Fixed `ModuleIdentityToken.verify()` ignoring the issued secret**: Added a check that `_secret.isNotEmpty` alongside the `moduleId` comparison, ensuring only properly issued tokens pass verification.
- **Removed unused `archive: ^4.0.7` dependency**: The `archive` package was declared in `pubspec.yaml` but never imported anywhere in the framework. Removed to reduce bundle size.

## [1.0.3] - 2026-03-03

### ✨ Visuals & Documentation

- **Brand Identity**: Added the official Air Framework SVG logo to the README and Developer Guide.
- **Documentation Site**: Updated the documentation site hero image and navigation logo for consistency.

## [1.0.2] - 2026-03-03

### 🔌 Air Adapters

- **`AirAdapter` Base Class**: New abstract class for headless service integrations (HTTP, analytics, error tracking). Follows the same lifecycle as `AppModule` (`onBind → onInit → onDispose`) but without routes or UI.
- **`AdapterManager`**: Standalone singleton for registering, managing, and unregistering adapters. Handles dependency checks and lifecycle events.
- **Contract Pattern**: Adapters expose abstract contracts (e.g., `HttpClient`) so modules never couple to specific libraries. Swap implementations without touching module code.
- **DevTools**: Added **ADAPTERS** tab to the DevTools inspector (8 tabs total: GRAPH, MODULES, ADAPTERS, STATE, PULSES, DI, PERF, LOGS).
- **Boot Order**: Established `Adapters → Modules → App` initialization order to ensure infrastructure is ready before feature modules.

### 📦 Example App

- **DioAdapter Integration**: Added `adapters/dio/` to the example app with `HttpClient` contract, `DioHttpClient` implementation, and `DioAdapter`.
- **UsersModule**: New module demonstrating the adapter pattern — fetches real data from JSONPlaceholder API through the abstract `HttpClient` (zero knowledge of Dio).
- **Shell Navigation**: Added Users tab to the bottom navigation bar.

## [1.0.1] - 2026-02-09

### 🚀 Improvements & Fixes

- **Architecture**: Standardized `AppModule` usage to use `extends` instead of `implements` for better inheritance support.
- **Security**: Enhanced real-time data access validation in coordination with `air_state` 1.0.2.
- **Lifecycle**: Improved `onDispose` to ensure all cross-module subscriptions are properly cleaned up.
- **Documentation**: Updated examples and comments to reflect the latest generator patterns.

## [1.0.0] - 2026-02-09

### 🎉 Initial Release

This is the first stable release of **Air Framework**, a modular, reactive, and scalable framework for building industrial-grade Flutter applications.

### Key Features

- **Modular Architecture**: True decoupling with `AppModule`, `AirDI`, and `AirRouter`. Build features in isolation and assemble them seamlessly.
- **Reactive State Management**: Integrated with `air_state` for high-performance, fine-grained reactivity using code generation (`@GenerateState`).
- **Event Bus System**: Powerful inter-module communication with:
  - **Typed Events**: Strong typing for critical business logic.
  - **Named Signals**: Flexible, lightweight messaging.
  - **Middlewares**: Intercept and process events globally.
  - **Schema Validation**: Ensure data integrity with runtime validation.
- **Dependency Injection**: Centralized Service Locator (`AirDI`) with module ownership and lifecycle management.
- **Smart Routing**: Built on top of `go_router` with distributed route definitions.
- **DevTools**: Built-in debugging tools for inspecting modules, state, and events.

### 🛡️ Security & Enterprise Features

- **Permission System**: A declarative, Opt-In security layer for controlling access between modules.
  - Grainular permissions: `dataRead`, `dataWrite`, `serviceCall`, `eventEmit`, `eventListen`.
  - **Tiered Enforcement**:
    - **Debug**: Non-blocking warnings (Yellow) for rapid development.
    - **Strict Mode**: Hard blocking for production/audit compliance.
- **Secure Service Registry**: Register services with access control lists (`allowedCallers`) and audit logging.
- **Audit Trail**: Comprehensive logging of security violations and cross-module interactions.
- **Data Protection**: Secure shared data storage with TTL (Time-To-Live).

### Developer Experience

- **Colored Console Logs**: Clear, color-coded output for Info, Debug, Warning, and Error logs.
- **Rapid Prototyping**: Permissive defaults in Debug mode allow you to build fast and secure later.
- **Comprehensive Documentation**: Extensive guides and API references included.

---

_Build better, scalable Flutter apps with Air Framework._
