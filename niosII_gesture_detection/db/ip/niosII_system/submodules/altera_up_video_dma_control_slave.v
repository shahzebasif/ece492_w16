/******************************************************************************
 * License Agreement                                                          *
 *                                                                            *
 * Copyright (c) 1991-2012 Altera Corporation, San Jose, California, USA.     *
 * All rights reserved.                                                       *
 *                                                                            *
 * Any megafunction design, and related net list (encrypted or decrypted),    *
 *  support information, device programming or simulation file, and any other *
 *  associated documentation or information provided by Altera or a partner   *
 *  under Altera's Megafunction Partnership Program may be used only to       *
 *  program PLD devices (but not masked PLD devices) from Altera.  Any other  *
 *  use of such megafunction design, net list, support information, device    *
 *  programming or simulation file, or any other related documentation or     *
 *  information is prohibited for any other purpose, including, but not       *
 *  limited to modification, reverse engineering, de-compiling, or use with   *
 *  any other silicon devices, unless such use is explicitly licensed under   *
 *  a separate agreement with Altera or a megafunction partner.  Title to     *
 *  the intellectual property, including patents, copyrights, trademarks,     *
 *  trade secrets, or maskworks, embodied in any such megafunction design,    *
 *  net list, support information, device programming or simulation file, or  *
 *  any other related documentation or information provided by Altera or a    *
 *  megafunction partner, remains with Altera, the megafunction partner, or   *
 *  their respective licensors.  No other licenses, including any licenses    *
 *  needed under any third party's intellectual property, are provided herein.*
 *  Copying or modifying any file, or portion thereof, to which this notice   *
 *  is attached violates this copyright.                                      *
 *                                                                            *
 * THIS FILE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR    *
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,   *
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL    *
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER *
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING    *
 * FROM, OUT OF OR IN CONNECTION WITH THIS FILE OR THE USE OR OTHER DEALINGS  *
 * IN THIS FILE.                                                              *
 *                                                                            *
 * This agreement shall be governed in all respects by the laws of the State  *
 *  of California and by the laws of the United States of America.            *
 *                                                                            *
 ******************************************************************************/

module altera_up_video_dma_control_slave (
	// Inputs
	clk,
	reset,

	address,
	byteenable,
	read,
	write,
	writedata,

	swap_addresses_enable,

	// Bi-Directional

	// Outputs
	readdata,

	current_start_address
);


/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/

// Parameters
parameter DEFAULT_BUFFER_ADDRESS		= 32'h00000000;
parameter DEFAULT_BACK_BUF_ADDRESS	= 32'h00000000;

parameter WIDTH							= 640; // Frame's width in pixels
parameter HEIGHT							= 480; // Frame's height in lines

parameter ADDRESSING_BITS				= 16'h0809;
parameter COLOR_BITS						= 4'h7; // Bits per color plane minus 1 
parameter COLOR_PLANES					= 2'h2; // Color planes per pixel minus 1
parameter ADDRESSING_MODE				= 1'b1; // 0: X-Y or 1: Consecutive

/*****************************************************************************
 *                             Port Declarations                             *
 *****************************************************************************/
// Inputs
input						clk;
input						reset;

input			[ 1: 0]	address;
input			[ 3: 0]	byteenable;
input						read;
input						write;
input			[31: 0]	writedata;

input						swap_addresses_enable;

// Bi-Directional

// Outputs
output reg	[31: 0]	readdata;

output		[31: 0]	current_start_address;

/*****************************************************************************
 *                           Constant Declarations                           *
 *****************************************************************************/


/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/
// Internal Wires

// Internal Registers
reg			[31: 0]	buffer_start_address;
reg			[31: 0]	back_buf_start_address;

reg						buffer_swap;

// State Machine Registers

/*****************************************************************************
 *                         Finite State Machine(s)                           *
 *****************************************************************************/


/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

// Output Registers
always @(posedge clk)
begin
	if (reset)
		readdata <= 32'h00000000;
   
	else if (read & (address == 2'h0))
		readdata <= buffer_start_address;
   
	else if (read & (address == 2'h1))
		readdata <= back_buf_start_address;
   
	else if (read & (address == 2'h2))
	begin
		readdata[31:16] <= HEIGHT;
		readdata[15: 0] <= WIDTH;
	end
   
	else if (read)
	begin
		readdata[31:16] <= ADDRESSING_BITS;
		readdata[15:12] <= 4'h0;
		readdata[11: 8] <= COLOR_BITS;
		readdata[ 7: 6] <= COLOR_PLANES;
		readdata[ 5: 2] <= 4'h0;
		readdata[    1] <= ADDRESSING_MODE;
		readdata[    0] <= buffer_swap;
	end
end

// Internal Registers
always @(posedge clk)
begin
	if (reset)
	begin
		buffer_start_address	<= DEFAULT_BUFFER_ADDRESS;
		back_buf_start_address	<= DEFAULT_BACK_BUF_ADDRESS;
	end
	else if (write & (address == 2'h1))
	begin
		if (byteenable[0])
			back_buf_start_address[ 7: 0] <= writedata[ 7: 0];
		if (byteenable[1])
			back_buf_start_address[15: 8] <= writedata[15: 8];
		if (byteenable[2])
			back_buf_start_address[23:16] <= writedata[23:16];
		if (byteenable[3])
			back_buf_start_address[31:24] <= writedata[31:24];
	end
	else if (buffer_swap & swap_addresses_enable)
	begin
		buffer_start_address <= back_buf_start_address;
		back_buf_start_address <= buffer_start_address;
	end
end

always @(posedge clk)
begin
	if (reset)
		buffer_swap <= 1'b0;
	else if (write & (address == 2'h0))
		buffer_swap <= 1'b1;
	else if (swap_addresses_enable)
		buffer_swap <= 1'b0;
end

/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/

// Output Assignments
assign current_start_address	= buffer_start_address;

// Internal Assignments

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/


endmodule

