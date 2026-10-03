# DriveOS — Practical System Architecture Specification

---

## 1. Architecture Overview

**DriveOS** is a production-oriented automotive digital cockpit and software prototype engineered in Modern C++ and Qt/QML.

The project architecture has been deliberately simplified to focus engineering effort where it provides the highest technical value:
1. **Excellent Automotive UI/UX**: Ultra-fluid, responsive, and distraction-conscious HMI presentation across five core views (Home, Media, Climate, Vehicle Settings, Navigation).
2. **Stable Application Architecture**: Clean separation of concerns with unidirectional data flow and strict MVVM boundaries.
3. **Clean C++ / QML Integration**: Declarative QML bound to strongly typed C++ ViewModels and Domain Services.
4. **Credible Vehicle-State Simulation**: Deterministic kinematics and cabin thermal models enabling autonomous development and testing.
5. **Lightweight Automotive Communication**: Standardized CAN 2.0B / SocketCAN communication governed by an official DBC file.
6. **Testing and Engineering Quality**: Headless unit verification, interface mocking, and clean dependency management.

### Explicitly Excluded (Scope Protection):
To prevent superficial implementation, distraction, and architectural decay, the following are strictly prohibited:
* Eclipse KUKSA & COVESA VSS
* Voice assistants, speech recognition, and AI engines
* Personalization profiles and multi-user cloud sync
* Full AUTOSAR (Classic / Adaptive)
* Android Automotive OS (AAOS)
* SOME/IP, DDS, and Automotive Ethernet
* Over-The-Air (OTA) update systems
* Custom Yocto / Buildroot Linux distributions
* Full ISO 14229 UDS / ISO 15765-2 (DoCAN / ISO-TP) transport stacks
* Hardware microcontrollers (STM32, ESP32) and FreeRTOS
* SQLite unless later justified by persistent storage requirements
* Docker unless later justified

---

## 2. Target High-Level Architecture

The system architecture organizes responsibilities into clean, focused layers:

```
                         DRIVEOS
                            │
              ┌─────────────┴─────────────┐
              │                           │
           Qt/QML                       C++
              │                           │
       ┌──────┴──────┐          ┌─────────┴────────┐
       │             │          │                  │
   UI Components  ViewModels  Services       SafetyPolicy
                                      │
                                      │
                            VehicleDataInterface
                                      │
                         ┌────────────┴────────────┐
                         │                         │
                 SimulatedVehicle          CANVehicle
                     Backend                  Backend
                         │                         │
                         │                    SocketCAN
                         │                         │
                         │                       vcan0
                         │                         │
                         │                        DBC
                         │
                         └────────────┬────────────┘
                                      │
                                Vehicle State
```

Diagnostics is represented as an independent, lightweight service connected to the application/domain layer.

---

## 3. Architectural Layer Responsibilities & Strict Boundaries

The architecture defines four practical layers:

### A. Presentation Layer (`app/presentation/`, `app/qml/`)
* **Responsibilities:**
  * Declarative UI components and screen layout containers in QML.
  * Centralized design tokens and theming ([`app/qml/theme/DesignSystem.qml`](file:///d:/automotive/app/qml/theme/DesignSystem.qml)).
  * Presentation state management via C++ ViewModels derived from [`BaseViewModel`](file:///d:/automotive/app/presentation/BaseViewModel.hpp).
  * Centralized application routing via [`NavigationController`](file:///d:/automotive/app/presentation/NavigationController.hpp).
  * Handling touch input and translating UI gestures into domain service commands.
* **Strict Invariants:**
  * QML shall **never** decode CAN frames or unpack raw byte buffers.
  * QML shall **never** access SocketCAN or POSIX file descriptors.
  * QML shall **never** contain vehicle communication logic.
  * QML shall **never** contain substantial business logic or domain calculations.
  * QML shall **never** directly access `VehicleDataInterface` or concrete backends; it binds strictly to ViewModels.

### B. Application & Domain Layer (`app/domain/`, `app/diagnostics/`)
* **Responsibilities:**
  * **VehicleService** ([`app/domain/VehicleService.hpp`](file:///d:/automotive/app/domain/VehicleService.hpp)): Manages powertrain state, drive mode selection, door lock toggles, and acts as the vehicle state coordinator (subsuming state management without unnecessary micro-abstractions).
  * **ClimateService** ([`app/domain/ClimateService.hpp`](file:///d:/automotive/app/domain/ClimateService.hpp)): Manages cabin HVAC setpoint adjustments, fan speed levels, and AC compressor toggles.
  * **MediaService** ([`app/domain/MediaService.hpp`](file:///d:/automotive/app/domain/MediaService.hpp)): Manages audio playback state, volume levels, and track metadata.
  * **SafetyPolicy** ([`app/domain/SafetyPolicy.hpp`](file:///d:/automotive/app/domain/SafetyPolicy.hpp)): Evaluates vehicle state and centralizes driver distraction restrictions for in-motion vehicle operation.
  * **DiagnosticService** ([`app/diagnostics/DiagnosticService.hpp`](file:///d:/automotive/app/diagnostics/DiagnosticService.hpp)): In-memory DTC store managing trouble codes, clearing faults, and reporting active/inactive status.
* **Strict Invariants:**
  * Domain services do not know whether the vehicle is real, simulated, or connected via SocketCAN.
  * Domain logic is pure C++20 and compiles headlessly without GUI, OpenGL, or display server dependencies.
  * No unnecessary services or micro-abstractions: services are created only when a distinct responsibility exists.

### C. Vehicle Layer (`app/vehicle/`)
* **Responsibilities:**
  * Pure abstract Hardware Abstraction Layer (HAL): [`VehicleDataInterface`](file:///d:/automotive/app/vehicle/VehicleDataInterface.hpp).
  * **SimulatedVehicleBackend**: In-process deterministic vehicle kinematics and cabin thermal simulation.
  * **CANVehicleBackend**: Linux SocketCAN network adapter connecting to `vcan0`.
* **Strict Invariants:**
  * Vehicle communication remains strictly behind the `VehicleDataInterface` abstraction.
  * Vehicle backends interact with domain services exclusively via the virtual methods and callback hooks of `VehicleDataInterface`.
  * Swapping between simulated and CAN backends requires zero code modifications in presentation, domain services, or QML screens.

### D. Communication Layer (`can/`)
* **Responsibilities:**
  * Formal CAN Database specification: [`can/driveos.dbc`](file:///d:/automotive/can/driveos.dbc).
  * DBC-related signal encoding and decoding (unpacking bitfields, applying linear scaling `Physical = Raw * Factor + Offset`).
  * Linux SocketCAN adapter running off the main UI thread.
* **Strict Invariants:**
  * All frame IDs, bit layouts, linear scaling factors, and offsets are derived directly from the DBC specification.
  * No hardcoded raw CAN byte interpretation throughout the application.
  * CAN sockets and frame decoding execute strictly on background worker threads, never blocking the UI event loop.

---

## 4. End-to-End Data Flow Architecture

DriveOS enforces strict unidirectional and reactive data flow patterns:

```
[ Vehicle Telemetry / Sensor Source ]
                │
                ▼ (Cyclic 20-50 Hz)
    [ Vehicle Backend (CAN / Sim) ]
                │
                ▼ (DBC Decode / SignalStatus)
      [ VehicleDataInterface ]
                │
                ▼ (onStateChanged / onFault)
       [ Domain & Application Services ]
                │
                ▼ (Safety Evaluation & Formatting)
       [ Presentation ViewModels ]
                │
                ▼ (Q_PROPERTY Bindings & Signals)
         [ QML Cockpit Screens ]
```

### Inbound Telemetry Flow:
1. **Ingestion**: Raw CAN frames arrive on `vcan0` or the kinematics simulator advances one Euler integration step.
2. **Decoding & Verification**: The backend unpacks bitfields according to `driveos.dbc`, applies linear scaling, verifies min/max range limits, and tags signals with a `SignalStatus` (`VALID`, `STALE`, `INVALID`).
3. **Dispatch to VDI**: Updated telemetry is assembled into the canonical `VehicleState` struct and passed to `VehicleDataInterface` registered callbacks.
4. **Domain Coordination**: `VehicleService` and `ClimateService` receive state updates, verify subsystem health, and notify listening ViewModels.
5. **Presentation Formatting**: ViewModels adapt domain values into UI-friendly representations (`QString`, formatted numbers, booleans) and update `isRestricted` status via `SafetyPolicy`.
6. **Reactive UI Render**: QML views bind directly to ViewModel properties; Qt Quick engine updates visual items at 60 FPS without polling.

### Outbound User Command Flow:
1. **User Gesture**: Driver taps an interactive element in QML (e.g. adjusts climate temperature setpoint or toggles drive mode).
2. **ViewModel Invocation**: QML invokes a `Q_INVOKABLE` method on the corresponding ViewModel (e.g. `climateViewModel->setTargetTemperature(22.5)`).
3. **Domain Validation**: The ViewModel forwards the request to the domain service (`ClimateService`), which clamps the value to valid physical limits.
4. **Safety Verification**: The service queries `SafetyPolicy` to verify if the requested interaction is permitted under the current vehicle motion state.
5. **VDI Command Dispatch**: If permitted, the service calls `VehicleDataInterface::setTargetTemperature()`.
6. **Hardware / Simulator Actuation**: The backend encodes the command into CAN frame `0x201` (`Climate_Command`) or updates the simulator internal setpoint.

### Fault & Health Flow:
1. **Detection**: The backend detects a missed periodic frame deadline (>500 ms) or an out-of-range sensor value.
2. **Tagging**: The signal status is transitioned from `VALID` to `STALE` or `INVALID`.
3. **VDI Propagation**: `VehicleDataInterface` fires registered fault and health callbacks with a `FaultRecord`.
4. **Diagnostic Logging**: `DiagnosticService` records a corresponding Diagnostic Trouble Code (DTC).
5. **Presentation Notification**: `BaseViewModel::setHealthy(false)` triggers fallback indicators (`"--"`) and displays degraded state indicators in QML.

---

## 5. Vehicle Data Interface (VDI)

The [`VehicleDataInterface`](file:///d:/automotive/app/vehicle/VehicleDataInterface.hpp) is a small, practical Hardware Abstraction Layer (HAL). It avoids dozens of granular getters/setters in favor of a coherent vehicle state representation:

```cpp
class VehicleDataInterface {
public:
    using StateCallback = std::function<void(const domain::VehicleState&)>;
    using HealthCallback = std::function<void(CommunicationHealth)>;
    using FaultCallback = std::function<void(const domain::FaultRecord&)>;

    virtual ~VehicleDataInterface() = default;

    // --- Lifecycle & Initialization ---
    virtual bool initialize() = 0;
    virtual void shutdown() = 0;

    // --- State & Health Query ---
    [[nodiscard]] virtual domain::VehicleState getVehicleState() const = 0;
    [[nodiscard]] virtual CommunicationHealth getCommunicationHealth() const = 0;

    // --- Vehicle Commands ---
    virtual void setTargetTemperature(float tempCelsius) = 0;
    virtual void setFanSpeed(int level) = 0;
    virtual void setACActive(bool active) = 0;
    virtual void setDriveMode(domain::DriveMode mode) = 0;
    virtual void setDoorLock(bool locked) = 0;

    // --- Asynchronous Notifications & Callbacks ---
    virtual void registerStateCallback(StateCallback callback) = 0;
    virtual void registerHealthCallback(HealthCallback callback) = 0;
    virtual void registerFaultCallback(FaultCallback callback) = 0;
};
```

---

## 6. Vehicle State Model & Operational States

The vehicle state is represented by the coherent struct `VehicleState` ([`app/domain/VehicleState.hpp`](file:///d:/automotive/app/domain/VehicleState.hpp)).

### Vehicle Signal Governance Rule
> **Rule:** *The vehicle signal set shall contain only signals required by implemented requirements. Signals may be added or removed when justified by actual functionality. Avoid artificial vehicle complexity.*

### Initial Candidate Vehicle Signals:
| Signal Name | Physical Range | Units | Operational Context |
| :--- | :--- | :--- | :--- |
| `speed` | 0.0 – 250.0 | km/h | Primary speedometer and motion lockout gate |
| `batterySoc` | 0.0 – 100.0 | % | High-voltage battery gauge and reserve alerts |
| `rangeKm` | 0.0 – 800.0 | km | Estimated driving range |
| `batteryTemperature` | -40.0 – 85.0 | °C | Thermal health indicator |
| `cabinTemperature` | -20.0 – 60.0 | °C | Interior climate display |
| `outsideTemperature` | -40.0 – 60.0 | °C | Exterior ambient temperature |
| `targetTemperature` | 16.0 – 28.0 | °C | HVAC setpoint |
| `acActive` | true / false | boolean | Compressor engagement state |
| `fanSpeed` | 0 – 5 | integer | Blower level (0: Off, 1-5) |
| `driveMode` | ECO, NORMAL, SPORT | enum | Dynamic drive profiles |
| `gear` | PARK, REVERSE, NEUTRAL, DRIVE | enum | Transmission selector |
| `doors` | FL, FR, RL, RR | struct (bool) | Closure safety monitoring |
| `chargingState` | DISCONNECTED, CHARGING, COMPLETE, ERROR | enum | EV charging status |
| `ignitionState` | OFF, ACCESSORY, ON | enum | Vehicle electrical lifecycle |

### Discrete Operational States:
* `PARKED`: Vehicle stationary, transmission in Park, all configuration accessible.
* `DRIVING`: Speed > 0 or transmission in Drive; driver distraction lockouts active.
* `REVERSE`: Vehicle in reverse gear; situational restrictions active.
* `CHARGING`: High-voltage battery actively replenishing; driving functions inhibited.
* `FAULT`: Active critical fault or sensor failure; degraded display mode triggered.

---

## 7. Backend Strategy: Dual-Backend Decoupling

DriveOS implements a clean dual-backend strategy enabled by `VehicleDataInterface`:

```
                    VehicleDataInterface (HAL)
                                │
            ┌───────────────────┴───────────────────┐
            │                                       │
  SimulatedVehicleBackend                    CANVehicleBackend
            │                                       │
  • In-process C++ Euler physics            • Linux SocketCAN (AF_CAN)
  • Deterministic 20-50 Hz timer            • Virtual CAN (vcan0)
  • Zero external socket dependency         • DBC bit-level frame decoding
  • 100% Host-independent (Windows/Mac/Linux)• Background worker thread (non-blocking)
```

### 1. SimulatedVehicleBackend (In-Process Simulation):
* Runs directly inside the application process using a lightweight background thread or high-resolution timer.
* Integrates realistic vehicle kinematics: acceleration curves, coast-down friction, regenerative braking, battery SOC depletion relative to power output, and cabin thermal physics.
* Fully deterministic: initial states and seed parameters yield repeatable telemetry for automated testing.
* **Host Independence**: Compiles and executes cleanly on Windows, Linux, and macOS without requiring any Linux kernel modules, POSIX sockets, or elevated permissions.

### 2. CANVehicleBackend (Automotive Network Communication):
* Connects to a standard Linux SocketCAN interface (such as virtual CAN `vcan0` or physical CAN transceiver).
* Operates on a dedicated non-blocking worker thread, reading raw `struct can_frame` buffers.
* Unpacks payload bitfields using signal specifications defined in [`can/driveos.dbc`](file:///d:/automotive/can/driveos.dbc).
* Monitors periodic message deadlines and tags signals as `STALE` if frames cease arriving.

### 3. Transparent Backend Swapping:
* The application bootstrap ([`app/main.cpp`](file:///d:/automotive/app/main.cpp)) instantiates either `SimulatedVehicleBackend` or `CANVehicleBackend` and passes it via pointer to the domain services.
* Neither ViewModels nor QML screens have any compile-time or runtime knowledge of which backend is active.
* The user interface behaves identically under both backends.

### 4. Windows Development Decoupling:
* Development, visual design iteration, and UI testing on Windows proceed unblocked using `SimulatedVehicleBackend`.
* Linux SocketCAN integration is validated automatically in GitHub Actions CI using native Ubuntu runners and the Linux `vcan` kernel module.

---

## 8. UI & Presentation Architecture (MVVM)

DriveOS adopts the Model-View-ViewModel (MVVM) architectural pattern:

```
[ QML Touchscreen UI ]
         ▲
         │ (Q_PROPERTY Bindings & Signals)
         ▼ (Q_INVOKABLE User Gestures)
[ C++ Presentation ViewModels ]
         ▲
         │ (C++ Callbacks & Domain Methods)
         ▼
[ Application & Domain Services ]
         ▲
         │ (C++ Abstract Interface)
         ▼
[ VehicleDataInterface (HAL) ]
```

* **QML Views:** Pure presentation templates. They bind to properties exposed by ViewModels and invoke methods on user interaction.
* **ViewModels (`BaseViewModel`):** Adapt domain data into UI-friendly types (`QString`, formatted numbers, booleans) and expose the `isRestricted` safety state and `isHealthy` status.
* **Services:** Manage feature lifecycles, validate user inputs against domain boundaries, and communicate with the `VehicleDataInterface`.

---

## 9. Centralized Navigation Architecture

Application navigation is strictly centralized in `NavigationController` ([`app/presentation/NavigationController.hpp`](file:///d:/automotive/app/presentation/NavigationController.hpp)):

* **Top-Level Destinations:**
  1. **Home:** Primary instrumentation, speed gauge, battery ring, quick telemetry.
  2. **Media:** Audio playback, track metadata, volume, source controls.
  3. **Climate:** HVAC temperature setpoint dials, blower controls, AC toggle.
  4. **Vehicle Settings:** Door closures, exterior lighting, drive mode selection.
  5. **Navigation:** Stylized contextual situational map and route cards.
* **Consistent Bottom Dock:** The bottom navigation bar remains persistent across all screens. Screens never manage global routing state independently. Route transitions are executed by updating `navigationController.currentScreen`.

---

## 10. Design System Architecture

All visual constants are centralized in `DesignSystem.qml` ([`app/qml/theme/DesignSystem.qml`](file:///d:/automotive/app/qml/theme/DesignSystem.qml)) as a QML singleton:

* **Dark Luxury Palette:** Obsidian background (`#090D16`), elevated surface (`#111827`), glass cards (`#1E293B`).
* **Semantic Accents:** Electric Cyan (`#00E5FF`), Emerald Green (`#00E676`), Warning Amber (`#FFB300`), Critical Ruby (`#FF5252`).
* **Typography Hierarchy:** Hero (56px), Display (36px), Title (24px), Subtitle (18px), Body (14px), Caption (12px), Micro (10px).
* **Automotive Touch Target Rule:** All touchable interactive elements adhere to a minimum size of **48x48 dp** (`minTouchTarget: 48.0`).
* **Standard Transitions:** Standard cubic easing (`Easing.OutCubic`) with defined timings (`durationFast: 180ms`, `durationNormal: 280ms`, `durationSlow: 420ms`).
* **Zero Hardcoding**: QML screens reference `DesignSystem.*` tokens exclusively rather than embedding raw hex colors or magic pixel values.

---

## 11. Safety Policy & Driver Distraction Boundary

The `SafetyPolicy` ([`app/domain/SafetyPolicy.hpp`](file:///d:/automotive/app/domain/SafetyPolicy.hpp)) centralizes driving distraction rules:

* **Motion Evaluation:** Vehicle is defined as "in motion" if `speed > 0.1 km/h` or transmission gear is in `DRIVE` / `REVERSE`.
* **Permitted in Motion:** Primary dock navigation, basic HVAC temperature adjustments, basic media track skipping and volume.
* **Restricted in Motion:** Deep vehicle closure toggles, exterior lighting mode configuration, full keyboard input, detailed diagnostic inspection.
* **ViewModel Integration:** ViewModels query `SafetyPolicy` on state updates and set `isRestricted = true` when applicable, enabling QML to display non-interactive indicators or warning overlays.
* *Regulatory Note:* This is a practical automotive distraction minimization model and does not claim formal ISO 26262 functional safety compliance.

---

## 12. Fault Propagation Model

DriveOS models signal validity and fault propagation across all layers:

```
[ Fault Event / Bus Timeout ]
            │
            ▼
[ Vehicle Backend (CAN / Sim) ]
            │ (SignalStatus = STALE / INVALID)
            ▼
[ VehicleDataInterface ]
            │ (onFault / onStateChanged)
            ▼
[ Application Service ]
            │ (Updates domain status)
            ▼
[ Presentation ViewModel ]
            │ (isHealthy = false, signal = "--")
            ▼
[ QML User Interface ]
            │ (Displays degraded indicator / fallback text)
```

* **Signal Status Lifecycle:** `VALID` -> `STALE` (missed deadline) -> `INVALID` (out of DBC bounds) -> `NOT_AVAILABLE`.
* **Graceful Degradation:** Stale telemetry shows fallback indicators (`"--"`) rather than crashing or freezing stale numbers.

---

## 13. Diagnostics Architecture

Diagnostics is kept intentionally small and practical:
* **Service:** `DiagnosticService` ([`app/diagnostics/DiagnosticService.hpp`](file:///d:/automotive/app/diagnostics/DiagnosticService.hpp)).
* **Structure:** In-memory DTC store managing trouble code records (`DtcRecord`: code, description, severity, status, timestamp).
* **Capabilities:**
  * Query active and confirmed DTC records (`getActiveDtcs()`).
  * Clear stored DTCs (`clearDtcs()`).
  * Report active/inactive status.
  * Inject simulated faults for testing and demonstration (`recordFault()`).
* **Deliberately Excluded:** Full ISO 14229 UDS protocol state machines, multi-frame ISO 15765-2 (DoCAN / ISO-TP) transport segmentation, and security access sessions are omitted to preserve schedule and avoid superficial complexity.

---

## 14. CAN Architecture & DBC Boundary

```
[ Vehicle Simulator / External Node ]
                 │
                 ▼
          [ CAN Encoder ]
                 │
                 ▼
       [ Linux SocketCAN API ]
                 │
                 ▼
        [ Linux vcan0 Bus ]
                 │
                 ▼
          [ CAN Decoder ]
                 │
                 ▼
      [ VehicleDataInterface ]
```

* **DBC Specification:** [`can/driveos.dbc`](file:///d:/automotive/can/driveos.dbc) acts as the single source of truth for all CAN frame IDs (`0x100`, `0x101`, `0x200`, `0x201`, `0x300`, `0x400`), signals, bit lengths, and linear factors.
* **Boundary Rule:** Raw CAN bytes, masks, and frame IDs are strictly prohibited from leaking beyond the communication layer.
* **Decoding Strategy:** Evaluated based on simplicity and maintainability. Avoids generated code unless clear engineering benefit is established.

---

## 15. Repository Structure

```
d:/automotive/
├── CMakeLists.txt                 # Modern CMake build configuration
├── README.md                      # Project overview and architecture guide
├── app/                           # Core application source tree
│   ├── main.cpp                   # Application bootstrap and surface setup
│   ├── presentation/              # MVVM ViewModels and NavigationController
│   │   ├── NavigationController.hpp / .cpp
│   │   └── BaseViewModel.hpp / .cpp
│   ├── domain/                    # Pure domain services and models
│   │   ├── VehicleState.hpp       # Cohesive vehicle state and candidate signals
│   │   ├── SafetyPolicy.hpp       # Driver distraction policy engine
│   │   ├── FaultModel.hpp         # Signal validity status and fault types
│   │   ├── VehicleService.hpp     # Vehicle and powertrain domain service
│   │   ├── ClimateService.hpp     # Climate and HVAC domain service
│   │   └── MediaService.hpp       # Audio playback domain service
│   ├── vehicle/                   # Hardware Abstraction Layer (HAL)
│   │   └── VehicleDataInterface.hpp # Pure abstract vehicle interface
│   ├── diagnostics/               # Lightweight diagnostic subsystem
│   │   └── DiagnosticService.hpp  # DTC store and diagnostic query interface
│   └── qml/                       # Declarative cockpit HMI
│       ├── Main.qml               # Root application window
│       ├── AppShell.qml           # Foundational shell (status bar, viewport, dock)
│       ├── theme/                 # Centralized Design System
│       │   ├── DesignSystem.qml   # Tokens (colors, typography, spacing, radii)
│       │   └── qmldir             # DesignSystem singleton declaration
│       └── components/            # Reusable UI components
│           └── NavButton.qml      # Automotive touch navigation button
├── can/                           # CAN communication specifications
│   └── driveos.dbc                # Formal CAN database specification
├── docs/                          # System documentation
│   ├── ARCHITECTURE.md            # This document
│   ├── ARCHITECTURE_DIAGRAM.md    # Mermaid architectural diagrams
│   ├── PROJECT_CHARTER.md         # Project charter & engineering contract
│   ├── REQUIREMENTS.md            # System requirements specification (SRS)
│   ├── TECHNOLOGY_DECISIONS.md    # Architectural Decision Records (ADRs)
│   ├── SCOPE.md                   # Signal scope and feature boundaries
│   ├── DEVELOPMENT_ENVIRONMENT.md # Toolchain & host environment strategy
│   └── RISKS.md                   # Risk assessment & mitigations
├── scripts/                       # Helper scripts and simulation daemon
│   └── can_sim_daemon.py          # Python standalone CAN simulation daemon
├── tests/                         # Test suites
│   └── unit/
│       ├── main.cpp               # GoogleTest test runner
│       └── test_foundation.cpp    # Architectural foundation unit tests
└── .github/
    └── workflows/                 # Automated CI workflows
        └── ci.yml                 # Ubuntu Linux GCC + SocketCAN vcan0 CI
```

---

## 16. Build Strategy & Environment Compatibility

* **Toolchain Requirements:** CMake >= 3.22, C++20 compiler (GCC, Clang, or MSVC), Qt 6 (Core, Gui, Quick, Qml), Ninja where available.
* **Simple Build Configuration:** Standard CMake target setup without complex package manager dependencies.
* **Host Decoupling (Windows Host Safe):** The application relies on `VehicleDataInterface`. Development and UI testing on Windows run against `SimulatedVehicleBackend` without requiring Linux SocketCAN kernel modules. Linux SocketCAN integration is validated in Linux CI environments.

---

## 17. Architectural Design Principles & Quality Rules

Every component in DriveOS must adhere to the following mandatory rules:

1. **Simplicity First**: Prefer clear, direct designs over premature micro-abstractions and speculative layering.
2. **Avoid Unnecessary Services**: Services are introduced only when a distinct domain responsibility exists.
3. **Avoid Unnecessary Dependencies**: Reject heavyweight third-party libraries and frameworks that do not provide decisive value.
4. **Strict Decoupling**: Keep UI presentation 100% independent from vehicle communication; keep vehicle communication 100% independent from UI presentation.
5. **Single Source of Truth**: `driveos.dbc` defines CAN frames; `VehicleState` defines domain state; `NavigationController` defines active screen.
6. **Deterministic Simulation**: The vehicle simulator operates deterministically, providing predictable states for testing and demonstrations.
7. **Testable Domain Logic**: Domain services, safety rules, and decoders must compile and execute headlessly without GUI dependencies.
8. **Fail-Safe Degradation**: Communication faults or sensor errors degrade gracefully, presenting clear fallback states rather than freezing or crashing.
9. **No Duplicate State**: Maintain state in one authoritative location; do not duplicate data across layers.
10. **Zero Resume-Keyword Code**: Do not introduce code, protocols, or frameworks solely to claim keywords. Every line must serve a practical automotive purpose.
