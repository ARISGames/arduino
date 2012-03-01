#include <EthernetDHCP.h>


/*
  Melody
 
 Plays a melody 
 
 circuit:
 * 8-ohm speaker on digital pin 8
 
 created 21 Jan 2010
 modified 30 Aug 2011
 by Tom Igoe 

This example code is in the public domain.
 
 http://arduino.cc/en/Tutorial/Tone
 
 */
#include "pitches.h"
#include <SPI.h>
#include <Ethernet.h>

#include <PusherClient.h>

// notes in the melody:
int melody[] = {
  NOTE_C4, NOTE_G3,NOTE_G3, NOTE_A3, NOTE_G3,0, NOTE_B3, NOTE_C4};

// note durations: 4 = quarter note, 8 = eighth note, etc.:
int noteDurations[] = {
  4, 8, 8, 4,4,4,4,4 };

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] = { 192, 168, 2, 2 };
//byte gateway[] = { 192, 168, 2, 1 };
//byte subnet[] = { 255, 255, 255, 128 };
//byte serverLocal[] = { 192,168,0,1 }; // Google
byte serverExternal[] = { 173,194,33,104 }; // Google
// Initialize the Ethernet client library
// with the IP address and port of the server
// that you want to connect to (port 80 is default for HTTP):
EthernetClient clientLocal;
EthernetClient clientExternal;
PusherClient client;
void setup() {
Serial.begin(9600);
      delay(1000);
  Serial.println("Attempting to obtain a DHCP lease...");


    EthernetDHCP.begin(mac);

    // Since we're here, it means that we now have a DHCP lease, so we print
    // out some information.
    const byte* ipAddr = EthernetDHCP.ipAddress();
    const byte* gatewayAddr = EthernetDHCP.gatewayIpAddress();
    const byte* dnsAddr = EthernetDHCP.dnsIpAddress();
      delay(1000);
    Serial.println("A DHCP lease has been obtained.");
      delay(1000);
    Serial.print("My IP address is ");
    Serial.println(ip_to_str(ipAddr));
      delay(1000);
    Serial.print("Gateway IP address is ");
    Serial.println(ip_to_str(gatewayAddr));
      delay(1000);
    Serial.print("DNS IP address is ");
    Serial.println(ip_to_str(dnsAddr));
    
      delay(3000);

      
/* // if you get a connection, report back via serial:
    if (clientLocal.connect(EthernetDHCP.ipAddress(),80)) {
        Serial.println("connected internally");
        // Make a HTTP request:
        clientLocal.println("GET /index.html HTTP/1.0");
        clientLocal.println();
    }
    else {
        // kf you didn't get a connection to the server:
        Serial.println("connection failed internally");
    }
*/
    // if you get a connection, report back via serial:

  /*  if (clientExternal.connect(serverExternal,80)) {
        Serial.println("connected externally");
        // Make a HTTP request:
        clientExternal.println("GET /search?q=arduino HTTP/1.0");
        clientExternal.println();
    }
    else {
        // kf you didn't get a connection to the server:
        Serial.println("connection failed externally");
    }*/
  if(client.connect("10582812642151b1b7a1")) {
    client.bind("test", play);

    client.subscribe("aris");
        Serial.println("Subscribed to aris channel");
  }
  else {
            Serial.println("Could not connect");
    while(1) {}
  }
}

void loop() {
  // You should periodically call this method in your loop(): It will allow
  // the DHCP library to maintain your DHCP lease, which means that it will
  // periodically renew the lease and rebind if the lease cannot be renewed.
  // Thus, unless you call this somewhere in your loop, your DHCP lease might
  // expire, which you probably do not want :-)
 // 
  if (client.connected()) {
    client.monitor();
EthernetDHCP.maintain();
  }
  else {

  }
}

void play(String data){
            Serial.println("Entering play");
   // iterate over the notes of the melody:
  for (int thisNote = 0; thisNote < 8; thisNote++) {

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
