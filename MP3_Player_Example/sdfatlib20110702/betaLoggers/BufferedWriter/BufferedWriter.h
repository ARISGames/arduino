/* Arduino BufferedWriter Library
 * Copyright (C) 2011 by William Greiman
 *
 * This file is part of the Arduino BufferedWriter Library
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
 * along with the Arduino BufferedWriter Library.  If not, see
 * <http://www.gnu.org/licenses/>.
 */
#ifndef BufferedWriter_h
#define BufferedWriter_h
#include <SdFat.h>

class BufferedWriter {
 public:
  void init(SdFile* file) {
    file_ = file;
    in_ = 0;
  }
  // write a char
  void putChar(char c) {
    if (in_ == sizeof(buf_)) writeBuf();
    buf_[in_++] = c;
  }
  // write CR/LF
  void putCRLF() {
    putChar('\r');
    putChar('\n');
  }
  void putHex(uint32_t n);
  void putNum(int8_t n);
  void putNum(uint8_t n);
  void putNum(int16_t n);
  void putNum(uint16_t n);
  void putNum(int32_t n);
  void putNum(uint32_t n);
  void putStr(char* str);
  void writeBuf();
 private:
  static const uint8_t BUF_DIM = 64;
  char buf_[BUF_DIM];
  uint8_t in_;
  SdFile* file_;
};
#endif  // BufferedWriter_h