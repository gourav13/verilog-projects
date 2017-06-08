`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    00:52:11 12/25/2016 
// Design Name: 
// Module Name:    uart3 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module uart3(
    
// Outputs
   uart_busy,   // High means UART is transmitting
   uart_busy_r,  // High means UART is receiving
	uart_rx,      // UART receive wire
	uart_tx,     // UART transmit wire
   // Inputs
   uart_wr_i,   // Raise to transmit byte
	uart_wr_i_r,   // Raise to receive byte
   uart_dat_i,  // 8-bit data
	uart_dat_i_r,  // 8-bit data for receive
   sys_clk_i,   // System clock, 68 MHz
   sys_rst_i,    // System transmit reset
	sys_rst_i_r    // System receive reset
);

  input uart_wr_i;
  input uart_wr_i_r;
  input [7:0] uart_dat_i;
  output reg [7:0] uart_dat_i_r;
  input sys_clk_i;
  input sys_rst_i;
  input sys_rst_i_r;
  
  output uart_busy;
  output uart_tx;
  output uart_busy_r;
  output uart_rx;
  
  reg [3:0] bitcount;
  reg [8:0] shifter;
  reg [3:0] bitcount_r;
  reg [8:0] shifter_r;
  reg uart_tx;
  reg uart_rx;

  wire uart_busy = |bitcount[3:1];
  wire sending = |bitcount;
 
  wire uart_busy_r = |(bitcount_r[3]&bitcount_r[0]);
  wire receiving = |(bitcount_r[3]&bitcount_r[1]&bitcount_r[0]);
  // sys_clk_i is 68MHz.  We want a 115200Hz clock
reg a;
reg p;
  reg [28:0] d=29'b0;
  wire [28:0] dInc = d[28] ? (34000000) : (34000000 - 68000000);
  wire [28:0] dNxt = d + dInc;
  always @(posedge sys_clk_i)
  begin
    d = dNxt;
  end
  wire ser_clk = ~d[28]; // this is the 115200 Hz clock
//transmit logic
  always @(posedge sys_clk_i)
  begin
		 if (sys_rst_i) 
		 begin
				uart_tx <= 1;
				bitcount <= 0;
				shifter <= 0;
		 end 
		 else
		    begin
					// just got a new byte
					  
					if (uart_wr_i & ~uart_busy) 
					 begin
						shifter <= { uart_dat_i[7:0], 1'h0 };
						bitcount <= (1 + 8 + 2);
					 end

					if (sending & ser_clk) 
					begin
						  { shifter, uart_tx } <= { 1'h1, shifter };
						  bitcount <= bitcount - 1;
						  uart_rx<=uart_tx;
					end
   		 end
  end
  //receiver logic
 always @(posedge sys_clk_i)
  begin
		 if (sys_rst_i_r)
			 begin
				uart_rx <= 1;
				bitcount_r <= 0;
				shifter_r <= 0;
		 end 
		 else 
			begin	// just got a new byte
				  
					if (uart_wr_i_r & uart_busy_r)
						begin
						 if(uart_rx==1'b1)
							  begin 
								 p=1'b1;
								 if(p==uart_rx)
								   begin							
									 uart_dat_i_r[8:0]<=shifter_r;
									 bitcount <= (0);
								   end	 
								end
						 end

					if (~receiving& ser_clk) 
						begin
						 if(uart_rx==1'b0)
						  begin
							  { shifter_r,a} <= { uart_rx,shifter_r };
								bitcount <= bitcount + 1;
						  end   					
						end
	   	 end
  end

endmodule
