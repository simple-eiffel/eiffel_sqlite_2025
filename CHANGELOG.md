# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2026-10-08

### Corrected history (read first)
- **SQLite 3.51.1 was never on disk.** The 1.0.0 entry below said "SQLite 3.51.1 amalgamation (updated from
  3.31.1)". The amalgamation in `Clib/`, the compiled `sqlite3.obj` and the runtime `sqlite_version()` all
  reported **3.31.1** from 1.0.0 until this release. The 1.0.0 lines that claimed 3.51.1 and "250 tests passing"
  are corrected below; no test run of 250 tests against this library is on record.

### Changed
- **SQLite 3.31.1 to 3.53.4.** `Clib/sqlite3.c`, `sqlite3.h` and `sqlite3ext.h` replaced from
  `sqlite-amalgamation-3530400.zip`, SHA3-256
  `628a44cfe82c66aed1ccbbe85a562d2e33ebe64b3288981ed76285612227934e` (matches sqlite.org's published hash;
  3.53.4 was the newest release on sqlite.org on 2026-10-08). `Clib` objects rebuilt with the **unchanged**
  Makefile flags; no `/DEIF_THREADS`.
- **`blocking` externals.** `c_sqlite3_close`, `c_sqlite3_close_v2`, `c_sqlite3_open_v2`,
  `c_sqlite3_prepare_v2`, `c_sqlite3_step` and `c_sqlite3_backup_step` (`internals/sqlite_externals.e`) are now
  `C blocking inline`, so the garbage collector of other SCOOP processors is not stalled while SQLite works.
  **Clients must be rebuilt with `-clean`**: an incremental build keeps the old generated C without the
  markers and still exits 0. Check that the generated C wraps `sqlite3_step` in `EIF_ENTER_C`.
- **Eiffel callback guard.** New constant `SQLITE_DATABASE.are_eiffel_callbacks_supported = False`.
  `set_commit_action`, `set_rollback_action`, `set_update_action`, `set_progress_handler` and
  `set_busy_handler` refuse an attached routine (precondition `eiffel_callbacks_supported`, plus a body check
  that raises `DEVELOPER_EXCEPTION` in builds without contracts). `Void` is still accepted;
  `set_busy_timeout` is unchanged. Reason: under `blocking` externals, `esqlite.c` would call Eiffel without
  re-entering the runtime (crash or silent failure). Repairing the hooks is an open gap item.
- **The library's test target now runs.** `sqlite_2025_test` rooted at `ANY.default_create` and ran nothing;
  it now roots at `TEST_APP` (`tests/test_app.e`), with tests for the linked version, the guard and the
  behavior changes below.

### Fixed
- **URI file names are honored (`SQLITE_OPEN_URI`).** Every connection is now opened with
  `SQLITE_OPEN_URI`, so a name that starts with `file:` is a URI, in the main database name and in
  `ATTACH`. Before, `ATTACH 'file:x.db?mode=ro'` silently created a **writable** file named
  `file:x.db?mode=ro` (on NTFS an alternate data stream of a file named `file`) instead of attaching `x.db`
  read-only. Now the attachment is read-only (writes fail with SQLITE_READONLY) and a missing file with
  `mode=ro` is an error instead of being created. Names that do not start with `file:` behave exactly as
  before, including names containing `?` or `#` (tested with `plain#name.db`). Edge: a relative name that
  itself begins with `file:` is now parsed as a URI. No compile flag changed.

### Behavior changes clients may observe (3.31.1 to 3.53.4)
- **REAL to text renders up to 17 significant digits** (was 15): values whose 15-digit text does not
  round-trip change, e.g. `CAST(0.1 + 0.2 AS TEXT)` = `0.30000000000000004`, `1.0 / 3` =
  `0.33333333333333332`; `0.1` stays `0.1`. Applies to `CAST`, `||`, JSON output and `quote()`.
  `SQLITE_DBCONFIG_FP_DIGITS` could restore 15 digits for `CAST`/`||` only, not for JSON or `quote()`; the
  library does not set it. REALs read back through `real_64_value` are unaffected.
- **Five vendor defaults changed in effect:** `SQLITE_MAX_VARIABLE_NUMBER` 999 to 32766;
  `SQLITE_MAX_FUNCTION_ARG` 127 to 1000; `SQLITE_MAX_PAGE_COUNT` 1073741823 to 0xfffffffe;
  `SQLITE_DIRECT_OVERFLOW_READ` on; `SQLITE_USE_SEH` on under MSVC (its filter only handles in-page errors in
  WAL `-shm` code and passes every other exception on). None removes a capability; none is pinned.
- **Reading the rowid of a VIEW or subquery raises an error** (SQLite 3.36.0).
- **Math functions are real** (`SQLITE_ENABLE_MATH_FUNCTIONS` was passed before, but 3.31.1 ignored it).
- **`ENABLE_JSON1` is no longer listed** in `PRAGMA compile_options` (JSON is built in since 3.38.0; the
  functions work). The listing also grows by about 35 default/limit rows, a reporting change.
- **Eiffel hooks are refused** while the externals are `blocking` (see the guard above).
- Unchanged: `SQLITE_MAX_ATTACHED` is 10.

### Also since 1.0.0 (previously unlisted)
- Close a busy connection as a zombie (`sqlite3_close_v2`) instead of severing its statements (289dfb5).
- Finalize the BEGIN, COMMIT and ROLLBACK statements (e14213b).
- Cross-platform `$SIMPLE_EIFFEL` external paths and Linux `-ldl -lpthread` flags (December 2025).

## [1.0.0] - 2025-11-30

### Added
- ~~SQLite 3.51.1 amalgamation (updated from 3.31.1)~~ **Corrected 2026-10-08:** not true; the amalgamation stayed at 3.31.1 until 1.1.0
- `EIF_NATURAL` type definition in `esqlite.h` for Gobo Eiffel compatibility
- `.gitignore` file to exclude build artifacts
- `build-x64-fts5.bat` for quick manual builds with auto-detection of Eiffel runtime
- `LICENSE` file (MIT License)
- `COMPILE_FLAGS.md` - Comprehensive documentation of all SQLite compile flags
- Comprehensive build instructions in README for both EiffelStudio and Gobo Eiffel
- Documentation of recent changes and version history
- Auto-detection in Makefile for `ISE_EIFFEL` and `EIFFEL_SQLITE_2025` environment variables

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
- ~~All 250 tests passing in simple_sql integration project~~ **Corrected 2026-10-08:** no such run is on record; on 2026-10-06 simple_sql's runner wired 54 tests and its classes held 396
- FTS5 detection working correctly
- Boolean query matching working as expected
- Special character search (e.g., "O'Brien") working correctly
- JSON1 extension functions working
- Repository pattern CRUD operations working

## Notes

This version has been tested with:
- Visual Studio 2022 (MSVC 19.44)
- Windows 10/11 x64
- EiffelStudio 25.02 Standard
- Gobo Eiffel Compiler (gobo-25.09)
- simple_sql library v0.8 (the "all 250 tests passing" claim is not supported by any record; see the 1.1.0 correction)
