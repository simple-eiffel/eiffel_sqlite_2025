# Makefile for eiffel_sqlite_2025 - Modern SQLite with FTS5, JSON1, and more
# Windows build using MSVC

CC = cl
AR = lib
CFLAGS = /nologo /MT /O2 /W3 /EHsc
INCLUDES = /I. /I"C:\Program Files\Eiffel Software\EiffelStudio 25.02 Standard\studio\spec\win64\include"

# Modern SQLite compile flags
SQLITE_FLAGS = /DSQLITE_THREADSAFE=1 \
               /DSQLITE_ENABLE_FTS5 \
               /DSQLITE_ENABLE_JSON1 \
               /DSQLITE_ENABLE_RTREE \
               /DSQLITE_ENABLE_GEOPOLY \
               /DSQLITE_ENABLE_MATH_FUNCTIONS \
               /DSQLITE_OMIT_LOAD_EXTENSION \
               /DSQLITE_ENABLE_COLUMN_METADATA

OUTDIR = D:\prod\eiffel_sqlite_2025\spec\msvc\win64\lib
OBJECTS = sqlite3.obj esqlite.obj

all: $(OUTDIR)\sqlite_2025.lib

$(OUTDIR)\sqlite_2025.lib: $(OBJECTS)
	@if not exist "$(OUTDIR)" mkdir "$(OUTDIR)"
	$(AR) /nologo /out:$@ $(OBJECTS)
	@echo.
	@echo SQLite 2025 library built successfully!
	@echo Location: $(OUTDIR)\sqlite_2025.lib
	@echo.

sqlite3.obj: sqlite3.c sqlite3.h
	$(CC) /c $(CFLAGS) $(INCLUDES) $(SQLITE_FLAGS) sqlite3.c

esqlite.obj: esqlite.c esqlite.h sqlite3.h
	$(CC) /c $(CFLAGS) $(INCLUDES) $(SQLITE_FLAGS) esqlite.c

clean:
	@if exist *.obj del *.obj
	@if exist $(OUTDIR)\sqlite_2025.lib del $(OUTDIR)\sqlite_2025.lib
	@echo Cleaned build artifacts

.PHONY: all clean
