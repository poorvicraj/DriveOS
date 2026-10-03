#!/usr/bin/env python3
"""
DriveOS DBC Validation Script using cantools.
Loads can/driveos.dbc, verifies message consistency, signal properties,
and runs encode/decode sanity checks against canonical telemetry values.
"""

import sys
import cantools

def main():
    print("=== Validating can/driveos.dbc with cantools ===")
    try:
        db = cantools.database.load_file('can/driveos.dbc')
    except Exception as e:
        print(f"FAILED: Could not load DBC file: {e}")
        return 1

    expected_messages = {
        0x100: "Powertrain_Status",
        0x101: "Battery_Status",
        0x200: "Climate_Status",
        0x201: "Climate_Command",
        0x300: "Body_Status",
        0x400: "Vehicle_Config",
        0x401: "Vehicle_Command"
    }

    print(f"Total messages loaded: {len(db.messages)}")
    for frame_id, name in expected_messages.items():
        try:
            msg = db.get_message_by_frame_id(frame_id)
            if msg.name != name:
                print(f"ERROR: Frame 0x{frame_id:03X} name mismatch: expected {name}, got {msg.name}")
                return 1
            print(f"  [OK] 0x{frame_id:03X} {msg.name} (length={msg.length} bytes, {len(msg.signals)} signals)")
        except KeyError:
            print(f"ERROR: Missing expected message 0x{frame_id:03X} ({name})")
            return 1

    # Test Vector 1: Powertrain Status
    pt_msg = db.get_message_by_name("Powertrain_Status")
    pt_data = pt_msg.encode({'Vehicle_Speed': 72.4, 'DriveMode': 'SPORT', 'Gear': 'DRIVE'})
    pt_dec = pt_msg.decode(pt_data)
    assert abs(pt_dec['Vehicle_Speed'] - 72.4) < 0.15, "Speed decode mismatch"
    assert pt_dec['DriveMode'] == 'SPORT', "DriveMode mismatch"
    assert pt_dec['Gear'] == 'DRIVE', "Gear mismatch"
    print("  [OK] Test Vector 1 (Powertrain_Status) verified")

    # Test Vector 2: Battery Status
    batt_msg = db.get_message_by_name("Battery_Status")
    batt_data = batt_msg.encode({
        'Battery_SOC': 84.5,
        'Vehicle_Range': 422,
        'ChargingState': 'CHARGING',
        'Battery_Temperature': 28.0
    })
    batt_dec = batt_msg.decode(batt_data)
    assert abs(batt_dec['Battery_SOC'] - 84.5) < 0.3, "SOC mismatch"
    assert batt_dec['Vehicle_Range'] == 422, "Range mismatch"
    assert batt_dec['ChargingState'] == 'CHARGING', "ChargingState mismatch"
    assert abs(batt_dec['Battery_Temperature'] - 28.0) < 0.5, "Battery temp mismatch"
    print("  [OK] Test Vector 2 (Battery_Status) verified")

    # Test Vector 3: Climate Status
    clim_msg = db.get_message_by_name("Climate_Status")
    clim_data = clim_msg.encode({
        'CabinTemperature': 22.5,
        'OutsideTemperature': 18.0,
        'Climate_AC': 1,
        'Climate_FanSpeed': 3,
        'Climate_TargetTemp': 21.5
    })
    clim_dec = clim_msg.decode(clim_data)
    assert abs(clim_dec['CabinTemperature'] - 22.5) < 0.3, "Cabin temp mismatch"
    assert abs(clim_dec['OutsideTemperature'] - 18.0) < 0.3, "Outside temp mismatch"
    assert clim_dec['Climate_AC'] in ('ON', 1), "AC mismatch"
    assert clim_dec['Climate_FanSpeed'] == 3, "Fan speed mismatch"
    assert abs(clim_dec['Climate_TargetTemp'] - 21.5) < 0.3, "Target temp mismatch"
    print("  [OK] Test Vector 3 (Climate_Status) verified")

    print("ALL DBC TEST VECTORS VALIDATED SUCCESSFULLY.")
    return 0

if __name__ == '__main__':
    sys.exit(main())
