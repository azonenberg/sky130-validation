`timescale 1ns/1ps
`default_nettype none
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

/**
	@brief Top level module
 */
module top(
	input wire			clk_25mhz,

	inout wire[3:0]		flash_dq,
	output logic		flash_cs_n = 1,

	inout wire[3:0]		mcu_gpio,

	input wire			mcu_spi_sck,
	input wire			mcu_spi_cs_n,
	input wire			mcu_spi_si,
	output wire			mcu_spi_so,

	output wire			dut_gpio0,

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
	assign dut_gpio0		= 0;

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Clock synthesis

	wire		clk_mgmt;
	assign		clk_mgmt = clk_25mhz;

	wire		clk_mem;
	wire[5:0]	unused;

	logic		pll_reset				= 0;
	wire		pll_locked;
	wire		pll_busy;

	logic		reconfig_start			= 0;
	logic		reconfig_finish			= 0;
	wire		reconfig_cmd_done;

	logic		reconfig_vco_en			= 0;
	logic[6:0]	reconfig_vco_mult		= 0;
	logic[6:0]	reconfig_vco_indiv		= 0;
	logic		reconfig_vco_bandwidth	= 0;

	logic		reconfig_output_en		= 0;
	logic[2:0]	reconfig_output_idx		= 0;
	logic[7:0]	reconfig_output_div		= 0;
	logic[8:0]	reconfig_output_phase	= 0;

	ReconfigurablePLL #(
		.OUTPUT_GATE(6'b111111),
		.OUTPUT_BUF_GLOBAL(6'b111111),
		.IN0_PERIOD(40.0),		//25 MHz
		.IN1_PERIOD(40.0),
		.OUT0_MIN_PERIOD(5),	//200 MHz
		.ACTIVE_ON_START(0)
	) pll (
		.clkin({clk_25mhz, clk_25mhz}),
		.clksel(1'b0),
		.clkout({unused, clk_mem}),

		.reset(pll_reset),
		.locked(pll_locked),
		.busy(pll_busy),

		.reconfig_clk(clk_mgmt),
		.reconfig_start(reconfig_start),
		.reconfig_finish(reconfig_finish),
		.reconfig_cmd_done(reconfig_cmd_done),

		.reconfig_vco_en(reconfig_vco_en),
		.reconfig_vco_mult(reconfig_vco_mult),
		.reconfig_vco_indiv(reconfig_vco_indiv),
		.reconfig_vco_bandwidth(reconfig_vco_bandwidth),

		.reconfig_output_en(reconfig_output_en),
		.reconfig_output_idx(reconfig_output_idx),
		.reconfig_output_div(reconfig_output_div),
		.reconfig_output_phase(reconfig_output_phase)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// SPI bus to MCU

	wire		cs_falling;
	logic[7:0]	spi_tx_data			= 0;
	logic		spi_tx_data_valid	= 0;
	wire[7:0]	spi_rx_data;
	wire		spi_rx_data_valid;

	SPIDeviceInterface spi(
		.clk(clk_mgmt),
		.spi_mosi(mcu_spi_si),
		.spi_sck(mcu_spi_sck),
		.spi_cs_n(mcu_spi_cs_n),
		.spi_miso(mcu_spi_so),
		.cs_falling(cs_falling),
		.cs_n_sync(),
		.tx_data(spi_tx_data),
		.tx_data_valid(spi_tx_data_valid),
		.rx_data(spi_rx_data),
		.rx_data_valid(spi_rx_data_valid)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// SRAM control flags and synchronizers

	//Control flags in SPI clock domain
	logic		fill_start			= 0;
	logic		read_port0_start	= 0;
	logic		read_port1_start	= 0;
	logic		clear_start			= 0;

	//Control flags in SRAM clock domain
	wire		fill_start_sync;
	wire		clear_start_sync;
	wire		read_port0_start_sync;
	wire		read_port1_start_sync;

	//Synchronizers
	PulseSynchronizer sync_fill_start(
		.clk_a(clk_mgmt),
		.pulse_a(fill_start),
		.clk_b(clk_mem),
		.pulse_b(fill_start_sync)
	);

	PulseSynchronizer sync_clear_start(
		.clk_a(clk_mgmt),
		.pulse_a(clear_start),
		.clk_b(clk_mem),
		.pulse_b(clear_start_sync)
	);

	PulseSynchronizer sync_read_port0_start(
		.clk_a(clk_mgmt),
		.pulse_a(read_port0_start),
		.clk_b(clk_mem),
		.pulse_b(read_port0_start_sync)
	);

	PulseSynchronizer sync_read_port1_start(
		.clk_a(clk_mgmt),
		.pulse_a(read_port1_start),
		.clk_b(clk_mem),
		.pulse_b(read_port1_start_sync)
	);

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// SRAM tester

	wire		port0_done;
	wire		port0_fail;
	wire[7:0]	port0_fail_addr;
	wire[7:0]	port0_fail_mask;
	wire		port1_done;
	wire		port1_fail;
	wire[7:0]	port1_fail_addr;
	wire[7:0]	port1_fail_mask;

	MemoryTester tester(
		.clk(clk_mem),

		.fill_start(fill_start_sync),
		.prbs_seed(31'h5eadbeef),
		.read_port0_start(read_port0_start_sync),
		.read_port1_start(read_port1_start_sync),

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
	// Busy flags

	logic	p0_busy		= 0;
	logic	p1_busy		= 0;

	logic	clear_busy	= 0;
	logic	clear_done	= 0;

	always_ff @(posedge clk_mem) begin

		if(read_port0_start_sync || fill_start_sync)
			p0_busy			<= 1;
		if(port0_done)
			p0_busy			<= 0;

		if(read_port1_start_sync)
			p1_busy			<= 1;
		if(port1_done)
			p1_busy			<= 0;

		if(clear_start_sync)
			clear_busy		<= 1;
		if(clear_done)
			clear_busy		<= 0;

	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Synchronizers for busy flags

	wire	p0_busy_sync;
	wire	p1_busy_sync;
	wire	clear_busy_sync;

	ThreeStageSynchronizer sync_p0_busy(
		.clk_in(clk_mem),
		.din(p0_busy),
		.clk_out(clk_mgmt),
		.dout(p0_busy_sync));

	ThreeStageSynchronizer sync_p1_busy(
		.clk_in(clk_mem),
		.din(p1_busy),
		.clk_out(clk_mgmt),
		.dout(p1_busy_sync));

	ThreeStageSynchronizer sync_clear_busy(
		.clk_in(clk_mem),
		.din(clear_busy),
		.clk_out(clk_mgmt),
		.dout(clear_busy_sync));

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Test result memory

	logic[7:0]	p0_fail_mem[255:0];
	logic[7:0]	p1_fail_mem[255:0];

	logic		table_wr_p0		= 0;
	logic		table_wr_p1		= 0;
	logic[7:0]	table_waddr_p0	= 0;
	logic[7:0]	table_waddr_p1	= 0;
	logic[7:0]	table_wdata_p0	= 0;
	logic[7:0]	table_wdata_p1	= 0;

	logic		table_rd		= 0;
	logic[7:0]	table_raddr		= 0;
	logic[7:0]	p0_rdata		= 0;
	logic[7:0]	p1_rdata		= 0;

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Test result memory writes

	always_ff @(posedge clk_mem) begin
		clear_done	<= 0;
		table_wr_p0	<= 0;
		table_wr_p1	<= 0;

		//Reset addresses when beginning a clear cycle
		if(clear_start) begin
			table_waddr_p0	<= 8'hff;
			table_waddr_p1	<= 8'hff;
		end

		//Run a clear cycle
		if(clear_busy) begin
			table_wr_p0		<= 1;
			table_waddr_p0	<= table_waddr_p0 + 1;
			table_wdata_p0	<= 0;

			table_wr_p1		<= 1;
			table_waddr_p1	<= table_waddr_p1 + 1;
			table_wdata_p1	<= 0;

			if(table_waddr_p0 == 8'hfe)
				clear_done	<= 1;
		end

		//Report test failures
		if(port0_fail) begin
			table_wr_p0		<= 1;
			table_waddr_p0	<= port0_fail_addr;
			table_wdata_p0	<= port0_fail_mask;
		end
		if(port1_fail) begin
			table_wr_p1		<= 1;
			table_waddr_p1	<= port1_fail_addr;
			table_wdata_p1	<= port1_fail_mask;
		end

		if(table_wr_p0)
			p0_fail_mem[table_waddr_p0]	<= table_wdata_p0;
		if(table_wr_p1)
			p1_fail_mem[table_waddr_p1]	<= table_wdata_p1;

	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Test result memory read

	always_ff @(posedge clk_mgmt) begin

		if(table_rd) begin
			p0_rdata	<= p0_fail_mem[table_raddr];
			p1_rdata	<= p1_fail_mem[table_raddr];
		end
	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// SPI state machine

	typedef enum logic[7:0]
	{
		REG_NOP				= 8'h00,		//ignored

		REG_COMMAND			= 8'h01,		//0x01	Fill memory
											//0x02	Read port 0
											//0x04	Read port 1
											//0x08	Clear results

		REG_STATUS			= 8'h02,		//0x01	Port 0 busy
											//0x02	Port 1 busy
											//0x04	Clear busy

		REG_ADDR			= 8'h03,		//Address for accessing test results

		REG_P0_MASK			= 8'h04,		//Read result for port 0
		REG_P1_MASK			= 8'h05,		//Read result for port 0

		REG_PLL_VCO_MULT	= 8'h06,		//6:0 PLL VCO multiplier
		REG_PLL_VCO_INDIV	= 8'h07,		//6:0 PLL VCO input divider
		REG_PLL_VCO_CFG		= 8'h08,		//0 PLL VCO bandwidth
											//Writing to this register commits all pending VCO register changes.

		REG_PLL_OUT_DIV		= 8'h09,		//7:0	PLL output divider
		REG_PLL_OUT_PHASELO	= 8'h0a,		//7:0	PLL output phase, bits 7:0
		REG_PLL_OUT_PHASEHI	= 8'h0b,		//0 	PLL output phase, bit 8
		REG_PLL_OUT_IDX		= 8'h0c,		//2:0	PLL output channel index
											//Writing to this register commits all pending output register changes

		REG_PLL_CTL			= 8'h0d,		//0		Write 1 to start the reconfiguration process
											//1		Write 1 to end the reconfiguration process

		REG_PLL_STAT		= 8'h0e			//0		PLL reconfiguration operation in progress
											//1		PLL initializing after reset
											//2		PLL locked

	} register_t;

	enum logic[3:0]
	{
		STATE_IDLE		= 0,
		STATE_END		= 1,
		STATE_COMMAND	= 2,
		STATE_ADDRESS	= 3,
		STATE_PLL_REG	= 4
	} state = STATE_IDLE;

	logic		reconfig_busy	= 0;
	logic[7:0]	current_regid	= 0;

	always_ff @(posedge clk_mgmt) begin

		fill_start			<= 0;
		read_port0_start	<= 0;
		read_port1_start	<= 0;
		clear_start			<= 0;
		spi_tx_data_valid	<= 0;
		table_rd			<= 0;

		reconfig_vco_en		<= 0;
		reconfig_output_en	<= 0;
		reconfig_start		<= 0;
		reconfig_finish		<= 0;

		case(state)

			//Wait for register access
			STATE_IDLE: begin

				if(spi_rx_data_valid) begin

					current_regid	<= spi_rx_data;

					//figure out what to do next
					case(spi_rx_data)

						REG_COMMAND: begin
							state	<= STATE_COMMAND;
						end

						REG_STATUS: begin
							spi_tx_data_valid	<= 1;
							spi_tx_data			<= {5'h0, clear_busy_sync, p1_busy_sync, p0_busy_sync};
							state				<= STATE_END;
						end

						REG_ADDR: begin
							state	<= STATE_ADDRESS;
						end

						REG_P0_MASK: begin
							spi_tx_data_valid	<= 1;
							spi_tx_data			<= p0_rdata;
							state				<= STATE_END;
						end

						REG_P1_MASK: begin
							spi_tx_data_valid	<= 1;
							spi_tx_data			<= p1_rdata;
							state				<= STATE_END;
						end

						REG_PLL_STAT: begin
							spi_tx_data_valid	<= 1;
							spi_tx_data			<= {5'h0, pll_locked, pll_busy, reconfig_busy};
							state				<= STATE_END;
						end

						default: begin
						end

					endcase

					if( (spi_rx_data >= REG_PLL_VCO_MULT) && (spi_rx_data <= REG_PLL_CTL) ) begin
						spi_tx_data_valid	<= 1;
						spi_tx_data			<= 8'h0;
						state				<= STATE_PLL_REG;
					end

				end

			end	//end STATE_IDLE

			//Transaction is over, wait for next CS# falling edge
			STATE_END: begin
			end	//end STATE_END

			//Writing a PLL register
			STATE_PLL_REG: begin

				if(spi_rx_data_valid) begin

					case(current_regid)

						REG_PLL_VCO_MULT: 		reconfig_vco_mult			<= spi_rx_data[6:0];
						REG_PLL_VCO_INDIV:		reconfig_vco_indiv			<= spi_rx_data[6:0];

						REG_PLL_VCO_CFG: begin
							reconfig_vco_en			<= 1;
							reconfig_vco_bandwidth	<= spi_rx_data[0];
						end

						REG_PLL_OUT_DIV:		reconfig_output_div			<= spi_rx_data[7:0];
						REG_PLL_OUT_PHASELO: 	reconfig_output_phase[7:0]	<= spi_rx_data[7:0];
						REG_PLL_OUT_PHASEHI:	reconfig_output_phase[8]	<= spi_rx_data[0];

						REG_PLL_OUT_IDX: begin
							reconfig_output_en		<= 1;
							reconfig_output_idx		<= spi_rx_data[2:0];
						end

						REG_PLL_CTL: begin
							reconfig_finish			<= spi_rx_data[1];
							reconfig_start			<= spi_rx_data[0];
						end

						default: begin
						end

					endcase

					state	<= STATE_END;

				end

			end	//end STATE_PLL_REG

			//Command
			STATE_COMMAND: begin

				if(spi_rx_data_valid) begin
					fill_start			<= spi_rx_data[0];
					read_port0_start	<= spi_rx_data[1];
					read_port1_start	<= spi_rx_data[2];
					clear_start			<= spi_rx_data[3];
					state				<= STATE_END;
				end

			end	//end STATE_COMMAND

			//Address
			STATE_ADDRESS: begin
				if(spi_rx_data_valid) begin
					table_raddr			<= spi_rx_data;
					table_rd			<= 1;
					state				<= STATE_END;
				end
			end	//end STATE_ADDRESS

		endcase

		//Reset SPI state machine on CS# falling edge
		if(cs_falling)
			state	<= STATE_IDLE;

	end

endmodule
