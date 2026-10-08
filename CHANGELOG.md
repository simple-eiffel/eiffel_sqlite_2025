# Changelog

All notable changes to this project will be documented in this file.

## [1.2.1] - 2026-10-08

### Fixed
- **Removing an action on a closed database failed.** `set_commit_action`, `set_rollback_action`,
  `set_update_action`, `set_progress_handler` and `set_busy_handler` required `is_readable` (an open database)
  even for `Void`, and then called `enable_*_callback (False)`, which also requires an open database. Now
  `is_readable` is required only for an attached action, and on a closed database the setter only records
  the action; `open` installs whatever is set. Test `test_void_actions_on_closed_database`: on 1.2.0 it fails
  (`[is_readable]`, 33 passed, 1 failed); with the fix the runner gives 34 passed, 0 failed.

### Corrected
- **K2 (b) wording.** 1.2.0 said per-row re-entry costs latency. Controls (600,000 rows, 11 rounds per run,
  worst root allocation, idle 1-3 ms) show otherwise:
  - per-row update action that allocates nothing: 2 2 2 3 2 2 2 2 2 3 2 ms (1.2.0): the binding adds nothing
    measurable;
  - action allocating 20 x 256-byte strings: 14 25 24 17 21 20 12 15 19 18 18 ms (1.2.0);
  - the same Eiffel work with no SQLite: 15 18 23 14 16 14 14 16 14 12 18 / 12 11 10 10 11 11 13 12 13 12 10 /
    15 10 12 21 14 9 11 13 10 14 12 ms.
  The 16 ms bar is missed by allocation-heavy callback bodies themselves. Keep per-row callbacks light.

### Not adopted: deferred update events
- A design that queued update and rollback events in C during the step and delivered them in Eiffel after it
  (no per-row re-entry) was built, tested and measured on the unmerged branch `fix/k2b-deferred-update`
  (commit 77d96b5). Its K2 (b) result was the same as 1.2.0 (light action 2-3 ms in both; heavy action within
  the same noise), so it bought nothing for latency while adding a C queue, a delivery path in every step
  and an ordering change (in an autocommit statement the commit action would run before that statement's
  update events). It was not merged.

## [1.2.0] - 2026-10-08

### Added
- **Eiffel hooks work under the `blocking` externals; the guard is lifted** (fork 04 verdict, ship plan step 8).
  `are_eiffel_callbacks_supported` is `True`. New: `is_callback_reentry_active`, `last_callback_exception`,
  `clear_last_callback_exception`, `progress_handler_period`, `set_progress_handler_period` (default 1000).
- **Re-entry without a compile flag.** The callback trampolines moved from `esqlite.c` (one precompiled object)
  to the header `Clib/esqlite_reentry.h`, reached through `C inline use` externals, so they compile inside each
  client's generated C with that client's flags. In concurrent targets they re-enter the runtime
  (`EIF_ENTER_EIFFEL; RTGC` ... `EIF_EXIT_EIFFEL`, only when the thread is outside Eiffel code); in
  `concurrency use="none"` targets the macros are empty and nothing from the multithreaded runtime is
  referenced. No `/DEIF_THREADS`, no ECF condition, no new object; `Clib` objects unchanged.
- **Exceptions in callbacks are contained.** Each callback routine catches its exception (kept in
  `last_callback_exception`) and answers SQLite safely: commit aborts (rollback), progress interrupts, busy
  stops waiting, update and rollback are ignored. Nothing unwinds through SQLite's frames.

### Fixed (D-16 wiring)
- Removing the commit action or the rollback action called `sqlite3_update_hook`, so it removed the
  **update** hook and left the commit or rollback hook installed. Each now removes its own hook.
- The progress handler registered `on_busy` (a routine with a different signature) through the busy-callback
  trampoline, passed null data, and ran every VM instruction. It now registers `on_progress` with its own
  data and trampoline, every `progress_handler_period` instructions.
- Commit, progress and busy callbacks return Eiffel `BOOLEAN` (one byte) but were called through
  `EIF_INTEGER`-returning pointers, so the upper bytes were garbage. The trampolines now use `EIF_BOOLEAN`.
- Removing a hook passed a null data pointer with a non-null callback; it now passes a null callback.
- Callback routines no longer carry preconditions (they are called from C); re-enabling a handler frees
  the previous callback data.

### Tests and measurements
- `TEST_SQLITE_HOOKS` (14 tests): every hook fires with the right data (update: action code, `main`, table,
  rowid; busy: counts 0,1,2,3; progress: many calls at period 100, interrupt on True); removing each hook
  leaves the others working; an exception in the update, commit, progress or busy callback leaves the
  connection usable; hooks survive close and reopen. Library runner: 33 passed, 0 failed.
- Stress spike (4 processors x 1,000 iterations; commit, rollback, update, progress and busy callbacks;
  callbacks allocate, force collections and raise; a busy callback releases a lock on another connection):
  identical totals in SCOOP DBC, SCOOP lean, non-concurrent DBC and non-concurrent lean builds: 4,000
  iterations, 3,664 commit, 1,528 rollback, 80,232 update, 8,000 progress and 696 busy callbacks, 600
  exceptions contained, 0 bad results, 0 errors, exit 0 (SCOOP builds run 3 times each, same totals).
  Negative control, re-entry switched off in a SCOOP build: 3 of 3 runs failed (one ROUTINE_FAILURE after
  3,016 iterations, two hangs killed at 20 minutes), each where a busy callback makes a nested `blocking`
  call on another connection.
- K2 (b), per-row update callback (600,000 rows) on a worker processor while the root allocates. First runs
  (action allocating 20 x 256-byte strings per call): root worst allocation 13-24 ms in 10 of 11 rounds, 94 ms
  in one. **Corrected in 1.2.1** after control runs: the binding adds no measurable wait (an action that
  allocates nothing gives 2-3 ms, the same as idle); the 16 ms bar is missed by allocation-heavy callback
  bodies themselves (the same work with no SQLite gives 9-23 ms). The earlier line "re-entering the runtime
  per row costs latency" was wrong.
- simple_sql 1.3.3 against this version, all from clean: `simple_sql_tests` 77/0, full EQA 419/0, mock apps
  todo 36/0, cpm 27/0, habit_tracker 48/0, dms 64/0, wms 25/0.

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

- **A failed COMMIT no longer claims the transaction ended** (fork 02 F-9 item e). `commit` set
  `is_in_transaction := False` unconditionally, even when COMMIT failed (for example SQLITE_BUSY or a deferred
  foreign key violation) and SQLite kept the transaction open. `begin_transaction`, `commit` and `rollback`
  now set the flag from SQLite's own state through the new query `is_autocommit`
  (`sqlite3_get_autocommit`); their postconditions read `is_in_transaction = not is_autocommit`. The failure
  is reported through `has_error` / `last_exception`. Behavior change: after a failed COMMIT,
  `is_in_transaction` stays True, so the client must roll back (or retry the COMMIT) before `close`.
- **A statement that failed to compile no longer leaves the connection locked.** `execute_internal`
  released the database lock only when the statement was connected; executing a statement that never
  compiled kept the lock, and a later `close` failed its `not_is_locked` precondition (fork 02 F-9 item h,
  library half). The lock is now always released.

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
