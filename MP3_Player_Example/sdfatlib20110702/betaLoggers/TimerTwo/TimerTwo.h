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
 /**
 * \file
 * \brief TimerTwo
 */
#ifndef TimerTwo_h
#define TimerTwo_h
/*!
 *  \addtogroup TimerTwo
 *  @{
 */
//! Namespace for TimerTwo functions.
namespace TimerTwo {
  /** Actual timer period used to approximate init() usec argument */
  extern unsigned period_;
	/**
	 * Initialize timer 2
	 * \param[in] usec Desired period. Maximum period is 256*1024
	 * clock cycles or 16,384 microseconds for a 16 MHz CPU.  The actual
	 * period will be approximately \a usec.  Call period() for the actual
	 * period.
	 *
	 * \return true for success else false.
	 */
	bool init(unsigned usec);
	/** Actual period used. */
  inline unsigned period() {return period_;}
	/** start timer 2 interrupts */
	void start();
	/** stop timer 2 interrupts */
	void stop();
}
/*! @} End of Doxygen Groups */
#endif // TimerTwo
