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

module MemoryTester(

	//Our input clock (2x SRAM clock)
	input wire			clk,

	//Control signals
	input wire			fill_start,
	input wire[30:0]	prbs_seed,
	input wire			read_port0_start,
	input wire			read_port1_start,

	//Status signals
	output logic		port0_done		= 0,
	output logic		port0_fail		= 0,
	output logic[7:0]	port0_fail_addr	= 0,
	output logic[7:0]	port0_fail_mask	= 0,
	output logic		port1_done		= 0,
	output logic		port1_fail		= 0,
	output logic[7:0]	port1_fail_addr	= 0,
	output logic[7:0]	port1_fail_mask	= 0,

	//Memory port 0
	output logic		clk0	= 0,
	output logic		cs0_n	= 1,
	output logic		we0_n	= 1,
	output logic[3:0]	wmask0	= 0,
	output logic[7:0]	addr0	= 0,
	output logic[7:0]	wdata0	= 0,
	input wire[7:0]		rdata0,

	//Memory port 1
	output logic		clk1	= 0,
	output logic		cs1_n	= 1,
	output logic[7:0]	addr1	= 0,
	input wire[7:0]		rdata1
);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Port 0 state machine

	wire[7:0] fill_prbs_out;
	wire[7:0] p0_read_prbs_out;

	enum logic[3:0]
	{
		STATE_IDLE			= 0,
		STATE_FILL			= 1,
		STATE_READ_P0		= 2
	} state = STATE_IDLE;

	logic		fill_start_ff		= 0;
	logic[7:0]	addr0_ff			= 0;
	logic		p0_read_prbs_update	= 0;
	logic		p0_fill_prbs_update	= 0;

	always_ff @(posedge clk) begin

		//Toggle clocks
		clk0				<= !clk0;

		//Save delayed flags
		fill_start_ff		<= fill_start;

		//Clear host side flags
		port0_done			<= 0;
		p0_read_prbs_update	<= 0;
		p0_fill_prbs_update	<= 0;

		//Start command can happen at an even OR odd cycle boundary
		if(fill_start)
			p0_fill_prbs_update	<= 1;
		if(fill_start_ff)
			state	<= STATE_FILL;
		if(read_port0_start)
			state	<= STATE_READ_P0;

		//Drive outputs on falling edge of clk0 (currently 1, going to 0 next cycle) to maximize setup window
		if(clk0) begin

			//Clear memory side flags
			cs0_n	<= 1;
			we0_n	<= 1;

			//Save the address of the previous command
			addr0_ff	<= addr0;

			case(state)

				STATE_IDLE: begin

					//set address to -1 mod 2^8
					//so after first increment, we start at 0
					addr0	<= 8'hff;

				end	//end STATE_IDLE

				STATE_FILL: begin
					cs0_n				<= 0;
					we0_n				<= 0;
					wmask0				<= 4'hf;
					addr0				<= addr0 + 1;
					wdata0				<= fill_prbs_out;
					p0_fill_prbs_update	<= 1;

					//About to write last word? We're done
					if(addr0 == 8'hfe) begin
						state			<= STATE_IDLE;
						port0_done		<= 1;
					end

				end	//end STATE_FILL

				STATE_READ_P0: begin
					cs0_n				<= 0;
					addr0				<= addr0 + 1;
					p0_read_prbs_update	<= 1;

					//About to read last word? We're done
					if(addr0 == 8'hfe) begin
						state		<= STATE_IDLE;
						port0_done	<= 1;
					end

				end	//end STATE_READ_P0

			endcase

		end

		//Read results on the rising edge (currently 0, going to 1 next cycle)
		else begin
		end

	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// PRBS generators

	PRBS31 #(
		.WIDTH(8)
	) fill_prbs_gen (
		.clk(clk),
		.init(fill_start),
		.update(p0_fill_prbs_update ),
		.seed(prbs_seed),
		.dout(fill_prbs_out)
	);

	PRBS31 #(
		.WIDTH(8)
	) p0_read_prbs_gen (
		.clk(clk),
		.init(read_port0_start),
		.update(p0_read_prbs_update),
		.seed(prbs_seed),
		.dout(p0_read_prbs_out)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Port 1 state machine

endmodule
