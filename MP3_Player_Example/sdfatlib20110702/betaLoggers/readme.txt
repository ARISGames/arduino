This is an early beta so you will need a good knowledge of the Arduino
and C++ programming.  Documentation is limited so this is not for the newbie.

The following programs demonstrate techniques to log data to an SD card at
higher rates by capturing data in a timer driven interrupt routine.

I have been able to log data at up to 40,000 samples per second using
binaryLogger.pde.  This requires an excellent SD card.

I have good luck with the new SanDisk 30 MB/sec Extreme 4 GB cards.  The
key is that these cards have very low write latency when used with
multiple block write commands and flash pre-erase.

You may need to increase the time between samples if your card has higher
latency.  Using a Mega Arduino can help since it has more buffering.

If you use a Mega, avoid the pins described in MegaPins.txt for the ADC.

I have an LED and resistor connected to pin 3 to signal data overruns.
You can disable this feature by setting the pin number negative:

// led to indicate overrun occurred, set to -1 if no led.
const int8_t RED_LED_PIN = 3;

adcTest.pde - Test program for development of MCP_SAR library.

binaryLogger.pde - Read from a MCP3201 or MCP3001 ADC and log
                   the data to a binary file.

fastLogger.pde - Read from analog pin zero or a MCP3201 ADC
                 and log the data to a text file.


i2cSlaveLogger.pde receives data sent from i2cMasterSender.pde and
writes it to a file.  The I2C pins of the two arduinos must be
connected.  SDA to SDA and SCL to SCL.

i2cMasterSender.pde - This program sends 1000 messages per second over
                      the I2C bus.  Each message is five bytes long.

i2cSlaveLogger.pde - This program receives messages from the I2C
                     bus and writes them to a file.


These programs require the following three libraries to installed:

BufferedWriter - Programs that speeds up writing text files.

MCP_SAR - Bit-bang SPI programs to read MicroChip MCP3201, MCP3202, MCP3204,
          and MCP3208 SAR ADCs.
          
TimerTwo - Programs to initialize timer 2 interrupts.

Place these three folders in your libraries folder.

I have included a small Python program that can be used on a PC/Mac to
convert the binary data file to text for the MCP3201.

I am not a Python programmer so it is the best I could do in a short time.