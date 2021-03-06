/***********************************************************************************************************************
*                                                                                                                      *
* SKY130 OPENRAM BRINGUP v0.1                                                                                          *
*                                                                                                                      *
* Copyright (c) 2021 Andrew D. Zonenberg                                                                               *
* All rights reserved.                                                                                                 *
*                                                                                                                      *
* Redistribution and use in source and binary forms, with or without modification, are permitted provided that the     *
* following conditions are met:                                                                                        *
*                                                                                                                      *
*    * Redistributions of source code must retain the above copyright notice, this list of conditions, and the         *
*      following disclaimer.                                                                                           *
*                                                                                                                      *
*    * Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the       *
*      following disclaimer in the documentation and/or other materials provided with the distribution.                *
*                                                                                                                      *
*    * Neither the name of the author nor the names of any contributors may be used to endorse or promote products     *
*      derived from this software without specific prior written permission.                                           *
*                                                                                                                      *
* THIS SOFTWARE IS PROVIDED BY THE AUTHORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED   *
* TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL *
* THE AUTHORS BE HELD LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES        *
* (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR       *
* BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT *
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE       *
* POSSIBILITY OF SUCH DAMAGE.                                                                                          *
*                                                                                                                      *
***********************************************************************************************************************/
#ifndef bringup_h
#define bringup_h

#include <stm32fxxx.h>
#include <peripheral/UART.h>
#include <peripheral/GPIO.h>
#include <peripheral/SPI.h>
#include <peripheral/I2C.h>
#include <peripheral/Timer.h>
#include <util/StringBuffer.h>
#include <util/Logger.h>
#include <string.h>
#include <stdlib.h>
#include <cli/UARTOutputStream.h>
#include "BringupCLISessionContext.h"

void SetDutVcore(int mv);
uint8_t GetFPGAStatus();
void FillMemory();
void ClearResults();
void SendCommand(uint8_t cmd);
void VerifyPort0();
void VerifyPort1();
void VerifyDualPort();
void FillVerifyFeedthrough();
void GetResultsPort0(uint8_t* masks);
void GetResultsPort1(uint8_t* masks);
void ConfigureClock(int target_khz, int target_phase = 715);
void WaitForPLLReady();
void WaitForPLLLocked();
void StartPLLReconfig();
void ConfigurePLLVCO(int indiv, int mult);
void ConfigurePLLOutput(int chan, int div, int phase);
void EndPLLReconfig();
void SetPRBSSeed(uint32_t seed);

extern UART* 			g_uart;
extern I2C*				g_i2c;
extern Logger	 		g_log;
extern UARTOutputStream g_uartStream;
extern BringupCLISessionContext g_cliContext;
extern Timer*			g_timer10KHz;

extern bool				g_fpgaUp;

void SleepMs(uint32_t ms);


#endif
