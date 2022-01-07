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

#include "bringup.h"

//Global peripherals and state
UART* 						g_uart;
I2C*						g_i2c;
SPI*						g_spi;
GPIOPin*					g_csn;
Logger 						g_log;
UARTOutputStream			g_uartStream;
Timer*						g_timer10KHz;
BringupCLISessionContext	g_sessionContext;

bool g_fpgaUp				= false;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Entry point

//When possible, long-lived stuff here should be declared static.
//This puts them in .bss instead of stack, and enables better accounting of memory usage
int main()
{
	//Copy .data from flash to SRAM (for some reason the default newlib startup won't do this??)
	memcpy(&__data_start, &__data_romstart, &__data_end - &__data_start + 1);

	//Initialize the PLL
	//CPU clock = AHB clock = APB clock = 48 MHz
	RCCHelper::InitializePLLFromInternalOscillator(2, 12, 1, 1);

	//Initialize LED GPIOs
	static GPIOPin led0(&GPIOA, 4, GPIOPin::MODE_OUTPUT);
	static GPIOPin led1(&GPIOA, 3, GPIOPin::MODE_OUTPUT);
	static GPIOPin led2(&GPIOA, 2, GPIOPin::MODE_OUTPUT);
	static GPIOPin led3(&GPIOA, 0, GPIOPin::MODE_OUTPUT);

	//Initial LED state: 0 on to indicate firmware is alive, rest off
	led0 = 1;
	led1 = 0;
	led2 = 0;
	led3 = 0;

	//Initialize the UART
	static GPIOPin uart_tx(&GPIOA, 9,	GPIOPin::MODE_PERIPHERAL, 1);
	static GPIOPin uart_rx(&GPIOA, 10, GPIOPin::MODE_PERIPHERAL, 1);
	static UART uart(&USART1, &USART1, 417);
	g_uart = &uart;

	//Enable RXNE interrupt vector (IRQ27)
	//TODO: better contants here
	volatile uint32_t* NVIC_ISER0 = (volatile uint32_t*)(0xe000e100);
	*NVIC_ISER0 = 0x8000000;

	//Set up timer with 100us (10 kHz) ticks, required by logger
	static Timer timer(&TIM1, Timer::FEATURE_ADVANCED, 4800);
	g_timer10KHz = &timer;

	//Set up logging
	g_log.Initialize(g_uart, &timer);
	g_log("UART logging ready\n");

	//Initialize FPGA status pins
	g_log("Releasing FPGA reset\n");
	static GPIOPin fpga_rst_n(&GPIOA, 15, GPIOPin::MODE_OUTPUT);
	static GPIOPin fpga_done(&GPIOB, 0, GPIOPin::MODE_INPUT);
	fpga_rst_n = 1;

	//Initialize CLI
	g_uartStream.Initialize(g_uart);
	g_sessionContext.Initialize(&g_uartStream, "admin");

	//Set up SPI bus at 6 MHz (APB/8)
	static GPIOPin spi_sck( &GPIOB, 3, GPIOPin::MODE_PERIPHERAL, 0);
	static GPIOPin spi_miso(&GPIOB, 4, GPIOPin::MODE_PERIPHERAL, 0);
	static GPIOPin spi_mosi(&GPIOB, 5, GPIOPin::MODE_PERIPHERAL, 0);
	static GPIOPin spi_cs_n(&GPIOB, 1, GPIOPin::MODE_OUTPUT, 0);
	static SPI spi(&SPI1, true, 8);
	g_spi = &spi;
	g_csn = &spi_cs_n;
	spi_cs_n = 1;

	//Set up I2C.
	//Prescale divide by 8 (6 MHz, 166.6 ns/tick)
	//Divide I2C clock by 16 after that to get 375 kHz
	static GPIOPin i2c_sda( &GPIOB, 7, GPIOPin::MODE_PERIPHERAL, 1);
	static GPIOPin i2c_scl( &GPIOB, 6, GPIOPin::MODE_PERIPHERAL, 1);
	static I2C i2c(&I2C1, 8, 8);
	g_i2c = &i2c;

	//Turn output power off
	SetDutVcore(0);

	//Enable interrupts only after all setup work is done
	EnableInterrupts();

	//Show the initial prompt
	g_sessionContext.PrintPrompt();

	//Main loop
	while(true)
	{
		//Poll for UART input
		if(g_uart->HasInput())
			g_sessionContext.OnKeystroke(g_uart->BlockingRead());

		//LED1 is FPGA boot state
		bool done = fpga_done.Get();
		led1 = done;
		if(done && !g_fpgaUp)
		{
			g_uartStream.Flush();
			g_uart->Printf("\n");
			g_log("FPGA is up\n");
		}
		if(!done && g_fpgaUp)
		{
			g_uartStream.Flush();
			g_uart->Printf("\n");
			g_log("FPGA is down\n");
		}
		g_fpgaUp = done;
	}

	return 0;
}

void SetDutVcore(int mv)
{
	//Safety limits
	if(mv > 2000)
	{
		g_uart->Printf("Clamping requested voltage of %d mV to 2000 mV\n", mv);
		mv = 2000;
	}

	//Calibration constants for Andrew's board derived from measurement against R&S HMC8012 multimeter
	//These may be different for different boards
	int offset_error = 2;	//mV
	int gain_error = 12932;	//uV / V

	int code_orig = (mv * 0xfff) / 3300;

	int gain_error_at_setpoint = mv * gain_error / 1000000;
	mv -= (offset_error + gain_error_at_setpoint);

	//Clamp to valid / safe range
	//TODO: more aggressive upper bound
	if(mv < 0)
		mv = 0;
	if(mv > 3000)
		mv = 3000;

	//0x0000 = 0V
	//0x0fff = 3300 mV
	int code = (mv * 0xfff) / 3300;
	g_i2c->BlockingWrite16(0x18, code);
}

uint8_t GetFPGAStatus()
{
	//Fill
	*g_csn = 0;
	g_spi->BlockingWrite(0x02);	//REG_STATUS
	uint8_t ret = g_spi->BlockingRead();
	*g_csn = 1;

	//g_uart->Printf("    status = %02x\n", ret);

	return ret;
}

void ClearResults()
{
	SendCommand(0x08);	//Clear

	//Block until not busy
	while( (GetFPGAStatus() & 4) != 0)
	{}
}

/**
	@brief Write a value to REG_COMMAND
 */
void SendCommand(uint8_t cmd)
{
	*g_csn = 0;
	g_spi->BlockingWrite(0x01);	//REG_COMMAND
	g_spi->BlockingWrite(cmd);
	g_spi->WaitForWrites();
	*g_csn = 1;

}

void FillMemory()
{
	SendCommand(0x01);	//Fill

	//Block until not busy
	while( (GetFPGAStatus() & 3) != 0)
	{}
}

void VerifyPort0()
{
	//Send verify command
	SendCommand(0x02);

	//Block until not busy
	while( (GetFPGAStatus() & 3) != 0)
	{}
}

void VerifyPort1()
{
	//Send verify command
	SendCommand(0x04);

	//Block until not busy
	while( (GetFPGAStatus() & 3) != 0)
	{}
}

void VerifyDualPort()
{
	//Send verify command
	SendCommand(0x06);

	//Block until not busy
	while( (GetFPGAStatus() & 3) != 0)
	{}
}

void GetResultsPort0(uint8_t* masks)
{
	for(int addr=0; addr<=0xff; addr ++)
	{
		*g_csn = 0;
		g_spi->BlockingWrite(0x03);	//REG_ADDR
		g_spi->BlockingWrite(addr);
		g_spi->WaitForWrites();
		*g_csn = 1;

		*g_csn = 0;
		g_spi->BlockingWrite(0x04);	//REG_P0_MASK
		masks[addr] = g_spi->BlockingRead();
		*g_csn = 1;
	}
}

void GetResultsPort1(uint8_t* masks)
{
	for(int addr=0; addr<=0xff; addr ++)
	{
		*g_csn = 0;
		g_spi->BlockingWrite(0x03);	//REG_ADDR
		g_spi->BlockingWrite(addr);
		g_spi->WaitForWrites();
		*g_csn = 1;

		*g_csn = 0;
		g_spi->BlockingWrite(0x05);	//REG_P1_MASK
		masks[addr] = g_spi->BlockingRead();
		*g_csn = 1;
	}
}

void SleepMs(uint32_t ms)
{
	for(uint32_t i=0; i<ms; i++)
		g_timer10KHz->Sleep(10, true);
}

/*
	Clock configurations

	Assume for now we always use indiv = 2 (PFD freq = 12.5 MHz) to get more frequency resolution
	Can use indiv=1 and half the multiplier for lower jitter when VCO multiplier is even

	Legal VCO multipliers:
		48 (600 MHz)
		49 (612.5 MHz)
		50 (625 MHz)
		51 (637.5 MHz)

		...
		96 (1200 MHz)

	Out div is 8 bit from VCO
 */
void ConfigureClock(int target_khz, int target_phase)
{
	//do everything in integer kHz fixed point to avoid heavy soft float libs
	int best_vcomult = 0;
	int best_vcofreq = 0;
	int best_outdiv = 0;
	int best_indiv = 0;
	int best_freq = 0;
	int best_error = 500000;

	for(int vcomult = 48; vcomult <= 96; vcomult ++)
	{
		int vco_khz = 12500 * vcomult;

		//Prefer smaller multiply/divide if multiple of 25 MHz
		int indiv = 2;
		int realmult = vcomult;
		if( (vcomult % 2) == 0)
		{
			indiv = 1;
			realmult = vcomult / 2;
		}

		for(int outdiv = 1; outdiv < 255; outdiv ++)
		{
			int outfreq = vco_khz / outdiv;

			//See if we got any closer to our target
			int error = abs(outfreq - target_khz);
			if(error < best_error)
			{
				best_vcomult = realmult;
				best_vcofreq = vco_khz;
				best_outdiv = outdiv;
				best_indiv = indiv;
				best_freq = outfreq;
				best_error = error;
			}
		}
	}

	StartPLLReconfig();
	ConfigurePLLVCO(best_indiv, best_vcomult);

	//Main output
	ConfigurePLLOutput(0, best_outdiv, 0);

	//Read capture clock
	//We want a static delay of 715 ps, but the PLL delay is calculated in 1/8 VCO cycles
	int input_ps = 40000;
	int vco_ps = input_ps * best_indiv / best_vcomult;
	int phase_tap_ps = vco_ps / 8;
	int phase_taps = target_phase / phase_tap_ps;
	//g_uart->Printf("Calculated: VCO period = %d, phase tap = %d, need %d taps\n",
	//	vco_ps, phase_tap_ps, phase_taps);
	ConfigurePLLOutput(1, best_outdiv, phase_taps);

	EndPLLReconfig();
}

void StartPLLReconfig()
{
	//g_log("Start reconfig\n");

	WaitForPLLReady();

	*g_csn = 0;
	g_spi->BlockingWrite(0x0d);	//REG_PLL_CTL
	g_spi->BlockingWrite(0x01);
	g_spi->WaitForWrites();
	*g_csn = 1;
}

void EndPLLReconfig()
{
	//g_log("Finish up\n");

	//WaitForPLLReady();

	*g_csn = 0;
	g_spi->BlockingWrite(0x0d);	//REG_PLL_CTL
	g_spi->BlockingWrite(0x02);
	g_spi->WaitForWrites();
	*g_csn = 1;

	WaitForPLLLocked();
}

void ConfigurePLLVCO(int indiv, int mult)
{
	WaitForPLLReady();

	//g_log("Configure VCO (indiv=%d, mult=%d)\n", indiv, mult);

	*g_csn = 0;
	g_spi->BlockingWrite(0x06);	//REG_PLL_VCO_MULT
	g_spi->BlockingWrite(mult);
	g_spi->WaitForWrites();
	*g_csn = 1;

	*g_csn = 0;
	g_spi->BlockingWrite(0x07);	//REG_PLL_VCO_INDIV
	g_spi->BlockingWrite(indiv);
	g_spi->WaitForWrites();
	*g_csn = 1;

	*g_csn = 0;
	g_spi->BlockingWrite(0x08);	//REG_PLL_VCO_CFG
	g_spi->BlockingWrite(0x0);
	g_spi->WaitForWrites();
	*g_csn = 1;
}

void ConfigurePLLOutput(int chan, int div, int phase)
{
	WaitForPLLReady();

	//g_log("Configure output (channel %d, div=%d, phase=%d)\n", chan, div, phase);

	*g_csn = 0;
	g_spi->BlockingWrite(0x09);	//REG_PLL_OUT_DIV
	g_spi->BlockingWrite(div);
	g_spi->WaitForWrites();
	*g_csn = 1;

	*g_csn = 0;
	g_spi->BlockingWrite(0x0a);	//REG_PLL_OUT_PHASELO
	g_spi->BlockingWrite(phase & 0xff);
	g_spi->WaitForWrites();
	*g_csn = 1;

	*g_csn = 0;
	g_spi->BlockingWrite(0x0b);	//REG_PLL_OUT_PHASEHI
	g_spi->BlockingWrite(phase >> 8);
	g_spi->WaitForWrites();
	*g_csn = 1;

	*g_csn = 0;
	g_spi->BlockingWrite(0x0c);	//REG_PLL_OUT_IDX
	g_spi->BlockingWrite(chan & 7);
	g_spi->WaitForWrites();
	*g_csn = 1;
}

void WaitForPLLReady()
{
	while(true)
	{
		*g_csn = 0;
		g_spi->BlockingWrite(0x0e);	//REG_PLL_STAT
		auto result = g_spi->BlockingRead();
		*g_csn = 1;

		if( (result & 3) == 0)
			return;
	}
}

void WaitForPLLLocked()
{
	while(true)
	{
		*g_csn = 0;
		g_spi->BlockingWrite(0x0e);	//REG_PLL_STAT
		auto result = g_spi->BlockingRead();
		*g_csn = 1;

		if( (result & 4) == 4)
			return;
	}
}

void SetPRBSSeed(uint32_t seed)
{
	*g_csn = 0;
	g_spi->BlockingWrite(0x0f);	//REG_PRBS_SEED_0
	g_spi->BlockingWrite(seed >> 24);
	g_spi->WaitForWrites();
	*g_csn = 1;

	*g_csn = 0;
	g_spi->BlockingWrite(0x10);	//REG_PRBS_SEED_1
	g_spi->BlockingWrite((seed >> 16) & 0xff);
	g_spi->WaitForWrites();
	*g_csn = 1;

	*g_csn = 0;
	g_spi->BlockingWrite(0x11);	//REG_PRBS_SEED_2
	g_spi->BlockingWrite((seed >> 8) & 0xff);
	g_spi->WaitForWrites();
	*g_csn = 1;

	*g_csn = 0;
	g_spi->BlockingWrite(0x12);	//REG_PRBS_SEED_3
	g_spi->BlockingWrite(seed & 0xff);
	g_spi->WaitForWrites();
	*g_csn = 1;
}
