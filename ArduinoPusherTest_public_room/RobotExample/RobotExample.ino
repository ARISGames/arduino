#include <SPI.h>
#include <Ethernet.h>
#include <PusherClient.h>

byte mac[] = { 0xAB, 0xCD, 0xE2, 0xFF, 0xFE, 0xED };
PusherClient client;

void setup() {
  Serial.begin(9600);
  Serial.println("Setup...");
  if (Ethernet.begin(mac) == 0) {
    Serial.println("Init Ethernet failed");
    while(1);
  }
  else
    Serial.println("Init Ethernet Success!");
  
  if(client.connect("79f6a265dbb7402a49c9")) {
    client.bindAll(eventHandler);
    client.subscribe("public-pusher_room_channel");
    Serial.println("Pusher Connect Success!");
  }
  else {
    Serial.println("Pusher Connect failed");
    while(1);
  }
}

void loop() {
  if (client.connected()) {
    client.monitor();
  }
  else {
    Serial.println("Client Disconnected... :(");
  }
}

void eventHandler(String data) {
  Serial.println("Event!");
}
