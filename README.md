# Boot Sector Snake Game

A 512-byte bootable snake game that runs directly from BIOS.

## Requirements
- NASM (to assemble)
- QEMU (to emulate)

## Build and Run
1. **Build**: Run `make` to generate `snake.img`.
2. **Run**: Use `make run` to start the game in QEMU.

## Controls
- **Arrow Keys**: Change direction
- **Speed**: Adjust delay in the `snake.asm` code.

## Features
- Real-mode BIOS interrupts
- Collision detection (walls/self)
- Food spawning
- Dynamic snake growth

## TODO:
- [ ] Optimize this MUCH further
- [ ] Find how to make it so that the window is the same size as the walls.
- [ ] Make a script to automate flashing this to an external drive
