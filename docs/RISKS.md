# DriveOS — Automotive IVI & Vehicle HMI
## Engineering Risk Register & Mitigation Strategy

---

### 1. Document Overview

This document identifies, analyzes, and establishes mitigation strategies for the primary technical, architectural, and operational risks facing **DriveOS**. Proactive risk management ensures that technical roadblocks—such as cross-platform kernel differences, toolchain availability, and asynchronous event handling—are mitigated by architectural design rather than reactive patching.

---

### 2. Risk Evaluation Matrix

```
       ▲
  HIGH │           [RSK-001]           [RSK-003]
       │           Host OS / CAN       Scope Creep
IMPACT │
   MED │ [RSK-008]           [RSK-004]           [RSK-007]
       │ CI Discrepancy      UI Coupling         Fault Gaps
       │
   LOW │                     [RSK-002]           [RSK-009]
       │                     Qt Complexity       Compliance Claims
       └──────────────────────────────────────────────────►
          LOW                   MEDIUM              HIGH
                           LIKELIHOOD
```

| Risk ID | Risk Title | Likelihood | Impact | Severity | Primary Mitigation Strategy |
| :---: | :--- | :---: | :---: | :---: | :--- |
| **RSK-001** | Host OS & SocketCAN Incompatibility | **High** | **High** | **Critical** | Pure `VehicleDataInterface` abstraction allowing dual backends (Mock/Sim on Windows, SocketCAN on Linux/CI). |
| **RSK-002** | Qt 6 Toolchain & Environment Complexity | **Medium** | **Medium** | **Moderate** | Standardized CMake configuration; clear, headless automated build recipes. |
| **RSK-003** | Scope Creep & Technology Bloat | **Medium** | **High** | **Major** | Strict Engineering Contract (17 rules); candidate signal dictionary; formal change approval. |
| **RSK-004** | UI Coupling to Vehicle Network Internals | **Medium** | **High** | **Major** | Architectural enforcement of MVVM; zero CAN/socket headers in QML or ViewModels. |
| **RSK-005** | Unrealistic or Hyper-Complex Vehicle Simulator | **Medium** | **Medium** | **Moderate** | Bounded kinematic model (Euler integration); candidate signal dictionary. |
| **RSK-006** | Flaky Asynchronous Timing in Unit Tests | **Medium** | **Medium** | **Moderate** | Decouple clocks; inject virtual time / step-based simulation in tests. |
| **RSK-007** | Silent Fault Failures & UI Freeze | **Medium** | **High** | **Major** | Explicit signal status enum (`VALID`, `STALE`, `INVALID`); dedicated heartbeat timeout monitors. |
| **RSK-008** | Dev Machine vs. CI Environment Discrepancy | **Low** | **Medium** | **Moderate** | Canonical Ubuntu runner in GitHub Actions loading `vcan` module on every build. |
| **RSK-009** | Misleading Compliance or Performance Claims | **Medium** | **Medium** | **Moderate** | Explicit disclaimer in all documentation; "measure, never invent" rule. |
| **RSK-010** | Host Environment & Toolchain Selection | **Medium** | **High** | **Major** | Defer environment decision (WSL2/Docker/MinGW/MSVC) to Phase 1; no premature installs. |

---

### 3. Detailed Risk Analysis & Mitigations

---

#### RSK-001: Host OS & SocketCAN Incompatibility
* **Description:** The development host is Windows 11. Linux SocketCAN (`<linux/can.h>`) is a native Linux kernel network driver and cannot compile or execute natively on Windows without a translation layer. Furthermore, the local WSL2 distribution crashed during inspection with an MCE kernel panic.
* **Impact:** High. If the software is tightly coupled to Linux SocketCAN sockets, the application cannot run or be debugged on the local Windows machine.
* **Likelihood:** High (confirmed by local environment inspection).
* **Mitigation Strategy:**
  1. Enforce strict Hardware Abstraction via `VehicleDataInterface`.
  2. Implement a `SimulatedVehicleBackend` in pure standard C++ that runs natively on Windows, macOS, and Linux without any CAN dependencies.
  3. Keep `CANVehicleBackend` (the SocketCAN implementation) cleanly isolated in a conditional compilation module (`#ifdef __linux__` or CMake platform target).
  4. GitHub Actions will provide automated Linux-based validation of the SocketCAN integration and associated tests.
  5. Provide troubleshooting guidance to remediate local WSL2 or Docker when local CAN sniffing is required.

---

#### RSK-002: Qt 6 Toolchain & Environment Complexity
* **Description:** Qt 6 is a large framework with diverse installation mechanisms (Qt Online Installer, vcpkg, Linux package managers) and deep CMake integration (`qt_add_qml_module`, MOC, RCC). Inconsistent versions or missing QML plugins can break builds.
* **Impact:** Medium. Can lead to build failures or configuration headaches for developers and evaluators.
* **Likelihood:** Medium.
* **Mitigation Strategy:**
  1. Target Qt 6.5+ LTS (Long Term Support) to ensure maximum API stability.
  2. Avoid esoteric third-party QML extensions; rely strictly on standard Qt Quick, Qt Quick Controls, and Qt Quick Layouts.
  3. Ensure all CMake scripts check for required Qt components gracefully with descriptive error diagnostics.
  4. Containerize the headless build in GitHub Actions using standard Ubuntu LTS packages.

---

#### RSK-003: Scope Creep & Technology Bloat (Keyword Chasing)
* **Description:** In student and fresher portfolio projects, there is a constant temptation to incorporate buzzwords (e.g., KUKSA, Eclipse VSS, GenAI, Voice Assistants, full AUTOSAR, Android Automotive). These additions inevitably lead to superficial "toy" implementations, broken builds, and diluted architectural focus.
* **Impact:** High. Destroys the credibility of the project and causes incomplete, buggy code.
* **Likelihood:** Medium.
* **Mitigation Strategy:**
  1. Enforce the **Engineering Contract** established in `PROJECT_CHARTER.md`.
  2. Bound the vehicle signal set to candidate signals required by implemented requirements, adding or removing signals only when justified by actual functionality.
  3. Reject any proposed feature that does not directly serve the 7 core user journeys.
  4. Treat code cleanliness, architectural isolation, and test coverage as the sole evaluation criteria.

---

#### RSK-004: UI Coupling to Vehicle Network Internals
* **Description:** Inexperienced HMI developers often leak low-level data structures (raw CAN frame bytes, arbitration IDs, socket error codes) directly into the UI layer or QML files.
* **Impact:** High. Breaks UI testability, prevents UI reskinning, and creates tight coupling between presentation and communication hardware.
* **Likelihood:** Medium.
* **Mitigation Strategy:**
  1. Architectural Rule: Zero CAN or socket includes in any ViewModel or QML file.
  2. The UI communicates strictly through ViewModels, which interact only with C++ Domain Services.
  3. Static code review and CI checks (ripgrep / grep search) to ensure no SocketCAN identifiers (`can_frame`, `canid_t`) appear outside `app/vehicle/`.

---

#### RSK-005: Unrealistic or Hyper-Complex Vehicle Simulator
* **Description:** Vehicle simulation can easily become an endless rabbit hole if complex suspension dynamics, aerodynamic drag coefficients, or electrochemical cell models are attempted. Conversely, a trivial random-number generator fails to demonstrate realistic vehicle state transitions.
* **Impact:** Medium. Diverts engineering time from core IVI and CAN architecture.
* **Likelihood:** Medium.
* **Mitigation Strategy:**
  1. Implement a clean, deterministic kinematics model based on simple Euler numerical integration ($v = v_0 + a \cdot \Delta t$).
  2. Energy consumption modeled as a straightforward function of vehicle speed and HVAC power draw ($SOC_{t+1} = SOC_t - \Delta E$).
  3. Provide deterministic scenario playback (e.g., "Drive Cycle A: Accelerate to 60 km/h, cruise, brake to stop").

---

#### RSK-006: Flaky Asynchronous Timing in Unit Tests
* **Description:** Asynchronous network operations, periodic CAN timers (e.g., 100ms cyclic frames), and QML animations can cause intermittent timing failures (flakiness) in automated unit test suites.
* **Impact:** Medium. Erodes confidence in continuous integration and slows development.
* **Likelihood:** Medium.
* **Mitigation Strategy:**
  1. Decouple timing dependencies: allow injecting virtual time or manual tick advancing into the `SignalTimeoutMonitor` and simulation engines during tests.
  2. Use GoogleMock expectations with deterministic method invocations rather than arbitrary `sleep()` statements.
  3. Ensure test timeouts are generous on CI virtualized runners.

---

#### RSK-007: Silent Fault Failures & UI Freeze
* **Description:** If a CAN frame stops arriving or an ECU fails, naive applications freeze the UI thread while waiting on blocking sockets, or continue to display stale values without indicating to the driver that data is outdated.
* **Impact:** High. Unacceptable in automotive systems where data validity must always be transparent.
* **Likelihood:** Medium.
* **Mitigation Strategy:**
  1. Every telemetry signal is modeled as a compound type: `SignalValue<T>` containing `T value`, `SignalStatus status`, and `std::chrono::system_clock::time_point timestamp`.
  2. Implement an active heartbeat timeout monitor in the CAN backend that transitions signal status to `SignalStatus::STALE` if no frame arrives within the timeout period.
  3. The HMI renders explicit fallback placeholders (e.g., `-- km/h`) and diagnostic alert icons when status is not `VALID`.

---

#### RSK-008: Dev Machine vs. CI Environment Discrepancy
* **Description:** Features developed on Windows using the mock simulator might pass locally but fail in Linux CI when tested against real SocketCAN and `vcan0`.
* **Impact:** Medium. Causes "works on my machine" friction.
* **Likelihood:** Low to Medium.
* **Mitigation Strategy:**
  1. Maintain identical CMake build definitions across all platforms.
  2. Run the full matrix build in GitHub Actions on every pull request.
  3. Keep the DBC definition file as the single source of truth for both the simulation generator and the CAN backend.

---

#### RSK-009: Misleading Compliance or Performance Claims
* **Description:** In portfolio documentation, claiming functional safety (ISO 26262), cybersecurity (ISO 21434), or process certifications (ASPICE) will immediately trigger severe skepticism from automotive technical interviewers.
* **Impact:** Medium. Damages candidate credibility during recruiter reviews.
* **Likelihood:** Medium.
* **Mitigation Strategy:**
  1. Explicitly document the prototype status in `PROJECT_CHARTER.md` and repository README.
  2. Frame all safety-aware and fault-handling features as *architectural demonstrations of safety-aware design patterns*, never as certified safety mechanisms.
  3. Enforce the "measure, never invent" rule for all performance figures.

---

#### RSK-010: Host Development Environment Resolution & Toolchain Selection
* **Description:** The development host is Windows 11 with a local WSL2 distribution that crashes with an MCE kernel panic. Several viable environment configurations exist (WSL2 hypervisor remediation, Docker Linux container, or native Windows MinGW/MSVC using the dual-backend abstraction). Prematurely installing toolchains or attempting ad-hoc hypervisor fixes risks operating-system instability, disk depletion, and toolchain conflicts.
* **Impact:** High. Could disrupt the developer's machine or establish an unsustainable local build setup.
* **Likelihood:** High (WSL2 crash empirically observed).
* **Mitigation Strategy:**
  1. Strict Phase 0 Guardrail: Do not install dependencies, repair WSL2, install Docker, or install MinGW/MSVC during Phase 0.
  2. Do not automatically make a final decision between WSL2, Docker, MinGW, or MSVC.
  3. Formally record the current environment status as an open project risk.
  4. Explicitly defer the final development-environment architecture decision to Phase 1, to be aligned and approved with the user before executing toolchain changes.
