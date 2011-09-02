// master
#include <Wire.h>
void setup(){
  Wire.begin();
}
char msg[] = "000\r\n";
int n = 0;

// send 1000 five byte messages/sec
void loop() {
  uint32_t m = micros();
  msg[0] = '0' + n / 100;
  msg[1] = '0' + (n / 10) % 10;
  msg[2] = '0' + n % 10;
  n = n < 999 ? n + 1 : 0;
  Wire.beginTransmission(4);
  Wire.send(msg);
  Wire.endTransmission();
  m = micros() - m;
  if (m < 1000) delayMicroseconds(1000 - m);
}
