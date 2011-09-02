/**
 * This program logs data from a Microchip ADC to a binary file.
 * The file contains 8-bit bytes or 16 bit Little Endian unsigned integers.
 *
 * The each 512 byte block of the file has a 16 bit header followed by
 * up to 510 bytes of data.  Bits in the 16 bit header are:
 *
 * 0X8000 - Indicates block has data
 * 0X7FFF - number of missed samples between this block and the previous block.
 *
 * Samples are taken every TIMER_USEC microseconds.  TIMER_USEC can be as low
 * as 25 microseconds if you have a high quality SD card such as the new
 * SanDisk Extreme 30 MB/sec cards.  The cards must have very low write latency.
 *
 * If you SD card has longer latency, it may be necessary to use a longer
 * interval between samples.  Using a Mega Arduino helps overcome latency
 * problems since 13 512 byte buffers will be used.
 *
 * The program creates a contiguous file with FILE_BLOCK_COUNT 512 byte blocks.
 * This file is flash erased using special SD commands.
 *
 * Data is written to the file using SD multiple block write commands.
 *
 */
#include <SdFat.h>
#include <SdFatUtil.h>
#include <TimerTwo.h>
#include <BufferedWriter.h>

// SD chip select pin
const uint8_t chipSelect = SS_PIN;

// interval between data points
const uint16_t TIMER_USEC = 25;

// max file size in blocks
const uint32_t FILE_BLOCK_COUNT = 256000;

// log file name
#define FILE_NAME "LOGFILE.BIN"

// pin to indicate overrun, set to -1 if not used
const int8_t RED_LED_PIN = 3;
//------------------------------------------------------------------------------
// must define ADC SPI pins before #include <MCP_SAR.h>
#if defined(__AVR_ATmega1280__)\
|| defined(__AVR_ATmega2560__)
const int8_t MCP_SAR_CLK_PIN   = 54;  // analog pin 0
const int8_t MCP_SAR_DOUT_PIN  = 55;  // analog pin 1
const int8_t MCP_SAR_DIN_PIN   = -1;  // ADC does not have Data In
const int8_t MCP_SAR_CS_PIN    = 56;  // analog pin 2
#else  // MEGA_TEST
const int8_t MCP_SAR_CLK_PIN   = 14;  // analog pin 0
const int8_t MCP_SAR_DOUT_PIN  = 15;  // analog pin 1
const int8_t MCP_SAR_DIN_PIN   = -1;  // ADC does not have Data In
const int8_t MCP_SAR_CS_PIN    = 16;  // analog pin 2
#endif  // MEGA_TEST
#include <MCP_SAR.h>
//------------------------------------------------------------------------------
SdFat sd;
#define error(msg) sd.errorHalt_P(PSTR(msg))
//==============================================================================
// select ADC/debug
#define USE_MPC3201
//------------------------------------------------------------------------------
#ifdef USE_MPC3001
// log single channel 8-bit ADC values

// one bytes per record
const uint8_t DATA_RECORD_SIZE = 1;

// read sensor in ISR
inline void readSensor(uint8_t* rec) {
  rec[0] = readMCP3001(MCP_SAR_CS_PIN);
}
// printRecord
inline void printRecord(Print* pr, uint8_t* rec) {
  pr->println(rec[0], DEC);
}
// write record
inline void writeRecord(BufferedWriter* bw, uint8_t* rec) {
  bw->putNum(rec[0]);
  bw->putCRLF();
}
#endif  // USE_MPC3001
//------------------------------------------------------------------------------
#ifdef USE_MPC3201
// log single channel 12-bit ADC values

// two bytes per record
const uint8_t DATA_RECORD_SIZE = 2;

// read sensor in ISR
inline void readSensor(uint8_t* rec) {
  uint16_t* adc = (uint16_t*)rec;
  adc[0] = readMCP3201(MCP_SAR_CS_PIN);
}
// printRecord
inline void printRecord(Print* pr, uint8_t* rec) {
  uint16_t* adc = (uint16_t*)rec;
  pr->println(adc[0]);
}
// write record
inline void writeRecord(BufferedWriter* bw, uint8_t* rec) {
  uint16_t* adc = (uint16_t*)rec;
  bw->putNum(adc[0]);
  bw->putCRLF();
}
#endif  // USE_MPC3201
//------------------------------------------------------------------------------
#ifdef USE_DEBUG_ISR
// log test counter

// four bytes per record
const uint8_t DATA_RECORD_SIZE = 2;

static uint16_t dbgCount = 0;

static uint16_t dbgCheck = 0;

// read sensor in ISR
inline void readSensor(uint8_t* rec) {
  uint16_t* adc = (uint16_t*)rec;
  adc[0] = dbgCount++;
}
// printRecord
inline void printRecord(Print* pr, uint8_t* rec) {
  uint16_t* adc = (uint16_t*)rec;
  pr->println(adc[0]);
}
// write record
inline void writeRecord(BufferedWriter* bw, uint8_t* rec) {
  uint16_t* adc = (uint16_t*)rec;
  bw->putNum(adc[0]);
  bw->putCRLF();
  if (adc[0] != dbgCheck++) error("dbgCheck");
}
#endif  // USE_DEBUG_ISR
//==============================================================================
// logger will use SdFat's buffer plus BUFFER_BLOCK_COUNT additional buffers
#if defined(__AVR_ATmega1280__)\
|| defined(__AVR_ATmega2560__)
// Mega - use total of 13 512 byte buffers
const uint8_t BUFFER_BLOCK_COUNT = 12;
#else
// 328 cpu -  use total of two 512 byte buffers
const uint8_t BUFFER_BLOCK_COUNT = 1;
#endif
//------------------------------------------------------------------------------
// queues of 512 byte SD blocks
const uint8_t QUEUE_DIM = 16;  // Must be a power of two!

uint8_t* emptyQueue[QUEUE_DIM];
uint8_t emptyHead;
uint8_t emptyTail;

uint8_t* fullQueue[QUEUE_DIM];
uint8_t fullHead;
uint8_t fullTail;

// queueNext assumes QUEUE_DIM is a power of two
inline uint8_t queueNext(uint8_t ht) {return (ht + 1) & (QUEUE_DIM -1);}

// get first 16 bits of block
inline uint16_t getHeader(uint8_t* b) {return *(uint16_t*)b;}

// set first 16 bits of block
inline void setHeader(uint8_t* b, uint16_t v) {*(uint16_t*)b = v;}
//------------------------------------------------------------------------------
// Interrupt Service Routine

//pointer to current buffer
static uint8_t* isrBuf;

// index for next data byte
static uint16_t isrIn;

// overrun count
static uint16_t isrOver;

ISR(TIMER2_COMPA_vect) {
  // check for buffer needed
  if (isrBuf == 0) {
    if (emptyHead != emptyTail) {
      // remove buffer from empty queue
      isrBuf = emptyQueue[emptyTail];
      emptyTail = queueNext(emptyTail);
      isrIn = 2;
    } else {
      // no buffers - count overrun
      if (isrOver < 0X7FFF) isrOver++;
      return;
    }
  }
  // get sensor data
  readSensor(isrBuf + isrIn);
  isrIn += DATA_RECORD_SIZE;
  // check for buffer full
  if (isrIn > (512 - DATA_RECORD_SIZE)) {
    // record any overruns
    setHeader(isrBuf, 0X8000 | isrOver);

    // put buffer isrIn full queue
    fullQueue[fullHead] = isrBuf;
    fullHead = queueNext(fullHead);
    
    //set buffer needed and clear overruns
    isrBuf = 0;
    isrOver = 0;
  }
}
//------------------------------------------------------------------------------
// convert binary file to text file
void binaryToText() {
  uint8_t lastPct;
  uint8_t buf[512];
  uint32_t t = 0;
  uint32_t syncCluster = 0;
  SdFile binFile;
  SdFile textFile;
  BufferedWriter bw;
  
  if (!binFile.open(FILE_NAME, O_READ)) {
    error("open binary");
  }
  // create a new binFile
  char name[13];
  strcpy_P(name, PSTR("DATA00.TXT"));
  for (uint8_t n = 0; n < 100; n++) {
    name[4] = '0' + n / 10;
    name[5] = '0' + n % 10;
    if (textFile.open(name, O_WRITE | O_CREAT | O_EXCL)) break;
  }
  if (!textFile.isOpen()) error("open textFile");
  PgmPrint("Writing: ");
  Serial.println(name);
  
  bw.init(&textFile);
  
  while (!Serial.available() && binFile.read(buf, 512) == 512) {
    uint16_t i;
    uint16_t header = getHeader(buf);
    if (header == 0) break;
    uint16_t over = header & 0X7FFF;
    if (over) {
      bw.putStr("OVERRUN,");
      bw.putNum(over);
      bw.putCRLF();
    }
    for (i = 2; i <= (512 - DATA_RECORD_SIZE); i += DATA_RECORD_SIZE) {
      writeRecord(&bw, buf + i);
    }
    
    if (textFile.curCluster() != syncCluster) {
      bw.writeBuf();
      textFile.sync();
      syncCluster = textFile.curCluster();
    }
    if ((millis() -t) > 1000) {
      uint8_t pct = binFile.curPosition() / (binFile.fileSize()/100);
      if (pct != lastPct) {
        t = millis();
        lastPct = pct;
        Serial.print(pct, DEC);
        Serial.println('%');
      }
    }
    if (Serial.available()) break;
  }
  bw.writeBuf();
  textFile.close();
  PgmPrintln("Done");
}
//------------------------------------------------------------------------------
// read data file and check for overruns
void checkOverrun() {
  SdFile file;
  bool headerPrinted = false;
  uint8_t buf[512];
  uint32_t bgnBlock, endBlock;
  uint32_t bn = 0;
  
  Serial.println();
  PgmPrintln("Checking for overrun errors");
  if (!file.open(FILE_NAME, O_READ)) {
    error("open");
  }
  if (!file.contiguousRange(&bgnBlock,&endBlock)) {
    error("contiguousRange");
  }
  while (file.read(buf, 512) == 512) {
    uint16_t header = getHeader(buf);
    if (header == 0) break;
    uint16_t over = header & 0X7FFF;
    if (over) {
      if (!headerPrinted) {
        Serial.println();
        PgmPrintln("Overruns:");
        PgmPrintln("fileBlockNumber,sdBlockNumber,overrunCount");
        headerPrinted = true;
      }
      Serial.print(bn);
      Serial.print(',');
      Serial.print(bgnBlock + bn);
      Serial.print(',');
      Serial.println(over);
    }
    bn++;
  }
  if (!headerPrinted) {
    PgmPrintln("No errors found");
  } else {
    PgmPrintln("Done");
  }
}
//------------------------------------------------------------------------------
// dump data file to Serial
void dumpData() {
  SdFile file;
  uint8_t buf[512];
  if (!file.open(FILE_NAME, O_READ)) {
    error("open");
  }
  while (!Serial.available() && file.read(buf , 512) == 512) {
    uint16_t i;
    uint16_t header = getHeader(buf);
    if (header == 0) break;
    uint16_t over = header & 0X7FFF;
    if (over) {
      PgmPrint("OVERRUN,");
      Serial.println(over);
    }
    for (i = 2; i <= (512 - DATA_RECORD_SIZE); i += DATA_RECORD_SIZE) {
      printRecord(&Serial, buf + i);
    }
  }
  PgmPrintln("Done");
}
//------------------------------------------------------------------------------
// log data
uint32_t const ERASE_SIZE = 262144L;
void logData() {
  SdFile file;
  uint32_t bgnBlock, endBlock;  
  // allocate extra buffer space
  uint8_t block[512 * BUFFER_BLOCK_COUNT];

  Serial.println();
  
  // initialize ADC
  initMcpSar(MCP_SAR_CS_PIN);
  
  // delete old log file
  if (sd.exists(FILE_NAME)) {
    PgmPrintln("Deleting old file");
    if (!sd.remove(FILE_NAME)) error("remove");
  }
  // create new file
  PgmPrintln("Creating new file");
  if (!file.createContiguous(sd.cwd(), FILE_NAME, 512 * FILE_BLOCK_COUNT)) {
    error("create");
  }
  // get address of file on SD
  if (!file.contiguousRange(&bgnBlock, &endBlock)) {
    error("range");
  }
  file.close();
  
  PgmPrintln("Erasing all data");
  // flash erase all data in file
  uint32_t bgnErase = bgnBlock;
  uint32_t endErase;
  while (bgnErase < endBlock) {
    endErase = bgnErase + ERASE_SIZE;
    if (endErase > endBlock) endErase = endBlock;
    if (!sd.card()->erase(bgnErase, endErase)) {
      error("erase");
    }
    bgnErase += ERASE_SIZE;
  }
  // initialize queues
  emptyHead = emptyTail = 0;
  fullHead = fullTail = 0;
  
  // initialize ISR
  isrBuf = 0;
  isrOver = 0;
  
  // use SdFats internal buffer
  uint8_t* cache = (uint8_t*)sd.vol()->cacheClear();
  if (cache == 0) error("cacheClear");
  emptyQueue[emptyHead] = cache;
  emptyHead = queueNext(emptyHead);
  
  // put rest of buffers in empty queue
  for ( uint8_t i = 0; i < BUFFER_BLOCK_COUNT; i++) {
    emptyQueue[emptyHead] = block + 512 * i;
    emptyHead = queueNext(emptyHead);
  }
  // start multiple block write
  if (!sd.card()->writeStart(bgnBlock, FILE_BLOCK_COUNT)) {
    error("writeBegin");
  }
  PgmPrintln("Logging - type any character to stop");
  
  // initialize and start timer two interrupts
  TimerTwo::init(TIMER_USEC);
  TimerTwo::start();
  
  uint32_t bn = 0;
  uint32_t t = millis();
  while (1) {
    if (fullHead != fullTail) {
      // block to write
      uint8_t* block = fullQueue[fullTail];
      
      // write block to SD
      if (!sd.card()->writeData(block)) {
        error("writeData");
      }
      // check for overrun
      if (RED_LED_PIN >= 0) {
        uint16_t d = *((uint16_t*)block);
        if (d & 0X7FFF) digitalWrite(RED_LED_PIN, HIGH);
      }
      // move block to empty queue
      emptyQueue[emptyHead] = block;
      emptyHead = queueNext(emptyHead);
      fullTail = queueNext(fullTail);
      bn++;
    }
    if (Serial.available() || bn == FILE_BLOCK_COUNT) break;
  }
  // stop ISR calls
  TimerTwo::stop();
  
  if (!sd.card()->writeStop()) error("writeStop");

  t = millis() - t;

  // truncate file if recording stoped early
  if (bn != FILE_BLOCK_COUNT) {    
    if (!file.open(FILE_NAME, O_WRITE)) error("open");
    PgmPrint("Truncating file");
    if (!file.truncate(512 * bn)) error("truncate");
    file.close();
  }
  Serial.println();
  PgmPrint("record time ms: ");
  Serial.println(t);
  PgmPrint("block count: ");
  Serial.println(bn);
  PgmPrintln("Done");
}
//------------------------------------------------------------------------------
void setup(void) {
  Serial.begin(9600);
  PgmPrint("FreeRam: ");
  Serial.println(FreeRam());
  
  // initialize file system.
  if (!sd.init(SPI_FULL_SPEED, chipSelect)) {
    sd.initErrorHalt();
  }
}
//------------------------------------------------------------------------------
void loop(void) {
  Serial.flush();
  Serial.println();
  PgmPrintln("type:");
  PgmPrintln("c to check for overruns");
  PgmPrintln("d to dump data to Serial");
  PgmPrintln("r to record ADC data");
  PgmPrintln("t to convert file to text");
  while(!Serial.available()) {}
  char c = Serial.read();
  Serial.flush();
  if (RED_LED_PIN >= 0) {
    pinMode(RED_LED_PIN, OUTPUT);
    digitalWrite(RED_LED_PIN, LOW);
  }
  if (c == 'c') {
    checkOverrun();
  } else if (c == 'd') {
    dumpData();
  } else if (c == 'r') {
    logData();
  } else if(c == 't') {
    binaryToText();
  } else {
    PgmPrintln("Invalid entry");
  }
}
