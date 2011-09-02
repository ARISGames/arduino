// I2C binary logger example

#include <Wire.h>
#include <SdFat.h>
#include <SdFatUtil.h>

SdFat sd;

SdFile file;

#define error(msg) sd.errorHalt_P(PSTR(msg))
//------------------------------------------------------------------------------
bool over = false;
//------------------------------------------------------------------------------
const uint16_t RING_DIM = 600;
uint8_t ring[RING_DIM];
volatile uint16_t head = 0;
volatile uint16_t tail = 0;
uint32_t syncCluster = 0;
//------------------------------------------------------------------------------
// buffer data from I2C
void receiveEvent(int howMany) {
  for (int i = 0; i < howMany; i++) {
    ring[head] = Wire.receive();
    uint16_t next = head < (RING_DIM - 1) ? head + 1 : 0;
    // check for space
    if (next != tail) {
      // space so advance head
      head = next;
    } else {
      // can't advance head so data is dropped
      over = true;
    }
  }
}
//------------------------------------------------------------------------------
void setup() {
  Serial.begin(9600);
  Serial.println("Type any character to start");
  while (!Serial.available());
  Serial.print("FreeRam: ");
  Serial.println(FreeRam());
  
  if (!sd.init()) sd.initErrorHalt();
  if (!file.open("I2C_TEST.TXT", O_WRITE | O_CREAT | O_TRUNC)) error("open");
  file.print("Start ");
  file.println(millis());
  file.sync();
  
  syncCluster = file.curCluster();
  Serial.println("Started - type any character to stop");
  Serial.flush();  

  Wire.begin(4);                // join i2c bus with address #4
  Wire.onReceive(receiveEvent); // register event
}
//------------------------------------------------------------------------------
void loop() {
  uint16_t n;
  uint16_t next;
  // disable interrupts to get 16-bit head
  cli();
  uint16_t h = head;
  sei();
  
  if (h != tail) {
    if (tail < h) {
      // amount to write
      n = h - tail;
      // new tail
      next = h;
    } else {  // h < tail
      // amount to write
      n = RING_DIM - tail;
      // new tail
      next = 0;
    }
    if (file.write(&ring[tail], n) != n) error("write");
    cli();
    tail = next;
    sei();
  }
  if (file.curCluster() != syncCluster) {
    if (!file.sync()) error("sync");
    syncCluster = file.curCluster();
  }
  if (!Serial.available() && !over) return;
  cli();
  file.print("Stop ");
  file.println(millis());
  file.close();
  if (over) error("overrun"); 
  Serial.println("stoped");
  while(1);
}
