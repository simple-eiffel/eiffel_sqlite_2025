# POSIX build of the objects sqlite_2025.ecf expects on macOS and Linux.
# GNU make reads this file first; nmake on Windows still reads Makefile.
# Usage: make -C Clib   (needs ISE_EIFFEL and ISE_PLATFORM for the Eiffel headers)

CC ?= cc
CFLAGS ?= -O2 -fPIC
EIFFEL_INCLUDE = -I"$(ISE_EIFFEL)/studio/spec/$(ISE_PLATFORM)/include"

# Same SQLite options as the Windows Makefile.
SQLITE_FLAGS = -DSQLITE_THREADSAFE=1 \
	-DSQLITE_ENABLE_FTS5 \
	-DSQLITE_ENABLE_JSON1 \
	-DSQLITE_ENABLE_RTREE \
	-DSQLITE_ENABLE_GEOPOLY \
	-DSQLITE_ENABLE_MATH_FUNCTIONS \
	-DSQLITE_OMIT_LOAD_EXTENSION \
	-DSQLITE_ENABLE_COLUMN_METADATA

all: sqlite3.o esqlite.o

sqlite3.o: sqlite3.c sqlite3.h
	$(CC) $(CFLAGS) -I. $(SQLITE_FLAGS) -c sqlite3.c -o $@

esqlite.o: esqlite.c esqlite.h sqlite3.h
	$(CC) $(CFLAGS) -I. $(EIFFEL_INCLUDE) $(SQLITE_FLAGS) -c esqlite.c -o $@

clean:
	rm -f sqlite3.o esqlite.o

.PHONY: all clean
