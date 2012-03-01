#include <aJSON.h>



#include <WString.h>
#include "pitches.h"
#include <SPI.h>
#include <Ethernet.h>

#include <PusherClient.h>

// notes in the melody:
int melody[] = {
  NOTE_FS2, NOTE_FS2,0,NOTE_A2, NOTE_A2,0, NOTE_E2,NOTE_E2,0, NOTE_FS2, NOTE_FS2};

// note durations: 4 = quarter note, 8 = eighth note, etc.:
int noteDurations[] = {
  6, 6, 1, 6,6,3,6,6,3,6,6 };
IPAddress server(50,57,138,30); // Google
String socket_id = "socket_id";
byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
int inputPin = 3;
int ledPin = 9;
EthernetClient arisClient;
PusherClient client;

void setup() {
  pinMode(inputPin, INPUT);
    pinMode(ledPin, OUTPUT);
Serial.begin(9600);
  delay(1000);
  Serial.println("Attempting to obtain a DHCP lease...");

 if (Ethernet.begin(mac) == 0) {
    Serial.println("Init Ethernet failed");
    for(;;)
      ;
  }
          Serial.println("Ethernet Connected");
  delay(3000);
  
  if(client.connect("7fe26fe9f55d4b78ea02")) {
   client.bind("private-pusher_room_event", play);
   client.bind("pusher:connection_established",getSocketId);
client.bindAll(handleAllEvents);

    client.subscribe("private-pusher_room_channel");
        Serial.println("Subscribed to aris channel");
  }
  else {
            Serial.println("Could not connect");
    while(1) {}
  }
  
  if(arisClient.connect(server,80)){
    Serial.println("Connected to ARIS server");
	
  }
  else{
    Serial.println("Could not connect to ARIS server");
  }
}

void loop() {
 
 if(digitalRead(inputPin) == HIGH){
  digitalWrite(ledPin, LOW);
 }
 else{
   digitalWrite(ledPin, HIGH);
   client.triggerEvent("aris","client-test", "{\"name\": \"Joe\", \"message_count\": 23}");
   Serial.println("Button Pressed");
 }

  if (client.connected()) {
    client.monitor();

  }
  else {
 Serial.println("Client Disconnected");
  }
  
  if (arisClient.available()) {
    //Serial.println("arisClient read");
    char c = arisClient.read();
    Serial.print(c);
  }

  // if the server's disconnected, stop the client:
  if (!arisClient.connected()) {
    Serial.println();
    Serial.println("disconnecting.");
    arisClient.stop();

    // do nothing forevermore:
    for(;;)
      ;
  }
  
}
void getSocketId(String data){
      socket_id = data.substring(data.lastIndexOf(':')+3,data.lastIndexOf('\\'));
    Serial.print("Got socket_id: ");
    Serial.println(socket_id);
    

        arisClient.println("POST /devserver/pusher/private_auth.php HTTP/1.1");
	arisClient.println("Host: arisgames.org"); 
        arisClient.println("Content-Type: application/x-www-form-urlencoded");
        arisClient.println("Content-Length: 62");
        arisClient.println();
        arisClient.println("socket_id="+socket_id+"&channel_name=private-pusher_room_channel");
        
                Serial.println("POST /devserver/pusher/private_auth.php HTTP/1.1");
                Serial.println("Host: arisgames.org");
                Serial.println("Content-Type: application/x-www-form-urlencoded");
                Serial.println("Content-Length: ");
        Serial.println();
        Serial.println("socket_id="+socket_id+"&channel_name=private-pusher_room_channel");
}
void handleAllEvents(String data){

Serial.println(data);

}
void play(String data){
            Serial.println("Entering play");
   // iterate over the notes of the melody:
  for (int thisNote = 0; thisNote < 11; thisNote++) {

    // to calculate the note duration, take one second 
    // divided by the note type.
    //e.g. quarter note = 1000 / 4, eighth note = 1000/8, etc.
    int noteDuration = 1000/noteDurations[thisNote];
    tone(8, melody[thisNote],noteDuration);

    // to distinguish the notes, set a minimum time between them.
    // the note's duration + 30% seems to work well:
    int pauseBetweenNotes = noteDuration * 1.30;
    delay(pauseBetweenNotes);
    // stop the tone playing:
    noTone(8);
  }
}

// Just a utility function to nicely format an IP address.
const char* ip_to_str(const uint8_t* ipAddr)
{
  static char buf[16];
  sprintf(buf, "%d.%d.%d.%d\0", ipAddr[0], ipAddr[1], ipAddr[2], ipAddr[3]);
  return buf;
}
