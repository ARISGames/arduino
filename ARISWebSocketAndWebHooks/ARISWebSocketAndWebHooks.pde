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
#include "MD5.c"

#define PREFIX "/ws"
#define PORT 8080
#define FIREPINDURATION 500
// CRLF characters to terminate lines/handshakes in headers.
#define CRLF "\r\n"

byte mac[] = { 0x90, 0xA2, 0xDA, 0x00, 0x49, 0xDE };
byte ip[] = { 144, 92, 40, 45 };
byte gateway[] = { 144,92,40, 1 };
byte subnet[] = { 255, 255, 255, 128 };

Server server(8080);

boolean pin8ButtonLastValue = false;
boolean pin9ButtonLastValue = false;

void setup() {

  Serial.begin(57600);
  pinMode(1, OUTPUT);
  pinMode(2, OUTPUT);
  pinMode(3, OUTPUT);
  pinMode(4, OUTPUT); 
  pinMode(8, INPUT);
  pinMode(9, INPUT);

   
  Ethernet.begin(mac, ip, gateway, subnet);
  delay(1000); // Give Ethernet time to get ready
  server.begin();
  
}


void sendData(const char *str) {
    Serial.print("Sending data: ");
    Serial.println(str);
    server.print((uint8_t) 0x00); // Frame start
    server.print(str);
    server.print((uint8_t) 0xFF); // Frame end
}




void loop() {
  // listen for incoming clients
  Client client = server.available();
  if (client) {    
     
    /***********************************************************************
    //
    // WebSocket Handshakes
    //
    ***********************************************************************/
    String temp = String(60);
    String readData;
    String origin;
    String host;
    char bite;
    bool foundupgrade = false;
    String key[2];
    unsigned long intkey[2];
    
        
    //Read client handshake
    while ((bite = client.read()) != -1) {
        temp += bite;
        if (bite == '\n') {
            Serial.print("Got Line: " + temp);
            // TODO: Should ignore case when comparing and allow 0-n whitespace after ':'. See the spec:
            // http://www.w3.org/Protocols/rfc2616/rfc2616-sec4.html
            if (!foundupgrade && temp.startsWith("Upgrade: WebSocket")) {
                // OK, it's a websockets handshake for sure
                foundupgrade = true;	
            } else if (temp.startsWith("Origin: ")) {
                origin = temp.substring(8,temp.length() - 2); // Don't save last CR+LF
            } else if (temp.startsWith("Host: ")) {
                host = temp.substring(6,temp.length() - 2); // Don't save last CR+LF
            } else if (temp.startsWith("Sec-WebSocket-Key1")) {
                key[0]=temp.substring(20,temp.length() - 2); // Don't save last CR+LF
            } else if (temp.startsWith("Sec-WebSocket-Key2")) {
                key[1]=temp.substring(20,temp.length() - 2); // Don't save last CR+LF
            }       
            temp = "";		
        }
        //Else just keep looping until we get an /n
    }
    temp += 0; // Terminate string

    // Assert that we have all headers that are needed. If so, go ahead and
    // send response headers.
    if (foundupgrade == true && host.length() > 0 && key[0].length() > 0 && key[1].length() > 0) {
        // All ok, proceed with challenge and MD5 digest
        char key3[9] = {0};
        // What now is in temp should be the third key
        temp.toCharArray(key3, 9);
        
        // Process keys
        for (int i = 0; i <= 1; i++) {
            unsigned int spaces =0;
            String numbers;
            
            for (int c = 0; c < key[i].length(); c++) {
                char ac = key[i].charAt(c);
                if (ac >= '0' && ac <= '9') {
                    numbers += ac;
                }
                if (ac == ' ') {
                    spaces++;
                }
            }
            char numberschar[numbers.length() + 1];
            numbers.toCharArray(numberschar, numbers.length()+1);
            intkey[i] = strtoul(numberschar, NULL, 10) / spaces;		
        }
        
        unsigned char challenge[16] = {0};
        challenge[0] = (unsigned char) ((intkey[0] >> 24) & 0xFF);
        challenge[1] = (unsigned char) ((intkey[0] >> 16) & 0xFF);
        challenge[2] = (unsigned char) ((intkey[0] >>  8) & 0xFF);
        challenge[3] = (unsigned char) ((intkey[0]      ) & 0xFF);	
        challenge[4] = (unsigned char) ((intkey[1] >> 24) & 0xFF);
        challenge[5] = (unsigned char) ((intkey[1] >> 16) & 0xFF);
        challenge[6] = (unsigned char) ((intkey[1] >>  8) & 0xFF);
        challenge[7] = (unsigned char) ((intkey[1]      ) & 0xFF);
        
        memcpy(challenge + 8, key3, 8);
        
        unsigned char md5Digest[16];
        MD5(challenge, md5Digest, 16);
        
        Serial.println("Sending response header:");
        String responseHeader;
        responseHeader += "HTTP/1.1 101 Web Socket Protocol Handshake\r\n";
        responseHeader += "Upgrade: WebSocket\r\n";
        responseHeader += "Connection: Upgrade\r\n";
        responseHeader += "Sec-WebSocket-Origin: ";        
        responseHeader += origin;
        responseHeader += CRLF;
        
        // The "Host:" value should be used as location
        responseHeader += "Sec-WebSocket-Location: ws://";
        responseHeader += host;
        responseHeader += "/";
        responseHeader += CRLF;
        responseHeader += CRLF;
        Serial.println(responseHeader);
        client.print(responseHeader);
        client.write(md5Digest, 16);
        Serial.println("Socket Connected");
    } else {
        Serial.println("This is not a Handshake"); 
        //Trim off the 0 and 0xFF
        readData = readData.substring(1,readData.length()-1);
        Serial.println(readData); 
        /*
       //Incoming websocket data should start with a 0 and end with (uint8_t)0xFF
        if (readData.startsWith(0)) {
          Serial.println("Started with 0");
          //parse over the 0
          readData = readData.substring(1,readData.length());
          Serial.println("readData after 0: "+readData);
          char lastChar = readData.substring(readData.length()-1);
          if ((uint8_t) lastChar == 0xFF) {
            Serial.println("Ended with with 0xFF");
          }
        }
        */
         
        
        readData = "";
     
    }        
  }//if client
  
  
  /***********************************************************************
  //
  // Outgoing Events
  //
  ***********************************************************************/
  //Ok No more handshakes. Let's get to buisness
  if (digitalRead(8) == LOW && !pin8ButtonLastValue) {
    Serial.println("Button on Pin 8 Pressed");
    sendData("ButtonOn8Pressed");
    pin8ButtonLastValue = true;
  }
  else if (digitalRead(8) == HIGH) pin8ButtonLastValue = false;
  
  
  
  
  
  
  
  
  
  
  
}//loop

