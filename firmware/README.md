# ⚡ GuardianHat — Embedded Firmware Documentation

This directory contains the embedded C++ / Arduino firmware running on the ESP32 microcontroller inside the **GuardianHat** smart safety helmet.

---

<p align="center">
  <img src="../assets/CircuitDiagram.png" alt="Hardware Circuit Schematic" width="750"/>
</p>

---

## 📌 Technical Specifications & Hardware Pinout

| Peripheral | Sensor / Module | ESP32 Pin | Logic Level | Description |
| :--- | :--- | :--- | :--- | :--- |
| **Ultrasonic Trigger** | HC-SR04 | `GPIO 32` | 3.3V / 5V | $10\mu\text{s}$ pulse initiation |
| **Ultrasonic Echo** | HC-SR04 | `GPIO 35` | 3.3V (Input Only) | High-pulse duration detection |
| **Haptic Motor** | ERM Vibration Motor | `GPIO 26` | 3.3V (via NPN/MOSFET) | Proportional pulsed tactile feedback |
| **IMU I2C SDA** | MPU-6050 | `GPIO 21` | 3.3V | 6-Axis Accelerometer / Gyroscope Data |
| **IMU I2C SCL** | MPU-6050 | `GPIO 22` | 3.3V | I2C Clock (Default 100kHz / 400kHz) |
| **GSM Module RX** | SIM800L | `GPIO 17` (TX2) | 3.3V / 4.2V (VCC) | ESP32 TX $\to$ SIM800L RX |
| **GSM Module TX** | SIM800L | `GPIO 16` (RX2) | 3.3V / 4.2V (VCC) | SIM800L TX $\to$ ESP32 RX |

---

## 🧠 Core Algorithms & Logic

### 1. Proportional Proximity Haptic Pulse
The firmware actively samples the ultrasonic distance. If an object is detected between **5 cm and 55 cm**, the vibration motor pulses in a non-blocking loop. The closer the obstacle, the faster the motor pulses:

$$\text{pulseSpeed} = \text{map}(\text{distance}, 5, 35, 50\text{ ms}, 800\text{ ms})$$

- At **35 cm+**: Gentle, spaced pulsation ($800\text{ ms}$ interval).
- At **5 cm**: Rapid, high-urgency buzz ($50\text{ ms}$ interval).
- Outside danger zone ($> 55\text{ cm}$): Motor remains `LOW` (idle).

---

### 2. Delta (Jerk) Fall Detection Algorithm
Rather than relying on static angle thresholds (which trigger false positives whenever the user looks down or bends over), GuardianHat evaluates angular velocity over a moving **1-second window**:

$$\Delta\theta = |\theta_{\text{current}} - \theta_{\text{previous}}|$$

- If $\Delta\theta > 50.0^\circ$ within $1000\text{ ms}$:
  - Instantly pauses vibration to prevent interference.
  - Generates emergency timestamp and triggers the **Emergency Protocol**.
  - Rate-limited to one emergency cycle every 20 seconds to prevent notification floods.

---

### 3. Multi-Tier Dual-Channel Emergency Dispatch Sequence

```
                         [ SUDDEN FALL DETECTED ]
                                    │
                                    ▼
                     Is Wi-Fi connected to Internet?
                                   / \
                            YES   /   \   NO
                                 /     \
                                ▼       ▼
                     [ Twilio REST API ]    [ SIM800L Cellular ]
                     HTTP POST via TLS      AT Commands via UART
                     Status: 201 Created    SMS Dispatched
                                │       ▲
                                │       │ (If Twilio Fails)
                                └───────┘
```

1. **Primary Route (Wi-Fi + Twilio REST Cloud API)**:
   - Constructs HTTP `POST` to `https://api.twilio.com/2010-04-01/Accounts/{SID}/Messages.json`.
   - Sends emergency alert body with embedded Google Maps coordinates.
2. **Secondary Route (SIM800L GSM Fallback)**:
   - If Wi-Fi fails or returns a non-201 HTTP code, fallback triggers immediately.
   - Dispatches SMS directly across GSM 2G/GPRS networks using AT commands:
     ```text
     AT+CMGF=1
     AT+CMGS="+91XXXXXXXXXX"
     > EMERGENCY! Fall Detected! Location: http://maps.google.com/?q=...
     ^Z
     ```

---

### 4. Telemetry Stream over HiveMQ Cloud
- Publishes JSON telemetry every **1 second** to topic `smarthat/telemetry`:
  ```json
  {
    "distance": 28.40,
    "angle": 6.15,
    "network": "Wi-Fi",
    "motor_active": false,
    "system_status": "NORMAL"
  }
  ```
- Uses `WiFiClientSecure` with non-blocking reconnection routines if connection drops.

---

## 🛠️ Flashing & Configuration

### Prerequisites
1. Install [Arduino IDE](https://www.arduino.cc/en/software) or VS Code with [PlatformIO](https://platformio.org/).
2. Add ESP32 board package (`https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`).
3. Install the following libraries via Library Manager:
   - **`PubSubClient`** (v2.8+)
   - **`ArduinoJson`** (v6.x or v7.x)

### Configuration
Open [`ArdiunoCode/MQTTCode.ino`](ArdiunoCode/MQTTCode.ino) and update the configuration section:

```cpp
// Wi-Fi Settings
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// HiveMQ Cloud TLS Details
const char* mqtt_server = "YOUR_HIVEMQ_HOST.hivemq.cloud";
const int mqtt_port = 8883;
const char* mqtt_user = "YOUR_HIVEMQ_USERNAME";
const char* mqtt_pass = "YOUR_HIVEMQ_PASSWORD";

// Twilio Cloud SMS Credentials
const String account_sid = "YOUR_TWILIO_ACCOUNT_SID"; 
const String auth_token = "YOUR_TWILIO_AUTH_TOKEN";
const String twilio_number = "%2B1XXXXXXXXXX";
const String my_phone_number = "%2B91XXXXXXXXXX";
const String raw_sim_number = "+91XXXXXXXXXX";
```

### Upload
1. Connect ESP32 via Micro-USB / Type-C.
2. Select Board: **ESP32 Dev Module**.
3. Select the active COM Port.
4. Set Baud Rate to **115200**.
5. Click **Upload** and open Serial Monitor to observe live boot logs.
