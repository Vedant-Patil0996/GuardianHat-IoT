#include <Wire.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

// ---------------------------------------------------
// 1. CLOUD SETTINGS (WI-FI, HIVEMQ & TWILIO)
// ---------------------------------------------------
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD"; // <-- Update with your Wi-Fi password

// HiveMQ Cloud TLS Details
const char* mqtt_server = "YOUR_HIVEMQ_HOST.hivemq.cloud";
const int mqtt_port = 8883;
const char* mqtt_user = "YOUR_HIVEMQ_USERNAME";
const char* mqtt_pass = "YOUR_HIVEMQ_PASSWORD"; // <-- Update with your HiveMQ credential password

const char* topic_telemetry = "smarthat/telemetry";
const char* topic_alerts    = "smarthat/alerts";

// Twilio Credentials
const String account_sid = "YOUR_TWILIO_ACCOUNT_SID"; 
const String auth_token = "YOUR_TWILIO_AUTH_TOKEN";

// Phone Numbers
const String twilio_number = "%2B1XXXXXXXXXX"; // URL Encoded
const String my_phone_number = "%2B91XXXXXXXXXX"; // URL Encoded
const String raw_sim_number = "+91XXXXXXXXXX"; // Raw for SIM800L

const String maps_link = "http://maps.google.com/?q=19.064500,72.835800";

// Secure Network Clients
WiFiClientSecure espClient;
PubSubClient mqttClient(espClient);

// ---------------------------------------------------
// 2. HARDWARE PINS
// ---------------------------------------------------
#define TRIG 32
#define ECHO 35
#define MOTOR 26

#define SIM_RX_PIN 16  // ESP32 RX2
#define SIM_TX_PIN 17  // ESP32 TX2
HardwareSerial simSerial(2);

// ---------------------------------------------------
// 3. SENSOR & LOGIC VARIABLES
// ---------------------------------------------------
const int MPU_addr = 0x68; 
float distance;
float angle;

// Vibration Logic
unsigned long lastMotorToggle = 0;
bool motorState = false;

// --- Delta Fall Detection Variables ---
float previousAngle = 0;
unsigned long lastAngleCheckTime = 0;
const float fallDeltaThreshold = 50.0;         // Fire if angle jumps 50+ degrees suddenly
const unsigned long angleCheckInterval = 1000; // Check difference every 1 second (1000 ms)

bool isSendingAlert = false; // STOPS vibration during SMS
unsigned long lastEmergencySmsTime = 0;

// Telemetry Timing
unsigned long lastDebugPrint = 0;
unsigned long lastMqttReconnectAttempt = 0;

// Function Prototypes
void connectMQTT();
void triggerEmergencyProtocol(float angleDifference);

// ---------------------------------------------------
// SETUP: BOOT SEQUENCE
// ---------------------------------------------------
void setup() {
  Serial.begin(115200);
  delay(1000);
  
  pinMode(TRIG, OUTPUT);
  pinMode(ECHO, INPUT);
  pinMode(MOTOR, OUTPUT);
  digitalWrite(MOTOR, LOW); 

  Serial.println("\n===========================================");
  Serial.println("     SMART HAT: FINAL CORE OS BOOTING      ");
  Serial.println("===========================================");

  // 1. MPU6050 Initialization
  Wire.begin(); 
  Wire.beginTransmission(MPU_addr);
  Wire.write(0x6B); 
  Wire.write(0); 
  Wire.endTransmission(true);
  
  // Take a starting angle snapshot so it doesn't instantly trigger a fall on boot
  Wire.beginTransmission(MPU_addr);
  Wire.write(0x3B); 
  Wire.endTransmission(false);
  Wire.requestFrom(MPU_addr, 6, true);  
  int16_t bootAcY = Wire.read() << 8 | Wire.read();  
  int16_t bootAcZ = Wire.read() << 8 | Wire.read();  
  previousAngle = abs(atan2(bootAcY, bootAcZ) * 180.0 / PI);

  // 2. SIM800L Initialization
  simSerial.begin(9600, SERIAL_8N1, SIM_RX_PIN, SIM_TX_PIN);
  delay(1000);
  simSerial.println("AT+CMGF=1"); // Pre-set text mode

  // 3. Wi-Fi & Secure MQTT Setup
  Serial.print("[SYSTEM] Searching for Wi-Fi...");
  WiFi.begin(ssid, password);
  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500); 
    Serial.print("."); 
    attempts++;
  }
  
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n[SUCCESS] Wi-Fi Active. IP: " + WiFi.localIP().toString());
    
    // Configure TLS verification and MQTT buffer
    espClient.setInsecure(); // Bypass CA verification for development
    mqttClient.setServer(mqtt_server, mqtt_port);
    mqttClient.setBufferSize(512); // Ensure JSON payloads fit comfortably
    connectMQTT();
  } else {
    Serial.println("\n[WARNING] Wi-Fi Offline. Defaulting to SIM800L.");
  }
}

// ---------------------------------------------------
// MQTT RECONNECT ROUTINE (Non-Blocking)
// ---------------------------------------------------
void connectMQTT() {
  if (WiFi.status() != WL_CONNECTED) return;
  
  Serial.print("[MQTT] Connecting to HiveMQ Broker...");
  String clientId = "SmartHat_ESP32_" + String(random(0xffff), HEX);
  
  if (mqttClient.connect(clientId.c_str(), mqtt_user, mqtt_pass)) {
    Serial.println(" [CONNECTED]");
  } else {
    Serial.print(" [FAILED] rc=");
    Serial.println(mqttClient.state());
  }
}

// ---------------------------------------------------
// MAIN LOOP
// ---------------------------------------------------
void loop() {
  unsigned long currentMillis = millis();

  // Maintain MQTT Connection
  if (WiFi.status() == WL_CONNECTED) {
    if (!mqttClient.connected()) {
      if (currentMillis - lastMqttReconnectAttempt > 5000) {
        lastMqttReconnectAttempt = currentMillis;
        connectMQTT();
      }
    } else {
      mqttClient.loop();
    }
  }

  // --- 1. SENSOR READINGS ---
  // Ultrasonic Reading
  digitalWrite(TRIG, LOW); 
  delayMicroseconds(2);
  digitalWrite(TRIG, HIGH); 
  delayMicroseconds(10); 
  digitalWrite(TRIG, LOW);
  long duration = pulseIn(ECHO, HIGH, 30000); 
  distance = (duration == 0) ? 999 : (duration * 0.034 / 2);

  // MPU6050 Reading
  Wire.beginTransmission(MPU_addr);
  Wire.write(0x3B); 
  Wire.endTransmission(false);
  Wire.requestFrom(MPU_addr, 6, true);  
  int16_t AcY = Wire.read() << 8 | Wire.read();  
  int16_t AcZ = Wire.read() << 8 | Wire.read();  
  angle = abs(atan2(AcY, AcZ) * 180.0 / PI);

  // --- 2. DEBUG & MQTT JSON TELEMETRY (Every 1 Second) ---
  if (currentMillis - lastDebugPrint > 1000) {
      String netStatus = (WiFi.status() == WL_CONNECTED) ? "Wi-Fi" : "SIM800L";
      String alertStatus = isSendingAlert ? "ALERT_ACTIVE" : "NORMAL";
      
      // Print Serial Debug Output
      String telemetryString = "[TELEMETRY] Dist: " + String(distance, 2) + " cm | " +
                               "Angle: " + String(angle, 2) + " deg | " +
                               "Network: " + netStatus + " | " + alertStatus;
      Serial.println(telemetryString);

      // Publish JSON to HiveMQ Broker
      if (mqttClient.connected()) {
        StaticJsonDocument<256> doc;
        doc["distance"] = round(distance * 100.0) / 100.0;
        doc["angle"] = round(angle * 100.0) / 100.0;
        doc["network"] = netStatus;
        doc["motor_active"] = motorState;
        doc["system_status"] = alertStatus;
        
        char jsonBuffer[256];
        serializeJson(doc, jsonBuffer);
        mqttClient.publish(topic_telemetry, jsonBuffer);
      }
      
      lastDebugPrint = currentMillis;
  }

  // --- 3. VIBRATION LOGIC (ONLY if not sending an alert) ---
  if (!isSendingAlert) {
      if (distance >= 5 && distance <= 55) {
          int pulseSpeed = map((int)distance, 5, 35, 50, 800); 
          
          if (currentMillis - lastMotorToggle > pulseSpeed) {
              motorState = !motorState; 
              digitalWrite(MOTOR, motorState);
              lastMotorToggle = currentMillis;
          }
      } else {
          digitalWrite(MOTOR, LOW); 
          motorState = false;
      }
  }

  // --- 4. SUDDEN DELTA (JERK) FALL DETECTION ---
  if (currentMillis - lastAngleCheckTime > angleCheckInterval) {
      float angleDifference = abs(angle - previousAngle);

      // If the difference is a massive, sudden jump...
      if (angleDifference > fallDeltaThreshold) { 
          if (currentMillis - lastEmergencySmsTime >= 20000) { 
              isSendingAlert = true;      
              digitalWrite(MOTOR, LOW);   
              motorState = false;
              
              String alertStr = "\n>>> SUDDEN FALL DETECTED! Previous Angle: " + String(previousAngle) + 
                                " | New Angle: " + String(angle) + 
                                " | Shifted by: " + String(angleDifference) + " degrees! <<<";
              Serial.println(alertStr);
              
              // Publish High-Priority Emergency Payload over MQTT
              if (mqttClient.connected()) {
                StaticJsonDocument<256> alertDoc;
                alertDoc["event"] = "FALL_DETECTED";
                alertDoc["previous_angle"] = round(previousAngle * 100.0) / 100.0;
                alertDoc["current_angle"] = round(angle * 100.0) / 100.0;
                alertDoc["delta"] = round(angleDifference * 100.0) / 100.0;
                alertDoc["maps_url"] = maps_link;

                char alertBuffer[256];
                serializeJson(alertDoc, alertBuffer);
                mqttClient.publish(topic_alerts, alertBuffer);
              }
              
              triggerEmergencyProtocol(angleDifference);
              
              isSendingAlert = false;     
              lastEmergencySmsTime = millis(); 
          }
      }
      
      previousAngle = angle;
      lastAngleCheckTime = currentMillis;
  }

  delay(20); 
}

// ---------------------------------------------------
// EMERGENCY SMS PROTOCOL
// ---------------------------------------------------
void triggerEmergencyProtocol(float angleDifference) {
  bool cloudSuccess = false;

  // STEP 1: Try Wi-Fi (Twilio)
  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("[NETWORK] Attempting Twilio Cloud SMS...");
    
    HTTPClient http;
    String url = "https://api.twilio.com/2010-04-01/Accounts/" + account_sid + "/Messages.json";

    http.begin(url); 
    http.setAuthorization(account_sid.c_str(), auth_token.c_str());
    http.addHeader("Content-Type", "application/x-www-form-urlencoded");

    String messageBody = "EMERGENCY!+Fall+Detected!+Location:+" + maps_link;
    String postData = "To=" + my_phone_number + "&From=" + twilio_number + "&Body=" + messageBody;

    int httpResponseCode = http.POST(postData);
    if (httpResponseCode == 201) {
      Serial.println("[SUCCESS] SMS Delivered via Wi-Fi!");
      cloudSuccess = true;
    } else {
      Serial.print("[ERROR] Twilio Failed (Code "); 
      Serial.print(httpResponseCode); 
      Serial.println(").");
    }
    http.end(); 
  }

  // STEP 2: SIM800L Hardware Fallback
  if (!cloudSuccess) {
    Serial.println("[NETWORK] Executing SIM800L Cellular Fallback...");
    
    simSerial.println("AT+CMGF=1"); 
    delay(500);
    simSerial.print("AT+CMGS=\""); 
    simSerial.print(raw_sim_number); 
    simSerial.println("\""); 
    delay(1000);
    
    simSerial.print("Wi-Fi failed. Sending via SIM800L.\nEMERGENCY! Fall Detected!\nLocation: "); 
    simSerial.print(maps_link); 
    delay(500);
    simSerial.write(26); 
    
    Serial.println("[NETWORK] AT Commands injected. Waiting 4 seconds for carrier dispatch...");
    delay(4000); 
    
    Serial.println("[SUCCESS] Cellular SMS Sequence Complete.");
  }
}