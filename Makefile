build/hexdump_asm: build/hexdump_asm.o
	ld -o $@ $<

build/hexdump_asm.o: hexdump_asm.asm
	nasm -f elf64 -g -o $@ $<
