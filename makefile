
OPT ?= -O2

EXE ?= 

BUILD_DIR ?= build
OBJ_DIR ?= $(BUILD_DIR)/obj
TMP_DIR ?= $(BUILD_DIR)/tmp
BIN_DIR ?= $(BUILD_DIR)/bin
RES_DIR ?= $(BUILD_DIR)/res

PROG_SRCS = main/minivm.c
PROG_OBJS = $(PROG_SRCS:%.c=$(OBJ_DIR)/%.o)

GC_SRCS = vm/gc/gc.c vm/gc/if.c
GC_OBJS = $(GC_SRCS:%.c=$(OBJ_DIR)/%.o)

STD_SRCS := vm/std/libs/io.c vm/std/std.c
VM_SRCS := vm/ir.c vm/lib.c vm/type.c vm/lang/ast.c vm/lang/paka.c vm/obj.c vm/be/tb.c vm/check.c vm/rblock.c
ALL_SRCS = $(VM_SRCS) $(STD_SRCS) $(EXTRA_SRCS)
ALL_OBJS = $(ALL_SRCS:%.c=$(OBJ_DIR)/%.o)

TB_SRCS := cuik/common/common.c cuik/common/perf.c cuik/tb/src/libtb.c cuik/tb/src/x64/x64.c
TB_OBJS = $(TB_SRCS:%.c=$(OBJ_DIR)/%.o)

OBJS = $(ALL_OBJS) $(GC_OBJS) $(TB_OBJS)

CFLAGS += $(FLAGS)
LDFLAGS += $(FLAGS)

RUNNER ?= $(BIN_DIR)/minivm

UNAME_S := $(shell uname -s)
UNAME_O := $(shell uname -o)

LDFLAGS_S_Darwin = -w -Wl,-pagezero_size,0x4000
LDFLAGS_S_Linux =
LDFLAGS_O_Cygwin =

LDFLAGS := $(LDFLAGS_S_$(UNAME_S)) $(LDFLAGS_O_$(UNAME_O)) $(LDFLAGS)

CFLAGS_O_Cygwin = -D_WIN32

CFLAGS := $(CFLAGS_O_$(UNAME_O)) $(CFLAGS)

default: all

all: bins

# windows

clang-windows: .dummy
	rm -rf build
	$(MAKE) -Bj$(J) CC=clang EXE=.exe OPT="$(OPT)" CFLAGS="-Icuik/c11threads $(CFLAGS)" LDFLAGS="$(LDFLAGS)" EXTRA_SRCS="cuik/c11threads/threads_msvc.c"

gcc-windows: .dummy
	rm -rf build
	$(MAKE) -Bj$(J) CC=gcc EXE=.exe OPT="$(OPT)" CFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS) -lSynchronization"

# binaries

bins: $(BIN_DIR)/minivm$(EXE)

minivm$(EXE) $(BIN_DIR)/minivm$(EXE): $(OBJ_DIR)/main/minivm.o $(OBJS)
	@mkdir -p $$(dirname $(@))
	$(CC) $(OPT) $(OBJ_DIR)/main/minivm.o $(OBJS) -o $(@) $(LDFLAGS)

# intermediate files

$(TB_OBJS): $(@:$(OBJ_DIR)/%.o=%.c)
	@mkdir -p $$(dirname $(@))
	$(CC) -w -c $(OPT) $(@:$(OBJ_DIR)/%.o=%.c) -o $(@) $(CFLAGS) -I cuik/tb/include -I cuik/common -DCUIK_USE_TB -DLOG_SUPPRESS

$(PROG_OBJS) $(ALL_OBJS): $(@:$(OBJ_DIR)/%.o=%.c)
	@mkdir -p $$(dirname $(@))
	$(CC) -c $(OPT) $(@:$(OBJ_DIR)/%.o=%.c) -o $(@) $(CFLAGS)

$(GC_OBJS): $(@:$(OBJ_DIR)/%.o=%.c)
	@mkdir -p $$(dirname $(@))
	$(CC) -c $(OPT) $(@:$(OBJ_DIR)/%.o=%.c) -o $(@) $(CFLAGS)

# format

format: .dummy
	clang-format -i $(ALL_OBJS:$(OBJ_DIR)/%.o=%.c)

# cleanup

clean: .dummy
	rm -rf $(BUILD_DIR)

# dummy

.dummy:
