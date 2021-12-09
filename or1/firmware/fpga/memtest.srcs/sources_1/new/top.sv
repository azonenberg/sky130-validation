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

	output wire			clk0,
	output wire			cs0_n,
	output wire			we0_n,
	output wire[3:0]	wmask0,
	output wire[7:0]	addr0,
	output wire[7:0]	wdata0,
	input wire[7:0]		rdata0,

	output wire			clk1,
	output wire			cs1_n,
	output wire[7:0]	addr1,
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
	// Clock synthesis

	//for now, just use the external oscillator with no PLL
	wire clk;
	assign clk = clk_25mhz;

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// SPI bus to MCU

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// SRAM tester

	logic		fill_start			= 0;
	logic		read_port0_start	= 0;
	logic		read_port1_start	= 0;

	wire		port0_done;
	wire		port0_fail;
	wire[7:0]	port0_fail_addr;
	wire[7:0]	port0_fail_mask;
	wire		port1_done;
	wire		port1_fail;
	wire[7:0]	port1_fail_addr;
	wire[7:0]	port1_fail_mask;

	MemoryTester tester(
		.clk(clk),

		.fill_start(fill_start),
		.prbs_seed(31'h5eadbeef),
		.read_port0_start(read_port0_start),
		.read_port1_start(read_port1_start),

		.port0_done(port0_done),
		.port0_fail(port0_fail),
		.port0_fail_addr(port0_fail_addr),
		.port0_fail_mask(port0_fail_mask),

		.port1_done(port1_done),
		.port1_fail(port1_fail),
		.port1_fail_addr(port1_fail_addr),
		.port1_fail_mask(port1_fail_mask),

		.clk0(clk0),
		.cs0_n(cs0_n),
		.we0_n(we0_n),
		.wmask0(wmask0),
		.addr0(addr0),
		.wdata0(wdata0),
		.rdata0(rdata0),

		.clk1(clk1),
		.cs1_n(cs1_n),
		.addr1(addr1),
		.rdata1(rdata1)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// High level state machine

	wire	trig_out;

	enum logic[3:0]
	{
		TEST_STATE_IDLE		= 0,
		TEST_STATE_FILL		= 1,
		TEST_STATE_READ_P0	= 2,
		TEST_STATE_READ_P1	= 3
	} test_state = TEST_STATE_IDLE;

	always_ff @(posedge clk) begin

		fill_start			<= 0;
		read_port0_start	<= 0;
		read_port1_start	<= 0;

		case(test_state)

			TEST_STATE_IDLE: begin
				if(trig_out) begin
					fill_start	<= 1;
					test_state	<= TEST_STATE_FILL;
				end
			end	//end TEST_STATE_IDLE

			TEST_STATE_FILL: begin
				if(port0_done) begin
					read_port0_start	<= 1;
					test_state			<= TEST_STATE_READ_P0;
				end
			end	//end TEST_STATE_FILL

			TEST_STATE_READ_P0: begin
				if(port0_done) begin
					read_port1_start	<= 1;
					test_state			<= TEST_STATE_READ_P1;
				end
			end	//end TEST_STATE_READ_P0

			TEST_STATE_READ_P1: begin
				if(port1_done)
					test_state			<= TEST_STATE_IDLE;
			end

		endcase

	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Debug ILA

	ila_0 ila(
		.clk(clk_25mhz),
		.trig_out(trig_out),
		.trig_out_ack(trig_out),
		.probe0(clk0),
		.probe1(cs0_n),
		.probe2(we0_n),
		.probe3(wmask0),
		.probe4(addr0),
		.probe5(wdata0),
		.probe6(rdata0),
		.probe7(clk1),
		.probe8(cs1_n),
		.probe9(addr1),
		.probe10(rdata1),
		.probe11(port0_done),
		.probe12(port1_done),
		.probe13(test_state),
		.probe14(fill_start),
		.probe15(read_port0_start),
		.probe16(read_port1_start),
		.probe17(port0_fail),
		.probe18(port0_fail_addr),
		.probe19(port0_fail_mask),
		.probe20(port1_fail),
		.probe21(port1_fail_addr),
		.probe22(port1_fail_mask),
		.probe23(tester.state),
		.probe24(tester.addr0_ff),
		.probe25(tester.p0_read_prbs_out),
		.probe26(tester.fill_prbs_out),
		.probe27(tester.p0_read_prbs_update),
		.probe28(tester.p0_fill_prbs_update)
	);

endmodule
