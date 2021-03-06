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

	//Separate clock for read capture (delayed ~715 ps behind main clock)
	input wire			clk_readcap,

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
	(* IOB = "TRUE" *)
	output logic		clk0	= 0,
	(* IOB = "TRUE" *)
	output logic		cs0_n	= 1,
	(* IOB = "TRUE" *)
	output logic		we0_n	= 1,
	(* IOB = "TRUE" *)
	output logic[3:0]	wmask0	= 0,
	(* IOB = "TRUE" *)
	output logic[7:0]	addr0	= 0,
	(* IOB = "TRUE" *)
	output logic[7:0]	wdata0	= 0,
	input wire[7:0]		rdata0,

	//Memory port 1
	(* IOB = "TRUE" *)
	output logic		clk1	= 0,
	(* IOB = "TRUE" *)
	output logic		cs1_n	= 1,
	(* IOB = "TRUE" *)
	output logic[7:0]	addr1	= 0,
	input wire[7:0]		rdata1
);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Register read data

	(* IOB = "TRUE" *)
	logic[7:0]	rdata0_ff	= 0;

	(* IOB = "TRUE" *)
	logic[7:0]	rdata1_ff	= 0;

	always_ff @(posedge clk_readcap) begin
		rdata0_ff	<= rdata0;
		rdata1_ff	<= rdata1;
	end

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

	logic		fill_start_ff			= 0;
	logic[7:0]	addr0_ff				= 0;
	logic[7:0]	addr0_ff2				= 0;
	logic[7:0]	addr0_ff3				= 0;
	logic		p0_read_prbs_update		= 0;
	logic		p0_fill_prbs_update		= 0;
	logic		port0_done_adv			= 0;
	logic		port0_rd				= 0;
	logic		port0_rd_ff				= 0;
	logic		port0_rd_ff2			= 0;
	logic		port0_rd_ff3			= 0;
	logic[7:0]	p0_read_prbs_out_ff		= 0;
	logic[7:0]	p0_read_prbs_out_ff2	= 0;

	//Internal signals (output pins register off these)
	logic		clk0_adv				= 0;
	logic[7:0]	addr0_adv				= 0;
	logic		cs0_n_adv				= 1;
	logic		we0_n_adv				= 1;
	logic[3:0]	wmask0_adv				= 0;
	logic[7:0]	wdata0_adv				= 0;

	always_ff @(posedge clk) begin

		//Register outputs
		clk0				<= clk0_adv;
		addr0				<= addr0_adv;
		cs0_n				<= cs0_n_adv;
		we0_n				<= we0_n_adv;
		wmask0				<= wmask0_adv;
		wdata0				<= wdata0_adv;

		//Toggle clocks
		clk0_adv			<= !clk0_adv;

		//Save delayed flags
		fill_start_ff		<= fill_start;

		//Clear host side flags
		port0_done			<= 0;
		port0_fail			<= 0;
		p0_read_prbs_update	<= 0;
		p0_fill_prbs_update	<= 0;

		//Pipeline delay on status flags
		port0_done_adv		<= 0;
		port0_done			<= port0_done_adv;

		//Start command can happen at an even OR odd cycle boundary
		if(fill_start)
			p0_fill_prbs_update	<= 1;
		if(fill_start_ff)
			state	<= STATE_FILL;
		if(read_port0_start)
			state	<= STATE_READ_P0;

		//Pipeline delay on signals used by input capture
		addr0_ff2				<= addr0_ff;
		addr0_ff3				<= addr0_ff2;
		port0_rd_ff2			<= port0_rd_ff;
		port0_rd_ff3			<= port0_rd_ff2;
		p0_read_prbs_out_ff		<= p0_read_prbs_out;
		p0_read_prbs_out_ff2	<= p0_read_prbs_out_ff;

		//Drive outputs on falling edge of clk0 (currently 1, going to 0 next cycle) to maximize setup window
		if(clk0_adv) begin

			//Clear memory side flags
			cs0_n_adv	<= 1;
			we0_n_adv	<= 1;

			//If we did a read last cycle, data should be ready this cycle
			port0_rd	<= 0;
			port0_rd_ff	<= port0_rd;

			//Save the address of the previous command
			addr0_ff	<= addr0_adv;

			case(state)

				STATE_IDLE: begin

					//set address to -1 mod 2^8
					//so after first increment, we start at 0
					addr0_adv	<= 8'hff;

				end	//end STATE_IDLE

				STATE_FILL: begin
					cs0_n_adv			<= 0;
					we0_n_adv			<= 0;
					wmask0_adv			<= 4'hf;
					addr0_adv			<= addr0_adv + 1;
					wdata0_adv			<= fill_prbs_out;
					p0_fill_prbs_update	<= 1;

					//About to write last word? We're done
					if(addr0_adv == 8'hfe) begin
						state			<= STATE_IDLE;
						port0_done		<= 1;
					end

				end	//end STATE_FILL

				STATE_READ_P0: begin
					port0_rd			<= 1;
					cs0_n_adv			<= 0;
					addr0_adv			<= addr0_adv + 1;
					p0_read_prbs_update	<= 1;

					//About to read last word? We're done
					if(addr0_adv == 8'hfe) begin
						state			<= STATE_IDLE;
						port0_done_adv	<= 1;
					end

				end	//end STATE_READ_P0

			endcase

		end

		//Read results are captured on the rising edge but pipelined, so we see them the next internal clock cycle
		//(falling edge of clk0, but rising edge of clk0_adv)
		if(!clk0_adv) begin

			//Report failures
			if(port0_rd_ff3 && (rdata0_ff != p0_read_prbs_out_ff2) ) begin
				port0_fail		<= 1;
				port0_fail_addr	<= addr0_ff3;
				port0_fail_mask	<= rdata0_ff ^ p0_read_prbs_out_ff2;
			end

		end

	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Port 1 state machine

	logic[7:0]	addr1_ff				= 0;
	logic[7:0]	addr1_ff2				= 0;
	logic[7:0]	addr1_ff3				= 0;
	logic		p1_busy					= 0;
	logic		p1_read_prbs_update		= 0;
	wire[7:0]	p1_read_prbs_out;
	logic[7:0]	p1_read_prbs_out_ff		= 0;
	logic[7:0]	p1_read_prbs_out_ff2	= 0;
	logic		port1_done_adv			= 0;
	logic		port1_rd				= 0;
	logic		port1_rd_ff				= 0;
	logic		port1_rd_ff2			= 0;
	logic		port1_rd_ff3			= 0;

	logic		read_port1_start_ff		= 0;

	//Internal signals (output pins register off these)
	logic		clk1_adv				= 0;
	logic[7:0]	addr1_adv				= 0;
	logic		cs1_n_adv				= 1;

	always_ff @(posedge clk) begin

		//Register outputs
		clk1				<= clk1_adv;
		addr1				<= addr1_adv;
		cs1_n				<= cs1_n_adv;

		//Toggle clocks
		clk1_adv			<= !clk1_adv;

		//Clear host side flags
		port1_done			<= 0;
		port1_fail			<= 0;
		p1_read_prbs_update	<= 0;

		//Pipeline delay on status flags
		port1_done_adv		<= 0;
		port1_done			<= port1_done_adv;
		read_port1_start_ff	<= read_port1_start;

		//Start command can happen at an even OR odd cycle boundary
		if(read_port1_start_ff)
			p1_busy			<= 1;

		//Pipeline delay for signals used by read capture
		port1_rd_ff2			<= port1_rd_ff;
		port1_rd_ff3			<= port1_rd_ff2;
		addr1_ff2				<= addr1_ff;
		addr1_ff3				<= addr1_ff2;
		p1_read_prbs_out_ff		<= p1_read_prbs_out;
		p1_read_prbs_out_ff2	<= p1_read_prbs_out_ff;

		//Drive outputs on falling edge of clk1 (currently 1, going to 0 next cycle) to maximize setup window
		if(clk1_adv) begin

			//Clear memory side flags
			cs1_n_adv		<= 1;

			//If we did a read last cycle, data should be ready this cycle
			port1_rd		<= 0;
			port1_rd_ff		<= port1_rd;

			//Save the address of the previous command
			addr1_ff		<= addr1_adv;

			if(!p1_busy) begin

				//set address to -1 mod 2^8
				//so after first increment, we start at 0
				addr1_adv	<= 8'hff;

			end

			else begin

				cs1_n_adv			<= 0;
				addr1_adv			<= addr1_adv + 1;
				p1_read_prbs_update	<= 1;
				port1_rd			<= 1;

				//About to read last word? We're done
				if(addr1_adv == 8'hfe) begin
					p1_busy			<= 0;
					port1_done_adv	<= 1;
				end

			end

		end

		//Read results are captured on the rising edge but pipelined, so we see them the next internal clock cycle
		//(falling edge of clk1, but rising edge of clk1_adv)
		if(!clk1_adv) begin

			//Report failures
			if(port1_rd_ff3 && (rdata1_ff != p1_read_prbs_out_ff2) ) begin
				port1_fail		<= 1;
				port1_fail_addr	<= addr1_ff3;
				port1_fail_mask	<= rdata1_ff ^ p1_read_prbs_out_ff2;
			end

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

	PRBS31 #(
		.WIDTH(8)
	) p1_read_prbs_gen (
		.clk(clk),
		.init(read_port1_start),
		.update(p1_read_prbs_update),
		.seed(prbs_seed),
		.dout(p1_read_prbs_out)
	);

endmodule
