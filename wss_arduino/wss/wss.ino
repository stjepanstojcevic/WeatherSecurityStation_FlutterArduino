#include <AsyncTCP.h>
#include <ESPAsyncWebServer.h>
#include <AsyncWebSocket.h>
#include "DHT.h"

const char *ssid = "SS";
const char *password = "stipa12345";

const int LED_PIN = 21;
const int BUZZER_PIN = 22;
const int DHTPIN = 23;
#define DHTTYPE DHT11

AsyncWebServer server(80);
AsyncWebSocket ws("/ws");

void onWebSocketEvent(AsyncWebSocket *server, AsyncWebSocketClient *client, AwsEventType type, void *arg, uint8_t *data, size_t len) {
  if (type == WS_EVT_CONNECT) {
    Serial.println("WebSocket povezan");
  } else if (type == WS_EVT_DISCONNECT) {
    Serial.println("WebSocket odspojen");
  } else if (type == WS_EVT_DATA) {
    AwsFrameInfo *info = (AwsFrameInfo *)arg;
    if (info->final && info->index == 0 && info->len == len && info->opcode == WS_TEXT) {
      if (strncmp((char *)data, "led/on", len) == 0) {
        digitalWrite(LED_PIN, HIGH);
        Serial.println("Uključi LED");
      } else if (strncmp((char *)data, "led/off", len) == 0) {
        digitalWrite(LED_PIN, LOW);
        Serial.println("Isključi LED");
      } else if (strncmp((char *)data, "buzzer/on", len) == 0) {
        digitalWrite(BUZZER_PIN, HIGH);
        Serial.println("Uključi Buzzer");
      } else if (strncmp((char *)data, "buzzer/off", len) == 0) {
        digitalWrite(BUZZER_PIN, LOW);
        Serial.println("Isključi Buzzer");
      }
    }
  }
}
DHT dht(DHTPIN, DHTTYPE);
void sendSensorData() {
  float humidity = dht.readHumidity();
  float temperature = dht.readTemperature();

  if (!isnan(humidity) && !isnan(temperature)) {
    String data = String(temperature) + ',' + String(humidity);
    ws.textAll(data);
  }
}

void setup() {
  Serial.begin(115200);

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(1000);
    Serial.println("Povezivanje na WiFi...");
  }

  Serial.println("Povezano na WiFi");

  pinMode(LED_PIN, OUTPUT);
  pinMode(BUZZER_PIN, OUTPUT);

  ws.onEvent(onWebSocketEvent);
  server.addHandler(&ws);

  server.begin();
  dht.begin();
}

void loop() {
  delay(1000);

  sendSensorData();
  
  float h = dht.readHumidity();
  float t = dht.readTemperature();

  if (isnan(h) || isnan(t)) {
    Serial.println(F("Failed to read from DHT sensor!"));
    return;
  }

  Serial.print(F("Humidity: "));
  Serial.print(h);
  Serial.print(F("%  Temperature: "));
  Serial.print(t);
  Serial.println(F("°C "));
}