all:
	rgbasm -L -o obj/main.o src/main.asm
	rgbasm -L -o obj/input.o src/input.asm
	rgbasm -L -o obj/header.o src/header.asm 
	rgblink -o bin/Snake.gb obj/*.o
	rgbfix -v -p 0xFF bin/Snake.gb
	sameboy bin/Snake.gb
clean:
	rm bin/*.gb obj/*.o
