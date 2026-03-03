# Changelog

All notable changes to this project will be documented in this file.

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
