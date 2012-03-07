
#include <SPI.h>
#include <Ethernet.h>

#include <PusherClient.h>



IPAddress server(50,57,138,30); // Google
String socket_id = "socket_id";
byte mac[] = { 0x90, 0xA2, 0xDA, 0x00, 0x49, 0xDE };
byte ip[] = { 192,168,2,7 };
byte gateway[] = { 192,168,2,1 };
byte subnet[] = { 255, 255, 255, 0 };

int inputPin = 3;
int ledPin = 2;
const int RED_LED_PIN = 5;
const int GREEN_LED_PIN = 6;
const int BLUE_LED_PIN = 7;

int redIntensity = 0;
int greenIntensity = 0;
int blueIntensity = 0;
EthernetClient arisClient;
PusherClient client;

void setup() {
  pinMode(inputPin, INPUT);
    pinMode(ledPin, OUTPUT);
Serial.begin(9600);

  Serial.println("Attempting to obtain a DHCP lease...");
ethernetConnecting();
 /*if (Ethernet.begin(mac) == 0) {
    Serial.println("Init Ethernet failed");
    ethernetFailed();
    for(;;)
      ;
  }*/
  Ethernet.begin(mac,ip);
          Serial.println("Ethernet Connected");

  delay(1000);
  
  /*if(client.connect("7fe26fe9f55d4b78ea02")) {
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
  */
  if(arisClient.connect(server,80)){
    Serial.println("Connected to ARIS server");
	          ethernetSucceeded();
  }
  else{
    Serial.println("Could not connect to ARIS server");
    ethernetFailed();
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

  /*if (client.connected()) {
    client.monitor();

  }
  else {
 Serial.println("Client Disconnected");
  }*/
  
  if (arisClient.available()) {
    //Serial.println("arisClient read");
    char c = arisClient.read();
    Serial.print(c);
  }
  
  // if the server's disconnected, stop the client:
  if (!arisClient.connected()) {
    ethernetFailed();
    Serial.println();
    Serial.println("disconnecting.");
    arisClient.stop();

    // do nothing forevermore:
    for(;;)
      ;
  }
  else{

  }
  
}

void connectToServer(){
  
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
  //HANDLE EVENT HERE
  
}

void ethernetConnecting(){
  Serial.println("Ethernet Connecting");


    analogWrite(GREEN_LED_PIN, 18);
    analogWrite(BLUE_LED_PIN, 0);
    analogWrite(RED_LED_PIN, 40);

 
}
void ethernetFailed(){
  Serial.println("Ethernet Failed");
    
 
    analogWrite(GREEN_LED_PIN, 0);
    analogWrite(BLUE_LED_PIN, 0);
    analogWrite(RED_LED_PIN, 20);

}

void ethernetSucceeded(){
  Serial.println("Ethernet Succeeded");

      analogWrite(GREEN_LED_PIN, 20);
    analogWrite(BLUE_LED_PIN, 0);
    analogWrite(RED_LED_PIN, 0);
    
  
}
