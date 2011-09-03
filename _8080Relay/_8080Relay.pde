/*
 Chat  Server
 
 A simple server that distributes any incoming messages to all
 connected clients.  To use telnet to  your device's IP address and type.
 You can see the client's input in the serial monitor as well.
 Using an Arduino Wiznet Ethernet shield. 
 
 Circuit:
 * Ethernet shield attached to pins 10, 11, 12, 13
 * Analog inputs attached to pins A0 through A5 (optional)
 
 created 18 Dec 2009
 by David A. Mellis
 modified 10 August 2010
 by Tom Igoe
 
 */

#include <SPI.h>
#include <Ethernet.h>

// Enter a MAC address and IP address for your controller below.
// The IP address will be dependent on your local network.
// gateway and subnet are optional:
byte mac[] = { 0x90, 0xA2, 0xDA, 0x00, 0x49, 0xDE };
byte ip[] = { 144, 92, 40, 45 };
byte gateway[] = { 144,92,40, 1 };
byte subnet[] = { 255, 255, 255, 128 };

// telnet defaults to port 23
Server server(8080);
boolean gotAMessage = false; // whether or not you got a message from the client yet

void setup() {
  // initialize the ethernet device
  Ethernet.begin(mac, ip, gateway, subnet);
  // start listening for clients
  server.begin();
  // open the serial port
  Serial.begin(57600);
}

void loop() {
  // wait for a new client:
  Client client = server.available();
  
  // when the client sends the first byte, say hello:
  if (client) {
    if (!gotAMessage) {
      Serial.println("We have a new client");
      client.println("Hello, client!"); 
      gotAMessage = true;
    }
    
    // read the bytes incoming from the client:
    char thisChar = client.read();
    // echo the bytes back to the client:
    server.write(thisChar);
    // echo the bytes to the server as well:
    Serial.print(thisChar);
  }
}
