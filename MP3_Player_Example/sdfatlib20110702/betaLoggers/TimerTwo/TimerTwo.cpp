/* Arduino TimerTwo Library
 * Copyright (C) 2011 by William Greiman
 *
 * This file is part of the Arduino TimerTwo Library
 *
 * This Library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This Library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the Arduino TimerTwo Library.  If not, see
 * <http://www.gnu.org/licenses/>.
 */
#include <avr/pgmspace.h>
#include <avr/interrupt.h>
#include <TimerTwo.h>
// allowed prescale factors
const uint8_t PS1    = (1 << CS20);
const uint8_t PS8    = (1 << CS21);
const uint8_t PS32   = (1 << CS21) | (1 << CS20);
const uint8_t PS64   = (1 << CS22);
const uint8_t PS128  = (1 << CS22) | (1 << CS20);
const uint8_t PS256  = (1 << CS22) | (1 << CS21);
const uint8_t PS1024 = (1 << CS22) | (1 << CS21) | (1 << CS20);
// table by prescale = 2^n where n is the table index
static uint8_t preScale[] PROGMEM =
  {PS1, 0, 0, PS8, 0, PS32, PS64, PS128, PS256, 0, PS1024};
unsigned TimerTwo::period_;
//------------------------------------------------------------------------------
// initialize timer 2
bool TimerTwo::init(unsigned usec) {
  // assume F_CPU is a multiple of 1000000
  // number of clock ticks to delay usec microseconds
  unsigned long ticks = usec * (F_CPU/1000000);
  // determine prescale factor and TOP/OCR2A value
  // use minimum prescale factor 
  unsigned char ps, i;
  for (i = 0; i < sizeof(preScale); i++) {
    ps = pgm_read_byte(&preScale[i]);
    if (ps && (ticks >> i) <= 256) break;
  }
  //return error if usec is too large
  if (i == sizeof(preScale)) return false;
  
  period_ = ((long)(ticks >> i) * (1 << i))/ (F_CPU /1000000);

  // disable timer 2 interrupts
  TIMSK2 = 0;
  // use system clock (clkI/O).
  ASSR &= ~(1 << AS2);
  // Clear Timer on Compare Match (CTC) mode
  TCCR2A = (1 << WGM21);
  // only need prescale bits in TCCR2B
  TCCR2B = ps;
  // set TOP so timer period is (ticks >> i)
  OCR2A = (ticks >> i) - 1;
  return true;
}
//------------------------------------------------------------------------------
// Start timer two interrupts
void TimerTwo::start() {
  TIMSK2 |= (1 << OCIE2A);
}
//------------------------------------------------------------------------------
// Stop timer 2 interrupts
void TimerTwo::stop() {
  TIMSK2 = 0;
}




