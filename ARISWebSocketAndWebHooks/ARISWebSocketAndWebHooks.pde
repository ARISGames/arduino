/*
This sketch provides a physical interface to ARIS

It can be configued to send "buttonXPressed" to any connected webSocket clients, 
assumingly runing a "WebPage" object in ARIS and assumingly communicating to the ARIS
server using "Incoming Web Hooks" for major updates.

"buttonXPressed" events should also be able to be programmed to call Incoming Web Hooks
on ARIS, but the device will not be aware of the Player Id parameter so support has been skipped.

This sketch should also enable the Arduino to respond to "Outgoing Web Hooks" as simple HTTP GET
requests with parameters to specifiy which pin should go high and for how long. 
This means web socket handshaking is only used web sockets clients while maintaining
support for simple HTTP requests.

*/


#include <SPI.h>
#include <Ethernet.h>
#include <Streaming.h>
#include <WebSocket.h>

#define PREFIX "/ws"
#define PORT 8080
#define FIREPINDURATION 500

byte mac[] = { 0x52, 0x4F, 0x43, 0x4B, 0x45, 0x54 };
byte ip[] = { 192, 168,0, 3 };

WebSocket websocketServer(PREFIX, PORT);

boolean pin8ButtonLastValue = false;
boolean pin9ButtonLastValue = false;

boolean webSocketClientConnected = false;

// You must have at least one function with the following signature.
// It will be called by the server when a data frame is received.
void dataReceivedAction(WebSocket &socket, String &dataString) {

    if (dataString == "FIREPIN1") {
      Serial.println("FIREPIN1 Begin");
      digitalWrite(1, HIGH);
      delay(FIREPINDURATION);
      digitalWrite(1, LOW);
      Serial.println("FIREPIN1 End");
    }
    if (dataString == "FIREPIN2") {
      digitalWrite(2, HIGH);
      delay(FIREPINDURATION);
      digitalWrite(2, LOW);
    }
    if (dataString == "FIREPIN3") {
      digitalWrite(3, HIGH);
      delay(FIREPINDURATION);
      digitalWrite(3, LOW);
    }
    if (dataString == "FIREPIN4") {
      digitalWrite(4, HIGH);
      delay(FIREPINDURATION);
      digitalWrite(4, LOW);
    }
    
}

void setup() {
 
  Serial.begin(57600);
    pinMode(1, OUTPUT);
    pinMode(2, OUTPUT);
    pinMode(3, OUTPUT);
    pinMode(4, OUTPUT);
    
    pinMode(8, INPUT);
    pinMode(9, INPUT);

   
    Ethernet.begin(mac, ip);
    websocketServer.begin();
	// Add the callback function to the server. You can have several callback functions
	// if you like, they will be called with the same data and in the same order as you
	// add them to the server. If you have more than one, define CALLBACK_FUNCTIONS before including
	// WebSocket.h
    websocketServer.addAction(&dataReceivedAction);
    delay(1000); // Give Ethernet time to get ready
}

void loop() {
        
    if (digitalRead(8) == LOW && !pin8ButtonLastValue) {
      Serial.println("Button on Pin 8 Pressed");
      websocketServer.sendData("ButtonOn8Pressed");
      pin8ButtonLastValue = true;
    }
    else if (digitalRead(8) == HIGH) pin8ButtonLastValue = false;
    
    if (digitalRead(9) == LOW && !pin9ButtonLastValue) {
      Serial.println("Button on Pin 9 Pressed");
      websocketServer.sendData("ButtonOn9Pressed");
      pin9ButtonLastValue = true;
    }
    else if (digitalRead(9) == HIGH) pin9ButtonLastValue = false;
        
        
    // This pulls any connected client into an active stream.
    websocketServer.socket_client = websocketServer.socket_server.available();

    // If there is a connected client.
    if (websocketServer.socket_client.connected()) {
        // Check request and look for websocket handshake
        Serial.println("Client connected, try for websocket upgrade");
        if (websocketServer.analyzeRequest(BUFFER_LENGTH)) Serial.println("New Websocket established");

        //Handle any incoming events
        websocketServer.socketStream(BUFFER_LENGTH);
    }
}

