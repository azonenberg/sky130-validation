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

	wire		cs_falling;
	logic[7:0]	spi_tx_data			= 0;
	logic		spi_tx_data_valid	= 0;
	wire[7:0]	spi_rx_data;
	wire		spi_rx_data_valid;

	SPIDeviceInterface spi(
		.clk(clk),
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
	// Busy flags

	logic	p0_busy		= 0;
	logic	p1_busy		= 0;

	logic	clear_start	= 0;
	logic	clear_busy	= 0;
	logic	clear_done	= 0;

	always_ff @(posedge clk) begin

		if(read_port0_start || fill_start)
			p0_busy			<= 1;
		if(port0_done)
			p0_busy			<= 0;

		if(read_port1_start)
			p1_busy			<= 1;
		if(port1_done)
			p1_busy			<= 0;

		if(clear_start)
			clear_busy		<= 1;
		if(clear_done)
			clear_busy		<= 0;

	end

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

	always_ff @(posedge clk) begin

		if(table_rd) begin
			p0_rdata	<= p0_fail_mem[table_raddr];
			p1_rdata	<= p1_fail_mem[table_raddr];
		end

		if(table_wr_p0)
			p0_fail_mem[table_waddr_p0]	<= table_wdata_p0;
		if(table_wr_p1)
			p1_fail_mem[table_waddr_p1]	<= table_wdata_p1;

	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Test result memory writes

	always_ff @(posedge clk) begin
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

	end

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// SPI state machine

	typedef enum logic[7:0]
	{
		REG_NOP		= 8'h00,		//ignored

		REG_COMMAND	= 8'h01,		//0x01	Fill memory
									//0x02	Read port 0
									//0x04	Read port 1
									//0x08	Clear results

		REG_STATUS	= 8'h02,		//0x01	Port 0 busy
									//0x02	Port 1 busy
									//0x04	Clear busy

		REG_ADDR	= 8'h03,		//Address for accessing test results

		REG_P0_MASK	= 8'h04,		//Read result for port 0
		REG_P1_MASK	= 8'h05			//Read result for port 0

	} register_t;

	enum logic[7:0]
	{
		STATE_IDLE		= 0,
		STATE_END		= 1,
		STATE_COMMAND	= 2,
		STATE_ADDRESS	= 3
	} state = STATE_IDLE;

	always_ff @(posedge clk) begin

		fill_start			<= 0;
		read_port0_start	<= 0;
		read_port1_start	<= 0;
		clear_start			<= 0;
		spi_tx_data_valid	<= 0;
		table_rd			<= 0;

		case(state)

			//Wait for register access
			STATE_IDLE: begin

				if(spi_rx_data_valid) begin

					//figure out what to do next
					case(spi_rx_data)

						REG_COMMAND: begin
							state	<= STATE_COMMAND;
						end

						REG_STATUS: begin
							spi_tx_data_valid	<= 1;
							spi_tx_data			<= {5'h0, clear_busy, p1_busy, p0_busy};
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

					endcase

				end

			end	//end STATE_IDLE

			//Transaction is over, wait for next CS# falling edge
			STATE_END: begin
			end	//end STATE_END

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

	////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Debug ILA

	ila_0 ila(
		.clk(clk_25mhz),
		.probe0(spi_rx_data_valid),
		.probe1(spi_rx_data),
		.probe2(spi_tx_data_valid),
		.probe3(spi_tx_data),
		.probe4(state),
		.probe5(port0_fail),
		.probe6(spi.cs_n_sync),
		.probe7(read_port0_start),
		.probe8(table_rd),
		.probe9(port0_done),
		.probe10(p0_rdata),
		.probe11(port0_fail_addr),
		.probe12(port0_fail_mask),
		.probe13(table_wr_p0),
		.probe14(table_waddr_p0),
		.probe15(table_raddr)
	);

endmodule
