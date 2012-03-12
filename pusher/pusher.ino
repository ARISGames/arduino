#include <MultiLight.h>
#include <Ethernet.h>
#include <SPI.h>

byte mac[] = { 0x90, 0xA2, 0xDA, 0x00, 0x49, 0xDE };
byte ip[] = { 192, 168, 2, 2 };
byte gateway[] = { 192, 168, 2, 1 };
byte subnet[] = { 255, 255, 255, 0 };
byte aris[] = { 50, 57, 138, 30 };

String pusher_channel = "arduino_test_channel";
String pusher_event_register = "arduino_event_register";
String pusher_event_num[7] = { "arduino_event_1", "arduino_event_2", "arduino_event_3", "arduino_event_4", "arduino_event_5", "arduino_event_6", "arduino_event_7" };

int buttonBuffer = 1000;
int buttonPin[7] = { 3, 4, 5, 6, 7, 8, 9 };
boolean buttonState[7] = { false, false, false, false, false, false, false };
int buttonCountDown[7] = { 0, 0, 0, 0, 0, 0, 0 };

MultiLight multiLight = MultiLight(A0,A1,A2);

EthernetClient arisClient;

void setup() {
  Serial.begin(9600);
  ethernetConnecting();
  Ethernet.begin(mac,ip);
  delay(1000); //Give time to initialize before connecting
  while(!pushMessage("arduino_test_channel", "arduino_event_register", "success"))
    ethernetFailed();
  ethernetSucceeded();
    
  for(int i = 0; i < 7; i++)
    pinMode(buttonPin[i], INPUT);
}

void loop() {
  boolean datareturned = false;
  if(arisClient.available()) datareturned = true;
  while(arisClient.available()) 
    Serial.print((char)arisClient.read());
  if(datareturned)
    Serial.println();
    
  readButtons();
  actButtons();
}











void readButtons()
{
  for(int i = 0; i < 7; i++)
  {
    if(digitalRead(buttonPin[i]) == LOW)
    {
      if(buttonCountDown[i] == 0)
      {
        Serial.println("Button Down");
        Serial.println(i);
        buttonState[i] = true;
        buttonCountDown[i] = buttonBuffer;
      }
    }
    if(buttonCountDown[i] > 0) buttonCountDown[i]--;
  }
}

void actButtons()
{
  for(int i = 0; i < 7; i++)
  {
    if(buttonState[i] == true)
      if(pushMessage(pusher_channel, pusher_event_num[i], "Down")) Serial.println("Success...");
    buttonState[i] = false;
  }
}
boolean pushMessage(String channel, String event, String data)
{
  Serial.println("Pusher Send: "+channel+", "+event+", "+data);
  if(arisClient.connect(aris, 80)){
    ethernetSucceeded();
    String request = "GET /devserver/pusher/public_send.php?public_channel="+channel+"&public_event="+event+"&public_data="+data+" HTTP/1.0";
    Serial.println(request);
    arisClient.println(request);
    arisClient.println();
    arisClient.stop();
    return true;
  }
  return false;
}

void ethernetConnecting()
{
  Serial.println("Ethernet Connecting");
  multiLight.setColor(multiLight.COLOR_YELLOW);
}

void ethernetFailed()
{
  Serial.println("Ethernet Failed");
  multiLight.setColor(multiLight.COLOR_RED);
}

void ethernetSucceeded()
{
  Serial.println("Ethernet Succeeded");
  multiLight.setColor(multiLight.COLOR_GREEN);
}










 /*
 //LightDebugging
 //NOTE FROM PHIL:
 // if you use the analog pins, any output >= 130 registers as HIGH, and anything else as LOW. 
 // This has to do with the way it does mid-range voltage (PWM).
 // So yeah, if we are to save pins by using the analog ones (which makes sense, given that we only need
 // the light for debugging...), we lose the ability to fade :O
  while(true)
  {
    Serial.println("RED");
    multiLight.setColor(multiLight.COLOR_RED);
    delay(1000);
    Serial.println("MAN_RED");
    analogWrite(A0, 130);
    analogWrite(A1, 0);
    analogWrite(A2, 0);
    delay(1000);
    Serial.println("GREEN");
    multiLight.setColor(multiLight.COLOR_GREEN);
    delay(1000);
    Serial.println("MAN_GREEN");
    analogWrite(A0, 0);
    analogWrite(A1, 135);
    analogWrite(A2, 0);
    delay(1000);
    Serial.println("BLUE");
    multiLight.setColor(multiLight.COLOR_BLUE);
    delay(1000);
    Serial.println("MAN_BLUE");
    analogWrite(A0, 0);
    analogWrite(A1, 0);
    analogWrite(A2, 140);
    delay(1000);
  }
  */


