
ifneq ($(EMSCRIPTEN),)
   platform = emscripten
endif

ifeq ($(platform),)
platform = unix
ifeq ($(shell uname -a),)
   platform = win
else ifneq ($(findstring MINGW,$(shell uname -a)),)
   platform = win
else ifneq ($(findstring Darwin,$(shell uname -a)),)
   platform = osx
else ifneq ($(findstring win,$(shell uname -a)),)
   platform = win
endif
endif

TARGET_NAME := nogg

fpic=
ifeq ($(platform), unix)
   TARGET := $(TARGET_NAME)_libretro.so
   fpic := -fPIC
   SHARED := -shared -Wl,--no-undefined
else ifeq ($(platform), osx)
   TARGET := $(TARGET_NAME)_libretro.dylib
   fpic := -fPIC
   SHARED := -dynamiclib
else ifeq ($(platform), ios)
   TARGET := $(TARGET_NAME)_libretro_ios.dylib
	fpic := -fPIC
	SHARED := -dynamiclib
	DEFINES := -DIOS
	CC = clang -arch armv7 -isysroot $(IOSSDK)
else ifeq ($(platform), qnx)
	TARGET := $(TARGET_NAME)_libretro_qnx.so
   fpic := -fPIC
   SHARED := -shared -Wl,--no-undefined
else ifeq ($(platform), emscripten)
   TARGET := $(TARGET_NAME)_libretro_emscripten.so
   fpic := -fPIC
   SHARED := -shared -Wl,--no-undefined
# SF2000
else ifeq ($(platform), sf2000)
   TARGET := $(TARGET_NAME)_libretro_$(platform).a
   MIPS:=/opt/mips32-mti-elf/2019.09-03-2/bin/mips-mti-elf-
   CC = $(MIPS)gcc
   CXX = $(MIPS)g++
   AR = $(MIPS)ar
   CFLAGS = -EL -march=mips32 -mtune=mips32 -msoft-float -G0 -mno-abicalls -fno-pic
   CFLAGS += -ffast-math -fomit-frame-pointer -ffunction-sections -fdata-sections 
   CFLAGS += -DSF2000
   CXXFLAGS = $(CFLAGS)
   STATIC_LINKING = 1
else ifeq ($(platform), psp1)
   TARGET := $(TARGET_NAME)_libretro_psp1.a
   CC = psp-gcc$(EXE_EXT)
   CXX = psp-g++$(EXE_EXT)
   AR = psp-ar$(EXE_EXT)
   PLATFORM_DEFINES := -DPSP -G0
   STATIC_LINKING = 1
else
   CC = gcc
   TARGET := $(TARGET_NAME)_libretro.dll
   SHARED := -shared -static-libgcc -static-libstdc++ -Wl,--no-undefined -s
endif

ifeq ($(DEBUG), 1)
   CFLAGS += -O0 -g
else
   CFLAGS += -O3
endif

OBJECTS := pl.o collisions.o strl.o ground.o map.o game.o rpng.o json.o libretro.o
CFLAGS += -Wall -pedantic $(fpic) $(PLATFORM_DEFINES)

CFLAGS +=
LFLAGS := 
LIBS := -lm

ifeq ($(platform), qnx)
   CFLAGS += -Wc,-std=gnu99
else
   CFLAGS += -std=gnu99
endif

with_fpic=
ifneq ($(fpic),)
   with_fpic := --with-pic=yes
endif

all: $(TARGET)

$(TARGET): $(OBJECTS) 
ifeq ($(STATIC_LINKING), 1)
	$(AR) rcs $@ $(OBJECTS)
else
	$(CC) $(fpic) $(SHARED) $(INCLUDES) $(LFLAGS) -o $@ $(OBJECTS) $(LIBS) -lz
endif

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJECTS) $(TARGET)

install: all
	install -m755 $(TARGET) /usr/lib/libretro/
	install -d -m755 /usr/share/nogg
	cp -r assets/* /usr/share/nogg

.PHONY: clean
