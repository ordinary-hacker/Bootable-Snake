all: snake.img

snake.bin: snake.asm
	nasm -f bin -o snake.bin snake.asm

snake.img: snake.bin
	dd if=snake.bin of=snake.img bs=512 count=1

run: snake.img
	qemu-system-x86_64 -fda snake.img

clean:
	rm -f snake.bin snake.img
