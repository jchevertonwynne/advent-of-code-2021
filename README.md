# Advent of code 2021

My zig solutions for 2021's advent of code. The aim is to write generally performant solutions without tailoring the code to a particular input. 

## How to run

`zig build` will use the general purpose allocator to check for memory leaks

`zig build -Drelease-fast` will use the arena allocator 