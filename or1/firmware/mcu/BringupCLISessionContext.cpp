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
