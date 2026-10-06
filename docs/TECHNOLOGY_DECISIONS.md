# DriveOS — Automotive IVI & Vehicle HMI
## Architecture & Technology Decision Records (ADR)

---

### 1. Document Overview

This document formalizes the architectural decisions, technology selections, and trade-off evaluations for **DriveOS**. Every core technology has been deliberately chosen to reflect production automotive software engineering practices while strictly rejecting keyword bloat and unnecessary dependencies.

---

### 2. Summary of Locked Technology Stack

| Domain | Technology Selection | Primary Role |
| :--- | :--- | :--- |
| **HMI Framework** | **Qt 6 / Qt Quick (QML)** | Touchscreen UI presentation, hardware-accelerated rendering, declarative layout |
| **Core Language** | **Modern C++ (C++20 / C++17)** | High-performance domain services, decoders, state machines, hardware abstraction |
| **Build Automation** | **CMake (>=3.22) & Ninja** | Modular, cross-platform build orchestration and dependency management |
| **Operating System** | **Linux / Virtual CAN (`vcan0`)** | Native SocketCAN network stack, POSIX IPC, headless CI execution |
| **Vehicle Network** | **CAN 2.0B / SocketCAN** | Automotive standard multi-master serial bus; Linux network-socket abstraction |
| **Signal Definition** | **DBC (CAN Database)** | Industry standard bit-level signal layout, scaling, offsets, and frame timing |
| **CAN CLI Tooling** | **can-utils & cantools Evaluation** | Bus sniffing, frame inspection, DBC validation, and decoding tooling evaluation |
| **Diagnostics** | **Lightweight Diagnostic Subsystem** | In-memory DTC store, fault logging, clearing, and active/inactive status reporting |
| **Unit Testing** | **GoogleTest & GoogleMock** | Deterministic domain logic verification and interface mocking |
| **HMI Testing** | **Qt Test / Qt Quick Test** | ViewModel binding verification and QML UI interaction validation |
| **Static Analysis** | **clang-format & clang-tidy** | Strict coding style enforcement and compile-time bug detection |
| **CI / Automation** | **GitHub Actions** | Automated headless build, linting, and automated test execution |
| **Persistence** | **In-Memory / Config file (Optional SQLite)** | Transient state preferred; SQLite deferred unless persistent requirements emerge |

---

### 3. Detailed Technology Decision Records

---

#### ADR-001: HMI Framework — Qt 6 / Qt Quick (QML) vs. Alternatives

* **Context:** Modern automotive IVI systems require silky-smooth 60 FPS touch rendering, fluid animations, deep C++ integration, and a clear separation between visual presentation and business logic.
* **Decision:** Adopt **Qt 6** using **Qt Quick** (QML + Qt Quick Controls).
* **Role in System:** QML defines visual layout, declarative component hierarchies, transitions, and touch gesture handling. ViewModels exposed via C++ `QObject` properties feed data into QML reactively.
* **Alternatives Evaluated:**
  * *Electron / HTML5 / React:* Web stacks suffer from high memory footprints (Chromium instances), non-deterministic garbage collection pauses, and weak integration with low-level Linux sockets.
  * *Flutter Embedded:* Promising, but lacks widespread production automotive adoption compared to Qt. Tooling for CAN integration is immature in Dart.
  * *Android Automotive OS (AAOS):* Extremely heavy, requires complete AOSP platform builds, gigabytes of RAM, and obscures low-level C++/CAN communication behind high-level Java/Kotlin Vehicle Hardware Abstraction Layers (VHAL).
* **Why Rejected Technologies Were Excluded:**
  Qt is the undisputed industry standard for Linux-based automotive digital cockpits (used widely by Mercedes-Benz, BMW, Tesla, Ford, Hyundai). It provides direct, zero-overhead bindings to C++ domain models.

---

#### ADR-002: Core Programming Language — Modern C++ (C++20 / C++17)

* **Context:** Automotive applications demand deterministic memory execution, zero runtime garbage collection pauses, strict type safety, and direct system socket access.
* **Decision:** Adopt **Modern C++** (preferring C++20 where compiler support allows; fallback to C++17).
* **Role in System:** Powers all domain services, state machines, `VehicleDataInterface`, DBC bitfield decoding, kinematics simulation, and diagnostic handlers.
* **Alternatives Evaluated:**
  * *C (C99/C11):* Traditional for microcontroller ECUs, but lacks strong object-oriented encapsulation, RAII memory management, and modern standard library containers needed for complex HMI application services.
  * *Rust:* Excellent memory safety and concurrency, but Qt integration (cxx-qt) is still experimental and introduces build complexity.
  * *Python:* Excellent for scripting and test harnesses, but unacceptable for core embedded HMI runtime due to the Global Interpreter Lock (GIL) and runtime overhead.
* **Why Rejected Technologies Were Excluded:** Modern C++ provides RAII resource safety, `std::unique_ptr`/`std::shared_ptr` semantics, `std::span` and concepts (in C++20), and seamless zero-overhead integration with the Qt QObject object model.

---

#### ADR-003: Build System — CMake & Ninja

* **Context:** The project requires a cross-platform, modular build system supporting C++, Qt MOC (Meta-Object Compiler), RCC (Resource Compiler), external libraries (GoogleTest), and static analysis tooling.
* **Decision:** Adopt **CMake (>= 3.22)** paired with the **Ninja** build generator.
* **Role in System:** Manages compilation targets, handles Qt 6 CMake macros (`qt_add_executable`, `qt_add_qml_module`), and orchestrates `ctest` test discovery.
* **Alternatives Evaluated:**
  * *QMake:* Deprecated by The Qt Company in favor of CMake starting in Qt 6.
  * *Meson:* Fast, but lacks native first-party Qt 6 QML module integration.
  * *Make:* Slower parallel builds compared to Ninja and brittle cross-platform support.
* **Why Rejected Technologies Were Excluded:** CMake is the automotive and enterprise C++ standard. Every major automotive toolchain, IDE, and CI pipeline natively supports CMake.

---

#### ADR-004: Vehicle Network Protocol & Interface — CAN 2.0B & SocketCAN (`vcan0`)

* **Context:** The HMI must communicate with simulated vehicle ECUs using realistic automotive networking.
* **Decision:** Adopt **CAN 2.0B** over **Linux SocketCAN** using the virtual CAN interface (`vcan0`).
* **Role in System:** SocketCAN provides a POSIX socket interface (`AF_CAN`, `SOCK_RAW`) built directly into the Linux network subsystem. The application reads and writes standard CAN frames (`struct can_frame`) via standard non-blocking socket APIs.
* **Alternatives Evaluated:**
  * *Proprietary CAN Driver APIs (Vector XL Driver, PCAN-Basic):* Proprietary, expensive, and require specific physical USB hardware dongles.
  * *TCP/UDP Sockets / REST / WebSockets:* Unrealistic for internal vehicle bus communications. An automotive cockpit architecture must demonstrate actual CAN frame handling.
  * *SOME/IP / DDS:* Modern and relevant for Adaptive AUTOSAR and High-Performance Compute (HPC) domains, but excessively complex for this scope and distracts from core CAN/HMI foundations.
* **Why Rejected Technologies Were Excluded:** SocketCAN is open-source, standard across all embedded Linux platforms (AGL, Yocto), requires zero hardware thanks to `vcan`, and allows using standard Linux network utilities (`ip link`, `candump`, `cansend`).

---

#### ADR-005: Signal Definition & Encoding — DBC (CAN Database)

* **Context:** Raw CAN frames consist of an arbitration ID and up to 8 payload bytes. Interpreting these bytes requires a formal specification defining signal start bits, lengths, byte order (Intel/Motorola), scaling factors, offsets, and engineering units.
* **Decision:** Define all vehicle signals in an official **DBC** file (`driveos.dbc`).
* **Role in System:** The DBC acts as the single source of truth for all vehicle signals (speed, battery SOC, cabin temperatures, door status, AC state).
* **Alternatives Evaluated:**
  * *Ad-hoc Bitmasking:* Hardcoding bitshifts and masks (`(buf[2] << 8) | buf[3]`) in C++ code. Brittle, undocumented, error-prone, and rejected by all automotive engineering standards.
  * *AUTOSAR ARXML:* Extremely complex, XML-heavy schema requiring expensive commercial tooling (Vector DaVinci, EB tresos) to parse.
  * *JSON / Protocol Buffers:* Used in IoT/cloud, but not used for classic CAN bus multiplexing.
* **Why Rejected Technologies Were Excluded:** DBC is the universal automotive standard for CAN bus specification. Understanding and parsing DBC signal definitions demonstrates direct domain competence.

---

#### ADR-006: CAN Tooling Pipeline — can-utils & cantools Evaluation

* **Context:** We need mechanisms to inspect virtual bus traffic, inject frames, and decode DBC signals.
* **Decision:** Utilize **can-utils** for bus inspection and evaluate **cantools** (Python) for:
  - DBC validation
  - Signal inspection
  - Decoding/tooling
  - Optional code generation
* **Implementation Strategy:** The final implementation approach will be selected during Phase 1 based on simplicity, maintainability, testability, and actual tool capabilities. Do not introduce generated code unless there is a clear engineering benefit.
* **Alternatives Evaluated:**
  * *Handcrafted Tested C++ Decoders:* Transparent, zero build-step dependencies, easily unit tested with GoogleTest.
  * *cantools C-Source Generation:* Bit-exact automated generation, but introduces external build scripts and potential maintenance friction.
  * *Runtime DBC Parsing:* Dynamic, but introduces runtime file I/O and string parsing overhead.
* **Decision Rationale:** Rather than locking code generation prematurely, Phase 1 will benchmark both approaches and adopt the design providing the greatest simplicity, testability, and engineering benefit.

---

#### ADR-007: Diagnostics Architecture — In-Memory DTC Store via DiagnosticService vs. Full UDS Transport

* **Context:** The system needs to demonstrate diagnostic awareness, trouble code recording, and fault clearing without implementing thousands of pages of automotive standards.
* **Decision:** Implement a **lightweight, practical Diagnostic Subsystem** centered on `DiagnosticService`:
  1. **In-Memory DTC Store:** Maintain Diagnostic Trouble Codes with code, plain-text description, severity (`INFO`, `WARNING`, `CRITICAL`), and status (`ACTIVE`, `CONFIRMED`, `STORED`).
  2. **DTC Query & Clear:** Expose `getActiveDtcs()` and `clearDtcs()` methods to ViewModels and UI.
  3. **Fault Injection Hook:** Support `recordFault()` for demonstration and testing of fault propagation.
* **Alternatives Evaluated:**
  * *Full ISO 14229 / ISO 15765-2 (DoCAN / ISO-TP):* Multi-frame transport segmentation, security access (0x27), routine control (0x31). Excessive complexity for an HMI prototype; risks schedule derailment.
  * *Full UDS Session State Machines:* Multi-layer protocol handlers and transport timers.
  * *OBD-II (ISO 15031 / SAE J1979):* Focused on internal combustion emissions; less representative of modern EV interior diagnostics.
* **Why Rejected Technologies Were Excluded:** Full UDS implementations require months of protocol state-machine and transport layer coding. An intentionally lightweight `DiagnosticService` with a clean DTC store satisfies all product and diagnostic verification requirements while keeping the architecture small, stable, and easily maintainable.

---

#### ADR-008: Testing Strategy — GoogleTest, GoogleMock, and Qt Test

* **Context:** Automotive software demands rigorous verification. The architecture must enable automated testing of domain services, decoders, and UI bindings without requiring a physical screen.
* **Decision:** Adopt **GoogleTest (GTest)** and **GoogleMock (GMock)** for domain and CAN decoding logic; adopt **Qt Test** for ViewModel property verification.
* **Role in System:**
  * `GTest`: Validates DBC decoders, unit scaling, `SafetyPolicy` state transitions, kinematics simulation, and timeout detection.
  * `GMock`: Mocks `VehicleDataInterface` to simulate packet loss, network drops, and corrupted values.
  * `Qt Test`: Validates Qt property notifications and ViewModel-to-QML bindings.
* **Alternatives Evaluated:**
  * *Catch2 / doctest:* Good modern C++ testing libraries, but GoogleTest is the overwhelming industry standard across Tier-1 automotive software teams.

---

#### ADR-009: Code Quality & Static Analysis — clang-format & clang-tidy

* **Context:** High-integrity C++ requires uniform formatting and automated detection of undefined behavior, memory leaks, and antipatterns.
* **Decision:** Integrate **clang-format** and **clang-tidy** into the local build process and CI pipeline.
* **Role in System:**
  * `clang-format`: Enforces clean, consistent formatting across all `.cpp`, `.hpp`, and `.qml` files.
  * `clang-tidy`: Flags bugprone patterns, performance anti-patterns, modernize suggestions, and const-correctness violations.
* **Alternatives Evaluated:**
  * *SonarQube / Coverity:* Powerful commercial tools, but introduce server setup overhead unsuited for a lightweight standalone repository.

---

#### ADR-010: State Management & Persistence — Transient Memory vs. SQLite

* **Context:** The system manages vehicle settings, climate setpoints, media playback state, and diagnostic trouble codes.
* **Decision:** Core state shall be managed **in-memory** within C++ domain services, with optional lightweight file serialization (JSON or QSettings) for persistent preferences. **SQLite is deferred** until complex data storage requirements arise.
* **Alternatives Evaluated:**
  * *SQLite Database:* Excessive for storing a handful of user settings (temperature, drive mode, exterior lighting).
* **Decision Rationale:** Automotive HMIs frequently receive state continuously from vehicle ECUs rather than maintaining a local relational database. Storing state in memory with clean C++ domain services minimizes I/O latency and complexity.

---

#### ADR-011: Development Environment Architecture — Deferral to Phase 1

* **Context:** The development host is Windows 11 with WSL2 experiencing hypervisor MCE panics upon launch. Potential environment solutions include WSL2 remediation, Docker containerization, or native Windows MinGW/MSVC paired with the dual-backend Hardware Abstraction Layer (`SimulatedVehicleBackend`).
* **Decision:** Explicitly **defer** the final development-environment architecture decision between WSL2, Docker, MinGW, or MSVC to Phase 1.
* **Guardrail:** In strict compliance with Phase 0 directives, dependencies shall not be installed prematurely, WSL2 shall not be repaired, Docker shall not be installed, and MinGW/MSVC shall not be installed during Phase 0. The current environment status is recorded as an open project risk.
* **Decision Rationale:** Prevents speculative environment modifications, unnecessary system configuration changes, and ensures environment decisions are validated systematically during Phase 1.

---

### 4. Explicitly Rejected Technologies (Scope Protection)

| Technology | Reason for Rejection |
| :--- | :--- |
| **Eclipse KUKSA / COVESA VSS** | High abstraction overhead; obscures raw CAN/SocketCAN mechanics, arbitration IDs, and signal deserialization. |
| **Voice / Speech / GenAI** | Irrelevant for core automotive software engineering; adds external API dependencies and nondeterministic behavior. |
| **Full AUTOSAR (Classic / Adaptive)** | Requires commercial closed-source stacks (Vector Microsar, EB tresos) unavailable on open platforms. |
| **Yocto Project / Poky** | Custom BSP generation requires massive disk space (100GB+) and multi-hour compilation times, detracting from C++/Qt engineering. |
| **SOME/IP / DDS** | Out of scope for a vehicle CAN bus infotainment project. |
| **Cloud Telematics / REST APIs** | Unnecessary network complexity that distracts from on-vehicle embedded systems engineering. |
