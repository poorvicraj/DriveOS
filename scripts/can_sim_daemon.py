#!/usr/bin/env python3
"""
DriveOS Autonomous CAN Vehicle Simulation Daemon.
Broadcasts cyclic CAN 2.0B frames onto a SocketCAN interface (e.g. vcan0)
strictly matching the signal layout defined in driveos.dbc.
"""

import sys
import time
import cantools
import can

def main():
    channel = sys.argv[1] if len(sys.argv) > 1 else 'vcan0'
    print(f"=== DriveOS CAN Daemon starting on {channel} ===")

    try:
        db = cantools.database.load_file('can/driveos.dbc')
    except Exception as e:
        print(f"Failed to load DBC: {e}")
        sys.exit(1)

    try:
        bus = can.interface.Bus(channel=channel, interface='socketcan')
    except Exception as e:
        print(f"Failed to open SocketCAN interface '{channel}': {e}")
        print("Falling back to simulated print loop (non-Linux or vcan0 absent).")
        bus = None

    speed = 0.0
    soc = 85.0
    range_km = 425
    cabin_temp = 22.0
    outside_temp = 18.5

    t0 = time.time()
    tick_count = 0

    try:
        while True:
            now = time.time()
            dt = now - t0
            t0 = now
            tick_count += 1

            # Simple kinematic cruise cycle: accelerate to 70 km/h, cruise, brake
            phase = (time.time() % 30)
            if phase < 10:
                speed = min(80.0, speed + 8.0 * dt)
                gear = 'DRIVE'
            elif phase < 22:
                speed = 75.0 + 3.0 * (time.time() % 2)
                gear = 'DRIVE'
            else:
                speed = max(0.0, speed - 15.0 * dt)
                gear = 'PARK' if speed == 0 else 'DRIVE'

            soc = max(10.0, soc - (0.01 * dt))
            range_km = int(soc * 5.0)

            # 1. Powertrain Status (Every 50ms - 20Hz)
            powertrain_msg = db.get_message_by_name('Powertrain_Status')
            powertrain_data = powertrain_msg.encode({
                'Vehicle_Speed': speed,
                'DriveMode': 'NORMAL',
                'Gear': gear
            })
            if bus:
                bus.send(can.Message(arbitration_id=powertrain_msg.frame_id, data=powertrain_data, is_extended_id=False))

            # 2. Battery Status (Every 100ms - 10Hz)
            if tick_count % 2 == 0:
                batt_msg = db.get_message_by_name('Battery_Status')
                batt_data = batt_msg.encode({
                    'Battery_SOC': soc,
                    'Vehicle_Range': range_km,
                    'ChargingState': 'DISCONNECTED',
                    'Battery_Temperature': 24.5
                })
                if bus:
                    bus.send(can.Message(arbitration_id=batt_msg.frame_id, data=batt_data, is_extended_id=False))

            # 3. Climate Status (Every 200ms - 5Hz)
            if tick_count % 4 == 0:
                climate_msg = db.get_message_by_name('Climate_Status')
                climate_data = climate_msg.encode({
                    'CabinTemperature': cabin_temp,
                    'OutsideTemperature': outside_temp,
                    'Climate_AC': 1,
                    'Climate_FanSpeed': 2,
                    'Climate_TargetTemp': 22.0
                })
                if bus:
                    bus.send(can.Message(arbitration_id=climate_msg.frame_id, data=climate_data, is_extended_id=False))

            # 4. Body Status (Every 200ms - 5Hz)
            if tick_count % 4 == 0:
                body_msg = db.get_message_by_name('Body_Status')
                body_data = body_msg.encode({
                    'Door_FL_Open': 0,
                    'Door_FR_Open': 0,
                    'Door_RL_Open': 0,
                    'Door_RR_Open': 0,
                    'Door_Locked': 1,
                    'ExteriorLights': 'AUTO'
                })
                if bus:
                    bus.send(can.Message(arbitration_id=body_msg.frame_id, data=body_data, is_extended_id=False))

            # 5. Vehicle Config (Every 200ms - 5Hz)
            if tick_count % 4 == 0:
                config_msg = db.get_message_by_name('Vehicle_Config')
                config_data = config_msg.encode({
                    'IgnitionState': 'ON',
                    'OperationalState': 'DRIVING' if speed > 0.1 else 'PARKED'
                })
                if bus:
                    bus.send(can.Message(arbitration_id=config_msg.frame_id, data=config_data, is_extended_id=False))

            time.sleep(0.05)

    except KeyboardInterrupt:
        print("\nCAN Simulation Daemon stopped.")

if __name__ == '__main__':
    main()
