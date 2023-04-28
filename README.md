# ws2812b fpga Verilog for TangNano1K (GOWIN GW1NZ) 

This is a verilog learning project to drive ws2812b leds. 

##  ws2812b_rotate example
![Rotating Colors](doc/FPGA_rotate.mp4)

##  ws2812b_up_down example
![Up/Down](doc/FPGA_Ring_up_down.mp4)

## Dependancies (linux):
[GoWin IDE](https://www.gowinsemi.com/en/support/home/)
[openFPGALoader](https://github.com/trabucayre/openFPGALoader)

## Program notes (linux):
openFPGALoader -b tangnano1k -f ./projects/ws2812b_fpga_gowin/impl/pnr/ws2812b.fs

## Author:
Toby Smischny


