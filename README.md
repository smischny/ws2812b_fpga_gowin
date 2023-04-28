# ws2812b fpga Verilog for TangNano1K (GOWIN GW1NZ) 

This is learning project to drive ws2812b leds. The led ring din pin is connected to pin 28 on the TangNano1k.   The A button (pin 13) is connected as a reset button.  The clock source is the 27mhz crystal (pin 47).  The led ring is connected to the 3.3v power rail.

ws2812b pixels are driven by a 800khz signal with a 24 bit GRB data stream.   The data is sent MSB to LSB (g7,g6,g5,g4,g3,g2,g1,g0,r7,r6...).  

##  ws2812b_rotate example
https://user-images.githubusercontent.com/61064748/235144886-7095ea68-8705-4213-b891-23255e46efe8.mp4

##  ws2812b_up_down example
https://user-images.githubusercontent.com/61064748/235145118-e11ef248-d735-41fd-95fd-91fc236599ce.mp4

## Dependancies (linux):
 - [GoWin IDE](https://www.gowinsemi.com/en/support/home/)
 - [openFPGALoader](https://github.com/trabucayre/openFPGALoader)

## Notes (linux):
### Programing
openFPGALoader -b tangnano1k -f ./projects/ws2812b_fpga_gowin/impl/pnr/ws2812b.fs
### Slow Upload
Restart linux VM

## Author:
Toby Smischny


