# risc-computer

This is a learning project to create a computer of Von Neumann architecture. The CPU is made on FPGA, it is commented to RAM with parallel access and a four digit seven segment display interfaced just like memory (writing on RAM address with 1 as MSB will send the information to the display). To load the program into RAM I use Orange PI that wired to the same RAM chip and controls access between itself and FPGA. The program can be written in assembler that remind RISC 16 but not fully compatible.

![Main Layout](https://github.com/elijahsd/risc-computer/blob/main/schematics/Capture0.PNG)
![Display](https://github.com/elijahsd/risc-computer/blob/main/schematics/Capture1.PNG)
![Multiplexor](https://github.com/elijahsd/risc-computer/blob/main/schematics/Capture2.PNG)
