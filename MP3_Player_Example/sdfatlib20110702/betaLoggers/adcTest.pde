// Test program for MCP_SAR library development.
// Used with MCP3201, MCP3202, and MCP3204 connected to Arduino.
//
// SdFat for fastDigital functions
#include <SdFat.h>
// must run on a 168/328 Arduino.
// pins 6, 7, 8, and 9 on the Mega shouldn't be used.
// These Mega pins don't support fast atomic I/O ops.
const int8_t MCP_SAR_CLK_PIN = 9;
const int8_t MCP_SAR_DOUT_PIN  = 8;
const int8_t MCP_SAR_DIN_PIN  = 7;
const int8_t MCP3201_CS_PIN  = 6;
const int8_t MCP3202_CS_PIN  = 5;
const int8_t MCP3204_CS_PIN  = 4;

#include <MCP_SAR.h>
void setup() {
  Serial.begin(9600);
  initMcpSar(MCP3201_CS_PIN);
  initMcpSar(MCP3202_CS_PIN);
  initMcpSar(MCP3204_CS_PIN);
}
void loop() {
  uint16_t adc;  
  adc = 0;
  for (uint8_t i = 0; i < 16; i++) {
    adc += readMCP3201(MCP3201_CS_PIN);
  }
  // average of 16 reads
  adc /= 16;
  Serial.print(adc);
  Serial.print(',');
  Serial.println(5.0 * adc / 4095, 3); 
  Serial.println();

  for (uint8_t ch = 0; ch < 2; ch++) {
    uint16_t adc = readMCP3202(MCP3202_CS_PIN, ch | MCP_CTRL_SGL_DIFF);
    Serial.print(adc);
    Serial.print(',');
    Serial.println(5.0  * adc / 4095, 3);
  } 
  Serial.println();
 
  for (uint8_t ch = 0; ch < 4; ch++) {
    uint16_t adc = readMCP3204(MCP3204_CS_PIN, ch | MCP_CTRL_SGL_DIFF);
    Serial.print(adc);
    Serial.print(',');
    Serial.println(5.0  * adc / 4095, 3);
  }
  delay(1500);
  Serial.println();
}
