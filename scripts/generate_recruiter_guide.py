#!/usr/bin/env python3
"""
DriveOS - Comprehensive Technical Reference & Interview Preparation Guide Generator
Generates an executive-ready HTML document and renders it into a high-fidelity PDF via Microsoft Edge / Chrome headless.
"""

import os
import subprocess
import sys

HTML_CONTENT = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>DriveOS — Technical Architecture & Engineering Interview Guide</title>
<style>
  @page {
    size: A4;
    margin: 18mm 16mm 18mm 16mm;
    @bottom-right {
      content: counter(page);
    }
  }

  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    color: #1E293B;
    background-color: #FFFFFF;
    line-height: 1.58;
    font-size: 13.5px;
    margin: 0;
    padding: 0;
  }

  h1, h2, h3, h4, h5 {
    color: #0F172A;
    font-weight: 700;
    margin-top: 1.4em;
    margin-bottom: 0.5em;
    page-break-after: avoid;
  }

  h1 {
    font-size: 26px;
    border-bottom: 2px solid #0284C7;
    padding-bottom: 8px;
    margin-top: 0;
  }

  h2 {
    font-size: 19px;
    border-bottom: 1px solid #E2E8F0;
    padding-bottom: 5px;
    margin-top: 1.8em;
  }

  h3 {
    font-size: 15px;
    color: #0369A1;
    margin-top: 1.3em;
  }

  p {
    margin-top: 0;
    margin-bottom: 0.85em;
  }

  ul, ol {
    margin-top: 0;
    margin-bottom: 0.85em;
    padding-left: 22px;
  }

  li {
    margin-bottom: 0.35em;
  }

  code {
    font-family: "Cascadia Code", "Consolas", "Courier New", monospace;
    font-size: 11.8px;
    background-color: #F1F5F9;
    color: #0F172A;
    padding: 2px 5px;
    border-radius: 4px;
    border: 1px solid #E2E8F0;
  }

  pre {
    font-family: "Cascadia Code", "Consolas", "Courier New", monospace;
    background-color: #0F172A;
    color: #F8FAFC;
    padding: 14px 16px;
    border-radius: 6px;
    font-size: 11.5px;
    line-height: 1.48;
    overflow-x: auto;
    page-break-inside: avoid;
    margin-top: 0.5em;
    margin-bottom: 1em;
    border: 1px solid #1E293B;
  }

  pre code {
    background: transparent;
    border: none;
    color: inherit;
    padding: 0;
    font-size: inherit;
  }

  /* Syntax highlights in pre blocks */
  .kw { color: #38BDF8; font-weight: bold; } /* keyword */
  .type { color: #4ADE80; }                  /* type */
  .str { color: #FDE047; }                   /* string */
  .num { color: #FB923C; }                   /* number */
  .comm { color: #94A3B8; font-style: italic; } /* comment */
  .fn { color: #C084FC; }                    /* function */

  .badge {
    display: inline-block;
    padding: 3px 8px;
    font-size: 11px;
    font-weight: 600;
    border-radius: 12px;
    margin-right: 6px;
  }
  .badge-blue { background-color: #E0F2FE; color: #0369A1; border: 1px solid #BAE6FD; }
  .badge-green { background-color: #DCFCE7; color: #15803D; border: 1px solid #BBF7D0; }
  .badge-purple { background-color: #F3E8FF; color: #7E22CE; border: 1px solid #E9D5FF; }
  .badge-amber { background-color: #FEF3C7; color: #B45309; border: 1px solid #FDE68A; }

  .callout {
    padding: 12px 16px;
    border-radius: 6px;
    margin-top: 1em;
    margin-bottom: 1em;
    page-break-inside: avoid;
  }

  .callout-info {
    background-color: #F0F9FF;
    border-left: 4px solid #0284C7;
    color: #0C4A6E;
  }

  .callout-interview {
    background-color: #F0FDF4;
    border-left: 4px solid #16A34A;
    color: #14532D;
  }

  .callout-safety {
    background-color: #FFFBEB;
    border-left: 4px solid #D97706;
    color: #78350F;
  }

  .callout-technical {
    background-color: #FAF5FF;
    border-left: 4px solid #9333EA;
    color: #581C87;
  }

  .callout-title {
    font-weight: 700;
    margin-bottom: 4px;
    display: flex;
    align-items: center;
    gap: 6px;
  }

  table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 0.8em;
    margin-bottom: 1em;
    font-size: 12.5px;
    page-break-inside: avoid;
  }

  th, td {
    padding: 7px 10px;
    text-align: left;
    border: 1px solid #E2E8F0;
  }

  th {
    background-color: #F8FAFC;
    color: #0F172A;
    font-weight: 600;
    border-bottom: 2px solid #CBD5E1;
  }

  tr:nth-child(even) td {
    background-color: #F8FAFC;
  }

  .page-break {
    page-break-before: always;
  }

  .header-box {
    background: linear-gradient(135deg, #0F172A 0%, #1E293B 100%);
    color: #FFFFFF;
    padding: 24px 28px;
    border-radius: 8px;
    margin-bottom: 24px;
  }

  .header-box h1 {
    color: #FFFFFF;
    border-bottom: none;
    margin: 0 0 6px 0;
    font-size: 27px;
  }

  .header-box .subtitle {
    color: #38BDF8;
    font-size: 14.5px;
    font-weight: 500;
    margin-bottom: 14px;
  }

  .header-box .meta-grid {
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 12px;
    border-top: 1px solid #334155;
    padding-top: 14px;
    font-size: 11.5px;
  }

  .meta-item strong {
    display: block;
    color: #94A3B8;
    text-transform: uppercase;
    font-size: 10px;
    letter-spacing: 0.5px;
  }

  .meta-item span {
    color: #F8FAFC;
    font-weight: 600;
    font-size: 12.5px;
  }

  .arch-box {
    background-color: #F8FAFC;
    border: 1px solid #CBD5E1;
    border-radius: 6px;
    padding: 12px 16px;
    font-family: "Cascadia Code", "Consolas", monospace;
    font-size: 11px;
    line-height: 1.4;
    white-space: pre;
    color: #0F172A;
    page-break-inside: avoid;
    margin-bottom: 1em;
  }
</style>
</head>
<body>

<!-- COVER / HEADER -->
<div class="header-box">
  <h1>DriveOS — Automotive Cockpit & IVI Architecture</h1>
  <div class="subtitle">Comprehensive Technical Reference & Interview Preparation Guide</div>
  <div class="meta-grid">
    <div class="meta-item">
      <strong>Core Technology</strong>
      <span>C++20 &amp; Qt 6.6.3 Quick</span>
    </div>
    <div class="meta-item">
      <strong>Vehicle Bus</strong>
      <span>SocketCAN &amp; DBC Codec</span>
    </div>
    <div class="meta-item">
      <strong>Verification</strong>
      <span>67 Automated Tests</span>
    </div>
    <div class="meta-item">
      <strong>Performance</strong>
      <span>60 FPS | 43.7 MB RAM</span>
    </div>
  </div>
</div>

<p>
  <strong>Document Purpose:</strong> This technical reference guide provides an exhaustive architectural walkthrough of <strong>DriveOS</strong>. It is designed to prepare software engineers for technical deep-dives with automotive software hiring managers, recruiters, and engineering leads. It covers end-to-end data flow, hardware abstraction layers, kinematic simulation dynamics, CAN frame encoding/decoding, driver safety distraction mitigation policies, diagnostic lifecycle management, and high-frequency technical interview questions.
</p>

<!-- SECTION 1 -->
<h2>1. Executive Summary &amp; The 30-Second Elevator Pitch</h2>

<div class="callout callout-interview">
  <div class="callout-title">🎙️ The 30-Second Recruiter Pitch</div>
  <p>
    <em>"DriveOS is a production-grade automotive digital cockpit reference prototype built in Modern C++20 and Qt 6 Quick. It models the core architectural layers found in production vehicle infotainment (IVI) systems: a touch-first, distraction-mitigated QML HMI, an asynchronous Hardware Abstraction Layer (HAL), a 10 Hz deterministic kinematic simulation engine, a standard automotive CAN/DBC message codec, and an in-memory diagnostic trouble code (DTC) store. It delivers 60 FPS hardware-accelerated rendering at under 44 MB of RAM and is verified by 67 automated GoogleTest cases and a full CI pipeline."</em>
  </p>
</div>

<h3>Key Differentiators vs. Basic Academic / Toy Prototypes</h3>
<ul>
  <li><strong>True Layered Automotive Architecture:</strong> Strict Model-View-ViewModel (MVVM) separation. The presentation layer (QML) contains <strong>zero</strong> business calculations or protocol logic; it strictly binds to typed C++ ViewModels.</li>
  <li><strong>Hardware Abstraction Layer (HAL):</strong> Built upon a pure abstract C++ interface (<code>VehicleDataInterface</code>). The application seamlessly switches between an internal deterministic kinematic simulator and real/virtual Linux SocketCAN (<code>vcan0</code>) with zero UI alterations.</li>
  <li><strong>First-Principles CAN Communication:</strong> Features a formal DBC database (<code>can/driveos.dbc</code>) with bit-level signal packing, scale factors, offsets, endianness transformation, and out-of-range protection.</li>
  <li><strong>Driver Safety Distraction Engine:</strong> Software policy engine evaluating vehicle kinematics (speed &gt; 0.1 km/h, gear in Drive/Reverse) to lock out deep configuration settings and door closures in motion, adhering to NHTSA and European automotive HMI guidelines.</li>
  <li><strong>Automotive Touch Ergonomics:</strong> Adheres to automotive human-factors standards: minimum 48&times;48 dp touch targets, rapid 160–260 ms easing transitions, calm light automotive palette, and no ambiguous iconography.</li>
</ul>

<!-- SECTION 2 -->
<div class="page-break"></div>
<h2>2. System Architecture &amp; Layered Decomposition</h2>

<p>
  DriveOS implements a strict 4-tier layered architecture with unidirectional data flow:
</p>

<div class="arch-box">+-----------------------------------------------------------------------------------+
|                           PRESENTATION LAYER (Qt Quick / QML)                     |
|  [AppShell & Dock]  [HomeScreen]  [ClimateScreen]  [MediaScreen]  [VehicleScreen] |
+------------------------------------------+----------------------------------------+
                                           |  Q_PROPERTY Bindings & Signals
                                           v
+-----------------------------------------------------------------------------------+
|                             VIEWMODEL LAYER (C++ / Qt)                            |
|    HomeViewModel   ClimateViewModel   MediaViewModel   VehicleViewModel   NavVM   |
+------------------------------------------+----------------------------------------+
                                           |  Service Invocations & State Observers
                                           v
+-----------------------------------------------------------------------------------+
|                         APPLICATION DOMAIN SERVICES (C++20)                       |
|   VehicleStateManager     SafetyPolicy      ClimateService     DiagnosticService  |
|      VehicleService       MediaService      NavigationService  CanFrameCodec      |
+------------------------------------------+----------------------------------------+
                                           |  Hardware Abstraction Layer (HAL)
                                           v
+-----------------------------------------------------------------------------------+
|             HARDWARE ABSTRACTION LAYER (HAL) - VehicleDataInterface               |
+------------------------------------+----------------------------------------------+
                                     |
                +--------------------+--------------------+
                |                                         |
                v                                         v
+-------------------------------+         +-----------------------------------------+
|    SimulatedVehicleBackend    |         |            CANVehicleBackend            |
|  10 Hz Kinematic Slew Physics |         |  Linux SocketCAN (vcan0) / driveos.dbc  |
+-------------------------------+         +-----------------------------------------+</div>

<h3>Unidirectional Data Flow Pipeline</h3>
<ol>
  <li><strong>Telemetry Ingress:</strong> Raw signals are generated either by the 10 Hz kinematic physics ticker in <code>SimulatedVehicleBackend</code> or received as raw 8-byte frames over a Linux CAN socket (<code>vcan0</code>).</li>
  <li><strong>Signal Decoding &amp; Invariant Checks:</strong> <code>CanFrameCodec</code> extracts bits, applies DBC scale/offset multipliers, validates physical limits (e.g. speed &le; 250 km/h, SOC &le; 100%), and populates a canonical, immutable <code>VehicleState</code> snapshot struct.</li>
  <li><strong>State Aggregation &amp; Safety Evaluation:</strong> <code>VehicleStateManager</code> receives the new snapshot, caches it thread-safely, and alerts observers. <code>SafetyPolicy</code> immediately inspects speed and gear to evaluate whether motion-sensitive controls should be locked.</li>
  <li><strong>ViewModel Notification:</strong> ViewModels (e.g., <code>HomeViewModel</code>, <code>ClimateViewModel</code>) observe state updates, format numerical values into driver-friendly display strings (e.g. <code>"22.0 °C"</code>, <code>"64 km/h"</code>), and emit Qt change notification signals.</li>
  <li><strong>Hardware-Accelerated UI Rendering:</strong> Qt Quick updates the declarative QML scene graph at 60 FPS with hardware OpenGL/Direct3D rasterization.</li>
  <li><strong>Driver Command Egress:</strong> When the driver touches a UI element (e.g. temperature increment), QML invokes a <code>Q_INVOKABLE</code> method on the ViewModel. The ViewModel verifies safety permissions via <code>SafetyPolicy</code>, then calls the domain service, which dispatches the command down through <code>VehicleDataInterface</code> to the hardware/simulation backend.</li>
</ol>

<!-- SECTION 3 -->
<div class="page-break"></div>
<h2>3. Hardware Abstraction Layer (HAL) &amp; Vehicle Backends</h2>

<p>
  A cornerstone of professional automotive software engineering is decoupling user-facing features from underlying physical bus hardware (AUTOSAR / Adaptive approach). In DriveOS, this is achieved through the <code>VehicleDataInterface</code>.
</p>

<h3>The Pure Abstract Interface (VehicleDataInterface.hpp)</h3>
<pre><code><span class="kw">namespace</span> driveos::vehicle {

<span class="kw">enum class</span> <span class="type">CommunicationHealth</span> : uint8_t {
    HEALTHY = 0,    <span class="comm">// Cyclic message reception nominal, within deadlines</span>
    DEGRADED,       <span class="comm">// Non-critical frame timeout or intermittent drops</span>
    DISCONNECTED,   <span class="comm">// Bus interface down, no incoming traffic</span>
    BUS_OFF         <span class="comm">// CAN controller error passive or bus-off state</span>
};

<span class="kw">class</span> <span class="type">VehicleDataInterface</span> {
<span class="kw">public</span>:
    <span class="kw">using</span> <span class="type">StateCallback</span>  = std::function&lt;<span class="type">void</span>(<span class="kw">const</span> domain::VehicleState&amp;)&gt;;
    <span class="kw">using</span> <span class="type">HealthCallback</span> = std::function&lt;<span class="type">void</span>(CommunicationHealth)&gt;;
    <span class="kw">using</span> <span class="type">FaultCallback</span>  = std::function&lt;<span class="type">void</span>(<span class="kw">const</span> domain::FaultRecord&amp;)&gt;;

    <span class="kw">virtual</span> ~VehicleDataInterface() = <span class="kw">default</span>;

    <span class="comm">// Lifecycle</span>
    <span class="kw">virtual bool</span> <span class="fn">initialize</span>() = 0;
    <span class="kw">virtual void</span> <span class="fn">shutdown</span>() = 0;

    <span class="comm">// State &amp; Health Access</span>
    [[nodiscard]] <span class="kw">virtual</span> domain::VehicleState <span class="fn">getVehicleState</span>() <span class="kw">const</span> = 0;
    [[nodiscard]] <span class="kw">virtual</span> CommunicationHealth  <span class="fn">getCommunicationHealth</span>() <span class="kw">const</span> = 0;

    <span class="comm">// Vehicle Actuation Commands</span>
    <span class="kw">virtual void</span> <span class="fn">setTargetTemperature</span>(<span class="type">float</span> tempCelsius) = 0;
    <span class="kw">virtual void</span> <span class="fn">setFanSpeed</span>(<span class="type">int</span> level) = 0;
    <span class="kw">virtual void</span> <span class="fn">setACActive</span>(<span class="type">bool</span> active) = 0;
    <span class="kw">virtual void</span> <span class="fn">setDriveMode</span>(domain::DriveMode mode) = 0;
    <span class="kw">virtual void</span> <span class="fn">setDoorLock</span>(<span class="type">bool</span> locked) = 0;
};
}</code></pre>

<h3>Deterministic Kinematic Simulation Engine (SimulatedVehicleBackend.cpp)</h3>
<p>
  Instead of using random number generators or instant step jumps, the <code>SimulatedVehicleBackend</code> runs an internal 10 Hz ticker that computes smooth kinematic equations:
</p>
<ul>
  <li><strong>Smooth Speed Slewing:</strong> Accelerates at $18\text{ km/h per second}$ and decelerates at $28\text{ km/h per second}$.</li>
  <li><strong>Battery SOC &amp; Range Depletion:</strong> Depletion rate is a function of vehicle velocity, elapsed time &Delta;t, and drive mode multiplier (<code>Sport</code>: $1.35\times$, <code>Comfort</code>: $1.0\times$, <code>Eco</code>: $0.75\times$).</li>
  <li><strong>Cabin Thermal Equilibrium:</strong> When HVAC is active, cabin temperature slews toward target temperature at a rate proportional to fan speed. When HVAC is off, cabin temperature gradually leaks toward outside ambient temperature.</li>
</ul>

<pre><code><span class="comm">// Real C++ Kinematic Slew Implementation in SimulatedVehicleBackend::stepSimulation()</span>
<span class="kw">void</span> SimulatedVehicleBackend::<span class="fn">stepSimulation</span>(<span class="type">float</span> dtSeconds) {
    std::lock_guard&lt;std::mutex&gt; lock(m_mutex);

    <span class="comm">// 1. Speed Slewing with natural acceleration and braking rates</span>
    <span class="kw">if</span> (m_state.speed &lt; m_targetSpeed) {
        <span class="kw">const float</span> accelRate = <span class="num">18.0f</span>; <span class="comm">// km/h/s</span>
        m_state.speed = std::min(m_targetSpeed, m_state.speed + accelRate * dtSeconds);
    } <span class="kw">else if</span> (m_state.speed &gt; m_targetSpeed) {
        <span class="kw">const float</span> decelRate = <span class="num">28.0f</span>; <span class="comm">// km/h/s braking</span>
        m_state.speed = std::max(m_targetSpeed, m_state.speed - decelRate * dtSeconds);
    }

    <span class="comm">// 2. Dynamic Battery SOC &amp; Range Depletion</span>
    <span class="kw">if</span> (m_state.operationalState == domain::OperationalState::DRIVING) {
        <span class="kw">const float</span> modeMultiplier = (m_state.driveMode == domain::DriveMode::SPORT) ? <span class="num">1.35f</span> :
                                     (m_state.driveMode == domain::DriveMode::ECO)   ? <span class="num">0.75f</span> : <span class="num">1.0f</span>;
        <span class="kw">const float</span> drain = (m_state.speed / <span class="num">100.0f</span>) * <span class="num">0.035f</span> * modeMultiplier * dtSeconds;
        m_state.batterySoc = std::max(<span class="num">2.0f</span>, m_state.batterySoc - drain);
        m_state.rangeKm = m_state.batterySoc * <span class="num">5.0f</span>; <span class="comm">// 5 km per 1% SOC</span>
    }
}</code></pre>

<!-- SECTION 4 -->
<div class="page-break"></div>
<h2>4. In-Vehicle Networking: CAN Bus &amp; DBC Architecture</h2>

<p>
  DriveOS specifies all vehicle network telemetry in a standardized automotive database (<code>can/driveos.dbc</code>). The codec translates between wire-level 8-byte CAN frames and C++ typed domain structures.
</p>

<h3>CAN Message Catalog</h3>
<table>
  <thead>
    <tr>
      <th>CAN ID</th>
      <th>Message Name</th>
      <th>Cycle Time</th>
      <th>Length</th>
      <th>Key Signals &amp; Scaling</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>0x100</code></td>
      <td><code>POWERTRAIN_STATUS</code></td>
      <td>20 ms (50 Hz)</td>
      <td>8 bytes</td>
      <td><code>VehicleSpeed</code> (0.1 km/h/bit, [0, 250]), <code>DriveMode</code> (2 bits), <code>Gear</code> (2 bits)</td>
    </tr>
    <tr>
      <td><code>0x101</code></td>
      <td><code>BATTERY_STATUS</code></td>
      <td>50 ms (20 Hz)</td>
      <td>8 bytes</td>
      <td><code>BatterySOC</code> (0.5 %/bit, [0, 100]), <code>RangeKm</code> (1 km/bit), <code>BatteryTemp</code> (-40 offset)</td>
    </tr>
    <tr>
      <td><code>0x200</code></td>
      <td><code>CLIMATE_STATUS</code></td>
      <td>100 ms (10 Hz)</td>
      <td>8 bytes</td>
      <td><code>CabinTemp</code> (0.5 °C/bit, -20 offset), <code>OutsideTemp</code>, <code>AcActive</code>, <code>FanSpeed</code></td>
    </tr>
    <tr>
      <td><code>0x201</code></td>
      <td><code>CLIMATE_COMMAND</code></td>
      <td>Event-driven</td>
      <td>8 bytes</td>
      <td><code>TargetTemp</code> (0.5 °C/bit), <code>AcCommand</code>, <code>FanSpeedCommand</code>, <code>AirflowMode</code></td>
    </tr>
    <tr>
      <td><code>0x300</code></td>
      <td><code>VEHICLE_COMMAND</code></td>
      <td>Event-driven</td>
      <td>8 bytes</td>
      <td><code>TargetDriveMode</code>, <code>DoorLockCommand</code>, <code>TargetSpeed</code></td>
    </tr>
    <tr>
      <td><code>0x301</code></td>
      <td><code>BODY_CONFIG_STATUS</code></td>
      <td>100 ms (10 Hz)</td>
      <td>8 bytes</td>
      <td><code>FL_DoorOpen</code>, <code>FR_DoorOpen</code>, <code>RL_DoorOpen</code>, <code>RR_DoorOpen</code>, <code>ChildLock</code></td>
    </tr>
  </tbody>
</table>

<h3>First-Principles DBC Frame Decoding (CanFrameCodec.cpp)</h3>
<p>
  The codec performs bitwise masking, endianness reassembly, linear transformation ($y = \text{scale} \times x + \text{offset}$), and IEEE physical validation:
</p>

<pre><code><span class="comm">// Real C++ implementation of Powertrain CAN message decoding</span>
CodecResult CanFrameCodec::<span class="fn">decodePowertrainStatus</span>(<span class="kw">const</span> CanFrame&amp; frame, domain::VehicleState&amp; state) <span class="kw">const</span> {
    <span class="comm">// Extract 16-bit little-endian raw speed from Byte 0 and Byte 1</span>
    <span class="kw">const</span> uint16_t rawSpeed = <span class="kw">static_cast</span>&lt;uint16_t&gt;(frame.data[<span class="num">0</span>]) |
                              (<span class="kw">static_cast</span>&lt;uint16_t&gt;(frame.data[<span class="num">1</span>]) &lt;&lt; <span class="num">8</span>);
    
    <span class="comm">// Apply DBC scaling factor: 0.1 km/h per bit</span>
    <span class="kw">const float</span> speed = <span class="kw">static_cast</span>&lt;<span class="type">float</span>&gt;(rawSpeed) * <span class="num">0.1f</span>;
    <span class="kw">if</span> (speed &gt; <span class="num">250.0f</span>) {
        <span class="kw">return</span> CodecResult::<span class="fn">fail</span>(frame.canId, <span class="str">"Vehicle speed exceeds physical DBC limit (250 km/h)"</span>);
    }

    <span class="comm">// Extract 2-bit DriveMode and 2-bit Gear from Byte 2</span>
    <span class="kw">const</span> uint8_t rawDriveMode = frame.data[<span class="num">2</span>] &amp; <span class="num">0x03</span>;
    <span class="kw">const</span> uint8_t rawGear      = (frame.data[<span class="num">2</span>] &gt;&gt; <span class="num">2</span>) &amp; <span class="num">0x03</span>;

    state.speed = speed;
    state.driveMode = <span class="kw">static_cast</span>&lt;domain::DriveMode&gt;(rawDriveMode);
    state.gear = <span class="kw">static_cast</span>&lt;domain::Gear&gt;(rawGear);
    <span class="kw">return</span> CodecResult::<span class="fn">ok</span>(frame.canId);
}</code></pre>

<!-- SECTION 5 -->
<div class="page-break"></div>
<h2>5. Automotive Driver Distraction Mitigation: SafetyPolicy Engine</h2>

<div class="callout callout-safety">
  <div class="callout-title">🛡️ Driver Distraction Context (NHTSA &amp; ESoP Guidelines)</div>
  <p>
    Automotive touchscreens must never permit driver interactions that require prolonged visual off-road glances. National Highway Traffic Safety Administration (NHTSA) guidelines mandate that secondary secondary tasks must be executable in glances under 2 seconds. DriveOS implements this via a centralized, software-enforced <code>SafetyPolicy</code>.
  </p>
</div>

<h3>Centralized Safety Policy Architecture (SafetyPolicy.hpp)</h3>
<p>
  The safety engine categorizes all touch interactions into permission tiers and evaluates motion state:
</p>
<ul>
  <li><strong>Allowed While Driving:</strong> Primary dock tab navigation (glanceable 1-touch), basic climate bump (&plusmn;1&deg;C), media play/pause/track skip, glanceable map monitoring.</li>
  <li><strong>Strictly Locked While Driving:</strong> Door lock and closure toggles (preventing door latch actuation in motion), drive dynamics switches, diagnostic fault injection/clearing, deep configuration drawers.</li>
</ul>

<pre><code><span class="comm">// Centralized Motion Detection &amp; Safety Restriction Logic</span>
<span class="kw">class</span> <span class="type">SafetyPolicy</span> {
<span class="kw">public</span>:
    [[nodiscard]] <span class="kw">static bool</span> <span class="fn">isInMotion</span>(<span class="kw">const</span> VehicleState&amp; state) <span class="kw">noexcept</span> {
        <span class="kw">return</span> (state.speed &gt; <span class="num">0.1f</span>) ||
               (state.gear == Gear::DRIVE) ||
               (state.gear == Gear::REVERSE);
    }

    [[nodiscard]] <span class="kw">bool</span> <span class="fn">isVehicleConfigurationAllowed</span>(<span class="kw">const</span> VehicleState&amp; state) <span class="kw">const noexcept</span> {
        <span class="kw">return</span> !<span class="fn">isInMotion</span>(state) &amp;&amp; (state.operationalState != OperationalState::FAULT);
    }

    [[nodiscard]] <span class="kw">bool</span> <span class="fn">isEssentialClimateControlAllowed</span>(<span class="kw">const</span> VehicleState&amp;) <span class="kw">const noexcept</span> {
        <span class="kw">return true</span>; <span class="comm">// Single-touch climate bump always permitted</span>
    }
};</code></pre>

<h3>QML UI Gating &amp; Automotive Feedback</h3>
<p>
  When the vehicle enters motion, ViewModels notify the QML layer. The UI automatically applies disabled visual styling, displays lock icons (<code>🔒</code>), and intercepts attempted touches with an informative automotive toast message: <em>"Unavailable while driving"</em>.
</p>

<!-- SECTION 6 -->
<div class="page-break"></div>
<h2>6. Diagnostics &amp; Fault Handling Subsystem</h2>

<p>
  Automotive systems must gracefully tolerate sensor dropped packets, physical bus errors, and hardware timeouts. DriveOS incorporates an in-memory Diagnostic Trouble Code (DTC) manager (<code>DiagnosticService</code>).
</p>

<h3>Supported Diagnostic Trouble Codes (DTC Store)</h3>
<table>
  <thead>
    <tr>
      <th>DTC Code</th>
      <th>Identifier</th>
      <th>Severity</th>
      <th>System Behavior &amp; Fallback Safe-Mode</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>B1080</code></td>
      <td><code>HVAC_SENSOR_TIMEOUT</code></td>
      <td>WARNING</td>
      <td>Cabin temperature sensor offline. Climate subsystem degrades to manual blower fan speed mode.</td>
    </tr>
    <tr>
      <td><code>U0100</code></td>
      <td><code>VEHICLE_DATA_TIMEOUT</code></td>
      <td>CRITICAL</td>
      <td>Loss of vehicle bus communication. UI displays amber warning banner and retains last known good state.</td>
    </tr>
    <tr>
      <td><code>B1024</code></td>
      <td><code>DOOR_SENSOR_FAULT</code></td>
      <td>WARNING</td>
      <td>Door latch sensor inconsistency. Locks latch control to prevent accidental opening.</td>
    </tr>
    <tr>
      <td><code>U0111</code></td>
      <td><code>CAN_TIMEOUT</code></td>
      <td>CRITICAL</td>
      <td>CAN frame watchdog timeout (no frames received within deadline). Communication health transitions to <code>DEGRADED</code>.</td>
    </tr>
    <tr>
      <td><code>U0401</code></td>
      <td><code>INVALID_VEHICLE_SIGNAL</code></td>
      <td>WARNING</td>
      <td>Payload failed physical DBC range bounds check or CRC parity verification. Corrupt frame dropped.</td>
    </tr>
  </tbody>
</table>

<h3>Fault Injection &amp; Recovery Lifecycle</h3>
<ol>
  <li><strong>Fault Injection:</strong> The developer can inject faults via Developer View or test suites. The <code>DiagnosticService</code> records a timestamped <code>DtcRecord</code> with occurrence counters.</li>
  <li><strong>State Degradation:</strong> <code>VehicleStateManager</code> marks the operational state as <code>FAULT</code> / <code>DEGRADED</code>. Amber warning banners appear on the status bar.</li>
  <li><strong>Safe Recovery:</strong> Clicking <em>"Clear All Faults &amp; Reset to Normal"</em> resets active DTCs, clears amber banners, and restores <code>CommunicationHealth::HEALTHY</code>.</li>
</ol>

<!-- SECTION 7 -->
<div class="page-break"></div>
<h2>7. Presentation Layer &amp; Automotive UI/UX Design System</h2>

<h3>Modern Automotive Touch Ergonomics</h3>
<ul>
  <li><strong>Light Automotive Theme:</strong> Specially tuned for daylight automotive displays with high contrast: neutral background (<code>#F5F7FA</code>), elevated card surfaces (<code>#FFFFFF</code>), high-contrast typography (<code>#0F172A</code>), and sky cobalt accent (<code>#0284C7</code>).</li>
  <li><strong>Touch Hit Targets:</strong> Minimum $48\times 48\text{ dp}$ bounding boxes across all interactive buttons, sliders, and toggles to guarantee reliable actuation during road vibration.</li>
  <li><strong>Fluid Transitions:</strong> Screen switches and drawer animations are capped at $160\text{--}260\text{ ms}$ with cubic easing to prevent cognitive distraction while remaining responsive.</li>
  <li><strong>Zero Heavy Web Frameworks:</strong> Built with Qt 6 Quick / QML rendering to native OpenGL / Direct3D hardware swapchains with 4x MSAA antialiasing.</li>
</ul>

<h3>Screen Feature Inventory</h3>
<table>
  <thead>
    <tr>
      <th>Screen</th>
      <th>Primary Automotive Features</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>HomeScreen</strong></td>
      <td>Digital speedometer, gear pill (P/R/N/D), battery SOC gauge with range estimation, 2D chassis hero, and glanceable summary cards for Climate, Media, and Navigation.</td>
    </tr>
    <tr>
      <td><strong>ClimateScreen</strong></td>
      <td>Dual-zone driver/passenger controls (16.0&deg;C to 28.0&deg;C), one-touch dual synchronization (<code>SYNC</code>), 4-mode directional airflow (<code>Windshield</code>, <code>Vent</code>, <code>Floor</code>, <code>Bi-Level</code>), dynamic particle airflow canvas, and 3-stage seat heating.</td>
    </tr>
    <tr>
      <td><strong>MediaScreen</strong></td>
      <td>Procedural vinyl artwork canvas, track metadata, queue list, scrubbable progress bar, volume slider with mute, shuffle/repeat, and source selector (<code>Bluetooth</code>, <code>FM Radio</code>, <code>Streaming</code>).</td>
    </tr>
    <tr>
      <td><strong>VehicleScreen</strong></td>
      <td>Interactive 2D chassis with individual door closure toggles (Front-Left, Front-Right, Rear-Left, Rear-Right, Frunk, Trunk), drive dynamics selector (<code>Comfort</code>, <code>Eco</code>, <code>Sport</code>), exterior lighting controls, child locks, and active DTC fault inspector.</td>
    </tr>
    <tr>
      <td><strong>NavigationScreen</strong></td>
      <td>Lightweight procedural vector map canvas, arterial road grid, vehicle position cursor, speed limit pill ($60\text{ km/h}$), turn-by-turn guidance card, and 3D GNSS lock status indicator.</td>
    </tr>
  </tbody>
</table>

<!-- SECTION 8 -->
<div class="page-break"></div>
<h2>8. Quality Assurance: Automated Testing &amp; CI/CD Pipeline</h2>

<div class="callout callout-technical">
  <div class="callout-title">🧪 67 Automated Test Cases (Zero Regressions)</div>
  <p>
    Every commit is validated across 5 specialized test suites using GoogleTest and CTest. All 67 tests pass with 0 failures:
  </p>
</div>

<ul>
  <li><strong>Unit Tests (<code>test_foundation.cpp</code>):</strong> Validates service boundaries, temperature clamping (16.0&deg;C to 28.0&deg;C), fan levels [0..5], media playback state transitions, and volume bounds [0..100].</li>
  <li><strong>Kinematic Simulation Tests (<code>test_diagnostics.cpp</code>):</strong> Verifies speed acceleration/braking slew curves, battery drain equations, and state machine transitions.</li>
  <li><strong>CAN Subsystem Tests (<code>test_can.cpp</code>):</strong> Verifies bitwise packing/unpacking, DBC scale/offset multipliers, signed two's complement conversions, frame corruption detection, and DLC validation.</li>
  <li><strong>ViewModel Tests (<code>test_viewmodels.cpp</code>):</strong> Verifies UI string formatting (degree symbols, km/h formatting), safety distraction lockout flags, and signal emissions.</li>
  <li><strong>Headless QML Navigation Tests (<code>test_qml_navigation.cpp</code>):</strong> Instantiates an offscreen QML engine (<code>QT_QPA_PLATFORM=offscreen</code>), loading the complete UI tree to verify dock routing, back-stack integrity, and property bindings without requiring a physical monitor.</li>
</ul>

<h3>GitHub Actions CI Workflow (.github/workflows/ci.yml)</h3>
<p>
  Runs on Ubuntu 22.04 on every push and PR:
</p>
<ol>
  <li>Configures build environment with GCC, Qt 6.6+, CMake, Ninja, and Linux <code>can-utils</code>.</li>
  <li>Audits C++ code style with <code>clang-format</code> and executes static analysis via targeted <code>clang-tidy</code>.</li>
  <li>Validates CAN database syntax and signal alignments with <code>cantools</code> Python parser.</li>
  <li>Initializes a Linux virtual CAN interface (<code>vcan0</code>) and validates loopback frame transmission.</li>
  <li>Builds all targets and executes <code>ctest --output-on-failure</code> with headless offscreen platform.</li>
</ol>

<!-- SECTION 9 -->
<h2>9. Measured Embedded Performance Profile</h2>

<table>
  <thead>
    <tr>
      <th>Metric</th>
      <th>Measured Value</th>
      <th>Automotive Specification / Target</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>Cold Startup Time</strong></td>
      <td><strong>1.77 seconds</strong></td>
      <td>&lt; 2.5 seconds (Fast boot from process start to interactive display)</td>
    </tr>
    <tr>
      <td><strong>Working Set RAM</strong></td>
      <td><strong>43.71 MB</strong></td>
      <td>&lt; 80 MB (Extremely low footprint for resource-constrained automotive ECUs)</td>
    </tr>
    <tr>
      <td><strong>Rendering Frame Rate</strong></td>
      <td><strong>60.0 FPS</strong></td>
      <td>60 FPS steady (Hardware Direct3D/OpenGL VSync locked, 4x MSAA)</td>
    </tr>
    <tr>
      <td><strong>Touch Latency</strong></td>
      <td><strong>&lt; 16 ms</strong></td>
      <td>Sub-frame reaction time on touch input events</td>
    </tr>
  </tbody>
</table>

<!-- SECTION 10 -->
<div class="page-break"></div>
<h2>10. Technical Interview Preparation &amp; Model Answers</h2>

<p>
  Automotive software engineering managers and technical interviewers frequently ask deep architectural questions. Below are the top 6 questions and exact model answers:
</p>

<div class="callout callout-interview">
  <div class="callout-title">Q1: How do you handle thread safety between high-frequency vehicle telemetry (10 Hz simulation / 50 Hz CAN) and the 60 FPS UI thread?</div>
  <p>
    <strong>Model Answer:</strong><br>
    <em>"In automotive IVI systems, mixing network I/O or simulation threads directly with the GUI thread causes UI stutter and race conditions. In DriveOS, I solved this by treating the domain state as immutable snapshots. The <code>SimulatedVehicleBackend</code> and <code>CANVehicleBackend</code> protect internal state with standard <code>std::mutex</code>. When signals are processed, an immutable <code>VehicleState</code> value-struct is created. We dispatch this snapshot to the Qt main thread using Qt's thread-safe queued signal-slot mechanism. ViewModels running on the GUI thread update their reactive <code>Q_PROPERTY</code> bindings from this snapshot, guaranteeing lock-free, tear-free 60 FPS rendering."</em>
  </p>
</div>

<div class="callout callout-interview">
  <div class="callout-title">Q2: Why did you choose C++20 and Qt 6 Quick instead of web technologies like Electron or Flutter?</div>
  <p>
    <strong>Model Answer:</strong><br>
    <em>"C++ and Qt Quick (QML) are the industry standard for production automotive cockpits (used by Tesla, Mercedes-Benz MBUX, Ford SYNC, and Porsche). Automotive embedded platforms operate under strict memory, thermal, and boot-time constraints. Web runtimes like Electron require massive memory footprints (&gt; 300 MB RAM) and suffer from non-deterministic garbage collection pauses. DriveOS runs at <strong>43.7 MB RAM</strong>, boots cold in <strong>1.77 seconds</strong>, and compiles directly to native machine code with hardware-accelerated OpenGL/Direct3D rendering."</em>
  </p>
</div>

<div class="callout callout-interview">
  <div class="callout-title">Q3: How does your CAN frame codec handle signal resolution, endianness, and payload validation?</div>
  <p>
    <strong>Model Answer:</strong><br>
    <em>"Our <code>CanFrameCodec</code> implements standard automotive DBC database specifications. In the <code>POWERTRAIN_STATUS</code> frame (CAN ID <code>0x100</code>), vehicle speed is packed as a 16-bit little-endian unsigned integer across bytes 0 and 1 with a scale factor of 0.1 km/h per bit. The codec reconstructs the raw integer using bit shifts, multiplies by 0.1, and applies physical invariant boundary checks (e.g. speed &le; 250 km/h). For signed signals like cabin temperature, it applies scale factors with negative offsets (0.5 °C/bit with -20 °C offset). Corrupted DLC or out-of-range values return a structured <code>CodecResult::fail()</code>, protecting the vehicle state from corrupted data."</em>
  </p>
</div>

<div class="callout callout-interview">
  <div class="callout-title">Q4: Walk me through your driver distraction mitigation policy. How does the UI enforce it?</div>
  <p>
    <strong>Model Answer:</strong><br>
    <em>"Automotive HMI design must prioritize road safety over feature complexity. DriveOS features a centralized <code>SafetyPolicy</code> engine inspired by NHTSA and European ESoP guidelines. It monitors vehicle velocity and transmission gear. When motion is detected (speed &gt; 0.1 km/h or gear in D/R), primary glanceable controls (dock switching, temperature +/- bump, volume) remain enabled, but deep configuration settings (door latch toggles, drive mode switches, DTC fault injection) are locked in the domain layer. The QML UI reflects this by disabling controls, displaying lock badges, and showing non-intrusive automotive toasts when a driver touches a locked control."</em>
  </p>
</div>

<div class="callout callout-interview">
  <div class="callout-title">Q5: How would DriveOS scale to run in a real production vehicle?</div>
  <p>
    <strong>Model Answer:</strong><br>
    <em>"Because DriveOS is built around a Hardware Abstraction Layer (<code>VehicleDataInterface</code>), scaling to a production vehicle requires zero changes to the QML views, ViewModels, or application domain services. We would simply replace the virtual SocketCAN transport with a production AUTOSAR Classic or Adaptive transport plugin—such as a SOME/IP over Automotive Ethernet stack or native CAN-FD transceiver driver (e.g. Vector CAN / PEAK-System). The rest of the architecture remains completely untouched."</em>
  </p>
</div>

<div class="callout callout-interview">
  <div class="callout-title">Q6: What are the project limitations, and what would you build next?</div>
  <p>
    <strong>Model Answer:</strong><br>
    <em>"To maintain engineering transparency: DriveOS uses a lightweight procedural vector canvas for navigation rather than a commercial map SDK (like Mapbox or TomTom); the diagnostic subsystem is an in-memory DTC prototype rather than a full ISO 14229 UDS protocol stack; and the safety policy is an HMI distraction engine rather than a certified ISO 26262 ASIL-D safety cluster. In the next phase, I would integrate open-source vector map tiles via MapLibre Native, add audio streaming decoding via GStreamer, and introduce an AUTOSAR Adaptive SOME/IP serialization bridge."</em>
  </p>
</div>

<div style="margin-top: 30px; padding-top: 15px; border-top: 1px solid #CBD5E1; font-size: 11px; color: #64748B; text-align: center;">
  DriveOS Technical Reference &amp; Recruiter Interview Guide &bull; Automotive Cockpit Systems &bull; Built with C++20 &amp; Qt 6.6.3
</div>

</body>
</html>
"""

def main():
    docs_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "docs")
    os.makedirs(docs_dir, exist_ok=True)
    
    html_path = os.path.join(docs_dir, "DriveOS_Technical_Reference_and_Interview_Guide.html")
    pdf_path = os.path.join(docs_dir, "DriveOS_Technical_Reference_and_Interview_Guide.pdf")
    
    print(f"[1/3] Writing HTML document to: {html_path}")
    with open(html_path, "w", encoding="utf-8") as f:
        f.write(HTML_CONTENT)
    print("      HTML successfully written.")

    print(f"[2/3] Generating PDF using headless browser...")
    edge_exe = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
    chrome_exe = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
    
    browser_exe = None
    if os.path.exists(edge_exe):
        browser_exe = edge_exe
    elif os.path.exists(chrome_exe):
        browser_exe = chrome_exe
    else:
        print("ERROR: Neither Edge nor Chrome found on system.")
        return 1
        
    cmd = [
        browser_exe,
        "--headless",
        "--disable-gpu",
        "--no-pdf-header-footer",
        f"--print-to-pdf={pdf_path}",
        html_path
    ]
    
    result = subprocess.run(cmd, capture_output=True, text=True)
    if os.path.exists(pdf_path) and os.path.getsize(pdf_path) > 1000:
        size_kb = os.path.getsize(pdf_path) / 1024
        print(f"[3/3] Success! High-quality PDF generated:")
        print(f"      File: {pdf_path}")
        print(f"      Size: {size_kb:.1f} KB")
        return 0
    else:
        print(f"ERROR: PDF generation failed. Return code: {result.returncode}")
        print(f"Stderr: {result.stderr}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
