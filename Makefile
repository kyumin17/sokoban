sokoban: sokoban.o
	ld -s -o sokoban sokoban.o

sokoban.o: sokoban.asm
	nasm -f elf64 sokoban.asm

.PHONY: play
play: sokoban
	@stty -icanon -echo && ./sokoban; stty icanon echo