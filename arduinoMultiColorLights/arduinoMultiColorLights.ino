#include <MultiLight.h>


#include <SPI.h>
#include <Ethernet.h>

#include <PusherClient.h>

IPAddress server(50,57,138,30); // ARIS Server
byte mac[] = { 0x90, 0xA2, 0xDA, 0x00, 0x49, 0xDE };
byte ip[] = { 192, 168, 2, 2 };
byte gateway[] = { 192, 168, 2, 1 };
byte subnet[] = { 255, 255, 255, 0 };

MultiLight multiLight = MultiLight();

EthernetClient arisClient;

void setup() {
  
  Serial.begin(9600);
 
  multiLight.setPins(5,6,7);  //Set up pins 

  ethernetConnecting();
  
  Ethernet.begin(mac,ip);
 
  delay(1000); //Give time to initialize before connecting
  
  if(arisClient.connect(server,80)){
     ethernetSucceeded();
    }
  else{
     ethernetFailed();
    }

}

void loop() {

}

void ethernetConnecting(){
  Serial.println("Ethernet Connecting");

  multiLight.setColor(multiLight.COLOR_YELLOW);
 
}

void ethernetFailed(){
  Serial.println("Ethernet Failed");
    
   multiLight.setColor(multiLight.COLOR_RED);


}

void ethernetSucceeded(){
  Serial.println("Ethernet Succeeded");

  multiLight.setColor(multiLight.COLOR_GREEN);

    
}



