@echo off
REM Quick build script for x64 SQLite with FTS5
REM For use with Gobo Eiffel or when Makefile paths don't match your setup

echo ========================================
echo Building SQLite 3.51.1 (x64 with FTS5)
echo ========================================
echo.

REM Check for Visual Studio
where cl >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Visual Studio command line tools not found!
    echo Please run this from an x64 Native Tools Command Prompt.
    echo.
    pause
    exit /b 1
)

REM Check we're in the right directory
if not exist sqlite3.c (
    echo ERROR: sqlite3.c not found!
    echo Please run this from the Clib directory.
    echo.
    pause
    exit /b 1
)

echo Step 1: Compiling sqlite3.c with FTS5...
cl /c /O2 /MT /DSQLITE_ENABLE_FTS5 /DSQLITE_THREADSAFE=1 sqlite3.c
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to compile sqlite3.c
    pause
    exit /b 1
)
echo    ✓ sqlite3.obj created

echo.
echo Step 2: Compiling esqlite.c...

REM Try to find Gobo runtime first
if exist "D:\prod\gobo-gobo-25.09\gobo-gobo-25.09\tool\gec\backend\c\runtime\eif_eiffel.h" (
    echo    Using Gobo Eiffel runtime
    cl /c /O2 /MT /I"D:\prod\gobo-gobo-25.09\gobo-gobo-25.09\tool\gec\backend\c\runtime" /I. esqlite.c
) else (
    REM Try EiffelStudio
    if exist "C:\Program Files\Eiffel Software\EiffelStudio 25.02 Standard\studio\spec\win64\include\eif_eiffel.h" (
        echo    Using EiffelStudio runtime
        cl /c /O2 /MT /I"C:\Program Files\Eiffel Software\EiffelStudio 25.02 Standard\studio\spec\win64\include" /I. esqlite.c
    ) else (
        echo ERROR: Could not find Eiffel runtime headers!
        echo Please edit this script to add the correct path.
        pause
        exit /b 1
    )
)

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to compile esqlite.c
    pause
    exit /b 1
)
echo    ✓ esqlite.obj created

echo.
echo ========================================
echo Build SUCCESS!
echo ========================================
echo.
echo Object files created:
echo   - sqlite3.obj
echo   - esqlite.obj
echo.
echo These can now be linked with your Eiffel project.
echo.
pause
