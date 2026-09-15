config ?= debug

OFLAGS_BASE := -vet-unused-variables -vet-shadowing -vet-using-stmt -vet-cast -vet-semicolon

ifeq ($(config),debug)
    TARGET := bin/odingb_d
    OFLAGS := $(OFLAGS_BASE) -o:none -debug
else ifeq ($(config),release)
    TARGET := bin/odingb
    OFLAGS := $(OFLAGS_BASE) -o:speed
else
    $(error config must be 'debug' or 'release', got '$(config)')
endif

.PHONY: build debug release clean

build:
	@mkdir -p $(dir $(TARGET))
	odin build src/ -out:$(TARGET) $(OFLAGS)

debug:
	$(MAKE) build config=debug

release:
	$(MAKE) build config=release

clean:
	@rm bin/* -f

