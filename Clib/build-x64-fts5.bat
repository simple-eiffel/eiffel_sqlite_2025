@echo off
REM Quick build script for x64 SQLite with all modern features
REM Includes: FTS5, JSON1, RTREE, GEOPOLY, Math Functions, Column Metadata

echo =====================================================
echo Building SQLite 3.53.4 (x64 with all features; the Makefile holds the authoritative flags)
echo =====================================================
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

echo Step 1: Compiling sqlite3.c with all features...
cl /c /O2 /MT /DSQLITE_ENABLE_FTS5 /DSQLITE_ENABLE_JSON1 /DSQLITE_ENABLE_RTREE /DSQLITE_ENABLE_GEOPOLY /DSQLITE_ENABLE_MATH_FUNCTIONS /DSQLITE_ENABLE_COLUMN_METADATA /DSQLITE_THREADSAFE=1 /DSQLITE_OMIT_LOAD_EXTENSION sqlite3.c
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to compile sqlite3.c
    pause
    exit /b 1
)
echo    ✓ sqlite3.obj created

echo.
echo Step 2: Compiling esqlite.c...

REM Check for ISE_EIFFEL environment variable first
if defined ISE_EIFFEL (
    if exist "%ISE_EIFFEL%\studio\spec\win64\include\eif_eiffel.h" (
        echo    Using EiffelStudio runtime from ISE_EIFFEL environment variable
        cl /c /O2 /MT /I"%ISE_EIFFEL%\studio\spec\win64\include" /I. esqlite.c
        goto :compile_done
    )
)

REM Try to find Gobo runtime
if exist "D:\prod\gobo-gobo-25.09\gobo-gobo-25.09\tool\gec\backend\c\runtime\eif_eiffel.h" (
    echo    Using Gobo Eiffel runtime
    cl /c /O2 /MT /I"D:\prod\gobo-gobo-25.09\gobo-gobo-25.09\tool\gec\backend\c\runtime" /I. esqlite.c
    goto :compile_done
)

REM Try EiffelStudio default installation
if exist "C:\Program Files\Eiffel Software\EiffelStudio 25.02 Standard\studio\spec\win64\include\eif_eiffel.h" (
    echo    Using EiffelStudio runtime
    cl /c /O2 /MT /I"C:\Program Files\Eiffel Software\EiffelStudio 25.02 Standard\studio\spec\win64\include" /I. esqlite.c
    goto :compile_done
)

REM If we get here, no runtime was found
echo ERROR: Could not find Eiffel runtime headers!
echo.
echo Searched in:
echo   - ISE_EIFFEL environment variable
echo   - D:\prod\gobo-gobo-25.09\gobo-gobo-25.09\tool\gec\backend\c\runtime
echo   - C:\Program Files\Eiffel Software\EiffelStudio 25.02 Standard\studio\spec\win64\include
echo.
echo Please either:
echo   1. Set ISE_EIFFEL environment variable to your EiffelStudio installation
echo   2. Edit this script to add your Eiffel runtime path
pause
exit /b 1

:compile_done

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
