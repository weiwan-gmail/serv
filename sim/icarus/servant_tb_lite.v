`default_nettype none
/*
 * Icarus-friendly Servant TB without fusesoc:utils:vlog_tb_utils.
 * Same DUT and UART decoder as bench/servant_tb.v; firmware via +firmware=.
 */
module servant_tb_lite;

   parameter memfile = "";
   parameter memsize = 8192;
   parameter width = 1;
   parameter with_csr = 1;

   localparam baud_rate = 57600;

   reg wb_clk = 1'b0;
   reg wb_rst = 1'b1;

   wire q;

   always  #31 wb_clk <= !wb_clk;
   initial #62 wb_rst <= 1'b0;

   uart_decoder #(baud_rate) uart_decoder (q);

   servant_sim
     #(.memfile  (memfile),
       .memsize  (memsize),
       .width    (width),
       .with_csr (with_csr))
   dut
     (.wb_clk (wb_clk),
      .wb_rst (wb_rst),
      .pc_adr (),
      .pc_vld (),
      .q      (q));

   initial begin
      #200000000;
      $display("TIMEOUT: Exiting at time %0t", $time);
      $finish;
   end

endmodule
