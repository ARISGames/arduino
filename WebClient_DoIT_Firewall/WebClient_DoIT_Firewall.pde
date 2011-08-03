/*
  Web client
 
 This sketch connects to a website (http://www.google.com)
 using an Arduino Wiznet Ethernet shield. 
 
 Circuit:
 * Ethernet shield attached to pins 10, 11, 12, 13
 
 created 18 Dec 2009
 by David A. Mellis
 
 */

#include <SPI.h>
#include <Ethernet.h>

// Enter a MAC address and IP address for your controller below.
// The IP address will be dependent on your local network:
byte mac[] = { 0x90, 0xA2, 0xDA, 0x00, 0x49, 0xDE };
byte ip[] = { 128,104,17, 201 };
byte gateway[] = { 128,104,16, 1 };
byte subnet[] = { 255,255,252, 0 };

byte server[] = { 144,92,9,185 }; // Google

// Initialize the Ethernet client library
// with the IP address and port of the server 
// that you want to connect to (port 80 is default for HTTP):
Client client(server, 80);

void setup() {
  // start the Ethernet connection:
  Ethernet.begin(mac, ip, gateway, subnet);
  // start the serial library:
  Serial.begin(57600);
  // give the Ethernet shield a second to initialize:
  delay(2000);
  Serial.println("connecting...");

  // if you get a connection, report back via serial:
  Serial.println("client.connect:" + client.connect());
  if (client.connect()) {
    Serial.println("connected");
    // Make a HTTP request:
    client.println("GET /search?q=arduino HTTP/1.0");
    client.println();
  } 
  else {
    // kf you didn't get a connection to the server:
    Serial.println("connection failed");
  }
}

void loop()
{
  // if there are incoming bytes available 
  // from the server, read them and print them:
  if (client.available()) {
    char c = client.read();
    Serial.print(c);
  }

  // if the server's disconnected, stop the client:
  if (!client.connected()) {
    Serial.println();
    Serial.println("disconnecting.");
    client.stop();

    // do nothing forevermore:
    for(;;)
      ;
  }
}

