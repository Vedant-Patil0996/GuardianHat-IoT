# GuardianHat - Firmware

Embedded firmware for the Smart Hat IoT system.

## Overview

Handles sensor data acquisition (IMU/fall detection, environmental sensors, GPS/proximity), network communication (Wi-Fi / Cellular / MQTT), and emergency alerting.

## Planned Structure

```
firmware/
├── src/
│   └── main.cpp           # Main application entry point
├── include/
│   └── config.h           # Wi-Fi, MQTT, and API credentials (gitignored)
├── config.example.h       # Blank credential template for setup
└── README.md
```
