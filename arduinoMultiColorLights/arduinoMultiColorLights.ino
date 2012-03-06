
#include <SPI.h>
#include <Ethernet.h>

#include <PusherClient.h>

IPAddress server(50,57,138,30); // ARIS Server
String socket_id = "socket_id";
byte mac[] = { 0x90, 0xA2, 0xDA, 0x00, 0x49, 0xDE };
int inputPin = 3;
int ledPin = 2;

const int RED_LED_PIN = 9;
const int GREEN_LED_PIN = 10;
const int BLUE_LED_PIN = 11;

int redIntensity = 0;
int greenIntensity = 0;
int blueIntensity = 0;

const int DISPLAY_TIME = 100; //millis
EthernetClient arisClient;
PusherClient client;

void setup() {
  pinMode(inputPin, INPUT);
    pinMode(ledPin, OUTPUT);
Serial.begin(9600);


  ethernetConnecting();

    delay(3000);
    
  ethernetSucceeded();
  
      delay(3000);
      
      ethernetFailed();



}

void loop() {
 
 if(digitalRead(inputPin) == HIGH){
  digitalWrite(ledPin, LOW);
 }
 else{
   digitalWrite(ledPin, HIGH);
  // client.triggerEvent("aris","client-test", "{\"name\": \"Joe\", \"message_count\": 23}");
   Serial.println("Button Pressed");
 }

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
      redIntensity = 255;
      greenIntensity = 255;
  for(blueIntensity= 225;blueIntensity > 0;blueIntensity-=5){



      analogWrite(GREEN_LED_PIN, 20);
    analogWrite(BLUE_LED_PIN, 0);
    analogWrite(RED_LED_PIN, 0);
    

    delay(DISPLAY_TIME);
  }
}



