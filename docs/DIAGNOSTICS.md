# DriveOS Diagnostics & Fault Handling Subsystem

## 1. Overview & Architectural Claim

> [!IMPORTANT]
> **"This project implements a limited diagnostic prototype inspired by UDS concepts; it is not a complete ISO 14229 implementation."**

DriveOS features an intentionally compact, lightweight diagnostic subsystem designed for automotive cockpit fault observability and recovery without introducing the heavy complexity of a full Unified Diagnostic Services (UDS) / ISO 14229 or ISO 15765 transport stack.

---

## 2. Diagnostic Architecture

The diagnostics pipeline is centered on [`DiagnosticService`](file:///d:/automotive/app/diagnostics/DiagnosticService.hpp), backed by an in-memory Diagnostic Trouble Code (DTC) store, and linked directly to the canonical domain state and presentation layers:

```
[ Vehicle Telemetry / CAN / Simulator ]
                 │
                 ▼
       [ VehicleDataInterface ]
                 │ (FaultRecord / CommunicationHealth)
                 ▼
       [ DiagnosticService ] ◄────► [ In-Memory DTC Store ]
                 │
                 ▼ (Callbacks: DtcList, FaultNotice)
       [ VehicleStateManager ]
                 │
                 ▼
       [ VehicleViewModel ]
                 │ (Q_PROPERTY: hasActiveFaults, diagnosticSummary, activeDtcs)
                 ▼
   [ Driver-Facing Vehicle HMI ]  &  [ Developer DTC Debug Tool ]
```

---

## 3. Supported Prototype DTCs

The system models a curated set of realistic automotive prototype faults:

| DTC Code | Symbolic Identifier | Description | Severity | Target ECU / Subsystem |
|---|---|---|---|---|
| **`B1080`** | `HVAC_SENSOR_TIMEOUT` | Cabin HVAC temperature sensor timeout | `WARNING` | Climate Control Subsystem |
| **`B1081`** | `HVAC_SENSOR_UNAVAILABLE`| HVAC sensor hardware link unavailable | `WARNING` | Climate Control Subsystem |
| **`U0100`** | `VEHICLE_DATA_TIMEOUT` | Vehicle data interface communication timeout | `CRITICAL`| HAL / Powertrain Gateway |
| **`B1024`** | `DOOR_SENSOR_FAULT` | Chassis door closure latch sensor circuit performance | `WARNING` | Body & Closures Module |
| **`U0111`** | `CAN_TIMEOUT` | CAN bus transceiver lost communication timeout | `CRITICAL`| CAN Network Controller |
| **`U0401`** | `INVALID_VEHICLE_SIGNAL`| Invalid vehicle signal data received out of range | `WARNING` | Signal Validation Engine |

---

## 4. In-Memory DTC Store

* **Thread-Safe Operations**: Protected by `std::mutex` with lock-free callback dispatch.
* **Query API**:
  * `getActiveDtcs()`: Returns all trouble codes with status `ACTIVE` or `CONFIRMED`.
  * `getAllDtcs()`: Returns all stored records including cleared/historical codes.
  * `getDtc(codeOrId)`: Direct lookup by DTC code (e.g. `"B1080"`) or identifier (e.g. `"HVAC_SENSOR_TIMEOUT"`).
  * `hasActiveFaults()`: Fast boolean status check.
  * `getPrimaryFaultSummary()`: Returns concise human-readable summary (e.g. `"Systems normal"` or `"HVAC sensor timeout"`).
* **Lifecycle & Clearing**:
  * `clearDtcs()`: Transitions all active DTCs to `INACTIVE`. Notifies observers.
  * `clearDtc(code)`: Clears a specific DTC.
  * **State Restoration**: Restores `VehicleStateManager` to nominal `PARKED` state and `CommunicationHealth::HEALTHY`, and instructs the HAL backend to reset fault modes (`"NONE"`).

---

## 5. Developer Fault Injection

Developers and test harnesses can trigger faults on demand:

1. **Programmatic / C++**:
   ```cpp
   diagnosticService->injectFault("HVAC_SENSOR_TIMEOUT");
   diagnosticService->injectFault("VEHICLE_DATA_TIMEOUT");
   diagnosticService->clearDtcs();
   ```
2. **ViewModel Invocables**:
   ```cpp
   vehicleViewModel->injectFault("HVAC_SENSOR_TIMEOUT");
   vehicleViewModel->clearFaults();
   ```
3. **Interactive UI**:
   The **Vehicle & Chassis** screen features a collapsible developer tool panel enabling one-touch fault injection and DTC clearing.

---

## 6. HMI Integration

DriveOS adheres to the principle of simplicity for the driver while offering accessible diagnostics for developers:

### Driver-Facing Experience
* **Nominal Condition**:
  * Top Health Badge: `🟢 SYSTEMS NORMAL`
  * Status line: `Status: ● Systems normal`
* **Fault Condition**:
  * Top Health Badge: `⚠️ FAULT: HVAC SENSOR TIMEOUT` (Ruby badge)
  * Contextual Banner: `Vehicle Status: ⚠ HVAC sensor timeout — Safe degraded mode active.`
  * Quick Recovery: A sleek `Clear DTCs` action button directly in the banner allows immediate recovery.

### Developer Debug Drawer
* Click **"DTC Tools ▼"** to expand the non-intrusive diagnostic panel.
* One-click trigger buttons for each prototype fault (`HVAC Timeout`, `Data Timeout`, `Door Fault`, `CAN Timeout`, `Invalid Signal`).
* Live active trouble code monitor showing code, identifier, and description.
* **Clear DTCs & Restore** button.

---

## 7. Recovery & Elimination of Stale State

The recovery flow ensures that clearing faults leaves zero residual or stale fault state:

```
Normal (PARKED, HEALTHY)
        │
        ▼ (Developer triggers fault)
Active Fault (FAULT/DEGRADED, Active DTC, UI Caution Banner)
        │
        ▼ (User/developer clicks "Clear DTCs")
Normal State Restored (PARKED, HEALTHY, 0 Active DTCs, "Systems normal")
```
