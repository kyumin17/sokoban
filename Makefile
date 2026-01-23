sokoban: sokoban.o
	gcc -no-pie -Wl,-z,noexecstack -o sokoban sokoban.o

sokoban.o: sokoban.asm
	nasm -f elf64 -o sokoban.o sokoban.asm

.PHONY: play
play: sokoban
	@stty -icanon -echo && ./sokoban; stty icanon echo