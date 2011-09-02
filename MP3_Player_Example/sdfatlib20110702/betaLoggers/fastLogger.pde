/*
 * Demo data logger using a ring buffer to capture data in an interrupt
 * routine and format the data using fast format functions in loop().
 *
 * For best results use an high quality freshly formatted SD card.
 *
 * Data from an ADC is captured in the timer two ISR
 *
 * Default ADC is analog pin zero.  Define USE_MCP_SAR to
 * use a Microchip MCP3201 ADC.
 *
 * Data overruns are indicated by a point of the form:
 *
 * #<count>
 *
 * If count is less than 15, count is the number of dropped data points.
 * A value of 15 indicate 15 or more data points were dropped.
 */
#include <BufferedWriter.h>
#include <SdFat.h>
#include <SdFatUtil.h>
#include <TimerTwo.h>
//------------------------------------------------------------------------------
// uncomment next line to use a Microchip MCP3201 SAR ADC
//#define USE_MCP_SAR

// SD chip select pin
const uint8_t chipSelect = SS_PIN;

// led to indicate overrun occured, set to -1 if no led.
const int8_t RED_LED_PIN = 3;

// interval between timer interrupts in microseconds
const uint16_t TICK_TIME_USEC = 250;

// number of ticks between data points
const uint16_t TICK_LOG_COUNT = 1;

// interval in usec between data points.
const uint32_t LOG_INTERVAL_USEC = (uint32_t)TICK_TIME_USEC * TICK_LOG_COUNT;

// Maximum time between sync() calls in milliseconds.  If MAX_SYNC_TIME_MSEC is
// set to zero, sync will only be called when a character is typed to stop the
// program.  This allows the fastest possible rate.
const uint32_t MAX_SYNC_TIME_MSEC = 1000;

// To get the fastest rate set LOG_DATA_IN_HEX true and MAX_SYNC_TIME_MSEC zero.
const bool LOG_DATA_IN_HEX = false;

#ifdef USE_MCP_SAR
//------------------------------------------------------------------------------
// must define ADC pins before #include <MCP_SAR.h>
#if defined(__AVR_ATmega1280__)\
|| defined(__AVR_ATmega2560__)
const int8_t MCP_SAR_CLK_PIN   = 54;  // analog pin 0
const int8_t MCP_SAR_DOUT_PIN  = 55;  // analog pin 1
const int8_t MCP_SAR_DIN_PIN   = -1;  // not used for MCP3201
const int8_t MCP3201_CS_PIN    = 56;  // analog pin 2
#else  // MEGA_CHIP
const int8_t MCP_SAR_CLK_PIN   = 14;  // analog pin 0
const int8_t MCP_SAR_DOUT_PIN  = 15;  // analog pin 1
const int8_t MCP_SAR_DIN_PIN   = -1;  // not used for MCP3201
const int8_t MCP3201_CS_PIN    = 16;  // analog pin 2
#endif  // MEGA_CHIP
#include <MCP_SAR.h>
//  read from MCP3201

inline void initAdc() {initMcpSar(MCP3201_CS_PIN);}

inline uint16_t readAdc() {return readMCP3201(MCP3201_CS_PIN);}

#else   // USE_MCP_SAR
// read from analog pin zero

inline void initAdc() {}

inline uint16_t readAdc() {return analogRead(0);}
#endif  // US_MCP_SAR
//------------------------------------------------------------------------------
// File system object
SdFat sd;

// file for logging data
SdFile file;

// fast text formatter
BufferedWriter bw;
//------------------------------------------------------------------------------
// store error strings in flash
#define error(s) sd.errorHalt_P(PSTR(s));
//------------------------------------------------------------------------------
// ring buffer for binary ADC data
#if defined(__AVR_ATmega1280__)\
|| defined(__AVR_ATmega2560__)
// Mega
const uint16_t RING_DIM = 3000;
#else
// 328 cpu
const uint16_t RING_DIM = 400;
#endif
uint16_t ring[RING_DIM];
volatile uint16_t head = 0;
volatile uint16_t tail = 0;
//------------------------------------------------------------------------------
// number of points in the ring buffer
inline uint16_t ringAvailable() {
  return (head >= tail ? 0 : RING_DIM) + head - tail;
}
//------------------------------------------------------------------------------
// next value for head/tail
inline uint16_t ringNext(uint16_t ht) {
  return ht < (RING_DIM - 1) ? ht + 1 : 0;
}
//------------------------------------------------------------------------------
// interrupt routine for ADC read.
ISR(TIMER2_COMPA_vect) {
  // overrun count
  static uint16_t over = 0;
  
  // ticks until time to log a data point
  static uint16_t ticks = 0;
  
  // return if not time to log data
  if (ticks-- > 1) return;
  
  // reset tick count
  ticks = TICK_LOG_COUNT;
  
  // check for ring full
  uint16_t next = ringNext(head);
  if (next != tail) {
    // log data
    ring[head] = readAdc() | over;
    head = next;
    over = 0;
  } else {
    // use high four bits to count overruns
    if (over < 0XF000) over += 0X1000;
  }
}
//------------------------------------------------------------------------------
void setup() {
  Serial.begin(9600);
  
  PgmPrintln("Type any character to start.");
  while (!Serial.available());
  Serial.flush();
  
  if (RED_LED_PIN >=0) {
    pinMode(RED_LED_PIN, OUTPUT);
    digitalWrite(RED_LED_PIN, LOW);
  }
  // initialize ADC
  initAdc();
  
  // set tick time
  if (!TimerTwo::init(TICK_TIME_USEC)
    || TICK_TIME_USEC != TimerTwo::period()) {
    // TICK_TIME_USEC is too large or period rounds to a different value
    error("TimerTwo::init");
  }
  PgmPrint("FreeRam: ");
  Serial.println(FreeRam());
  PgmPrint("Log Interval: ");
  Serial.print(LOG_INTERVAL_USEC);
  PgmPrintln(" usec");
  
  // initialize file system.
  if (!sd.init(SPI_FULL_SPEED, chipSelect)) sd.initErrorHalt();
  
  // create a new file
  char name[13];
  strcpy_P(name, PSTR("FAST00.CSV"));
  for (uint8_t n = 0; n < 100; n++) {
    name[4] = '0' + n / 10;
    name[5] = '0' + n % 10;
    if (file.open(name, O_WRITE | O_CREAT | O_EXCL)) break;
  }
  if (!file.isOpen()) error("file.open");

  file.write_P(PSTR("Log Interval usec: "));
  file.println(LOG_INTERVAL_USEC);
  
  bw.init(&file);
  
  PgmPrint("Logging to: ");
  Serial.println(name);
  PgmPrintln("Type any character to stop.");
  
  // start calls to ISR
  TimerTwo::start();
}
//------------------------------------------------------------------------------
// cluster for last sync
uint32_t syncCluster = 0;

// time of last sync
uint32_t syncTime = 0;

void loop() {
  // 16-bit memory read is not atomic so disable interrupts
  cli();
  uint16_t n = ringAvailable();
  sei();
  
  for (uint16_t i = 0; i < n; i++) {
    // get data point
    uint16_t d = ring[tail];

    // disable interrupts since 16-bit store is not atomic
    cli();
    tail = ringNext(tail);
    sei();
    
    // check for overrun
    if (d & 0XF000) {
      if (RED_LED_PIN >= 0) {
        // light overrun led
        digitalWrite(RED_LED_PIN, HIGH);
      }
      // write overrun indicator
      bw.putChar('#');
      bw.putNum(d >> 12);
      bw.putCRLF();
      d &= 0XFFF;
    }
    // format the data point
    if (LOG_DATA_IN_HEX) {
      bw.putHex(d);
    } else {
      bw.putNum(d);
    }
    bw.putCRLF();
  }
  // check for write error
  if (file.writeError) error("write");
  
  // stop program if user types a character
  if (Serial.available()) {
    TimerTwo::stop();
    bw.writeBuf();
    if (!file.close()) error("file.close");
    cli();
    PgmPrintln("Stopped!");
    while (1);
  }
  // never sync if zero
  if (MAX_SYNC_TIME_MSEC == 0) return;
  
  if (syncCluster == file.curCluster()
    && (millis() - syncTime) < MAX_SYNC_TIME_MSEC) return;
    
  if (!file.sync()) error("file.sync");
  syncCluster = file.curCluster();
  syncTime = millis();
}
