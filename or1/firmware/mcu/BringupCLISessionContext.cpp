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
#include "BringupCLISessionContext.h"
#include <ctype.h>

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Command table

//List of all valid commands
enum cmdid_t
{
	CMD_DUAL_PORT,
	CMD_FREQUENCY,
	CMD_FPSHMOO,
	CMD_FVSHMOO,
	CMD_OPERATION,
	CMD_RETENTION,
	CMD_RWSHMOO,
	CMD_RWTEST,
	CMD_SINGLE_PORT,
	CMD_TEST,
	CMD_VCORE,
	CMD_VMAP,
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// "test"

static const clikeyword_t g_testCommands[] =
{
	{"<string>",		FREEFORM_TOKEN,			NULL,						"Port number to test readback on"},
	{NULL,				INVALID_COMMAND,		NULL,						NULL}
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// "vcore"

static const clikeyword_t g_vcoreCommands[] =
{
	{"<string>",		FREEFORM_TOKEN,			NULL,						"New target Vcore, in mV"},
	{NULL,				INVALID_COMMAND,		NULL,						NULL}
};


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// "operation"

static const clikeyword_t g_operationCommands[] =
{
	{"single",			CMD_SINGLE_PORT,		NULL,						"Single port readback"},
	{"dual",			CMD_DUAL_PORT,			NULL,						"Simultaneous dual port readback"},
	{NULL,				INVALID_COMMAND,		NULL,						NULL}
};


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Top level command list

static const clikeyword_t g_rootCommands[] =
{
	{"frequency",		CMD_FREQUENCY,			NULL,						"Frequency test"},
	{"fpshmoo",			CMD_FPSHMOO,			g_operationCommands,		"Frequency vs capture phase shmoo"},
	{"fvshmoo",			CMD_FVSHMOO,			g_operationCommands,		"Frequency vs voltage shmoo"},
	{"operation",		CMD_OPERATION,			g_operationCommands,		"Operation voltage test"},
	{"retention",		CMD_RETENTION,			NULL,						"Retention voltage test"},
	{"rwshmoo",			CMD_RWSHMOO,			NULL,						"Frequency vs voltage shmoo with simultaneous R+W"},
	{"rwtest",			CMD_RWTEST,				NULL,						"Single point test of simultaneous R+W"},
	{"test",			CMD_TEST,				g_testCommands,				"Test memory"},
	{"vcore",			CMD_VCORE,				g_vcoreCommands,			"Set DUT core voltage"},
	{"vmap",			CMD_VMAP,				g_operationCommands,		"Minimum voltage map"},

	{NULL,				INVALID_COMMAND,		NULL,						NULL}
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Construction / destruction

BringupCLISessionContext::BringupCLISessionContext()
	: CLISessionContext(g_rootCommands)
	, m_stream(NULL)
{
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Prompt

void BringupCLISessionContext::PrintPrompt()
{
	m_stream->Printf("%s@bringup$ ", m_username);
	m_stream->Flush();
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Top level command dispatch

void BringupCLISessionContext::OnExecute()
{
	MakeSureFPGAIsUp();

	switch(m_command[0].m_commandID)
	{
		case CMD_FREQUENCY:
			OnClockFrequencyTest();
			break;

		case CMD_FPSHMOO:
			OnFrequencyPhaseShmoo(m_command[1].m_commandID == CMD_DUAL_PORT);
			break;

		case CMD_FVSHMOO:
			OnFrequencyVoltageShmoo(m_command[1].m_commandID == CMD_DUAL_PORT);
			break;

		case CMD_OPERATION:
			OnOperatingVoltageTest(m_command[1].m_commandID == CMD_DUAL_PORT);
			break;

		case CMD_RETENTION:
			OnRetentionTest();
			break;

		case CMD_RWSHMOO:
			OnReadWriteShmoo();
			break;

		case CMD_RWTEST:
			OnReadWriteTest();
			break;

		case CMD_TEST:
			OnTest(atoi(m_command[1].m_text));
			break;

		case CMD_VCORE:
			OnVcore(atoi(m_command[1].m_text));
			break;

		case CMD_VMAP:
			OnOperatingVoltageMap(m_command[1].m_commandID == CMD_DUAL_PORT);
			break;

		default:
			break;
	}

	m_stream->Flush();
}

void BringupCLISessionContext::MakeSureFPGAIsUp()
{
	m_stream->Flush();
	if(!g_fpgaUp)
	{
		g_log(Logger::ERROR, "FPGA is not up, can't run test\n");
		return;
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// "frequency"

void BringupCLISessionContext::OnClockFrequencyTest()
{
	SetDutVcore(1800);

	g_uart->Printf("Running single port operating frequency test at 1.8V\n");

	uint8_t results[256] = {0};
	g_uart->Printf("tester_mhz, ram_mhz, badbits\n");
	for(int mhz = 10; mhz < 60; mhz += 2)
	{
		ConfigureClock(mhz * 1000);

		ClearResults();
		FillMemory();
		VerifyPort0();
		GetResultsPort0(results);

		int badbits = 0;
		for(int i=0; i<256; i++)
			badbits += __builtin_popcount(results[i]);
		g_uart->Printf("%3d, %3d, %d\n", mhz, mhz/2, badbits);
	}

	ConfigureClock(25 * 1000);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// "fpshmoo"

void BringupCLISessionContext::OnFrequencyPhaseShmoo(bool dualport)
{
	if(dualport)
		g_uart->Printf("Running dual port operating frequency vs capture phase shmoo\n");
	else
		g_uart->Printf("Running single port operating frequency vs capture phase shmoo\n");

	//Run this test at a constant 1.8V
	SetDutVcore(1800);
	SleepMs(10);

	//Print header
	g_uart->Printf(",       ");
	for(int ram_mhz = 10; ram_mhz <= 45; ram_mhz ++)
		g_uart->Printf("%4d, ", ram_mhz);
	g_uart->Printf("\n");

	uint8_t results1[256] = {0};
	uint8_t results2[256] = {0};
	for(int phase = 11000; phase >= 2000; phase -= 200)
	{
		g_uart->Printf("%5d, ", phase);

		for(int mhz = 10; mhz <= 45; mhz ++)
		{
			ConfigureClock(mhz * 2 * 1000, phase);	//ram clock is half PLL freq

			ClearResults();
			FillMemory();

			if(dualport)
				VerifyDualPort();
			else
				VerifyPort0();
			GetResultsPort0(results1);
			if(dualport)
				GetResultsPort1(results2);
			else
				memset(results2, 0, sizeof(results2));

			int badbits = 0;
			for(int i=0; i<256; i++)
				badbits += __builtin_popcount(results1[i] | results2[i]);
			g_uart->Printf("%4d, ", badbits);
		}

		g_uart->Printf("\n");
	}

	ConfigureClock(25 * 1000);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// "fvshmoo"

void BringupCLISessionContext::OnFrequencyVoltageShmoo(bool dualport)
{
	int phase = 10000;

	if(dualport)
		g_uart->Printf("Running dual port operating frequency vs voltage shmoo with %d ps read capture delay\n", phase);
	else
		g_uart->Printf("Running single port operating frequency vs voltage shmoo with %d ps read capture delay\n", phase);

	//Print header
	g_uart->Printf("vcore, ");
	for(int ram_mhz = 10; ram_mhz < 45; ram_mhz ++)
		g_uart->Printf("%4d, ", ram_mhz);
	g_uart->Printf("\n");

	uint8_t results1[256] = {0};
	uint8_t results2[256] = {0};
	for(int vcore = 1800; vcore >= 1400; vcore -= 10)
	{
		SetDutVcore(vcore);
		SleepMs(10);
		g_uart->Printf("%5d, ", vcore);

		for(int mhz = 10; mhz < 45; mhz ++)
		{
			ConfigureClock(mhz * 2 * 1000, phase);	//ram clock is half PLL freq

			ClearResults();
			FillMemory();

			if(dualport)
				VerifyDualPort();
			else
				VerifyPort0();
			GetResultsPort0(results1);
			if(dualport)
				GetResultsPort1(results2);
			else
				memset(results2, 0, sizeof(results2));

			int badbits = 0;
			for(int i=0; i<256; i++)
				badbits += __builtin_popcount(results1[i] | results2[i]);
			g_uart->Printf("%4d, ", badbits);
		}

		g_uart->Printf("\n");
	}

	ConfigureClock(25 * 1000);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// "vcore"

void BringupCLISessionContext::OnVcore(int mv)
{
	m_stream->Flush();
	g_uart->Printf("Setting DUT Vcore to %d mV\n", mv);
	SetDutVcore(mv);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// "operation"

void BringupCLISessionContext::OnOperatingVoltageTest(bool dualport)
{
	g_uart->Printf("Running single port operation voltage test with readback on port 0\n");

	//Do a series of write-then-read tests while sweeping voltage
	g_uart->Printf("vcore,badbits\n");
	uint8_t results1[256] = {0};
	uint8_t results2[256] = {0};
	for(int mv = 1800; mv > 1000; mv -= 10)
	{
		//Fill the memory
		SetDutVcore(mv);
		SleepMs(10);
		ClearResults();
		FillMemory();

		//Wait for retention period
		SleepMs(50);

		//Read back
		if(dualport)
			VerifyDualPort();
		else
			VerifyPort0();
		GetResultsPort0(results1);
		if(dualport)
			GetResultsPort1(results2);
		else
			memset(results2, 0, sizeof(results2));

		int badbits = 0;
		for(int i=0; i<256; i++)
			badbits += __builtin_popcount(results1[i] | results2[i]);
		g_uart->Printf("%4d, %d\n", mv, badbits);
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// "retention"

void BringupCLISessionContext::OnRetentionTest()
{
	int delay_sec = 10;
	g_uart->Printf("Running retention test with swept retention voltage, %d sec delay, 1800 mV read/write\n",
		delay_sec);

	//Do a series of write-then-read tests while sweeping voltage
	g_uart->Printf("vretention,badbits\n");
	uint8_t results[256] = {0};
	for(int mv = 500; mv > 0; mv -= 10)
	{
		//Fill the memory
		SetDutVcore(1800);
		SleepMs(10);
		ClearResults();
		FillMemory();

		//Reduce voltage to retention level
		SetDutVcore(mv);

		//Wait for retention period
		SleepMs(delay_sec * 1000);

		//Read back
		SetDutVcore(1800);
		SleepMs(10);
		VerifyPort0();
		GetResultsPort0(results);

		int badbits = 0;
		for(int i=0; i<256; i++)
			badbits += __builtin_popcount(results[i]);
		g_uart->Printf("%4d, %d\n", mv, badbits);
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// "test"

void BringupCLISessionContext::OnTest(int nport)
{
	ClearResults();
	FillMemory();
	uint8_t results[256] = {0};
	if(nport == 0)
	{
		VerifyPort0();
		GetResultsPort0(results);
	}
	else
	{
		VerifyPort1();
		GetResultsPort1(results);
	}

	g_uart->Printf("Process results\n");
	for(int i=0; i<256; i++)
	{
		if(results[i] != 0)
			g_uart->Printf("%02x: %02x\n", i, results[i]);
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// "vmap"

void BringupCLISessionContext::OnOperatingVoltageMap(bool dualport)
{
	const int testvmax = 1800;
	const int testvmin = 600;

	const int mhz = 30;
	const int capturedelay = 10000;
	ConfigureClock(mhz * 2 * 1000, capturedelay);
	g_uart->Printf("Running operating voltage map at %d MHz, %d ps read capture delay\n", mhz, capturedelay);

	g_uart->Printf("addr, bit0,  bit1,  bit2,  bit3,  bit4,  bit5,  bit6,  bit7\n");

	//We don't have enough RAM to store the minimum voltage for every bit of every byte!
	//This requires a bit of duplicated effort, testing the entire array
	//but only actually processing 16 bytes per block.
	for(int block=0; block<16; block++)
	{
		//g_uart->Printf("Block %d\n", block);

		uint16_t blockmin[128];						//16 bytes * 8 bits
		memset(blockmin, 0x00, sizeof(blockmin));

		//Repeat the test on the entire block and report the highest failing voltage
		for(int i=0; i<5; i++)
		{
			//g_uart->Printf("Iteration %d\n", i);

			SetPRBSSeed(0x5eadbeef + i);

			for(int mv = testvmax; mv > testvmin; mv -= 10)
			{
				//Fill the memory
				SetDutVcore(mv);
				SleepMs(10);
				ClearResults();
				FillMemory();

				//Wait for retention period
				SleepMs(25);

				//Read back
				uint8_t results1[256] = {0};
				uint8_t results2[256] = {0};
				if(dualport)
					VerifyDualPort();
				else
					VerifyPort0();
				GetResultsPort0(results1);
				if(dualport)
					GetResultsPort1(results2);
				else
					memset(results2, 0, sizeof(results2));

				for(int off=0; off<16; off++)
				{
					//Find which bits are bad in this byte (from either port)
					int addr = block*16 + off;
					uint8_t mask = results1[addr] | results2[addr];
					if(mask == 0)
						continue;

					for(int nbit=0; nbit<8; nbit ++)
					{
						//bit is good, nothing to do
						if( ( (mask >> nbit) & 1) == 0)
							continue;

						//Bit is bad. Did we already fail at a higher voltage?
						int bindex = off*8 + nbit;
						if(blockmin[bindex] > mv)
							continue;

						//Nope, first time it failed. Save the current voltage
						blockmin[bindex] = mv;
					}
				}
			}
		}

		//Done, summarize results
		for(int i=0; i<16; i++)
		{
			g_uart->Printf("%4d, %5d, %5d, %5d, %5d, %5d, %5d, %5d, %5d\n",
				block*16 + i,
				blockmin[i*8 + 0],
				blockmin[i*8 + 1],
				blockmin[i*8 + 2],
				blockmin[i*8 + 3],
				blockmin[i*8 + 4],
				blockmin[i*8 + 5],
				blockmin[i*8 + 6],
				blockmin[i*8 + 7]
			);
		}
	}

	//restore default
	SetPRBSSeed(0x5eadbeef);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// "rwshmoo"

void BringupCLISessionContext::OnReadWriteShmoo()
{
	int phase = 10000;
	g_uart->Printf("Running simultaneous R+W operating frequency vs voltage shmoo with %d ps read capture delay\n", phase);

	//Print header
	g_uart->Printf("vcore, ");
	for(int ram_mhz = 10; ram_mhz < 45; ram_mhz ++)
		g_uart->Printf("%4d, ", ram_mhz);
	g_uart->Printf("\n");

	uint8_t results[256] = {0};
	for(int vcore = 1800; vcore >= 1400; vcore -= 10)
	{
		SetDutVcore(vcore);
		SleepMs(10);
		g_uart->Printf("%5d, ", vcore);

		for(int mhz = 10; mhz < 45; mhz ++)
		{
			ConfigureClock(mhz * 2 * 1000, phase);	//ram clock is half PLL freq

			SetPRBSSeed(0x5eadbeef + vcore + mhz);

			ClearResults();
			FillVerifyFeedthrough();
			GetResultsPort1(results);

			int badbits = 0;
			for(int i=0; i<256; i++)
				badbits += __builtin_popcount(results[i]);
			g_uart->Printf("%4d, ", badbits);
		}

		g_uart->Printf("\n");
	}

	//restore default
	SetPRBSSeed(0x5eadbeef);
	ConfigureClock(25 * 1000);
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// "rwtest"

void BringupCLISessionContext::OnReadWriteTest()
{
	g_uart->Printf("Running simultaneous R+W operating frequency vs voltage test\n");

	ClearResults();
	FillVerifyFeedthrough();

	uint8_t results[256] = {0};
	GetResultsPort1(results);

	g_uart->Printf("Process results\n");
	for(int i=0; i<256; i++)
	{
		if(results[i] != 0)
			g_uart->Printf("%02x: %02x\n", i, results[i]);
	}
}
