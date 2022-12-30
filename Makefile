
.SUFFIXES:

# Shortcut if you want to use a local copy of RGBDS
RGBDS   :=
RGBASM  := $(RGBDS)rgbasm
RGBLINK := $(RGBDS)rgblink
RGBFIX  := $(RGBDS)rgbfix

ROM = bin/pong.gb

# Argument constants
INCDIRS  = src/ src/include/
WARNINGS = all extra
ASFLAGS  = -L -p 0xFF $(addprefix -i,$(INCDIRS)) $(addprefix -W,$(WARNINGS))
LDFLAGS  = -p 0xFF
FIXFLAGS = -p 0xFF -v -k "AB" -l 0x33 -n 0 -t "Pong"

SRCS := $(shell find src -name '*.asm')

all: $(ROM)
.PHONY: all

clean:
	rm -rf bin obj dep res
.PHONY: clean

rebuild:
	$(MAKE) clean
	$(MAKE) all
.PHONY: rebuild

bin/%.gb bin/%.sym bin/%.map: $(patsubst src/%.asm,obj/%.o,$(SRCS))
	@mkdir -p $(@D)
	$(RGBLINK) $(LDFLAGS) -m bin/$*.map -n bin/$*.sym -o bin/$*.gb $^ \
	&& $(RGBFIX) $(FIXFLAGS) bin/$*.gb

# `.mk` files are auto-generated dependency lists of the "root" ASM files, to save a lot of hassle.
# Also add all obj dependencies to the dep file too, so Make knows to remake it
# Caution: some of these flags were added in RGBDS 0.4.0, using an earlier version WILL NOT WORK
# (and produce weird errors)
obj/%.o dep/%.mk: src/%.asm
	@mkdir -p $(patsubst %/,%,$(dir obj/$* dep/$*))
	$(RGBASM) $(ASFLAGS) -M dep/$*.mk -MG -MP -MQ obj/$*.o -MQ dep/$*.mk -o obj/$*.o $<

ifneq ($(MAKECMDGOALS),clean)
-include $(patsubst src/%.asm,dep/%.mk,$(SRCS))
endif

VPATH := src/

# Convert .png files into .2bpp files.
res/%.2bpp: res/%.png
	@mkdir -p $(@D)
	rgbgfx -o $@ $<

# Catch non-existent files
# KEEP THIS LAST!!
%:
	@false