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

module top(
	input wire			clk_25mhz,

	inout wire[3:0]		flash_dq,
	output logic		flash_cs_n = 1,

	inout wire[3:0]		mcu_gpio,

	input wire			mcu_spi_sck,
	input wire			mcu_spi_cs_n,
	input wire			mcu_spi_si,
	output wire			mcu_spi_so,

	output logic		dut_gpio0 = 0,

	output logic		clk0	= 0,
	output logic		cs0_n	= 1,
	output logic		we0_n	= 1,
	output logic[3:0]	wmask0	= 0,
	output logic[7:0]	addr0	= 0,
	output logic[7:0]	wdata0	= 0,
	input wire[7:0]		rdata0,

	output logic		clk1	= 0,
	output logic		cs1_n	= 1,
	output logic[7:0]	addr1	= 0,
	input wire[7:0]		rdata1
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Tie off signals we're not using for now

	assign flash_dq[3:0]	= 4'b0;
	assign mcu_gpio[3:0]	= 4'b0;

	//Dummy so we have something to synthesize
	always_ff @(posedge clk_25mhz) begin
		dut_gpio0 <= !dut_gpio0;
	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// SPI bus to MCU

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// SRAM interface

endmodule
