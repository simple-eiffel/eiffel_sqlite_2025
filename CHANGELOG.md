# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2025-11-30

### Added
- SQLite 3.51.1 amalgamation (updated from 3.31.1)
- `EIF_NATURAL` type definition in `esqlite.h` for Gobo Eiffel compatibility
- `.gitignore` file to exclude build artifacts
- `build-x64-fts5.bat` for quick manual builds
- Comprehensive build instructions in README for both EiffelStudio and Gobo Eiffel
- Documentation of recent changes and version history

### Changed
- Compiled for x64 (64-bit) architecture instead of x86
- Changed from `/MD` (dynamic runtime) to `/MT` (static runtime) for better portability
- Updated Makefile to use `/MT` flag
- Updated README with correct SQLite version and detailed build instructions

### Fixed
- FTS5 full-text search now properly enabled and tested
- Special character handling in FTS5 queries (apostrophes)
- Type compatibility issues with Gobo Eiffel runtime

### Verified
- All 181 tests passing in simple_sql integration project
- FTS5 detection working correctly
- Boolean query matching working as expected
- Special character search (e.g., "O'Brien") working correctly

## Notes

This version has been tested with:
- Visual Studio 2022 (MSVC 19.44)
- Windows 10/11 x64
- EiffelStudio 25.02 Standard
- Gobo Eiffel Compiler (gobo-25.09)
- simple_sql library (all 181 tests passing)
