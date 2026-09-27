# GuardianHat - Mobile App

Companion mobile application for the Smart Hat IoT ecosystem.

## Overview

Provides real-time telemetry tracking, sensor status monitoring, push notifications, and emergency alerts from GuardianHat devices.

## Planned Structure

```
mobile_app/
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── core/              # Constants, themes, network config
│   ├── models/            # TelemetryData, AlertPayload mappings
│   ├── services/          # MqttService, NotificationService
│   ├── state/             # State management (Riverpod/Provider)
│   └── ui/                # UI screens, dials, radar & alert views
├── assets/                # Animations, SVGs, sound effects
└── README.md
```
