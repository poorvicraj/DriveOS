# DriveOS — Architectural System Diagrams

This document illustrates the practical software architecture of DriveOS via Mermaid diagrams.

---

## 1. System Architecture Diagram

```mermaid
graph TD
    subgraph PresentationLayer["Presentation Layer (Qt Quick / QML & ViewModels)"]
        UI["AppShell & QML Screens<br/>(Home, Media, Climate, Vehicle, Navigation)"]
        Theme["DesignSystem Singleton<br/>(Colors, Typography, Radii, Spacing)"]
        NavCtrl["NavigationController<br/>(Centralized Routing)"]
        VM["ViewModels (MVVM)<br/>(HomeVM, ClimateVM, MediaVM, SettingsVM)"]
    end

    subgraph DomainLayer["Application & Domain Layer"]
        Services["Application Services<br/>(VehicleService, ClimateService, MediaService)"]
        Safety["SafetyPolicy Engine<br/>(Driver Distraction Evaluator)"]
        Diag["DiagnosticService<br/>(Lightweight DTC Store)"]
        VState["VehicleState Model<br/>(Candidate Signals & Operational States)"]
    end

    subgraph VehicleLayer["Vehicle Layer (HAL)"]
        VDI["VehicleDataInterface<br/>(Pure Abstract C++ HAL)"]
        SimBackend["SimulatedVehicleBackend<br/>(Deterministic In-Process Simulation)"]
        CANBackend["CANVehicleBackend<br/>(Linux SocketCAN Driver)"]
    end

    subgraph CommLayer["Communication & Network Layer"]
        SocketCAN["Linux SocketCAN API<br/>(AF_CAN, raw socket worker thread)"]
        VCAN["Linux Kernel vcan0 Bus"]
        DBC["CAN Database Specification<br/>(driveos.dbc)"]
    end

    %% Presentation Bindings
    UI -->|"User Gestures / Commands"| VM
    VM -->|"Q_PROPERTY Bindings & Signals"| UI
    UI -.->|"Tokens"| Theme
    UI -->|"Route Changes"| NavCtrl
    NavCtrl -->|"Active Route"| UI

    %% ViewModel to Domain
    VM -->|"Command Dispatch"| Services
    Services -->|"State Updates"| VM
    Services -->|"Evaluate Interaction"| Safety
    Safety -->|"Restriction State"| VM
    Diag -->|"DTC State"| VM

    %% Domain to VDI
    Services -->|"Commands (Temp, Mode, Locks)"| VDI
    VDI -->|"Canonical State Callbacks"| Services
    Services -.->|"Updates"| VState

    %% VDI Implementations
    SimBackend -.->|"implements"| VDI
    CANBackend -.->|"implements"| VDI

    %% CAN Network Flow
    CANBackend -->|"Send / Recv Frames"| SocketCAN
    SocketCAN -->|"Network Packets"| VCAN
    VCAN -->|"Network Packets"| SocketCAN
    CANBackend -.->|"Signal Definitions"| DBC
```

---

## 2. Vehicle Data Flow Diagram

```mermaid
sequenceDiagram
    autonumber
    participant Net as Virtual Bus (vcan0) / Sim Generator
    participant Backend as Vehicle Backend (CAN / Sim)
    participant VDI as VehicleDataInterface
    participant Svc as Application Services
    participant Safety as SafetyPolicy Engine
    participant VM as Presentation ViewModel
    participant QML as QML Touchscreen UI

    Note over Net,Backend: Telemetry Ingestion (Cyclic 20-50 Hz)
    Net->>Backend: Ingest Raw Telemetry (or Euler Kinematics Step)
    Backend->>Backend: Decode Signals & Apply Linear DBC Scaling
    Backend->>Backend: Update Signal Validity (VALID / STALE)
    Backend->>VDI: Dispatch Updated VehicleState
    VDI->>Svc: onStateChanged(VehicleState)

    Note over Svc,Safety: Domain & Safety Evaluation
    Svc->>Safety: evaluateInteraction(category, state)
    Safety-->>Svc: SafetyEvaluation (isAllowed, reason)
    Svc->>VM: Notify Domain State Changed

    Note over VM,QML: Presentation & Reactive Rendering
    VM->>VM: Format Telemetry (Strings, Units, Clamping)
    VM->>VM: Update isRestricted Property
    VM-->>QML: emit speedChanged(), emit batterySocChanged()
    QML->>QML: Reactive Arc Redraw & Gauge Needle Update (60 FPS)
```

---

## 3. UI Data Flow & User Interaction Diagram

```mermaid
sequenceDiagram
    autonumber
    actor Driver as Driver / User
    participant QML as QML View Component
    participant Nav as NavigationController
    participant VM as Presentation ViewModel
    participant Svc as Application Service
    participant Safety as SafetyPolicy Engine
    participant VDI as VehicleDataInterface

    alt Navigation Dock Tap
        Driver->>QML: Tap Navigation Dock Button (e.g., 'Climate')
        QML->>Nav: navigateTo(Screen::Climate)
        Nav-->>QML: emit currentScreenChanged(Climate)
        QML->>QML: Swap Center Viewport Content
    else Setpoint Command While Driving
        Driver->>QML: Adjust Target Temperature (+0.5°C)
        QML->>VM: setTargetTemperature(22.5)
        VM->>Svc: requestTargetTemperature(22.5)
        Svc->>Safety: evaluateInteraction(BASIC_HVAC, currentState)
        Safety-->>Svc: Allowed (Basic HVAC permitted in motion)
        Svc->>VDI: setTargetTemperature(22.5)
        VDI-->>Driver: State propagates back and reflects on UI dial
    else Restricted Deep Setting While Driving
        Driver->>QML: Tap 'Open Trunk / Hood' while Speed > 0
        QML->>VM: requestDoorToggle(FrontTrunk)
        VM->>Svc: requestDoorToggle(FrontTrunk)
        Svc->>Safety: evaluateInteraction(DEEP_SETTINGS, currentState)
        Safety-->>Svc: Disallowed ('Motion Detected: Deep settings locked')
        Svc-->>VM: Command Rejected
        VM-->>QML: emit userNotificationRequested('Driver Distraction Lockout')
        QML->>QML: Display Toast / Warning Overlay Banner
    end
```

---

## 4. Fault Propagation Diagram

```mermaid
graph TD
    subgraph Trigger["Fault Occurrence"]
        F1["CAN Cyclic Deadline Missed<br/>(> 500 ms)"]
        F2["Sensor Out of DBC Bounds<br/>(e.g., Temp > 85°C)"]
        F3["Physical Socket Disconnection"]
    end

    subgraph Detection["Vehicle Backend Layer"]
        Mon["SignalTimeoutMonitor /<br/>Backend Validator"]
        Mon -->|"Set Status"| SigStatus["SignalStatus::STALE /<br/>SignalStatus::INVALID"]
        Mon -->|"Set Health"| BusHealth["CommunicationHealth::DEGRADED"]
    end

    subgraph VDI_Layer["Vehicle Data Interface"]
        VDI_Hook["VehicleDataInterface Callbacks<br/>(registerFaultCallback / registerHealthCallback)"]
    end

    subgraph Domain["Application & Diagnostic Services"]
        DiagSvc["DiagnosticService<br/>(Record DTC: e.g. U0111 / B1080)"]
        VehSvc["VehicleService<br/>(Update Subsystem Health)"]
    end

    subgraph Presentation["Presentation & UI"]
        BaseVM["BaseViewModel<br/>(isHealthy = false)"]
        QML_UI["QML Cockpit View<br/>(Render '--' fallback, Amber Alert Badge)"]
    end

    F1 --> Mon
    F2 --> Mon
    F3 --> Mon

    SigStatus --> VDI_Hook
    BusHealth --> VDI_Hook

    VDI_Hook --> VehSvc
    VDI_Hook --> DiagSvc

    VehSvc --> BaseVM
    DiagSvc --> BaseVM

    BaseVM --> QML_UI
```
