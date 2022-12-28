all:
	rgbasm -L -o main.o main.asm
	rgbasm -L -o input.o input.asm
	rgbasm -L -o header.o header.asm 
	rgblink -o Pong.gb *.o
	rgbfix -v -p 0xFF Pong.gb
	sameboy Pong.gb
clean:
	rm /build/*.gb /Build/*.o
