# DriveOS — Automotive IVI & Vehicle HMI
## System Requirements Specification (SRS)

---

### 1. Document Overview

This document specifies the functional requirements (FR), non-functional requirements (NFR), architectural constraints, and engineering assumptions for the **DriveOS** automotive IVI and vehicle HMI production-oriented software prototype.

Each requirement is assigned a unique identifier to maintain traceability throughout the development lifecycle, linking requirements to architecture, implementation, and automated test cases.

---

### 2. Requirements Hierarchy & Classification

Requirements are classified under the following taxonomies:
* **FR-HMI-xxx:** Touchscreen Human-Machine Interface and User Interaction
* **FR-DOM-xxx:** Domain Services, Application Logic, and State Evaluation
* **FR-VDI-xxx:** Vehicle Data Abstraction and Signal Management
* **FR-CAN-xxx:** CAN Communication, SocketCAN, and DBC Signal Decoding
* **FR-SIM-xxx:** Vehicle Kinematics Simulation and Fault Injection
* **FR-DIA-xxx:** Diagnostic Subsystem and Fault Storage
* **NFR-xxx:** Non-Functional Quality Attributes (Performance, Testability, Modularity, etc.)
* **CON-xxx:** Technical Constraints and Platform Limitations
* **ASM-xxx:** Operational Assumptions

---

### 3. Functional Requirements

#### 3.1 Touchscreen HMI & Navigation (FR-HMI)

| Req ID | Requirement Statement | Traceable Component | Verification Method |
| :--- | :--- | :--- | :--- |
| **FR-HMI-001** | The system shall provide a persistent primary navigation bar enabling single-tap transitions between Home, Media, Climate, Vehicle Settings, and Navigation views. | `AppShell.qml`, `NavigationController` | HMI Test / Qt Test |
| **FR-HMI-002** | The system shall provide a **Home Screen** displaying real-time vehicle speed (km/h), battery State of Charge (SOC %), estimated driving range (km), current gear/drive mode, and ambient cabin status. | `HomeScreen.qml`, `HomeViewModel` | Unit Test + HMI Test |
| **FR-HMI-003** | The system shall provide a **Media Screen** supporting play/pause toggling, track progression (previous/next), audio track title/artist metadata display, and volume level adjustment (0–100%). | `MediaScreen.qml`, `MediaViewModel` | Unit Test + HMI Test |
| **FR-HMI-004** | The system shall provide a **Climate (HVAC) Screen** displaying cabin temperature, ambient exterior temperature, target setpoint adjustment (16.0°C to 28.0°C in 0.5°C increments), fan speed levels (Off, 1–5), and AC compressor on/off state. | `ClimateScreen.qml`, `ClimateViewModel` | Unit Test + HMI Test |
| **FR-HMI-005** | The system shall provide a **Vehicle Settings Screen** displaying door lock states (locked/unlocked), exterior lighting modes (Auto, Off, Low Beam, High Beam), and drive mode selection (Eco, Normal, Sport). | `SettingsScreen.qml`, `SettingsViewModel` | Unit Test + HMI Test |
| **FR-HMI-006** | The system shall provide a conceptual **Navigation Screen** displaying a stylized situational map view, simulated route bearing, and turn-by-turn instruction card. | `NavigationScreen.qml`, `NavigationViewModel` | HMI Test |
| **FR-HMI-007** | The HMI shall apply visual lockouts or non-interactive indicators on restricted UI controls whenever the vehicle is in a driving state. | `SafetyPolicyGate.qml`, `BaseViewModel` | Qt Test |
| **FR-HMI-008** | The HMI shall display dedicated diagnostic warning telltales and alert banners whenever an active Diagnostic Trouble Code (DTC) or system degraded state is active. | `AlertOverlay.qml`, `DiagnosticViewModel` | Qt Test |

#### 3.2 Domain & Application Layer (FR-DOM)

| Req ID | Requirement Statement | Traceable Component | Verification Method |
| :--- | :--- | :--- | :--- |
| **FR-DOM-001** | The domain layer shall maintain a centralized **Vehicle State Machine** supporting the discrete states: `PARKED`, `DRIVING`, `REVERSE`, `CHARGING`, and `FAULT`. | `VehicleStateMachine` | Unit Test (GTest) |
| **FR-DOM-002** | The system shall implement a centralized **SafetyPolicy Engine** that evaluates current vehicle state and determines permitted touchscreen interaction levels according to driving distraction rules. | `SafetyPolicyEngine` | Unit Test (GTest) |
| **FR-DOM-003** | The `SafetyPolicyEngine` shall transition interaction mode to `RESTRICTED` when `Vehicle.Speed > 0 km/h` or when gear is set to `DRIVE` / `REVERSE`. | `SafetyPolicyEngine` | Unit Test (GTest) |
| **FR-DOM-004** | Under `RESTRICTED` interaction mode, deep settings modifications, text input fields, and extensive list scrolling shall be rejected by ViewModels. | `BaseViewModel`, `SettingsViewModel` | Unit Test (GTest) |
| **FR-DOM-005** | Essential controls (climate target adjustment, audio mute, audio pause/skip, primary telemetry) shall remain operable under `RESTRICTED` interaction mode. | `SafetyPolicyEngine` | Unit Test (GTest) |
| **FR-DOM-006** | The domain services shall validate all user input setpoints against strict domain boundaries (e.g., target temperature clamped between 16°C and 28°C) before dispatching commands. | `ClimateService`, `MediaService` | Unit Test (GTest) |

#### 3.3 Vehicle Data Abstraction (FR-VDI)

> **Vehicle Signal Governance Rule:** The vehicle signal set shall contain only signals required by implemented requirements. Signals may be added or removed when justified by actual functionality. Avoid artificial vehicle complexity. The initial 12 signals documented in the project baseline are treated strictly as **initial candidate vehicle signals**.

| Req ID | Requirement Statement | Traceable Component | Verification Method |
| :--- | :--- | :--- | :--- |
| **FR-VDI-001** | The system shall decouple domain services from vehicle hardware using a pure abstract interface: `VehicleDataInterface`. | `VehicleDataInterface.hpp` | Code Inspection / Architecture Review |
| **FR-VDI-002** | `VehicleDataInterface` shall provide asynchronous notification mechanisms (signals/callbacks) for the initial candidate vehicle signals required by implemented requirements (Speed, Battery SOC, Range, Cabin Temperature, Outside Temperature, Drive Mode, Door State, Charging State, Ignition State). | `VehicleDataInterface` | Unit Test (Mock Backend) |
| **FR-VDI-003** | `VehicleDataInterface` shall provide command transmission methods to request vehicle state modifications (Target Temperature, Fan Speed, AC State, Drive Mode, Door Lock State). | `VehicleDataInterface` | Unit Test (Mock Backend) |
| **FR-VDI-004** | Every telemetry signal exposed by `VehicleDataInterface` shall include a data validity status enum (`VALID`, `STALE`, `INVALID`, `NOT_AVAILABLE`). | `Signal<T>` / `SignalValue` | Unit Test (GTest) |

#### 3.4 CAN Communication & DBC Decoding (FR-CAN)

| Req ID | Requirement Statement | Traceable Component | Verification Method |
| :--- | :--- | :--- | :--- |
| **FR-CAN-001** | The system shall provide a concrete `CANVehicleBackend` implementing `VehicleDataInterface` utilizing Linux SocketCAN sockets. | `CANVehicleBackend` | Integration Test (vcan0) |
| **FR-CAN-002** | The system shall bind to a configurable CAN network interface (defaulting to virtual interface `vcan0`). | `SocketCanSocket` | Integration Test (vcan0) |
| **FR-CAN-003** | The system shall decode incoming CAN frames and encode outbound CAN frames strictly according to an official, defined DBC specification file (`driveos.dbc`). | `DbcDecoder`, `driveos.dbc` | Unit Test (GTest) |
| **FR-CAN-004** | The DBC decoder shall unpack raw frame payloads, extract bit-level signals, apply linear scaling (`Physical = Raw * Factor + Offset`), and enforce signal minimum/maximum ranges. | `DbcSignalParser` | Unit Test (GTest) |
| **FR-CAN-005** | The CAN backend shall run network reception on a dedicated background worker thread, ensuring the main UI/Qt event loop is never blocked by socket operations. | `CanWorkerThread` | Integration Test |
| **FR-CAN-006** | The CAN backend shall detect cyclic signal timeouts when expected periodic frames (e.g., Powertrain Status at 100ms) fail to arrive within a configurable threshold (e.g., 500ms). | `SignalTimeoutMonitor` | Unit Test (GTest) |
| **FR-CAN-007** | Upon timeout detection, the backend shall update the corresponding signal status to `STALE` and notify the domain layer without terminating the application. | `SignalTimeoutMonitor` | Unit Test (GTest) |

#### 3.5 Vehicle Simulation & Fault Injection (FR-SIM)

| Req ID | Requirement Statement | Traceable Component | Verification Method |
| :--- | :--- | :--- | :--- |
| **FR-SIM-001** | The system shall provide an autonomous **Vehicle Simulation Backend** capable of operating without physical vehicle hardware. | `VehicleSimulationEngine` | Unit Test (GTest) |
| **FR-SIM-002** | The simulator shall calculate deterministic vehicle kinematics (acceleration, braking, cruising, energy depletion based on speed and HVAC power consumption). | `KinematicsSimulator` | Unit Test (GTest) |
| **FR-SIM-003** | The simulator shall support a **Dual-Mode Architecture**: Mode A (direct in-process simulation) and Mode B (autonomous external daemon broadcasting standard CAN frames onto `vcan0`). | `SimulationRunner` | Integration Test |
| **FR-SIM-004** | The system shall include a **Fault Injection Interface** capable of simulating: CAN cyclic packet drop/timeout, invalid out-of-range sensor readings, sudden loss of battery SOC signal, and ECU disconnection. | `FaultInjectionService` | Integration Test |

#### 3.6 Diagnostic Subsystem (FR-DIA)

| Req ID | Requirement Statement | Traceable Component | Verification Method |
| :--- | :--- | :--- | :--- |
| **FR-DIA-001** | The system shall implement an intentionally lightweight Diagnostic Subsystem centered on `DiagnosticService` without full UDS transport overhead. | `DiagnosticService` | Code Inspection / Architecture Review |
| **FR-DIA-002** | The diagnostic subsystem shall maintain an in-memory Diagnostic Trouble Code (DTC) store containing code, description, severity (`INFO`, `WARNING`, `CRITICAL`), and status (`ACTIVE`, `CONFIRMED`, `STORED`). | `DiagnosticService`, `DtcRecord` | Unit Test (GTest) |
| **FR-DIA-003** | The diagnostic subsystem shall support querying active and confirmed DTC records (`getActiveDtcs()`). | `DiagnosticService` | Unit Test (GTest) |
| **FR-DIA-004** | The diagnostic subsystem shall support clearing stored DTCs (`clearDtcs()`). | `DiagnosticService` | Unit Test (GTest) |
| **FR-DIA-005** | The diagnostic subsystem shall provide a fault recording hook (`recordFault()`) enabling simulated fault injection and test verification. | `DiagnosticService` | Unit Test (GTest) |

---

### 4. Non-Functional Requirements

#### 4.1 Responsiveness & Performance (NFR-PERF)
* **NFR-PERF-001:** The HMI presentation layer shall maintain a target rendering rate of **60 frames per second (FPS)** under standard operating conditions.
* **NFR-PERF-002:** SocketCAN frame reception and decoding must occur asynchronously off the UI main thread; processing a received frame must take less than 1 ms on the worker thread.
* **NFR-PERF-003:** User touch interactions on the HMI (e.g., button press to ViewModel property change) shall register within 50 ms.
* **NFR-PERF-004:** *Empirical Measurement Clause:* All latency, memory footprint, and frame rate figures must be verified via actual profiling tools (e.g., QML profiler, Linux `perf`, `top`); unverified estimates are prohibited.

#### 4.2 Architecture, Modularity & Decoupling (NFR-MOD)
* **NFR-MOD-001 (Zero CAN in QML):** No QML file shall import or reference SocketCAN headers, raw byte arrays, frame IDs, or socket file descriptors.
* **NFR-MOD-002 (Dependency Inversion):** Domain services and ViewModels shall depend exclusively on the abstract `VehicleDataInterface`, never on concrete CAN or simulation classes.
* **NFR-MOD-003 (MVVM Strictness):** ViewModels shall expose presentation state via Qt properties and handle user commands via Qt slots/methods; no business or calculation logic shall be coded in QML Javascript blocks.

#### 4.3 Testability & Verification (NFR-TEST)
* **NFR-TEST-001 (Headless Execution):** Domain services, safety policy logic, DBC decoders, and diagnostic handlers shall compile and pass unit tests headlessly (without X11, Wayland, or GPU display hardware).
* **NFR-TEST-002 (Mockability):** All external I/O (sockets, timers, clocks) shall be mockable using GoogleMock to enable deterministic unit test assertions.
* **NFR-TEST-003 (Automated Test Suite):** The test suite shall run via a single command (`ctest --output-on-failure`); GitHub Actions will provide automated Linux-based validation of the SocketCAN integration and associated tests.

#### 4.4 Reliability & Fault Tolerance (NFR-REL)
* **NFR-REL-001 (Deterministic Failure State):** In the event of vehicle communication loss or signal corruption, the system shall never crash, throw unhandled exceptions, or display frozen erroneous values; stale signals shall display predefined fallback graphics.
* **NFR-REL-002 (Memory Safety):** The C++ codebase shall employ strict RAII idioms and modern smart pointers (`std::unique_ptr`, `std::shared_ptr`). Zero manual memory management (`new`/`delete`) outside established Qt parent-child ownership models.
* **NFR-REL-003 (Automatic Recovery):** When CAN communication recovers after a bus timeout, the system shall restore normal telemetry display without requiring application reboot or user intervention.

#### 4.5 Observability & Logging (NFR-OBS)
* **NFR-OBS-001:** The system shall use structured, category-based logging utilizing `QLoggingCategory` (e.g., `driveos.can`, `driveos.vdi`, `driveos.safety`, `driveos.hmi`, `driveos.diag`).
* **NFR-OBS-002:** Logging verbosity shall be configurable via command-line flags or configuration files (`Debug`, `Info`, `Warning`, `Critical`).

#### 4.6 Code Quality & Static Analysis (NFR-QUAL)
* **NFR-QUAL-001:** Codebase formatting shall be enforced via `clang-format` based on a project `.clang-format` profile.
* **NFR-QUAL-002:** Static analysis shall be run using `clang-tidy` and `cppcheck`, with zero tolerance for critical issues, memory leaks, or uninitialized variables.
* **NFR-QUAL-003:** Compiler warnings shall be treated as errors (`-Wall -Wextra -Wpedantic -Werror` on GCC/Clang).

---

### 5. System Constraints & Assumptions

#### 5.1 Technical Constraints (CON)
* **CON-001 (Host Operating System):** Production vehicle communication relies on Linux SocketCAN kernel drivers. Development environments running on Windows require either WSL2, Docker Linux containerization, or a cross-platform Mock backend for host development. *(Note: Development-environment architecture decision between WSL2, Docker, MinGW, or MSVC is explicitly deferred to Phase 1 per ADR-011 and RSK-010).*
* **CON-002 (Language Standard):** C++20 standard shall be used where supported by the compiler toolchain; fallback to C++17 if required by older toolchains.
* **CON-003 (UI Framework):** The HMI shall be implemented using Qt 6 (minimum Qt 6.5 LTS recommended) using Qt Quick and QML.
* **CON-004 (Build System):** Build automation shall use CMake (minimum version 3.22) and Ninja build generator.

#### 5.2 Engineering Assumptions (ASM)
* **ASM-001:** Vehicle CAN bus runs at standard 500 kbps CAN 2.0B with 11-bit or 29-bit identifiers.
* **ASM-002:** The primary development and CI environment is Linux (Ubuntu 22.04 or 24.04 LTS), providing native `vcan` kernel module support.
* **ASM-003:** Touchscreen display resolution is targeted at 1920x1080 (Full HD, 16:9 aspect ratio) or 1280x720 (720p automotive landscape).
* **ASM-004:** For Windows host development without functioning WSL2, the application supports compiling with a `MockVehicleBackend` to allow HMI and domain development without blocking on Linux kernel availability.

---

### 6. Requirements Traceability Matrix (Initial Baseline)

| Requirement ID | Architectural Component | Planned Verification / Test Suite |
| :--- | :--- | :--- |
| **FR-HMI-001..006** | `Qt Quick QML Views`, `ViewModels` | `tst_hmi_navigation`, `tst_viewmodels` |
| **FR-HMI-007, FR-DOM-002..005** | `SafetyPolicyEngine`, `BaseViewModel` | `tst_safety_policy` (GTest) |
| **FR-DOM-001** | `VehicleStateMachine` | `tst_vehicle_state_machine` (GTest) |
| **FR-VDI-001..004** | `VehicleDataInterface`, `Signal<T>` | `tst_vdi_abstraction` (GTest) |
| **FR-CAN-001..002** | `CANVehicleBackend`, `SocketCanSocket` | `tst_socketcan_integration` (vcan0) |
| **FR-CAN-003..004** | `DbcDecoder`, `driveos.dbc` | `tst_dbc_decoder` (GTest) |
| **FR-CAN-006..007** | `SignalTimeoutMonitor` | `tst_timeout_monitor` (GTest) |
| **FR-SIM-001..004** | `VehicleSimulationEngine`, `FaultInjector`| `tst_simulation_engine` (GTest) |
| **FR-DIA-001..005** | `DiagnosticSubsystem`, `DtcManager` | `tst_diagnostic_subsystem` (GTest) |
| **NFR-PERF-001..004** | Whole System | Profiling logs, QML Benchmarks |
| **NFR-MOD-001..003** | Code Architecture | Architecture Review, Static Analysis |
| **NFR-TEST-001..003** | Test Suite / CMake / CI | `ctest`, GitHub Actions workflow |
| **NFR-QUAL-001..003** | Build Toolchain | `clang-format -Werror`, `clang-tidy` |
