

/*
 * Derive a clock from another clock
 */
module clk_divider #(parameter ONCNT=10,OFFCNT=10)
                    (input clk,
                     output subClk);

   reg [31:0]  count = 0;
   reg         on = 0;

   assign subClk = on;

   always @ (posedge clk)
   begin
      count = count + 1;
      case (on)
         0:
           begin
             if (count == OFFCNT) 
             begin
                 on = 1;
                 count = 0;
             end
           end
         1:
           begin
             if (count == ONCNT) 
             begin
                 on = 0;
                 count = 0;
             end
           end
      endcase
   end

endmodule


/*
 * Drive the output line to a ws2812b GRB led.
 * The bit is read on the negative edge of the clk_2_4_mhz 
 * signal on the second pulse out of three. 
 *
 * The clock is 2.4 mhz instead of the 800 khz, as
 * we need to be able to send the pattern 110 or 100 at
 * 800 khz.   So 800 khz * 3 = 2.4mhz
 *
 * enable must be high to send data.   Otherwise, the pin 
 * is held low.
 *
 */
module ws2812b_pixel_driver (input clk_2_4_mhz,
                             input bit,
                             input enable,
                             output pin);

   reg [1:0] bitCount = 0;
   reg       state = 0;

   assign pin = state;

   always @(negedge clk_2_4_mhz)
   begin
    if (enable)
    begin
        case (bitCount)
          0:  
              begin 
                 state = 1;
                 bitCount = bitCount + 2'b1;
              end
          1:  
              begin 
                state = bit;
                bitCount = bitCount + 2'b1;
              end
          2:
             begin
               state = 0;
               bitCount = 0;
             end
        endcase
    end
    else 
        state = 0;
   end

endmodule

/*
 * Send 24 bit GRB values to the ws2812b
 *
 * The pixel_grb must be set before enable is 
 * set high.   The sending of multiple pixels must
 * be timed off the clk_2_4_mhz clock at 72 (24*3) cycles.
 */
module ws2812b (input  clk_2_4_mhz,
                // note [0:23] to send in right order
                // g7,g6,g5,g4,g3,g3,g1,g0,r7...
                input  [0:23] pixel_grb, 
                input  enable,
                output pin);


  reg [4:0] pixel_idx = 0;
  wire      pixel_clk;
  
  // generate a 800khz pixel clock
  clk_divider #(1,2) clk_divider800_khz (clk_2_4_mhz,pixel_clk);


  ws2812b_pixel_driver pixel_driver(clk_2_4_mhz,
                                    // note: pixel_idx is changed in event to select the pixel to output
                                    pixel_grb[pixel_idx],
                                    enable,
                                    pin); 
  
  always @ (posedge pixel_clk)
  begin
     if (enable)
     begin   
         pixel_idx = (pixel_idx + 1) % 24;
     end
     else 
     begin
         // prime the pixel index for the next pixel
         pixel_idx = 0;
     end
  end

endmodule

/*
 * Rotate the pixel colors around ring.
 * This is setup for a 12 ws2812b ring
 */
module ws2812b_rotate (input  clk_2_4_mhz,
                       input  word_clk,
                       input  sys_rst_n,
                       output pixel_pin);

  parameter PIXEL_CNT = 12;

  reg [4:0]  start_index = 0;
  reg [12:0] pixel_cnt = 0;
  reg        enable = 0;
  reg [4:0]  pixel_idx = 0;
  reg [23:0] pixels [PIXEL_CNT-1:0];

  initial 
  begin
     // 24 bit pixel in GRB format
     pixels[0]  = 24'b00111111_00111111_00111111;
     pixels[1]  = 24'b00000000_00111111_00000000;
     pixels[2]  = 24'b00111111_00111111_00000000;
     pixels[3]  = 24'b00111111_00000000_00000000;
     pixels[4]  = 24'b00111111_00000000_00111111;
     pixels[5]  = 24'b00000000_00000000_00111111;
     pixels[6]  = 24'b00000000_00000000_00000000;
     pixels[7]  = 24'b00000000_00001111_00000000;
     pixels[8]  = 24'b00001111_00001111_00000000;
     pixels[9]  = 24'b00001111_00000000_00000000;
     pixels[10] = 24'b00001111_00000000_00001111;
     pixels[11] = 24'b00000000_00000000_00001111;
     
  end

  ws2812b ws2812b_driver(clk_2_4_mhz,
                         // note in the event block, we are only changing pixel_idx to set the output pixel
                         pixels[pixel_idx],  
                         enable,
                         pixel_pin);


  always @ (posedge word_clk or negedge sys_rst_n)
  begin
     if (!sys_rst_n) 
     begin 
         pixel_cnt = 0;
         start_index = 0;
     end
     else 
     begin
         if (pixel_cnt < PIXEL_CNT)
         begin
            pixel_idx = (pixel_cnt + start_index) % PIXEL_CNT;
            pixel_cnt = pixel_cnt + 11'b1;
            enable = 1;
            if (pixel_cnt == PIXEL_CNT)
            begin
                 start_index = (start_index + 1) % PIXEL_CNT;
            end
         end
         else
         begin
            // disabled from PIXEL_CNT to 6000
            // approx 1/6 of a second
            pixel_cnt = pixel_cnt + 11'b1;
            if (pixel_cnt == 8000)
                pixel_cnt = 0;
            enable = 0;
         end
     end     
  end

endmodule


/*
 * This will move a red 5 pixel gradient up and down 
 */
module ws2812b_up_down #(parameter PIXEL_CNT=12)
                        (input  clk_2_4_mhz,
                        input  word_clk,
                        input  sys_rst_n,
                        output pixel_pin);


  reg [4:0]  start_index = 0;
  reg        going_up = 1;
  reg [11:0] pixel_cnt = 0;
  reg        enable = 0;
  reg [4:0]  pixel_idx = 0;
  reg [23:0] pixels [6:0];
  
  initial 
  begin

     // build the gradient and fill the rest of the pixels
     // with black.
     pixels[0]  = 24'b00000000_00000100_00000000;
     pixels[1]  = 24'b00000000_00011000_00000000;
     pixels[2]  = 24'b00000000_11100000_00000000;
     pixels[3]  = 24'b00000000_00011000_00000000;
     pixels[4]  = 24'b00000000_00000100_00000000;
     pixels[5]  = 24'b00000000_00000000_00000000;
    
  end

  ws2812b ws2812b_driver(clk_2_4_mhz,
                         // note: in the event block, we are only changing pixel_idx to set the output pixel
                         pixels[pixel_idx],
                         enable,
                         pixel_pin);


  always @ (posedge word_clk or negedge sys_rst_n)
  begin
     if (!sys_rst_n) 
     begin 
         pixel_cnt = 0;
         start_index = 0;
         going_up = 1;
     end
     else 
     begin
         if (pixel_cnt < PIXEL_CNT)
         begin
            if (((pixel_cnt + (PIXEL_CNT - start_index)) % PIXEL_CNT) <=4 )
               pixel_idx = ((pixel_cnt + (PIXEL_CNT - start_index)) % PIXEL_CNT);
            else 
               pixel_idx = 5;
            pixel_cnt = pixel_cnt + 5'b1;
            enable = 1;
            if (pixel_cnt == PIXEL_CNT)
            begin
                 if (going_up)
                 begin
                    if (start_index < (PIXEL_CNT - 5))
                       start_index = start_index + 5'b1;
                    else 
                       going_up = 0;
                 end
                 else
                 begin
                    if (start_index > 0) 
                        start_index = start_index - 5'b1;
                     else
                       going_up = 1;
                 end 
            end
         end
         else
         begin
            // disabled from PIXEL_CNT to 4095
            // approx 1/8 of a second
            pixel_cnt = pixel_cnt + 5'b1;
            enable = 0;
         end
     end     
  end

endmodule



module test_ws2812b (input sys_clk,
                     input sys_rst_n,
                     output pixel_pin);

  //
  // sys_clk is at 27mhz
  //
  // We need to generate a 800khz signal to the ws2318b leds to output 24 GRB data.
  // The pixels need to be encoded using 110 or 100 waveform.  So to do that, we 
  // really need 800khz*3 or 2.4mhz.
  //
  //
  // If the sys_clk is 48mhz, then CLK_TO_2_4_MHZ_HI = 10, CLK_TO_2_4_MHZ_LO = 10
  //
  parameter CLK_TO_2_4_MHZ_HI = 6;
  parameter CLK_TO_2_4_MHZ_LO = 5;
  parameter CLK_WORD          = 24 * 3 / 2;

  parameter PIXEL_CNT = 12; // 12 pixel ring
 
  wire word_clk;
  wire clk_ws2812b;

  clk_divider #(CLK_TO_2_4_MHZ_HI,CLK_TO_2_4_MHZ_LO)  clk_divider2_4_mhz    (sys_clk,clk_ws2812b);
  clk_divider #(CLK_WORD,CLK_WORD)                    clk_divider_word_clk  (clk_ws2812b,word_clk);


 // two examples...  use only one at a time



  ws2812b_rotate ws2812b_driver(clk_ws2812b,
                                word_clk,
                                sys_rst_n,
                                pixel_pin);

/*


  ws2812b_up_down #(PIXEL_CNT)  ws2812b_driver(clk_ws2812b,
                                               word_clk,
                                               sys_rst_n,
                                               pixel_pin);



*/
endmodule