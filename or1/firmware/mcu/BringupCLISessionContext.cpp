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
	CMD_RETENTION,
	CMD_TEST,
	CMD_VCORE
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// "vcore"

static const clikeyword_t g_vcoreCommands[] =
{
	{"<string>",		FREEFORM_TOKEN,			NULL,						"New target Vcore, in mV"},
	{NULL,				INVALID_COMMAND,		NULL,						NULL}
};

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Top level command list

static const clikeyword_t g_rootCommands[] =
{
	{"retention",		CMD_RETENTION,			NULL,						"Retention voltage test"},
	{"test",			CMD_TEST,				NULL,						"Test memory"},
	{"vcore",			CMD_VCORE,				g_vcoreCommands,			"Set DUT core voltage"},

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
	switch(m_command[0].m_commandID)
	{
		case CMD_RETENTION:
			OnRetentionTest();
			break;

		case CMD_TEST:
			OnTest();
			break;

		case CMD_VCORE:
			OnVcore(atoi(m_command[1].m_text));
			break;

		default:
			break;
	}

	m_stream->Flush();
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
// "decay"

void BringupCLISessionContext::OnRetentionTest()
{
	m_stream->Flush();
	if(!g_fpgaUp)
	{
		g_log(Logger::ERROR, "FPGA is not up, can't run test\n");
		return;
	}

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

void BringupCLISessionContext::OnTest()
{
	m_stream->Flush();

	if(!g_fpgaUp)
	{
		g_log(Logger::ERROR, "FPGA is not up, can't run test\n");
		return;
	}

	ClearResults();
	FillMemory();
	VerifyPort0();

	uint8_t results[256] = {0};
	GetResultsPort0(results);

	g_uart->Printf("Process results\n");
	for(int i=0; i<256; i++)
	{
		if(results[i] != 0)
			g_uart->Printf("%02x: %02x\n", i, results[i]);
	}
}
