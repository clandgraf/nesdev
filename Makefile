FCEUX=fceux
INES_OBJECTS=main.o ines.o

.PHONY=run all

%.o:	%.s
	ca65 $< -o $@

all:	test.nes
run:	test.nes
	$(FCEUX) test.nes

test.nes:	$(INES_OBJECTS)
	ld65 -C link.x $^ -o test.nes

clean:
	rm -f *~ *.o *.nes
