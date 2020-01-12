.PNONY:all

#---------

TARGET ?= x
FINALPROCNAME = x

#-----------platform

include Platform.mk

linux macosx: all

#-----------library

#lua

LUA_DIR=deps/lua
LUA_INC=$(LUA_DIR)
LUA_STATICLIB=$(LUA_DIR)/liblua.a

$(LUA_STATICLIB):
	make -C $(LUA_DIR) $(PLAT) MYCFLAGS=-g

#jemalloc

JEMALLOC_DIR=deps/jemalloc
JEMALLOC_INC=$(JEMALLOC_DIR)/include
JEMALLOC_STATICLIB=$(JEMALLOC_DIR)/lib/libjemalloc.a


$(JEMALLOC_STATICLIB):$(JEMALLOC_DIR)/Makefile
	make -C $(JEMALLOC_DIR)

$(JEMALLOC_DIR)/Makefile:$(JEMALLOC_DIR)/autogen.sh
	cd $(JEMALLOC_DIR)&&\
		./autogen.sh --with-jemalloc-prefix=je_

$(JEMALLOC_DIR)/autogen.sh:
	git submodule update --init

jemalloc:$(JEMALLOC_STATICLIB)

#malloc lib select
MALLOC_STATICLIB=$(JEMALLOC_STATICLIB)

all:jemalloc

#-----------project
BIN_DIR = /usr/local/bin
TEST_PATH = test
LUACLIB_PATH ?= luaclib
SRC_PATH = x-src
LIB_PATH = lualib-src
INCLUDE = -I $(LUA_INC) -I $(JEMALLOC_INC) -I $(SRC_PATH)
SRC_FILE = \
      main.c \
      x_socket.c \
      x_queue.c \
      x_worker.c \
      x_timer.c \
      x_run.c \
      x_daemon.c \
      x_env.c \
      x_malloc.c \
      x_log.c \

SRC = $(addprefix $(SRC_PATH)/, $(SRC_FILE))
OBJS = $(patsubst %.c,%.o,$(SRC))

LIB_SRC = lualib-x.c \
	  lualib-profiler.c \
	  lualib-netstream.c \
	  lualib-netpacket.c \
	  lualib-netssl.c \
	  lualib-crypt.c lsha1.c aes.c sha256.c \
	  lualib-debugger.c\

all: \
	$(TARGET) \
	$(LUACLIB_PATH)/sys.so \
	$(LUACLIB_PATH)/zproto.so \
	$(LUACLIB_PATH)/test.so \

$(TARGET):$(OBJS) $(LUA_STATICLIB) $(MALLOC_STATICLIB)
	$(LD) -o $@ $^ $(LDFLAG)

$(LUACLIB_PATH):
	mkdir $(LUACLIB_PATH)

$(LUACLIB_PATH)/sys.so: $(addprefix $(LIB_PATH)/, $(LIB_SRC)) | $(LUACLIB_PATH)
	$(CC) $(CCFLAG) $(INCLUDE) -o $@ $^ $(SHARED)
$(LUACLIB_PATH)/zproto.so: lualib-src/zproto/lzproto.c lualib-src/zproto/zproto.c | $(LUACLIB_PATH)
	$(CC) $(CCFLAG) $(INCLUDE) -o $@ $^ $(SHARED)
$(LUACLIB_PATH)/test.so: $(LIB_PATH)/lualib-test.c | $(LUACLIB_PATH)
	$(CC) $(CCFLAG) $(INCLUDE) -o $@ $^ $(SHARED)

.depend:
	@$(CC) $(INCLUDE) -MM $(SRC) 2>/dev/null |\
		sed 's/\([^.]*\).o[: ]/$(SRC_PATH)\/\1.o $@: /g' > $@ || true

-include .depend

%.o:%.c
	$(CC) $(CCFLAG) $(INCLUDE) -c -o $@ $<

clean:
	-rm $(SRC:.c=.o) *.so $(TARGET)
	-rm -rf $(LUACLIB_PATH)
	-rm .depend

cleanall: clean
	make -C $(LUA_DIR) clean
ifneq (,$(wildcard $(JEMALLOC_DIR)/Makefile))
	cd $(JEMALLOC_DIR)&&make clean&&rm Makefile
endif

install:
	install -D $(FINALPROCNAME) $(BIN_DIR)/$(FINALPROCNAME)