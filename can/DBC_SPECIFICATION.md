# DriveOS CAN Database (DBC) Specification

This document defines the formal CAN 2.0B network message catalog for the DriveOS Digital Cockpit, matching [`can/driveos.dbc`](file:///d:/automotive/can/driveos.dbc).

All frames utilize standard 11-bit CAN identifiers, little-endian (Intel) byte ordering, and an 8-byte Data Length Code (DLC = 8).

---

## CAN Message Matrix Summary

| CAN ID (Hex) | CAN ID (Dec) | Message Name | Transmitter | DLC | Cycle Time | Description |
|---|---|---|---|---|---|---|
| `0x100` | 256 | `Powertrain_Status` | POWERTRAIN | 8 | 50 ms | Vehicle speed, drive mode, and transmission gear position |
| `0x101` | 257 | `Battery_Status` | POWERTRAIN | 8 | 100 ms | Battery state of charge, range estimation, charging, and temperature |
| `0x200` | 512 | `Climate_Status` | CLIMATE | 8 | 200 ms | Cabin and ambient temperatures, AC active status, and fan speed |
| `0x201` | 513 | `Climate_Command` | HMI | 8 | Event / 100 ms | HMI HVAC control setpoints (AC compressor, fan speed, target temp) |
| `0x300` | 768 | `Body_Status` | BODY | 8 | 200 ms | Door closure positions, central lock actuator status, exterior lights |
| `0x400` | 1024 | `Vehicle_Config` | BODY | 8 | 200 ms | Master ignition power state and operational lifecycle state |
| `0x401` | 1025 | `Vehicle_Command` | HMI | 8 | Event | HMI vehicle commands (driver dynamics mode, door lock/unlock) |

---

## Detailed Signal Breakdown

### 1. `0x100` — `Powertrain_Status` (256)
* **Transmitter**: Powertrain / Traction Inverter / VCU
* **Cycle Time**: 50 ms (20 Hz)
* **DLC**: 8

| Signal Name | Start Bit | Length | Byte Order | Value Type | Scaling (Factor) | Offset | Min | Max | Unit | Value Description |
|---|---|---|---|---|---|---|---|---|---|---|
| `Vehicle_Speed` | 0 | 16 | Little Endian | Unsigned | 0.1 | 0 | 0.0 | 250.0 | km/h | Longitudinal vehicle speed |
| `DriveMode` | 16 | 2 | Little Endian | Unsigned | 1.0 | 0 | 0 | 2 | — | `0` = ECO, `1` = NORMAL, `2` = SPORT |
| `Gear` | 18 | 2 | Little Endian | Unsigned | 1.0 | 0 | 0 | 3 | — | `0` = PARK, `1` = REVERSE, `2` = NEUTRAL, `3` = DRIVE |

---

### 2. `0x101` — `Battery_Status` (257)
* **Transmitter**: High-Voltage Battery Management System (BMS)
* **Cycle Time**: 100 ms (10 Hz)
* **DLC**: 8

| Signal Name | Start Bit | Length | Byte Order | Value Type | Scaling (Factor) | Offset | Min | Max | Unit | Value Description |
|---|---|---|---|---|---|---|---|---|---|---|
| `Battery_SOC` | 0 | 8 | Little Endian | Unsigned | 0.5 | 0 | 0.0 | 100.0 | % | Usable state of charge |
| `Vehicle_Range` | 8 | 16 | Little Endian | Unsigned | 1.0 | 0 | 0 | 800 | km | Estimated distance to empty |
| `ChargingState` | 24 | 3 | Little Endian | Unsigned | 1.0 | 0 | 0 | 4 | — | `0` = DISCONNECTED, `1` = CONNECTING, `2` = CHARGING, `3` = COMPLETE, `4` = ERROR |
| `Battery_Temperature` | 32 | 8 | Little Endian | Unsigned | 1.0 | -40 | -40.0 | 85.0 | degC | Battery pack temperature |

---

### 3. `0x200` — `Climate_Status` (512)
* **Transmitter**: HVAC / Climate Control Unit
* **Cycle Time**: 200 ms (5 Hz)
* **DLC**: 8

| Signal Name | Start Bit | Length | Byte Order | Value Type | Scaling (Factor) | Offset | Min | Max | Unit | Value Description |
|---|---|---|---|---|---|---|---|---|---|---|
| `CabinTemperature` | 0 | 8 | Little Endian | Unsigned | 0.5 | -20 | -20.0 | 50.0 | degC | Passenger cabin ambient temperature |
| `OutsideTemperature` | 8 | 8 | Little Endian | Unsigned | 0.5 | -40 | -40.0 | 60.0 | degC | External ambient temperature |
| `Climate_AC` | 16 | 1 | Little Endian | Unsigned | 1.0 | 0 | 0 | 1 | — | `0` = OFF, `1` = ON (Compressor active) |
| `Climate_FanSpeed` | 17 | 3 | Little Endian | Unsigned | 1.0 | 0 | 0 | 5 | — | `0` = Off, `1`..`5` = Blower level |
| `Climate_TargetTemp` | 24 | 8 | Little Endian | Unsigned | 0.5 | 0 | 16.0 | 28.0 | degC | Active cabin target temperature setpoint |

---

### 4. `0x201` — `Climate_Command` (513)
* **Transmitter**: HMI / Digital Cockpit
* **Cycle Time**: Event / 100 ms
* **DLC**: 8

| Signal Name | Start Bit | Length | Byte Order | Value Type | Scaling (Factor) | Offset | Min | Max | Unit | Value Description |
|---|---|---|---|---|---|---|---|---|---|---|
| `Climate_AC` | 0 | 1 | Little Endian | Unsigned | 1.0 | 0 | 0 | 1 | — | `0` = Request AC OFF, `1` = Request AC ON |
| `Climate_FanSpeed` | 1 | 3 | Little Endian | Unsigned | 1.0 | 0 | 0 | 5 | — | Desired fan speed level (0-5) |
| `Climate_TargetTemp` | 8 | 8 | Little Endian | Unsigned | 0.5 | 0 | 16.0 | 28.0 | degC | Desired cabin setpoint temperature |

---

### 5. `0x300` — `Body_Status` (768)
* **Transmitter**: Body Control Module (BCM)
* **Cycle Time**: 200 ms (5 Hz)
* **DLC**: 8

| Signal Name | Start Bit | Length | Byte Order | Value Type | Scaling (Factor) | Offset | Min | Max | Unit | Value Description |
|---|---|---|---|---|---|---|---|---|---|---|
| `Door_FL_Open` | 0 | 1 | Little Endian | Unsigned | 1.0 | 0 | 0 | 1 | — | `0` = Closed, `1` = Front Left Ajar |
| `Door_FR_Open` | 1 | 1 | Little Endian | Unsigned | 1.0 | 0 | 0 | 1 | — | `0` = Closed, `1` = Front Right Ajar |
| `Door_RL_Open` | 2 | 1 | Little Endian | Unsigned | 1.0 | 0 | 0 | 1 | — | `0` = Closed, `1` = Rear Left Ajar |
| `Door_RR_Open` | 3 | 1 | Little Endian | Unsigned | 1.0 | 0 | 0 | 1 | — | `0` = Closed, `1` = Rear Right Ajar |
| `Door_Locked` | 4 | 1 | Little Endian | Unsigned | 1.0 | 0 | 0 | 1 | — | `0` = Unlocked, `1` = All Doors Locked |
| `ExteriorLights` | 5 | 2 | Little Endian | Unsigned | 1.0 | 0 | 0 | 3 | — | `0` = OFF, `1` = AUTO, `2` = LOW_BEAM, `3` = HIGH_BEAM |

---

### 6. `0x400` — `Vehicle_Config` (1024)
* **Transmitter**: Central Gateway / Body Master
* **Cycle Time**: 200 ms (5 Hz)
* **DLC**: 8

| Signal Name | Start Bit | Length | Byte Order | Value Type | Scaling (Factor) | Offset | Min | Max | Unit | Value Description |
|---|---|---|---|---|---|---|---|---|---|---|
| `IgnitionState` | 0 | 2 | Little Endian | Unsigned | 1.0 | 0 | 0 | 2 | — | `0` = OFF, `1` = ACCESSORY, `2` = ON |
| `OperationalState` | 2 | 3 | Little Endian | Unsigned | 1.0 | 0 | 0 | 4 | — | `0` = PARKED, `1` = DRIVING, `2` = REVERSE, `3` = CHARGING, `4` = FAULT |

---

### 7. `0x401` — `Vehicle_Command` (1025)
* **Transmitter**: HMI / Digital Cockpit
* **Cycle Time**: Event
* **DLC**: 8

| Signal Name | Start Bit | Length | Byte Order | Value Type | Scaling (Factor) | Offset | Min | Max | Unit | Value Description |
|---|---|---|---|---|---|---|---|---|---|---|
| `Command_DriveMode` | 0 | 2 | Little Endian | Unsigned | 1.0 | 0 | 0 | 2 | — | `0` = Request ECO, `1` = Request NORMAL, `2` = Request SPORT |
| `Command_DoorLock` | 2 | 1 | Little Endian | Unsigned | 1.0 | 0 | 0 | 1 | — | `0` = Request Unlock, `1` = Request Central Lock |
