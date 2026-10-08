<p align="center">
  <img src="https://raw.githubusercontent.com/ljr1981/claude_eiffel_op_docs/main/artwork/LOGO-3.png" alt="simple_ library logo" width="400">
</p>

# Eiffel SQLite 2025

**SQLite 3.53.4 wrapper for Eiffel with FTS5, JSON, RTREE, GEOPOLY and math functions.**

The low-level SQLite binding under [simple_sql](https://github.com/ljr1981/simple_sql). In the Simple Eiffel
ecosystem, `simple_sql.ecf` is the only ECF that names this library; every other client reaches SQLite through
simple_sql.

> **Version history correction (1.1.0).** Earlier versions of this README and CHANGELOG said the library
> linked SQLite 3.51.1. That was never true: the amalgamation on disk, the compiled object and the runtime
> all reported **3.31.1** until 1.1.0. Version 1.1.0 is the first release that links a newer engine (3.53.4).

## Why This Library?

| Feature | ISE EiffelStudio SQLite library | eiffel_sqlite_2025 |
|---------|-----------------|-------------------|
| SQLite Version | 3.31.1 | **3.53.4** (since 1.1.0; 3.31.1 before) |
| Architecture | x86 (32-bit) | **x64 (64-bit)** |
| FTS5 Full-Text Search | No | **Yes** |
| JSON functions | No | **Yes** (built into SQLite since 3.38.0) |
| RTREE Spatial Index | No | **Yes** |
| GEOPOLY | No | **Yes** |
| Math Functions | No | **Yes** (since 1.1.0; the flag was passed before but 3.31.1 ignored it) |
| Runtime Linking | /MD (dynamic) | **/MT (static)** |

## Features

### SQLite Extensions Enabled

- **FTS5**: Full-text search with BM25 ranking, Boolean queries, phrase matching
- **JSON**: JSON functions (`json_extract`, `json_set`, `json_array`, etc.), built into the engine
- **RTREE**: Spatial indexing for geographic/geometric data
- **GEOPOLY**: Geographic polygon queries and operations
- **Math Functions**: `sin`, `cos`, `tan`, `log`, `exp`, `sqrt`, etc. (effective since 1.1.0)
- **Column Metadata**: Enhanced schema introspection

### Technical Specifications

- **SQLite Version**: 3.53.4 (2026-07-24, source id `2026-07-24 19:02:57 bf7c7f30...`)
- **Amalgamation SHA3-256** (`sqlite-amalgamation-3530400.zip`, as published on sqlite.org):
  `628a44cfe82c66aed1ccbbe85a562d2e33ebe64b3288981ed76285612227934e`
- **Architecture**: x64 native (64-bit Windows)
- **Runtime**: Static linking (/MT) - no DLL dependencies
- **Thread Safety**: SQLITE_THREADSAFE=1
- **Long calls are `blocking` externals**: `sqlite3_open_v2`, `sqlite3_prepare_v2`, `sqlite3_step`,
  `sqlite3_close`, `sqlite3_close_v2` and `sqlite3_backup_step` let the Eiffel garbage collector run in other
  SCOOP processors while SQLite works, so a long query no longer stalls the whole program.
- **Compatibility**: EiffelStudio 25.02+, Gobo Eiffel (gobo-25.09+)

For complete compile flag documentation, see [COMPILE_FLAGS.md](COMPILE_FLAGS.md).

### URI file names (read-only attach)

Connections are opened with `SQLITE_OPEN_URI` (since 1.1.0). A name beginning with `file:` is a URI, so

```sql
ATTACH DATABASE 'file:other.db?mode=ro' AS other;
```

attaches `other.db` **read-only**, and fails if `other.db` does not exist. Before 1.1.0 the same statement
silently created a writable file literally named `file:other.db?mode=ro`. Percent-encode `?`, `#` and `%` in
a URI's path. Plain names (not starting with `file:`) are unaffected, including names with `?` or `#`.

### Eiffel callbacks are refused (known gap)

`SQLITE_DATABASE.are_eiffel_callbacks_supported` is `False`. While the six externals above are `blocking`,
`esqlite.c` would call Eiffel code from inside them without re-entering the runtime, which crashes or fails
silently. So `set_commit_action`, `set_rollback_action`, `set_update_action`, `set_progress_handler` and
`set_busy_handler` refuse an attached routine: a precondition in contract-checked builds, and a
`DEVELOPER_EXCEPTION` raised by the body in every build. Passing `Void` (unset) is still accepted.
`set_busy_timeout` is unaffected: it uses SQLite's own C busy wait. Repairing the hooks is an open gap item.

---

## Integration with simple_sql

```
┌─────────────────────────────────────────────────────────────┐
│                      YOUR APPLICATION                        │
├─────────────────────────────────────────────────────────────┤
│                        simple_sql                            │
│  • Fluent query builders    • Repository pattern            │
│  • Schema migrations        • Audit/change tracking         │
│  • FTS5 full-text search    • JSON operations               │
│  • BLOB handling            • Result streaming              │
├─────────────────────────────────────────────────────────────┤
│                    eiffel_sqlite_2025                        │
│  • SQLite 3.53.4 C binding  • x64 native                    │
│  • FTS5, JSON, RTREE        • Static runtime                │
│  • Eiffel external API      • Gobo compatible               │
├─────────────────────────────────────────────────────────────┤
│                     SQLite 3.53.4                            │
│              (Public Domain, embedded)                       │
└─────────────────────────────────────────────────────────────┘
```

### Using with simple_sql

1. Clone both repositories into the folder named by `SIMPLE_EIFFEL`.
2. Build the C objects (see Build Instructions below).
3. Add simple_sql to your project; it references eiffel_sqlite_2025 through `$SIMPLE_EIFFEL`.

### Using Standalone

```xml
<library name="sqlite_2025" location="$SIMPLE_EIFFEL/eiffel_sqlite_2025/sqlite_2025.ecf"/>
```

---

## Build Instructions

### Prerequisites

- Visual Studio 2022 (or 2019+) with C++ Build Tools
- x64 Native Tools Command Prompt (or `vcvars64.bat`)

### Using the Makefile

```cmd
:: Open "x64 Native Tools Command Prompt for VS 2022"
cd %SIMPLE_EIFFEL%\eiffel_sqlite_2025\Clib
nmake /f Makefile sqlite3.obj esqlite.obj
```

The ECF links `Clib\sqlite3.obj` and `Clib\esqlite.obj`. The Makefile's flags are the library's flags:

```
/nologo /MT /O2 /W3 /EHsc /DSQLITE_THREADSAFE=1 /DSQLITE_ENABLE_FTS5 /DSQLITE_ENABLE_JSON1
/DSQLITE_ENABLE_RTREE /DSQLITE_ENABLE_GEOPOLY /DSQLITE_ENABLE_MATH_FUNCTIONS /DSQLITE_OMIT_LOAD_EXTENSION
/DSQLITE_ENABLE_COLUMN_METADATA
```

Do **not** add `/DEIF_THREADS`: it is inert for the stock `esqlite.c`, and code that relies on it breaks every
non-concurrent link. **Do not use `/MD`** (dynamic runtime): it causes linker errors with Eiffel projects.

### Upgrade procedure (new SQLite release)

1. Download `sqlite-amalgamation-NNNNNNN.zip` from sqlite.org and **verify its SHA3-256** against the hash
   that sqlite.org publishes on its download page.
2. Copy `sqlite3.c`, `sqlite3.h` and `sqlite3ext.h` into `Clib\`.
3. Rebuild `Clib\sqlite3.obj` and `Clib\esqlite.obj` with the **unchanged** Makefile flags.
4. Run this library's tests (`ec.sh test -config sqlite_2025.ecf -target sqlite_2025_test`, then
   `EIFGENs/sqlite_2025_test/F_code/sqlite_2025.exe`); update `test_linked_engine_version`.
5. Rebuild **every** dependent with `-clean` (delete its EIFGENs). An incremental build keeps the old
   generated C, which drops the `blocking` markers while still exiting 0.
6. In each rebuilt dependent, check that the generated C wraps the library's `sqlite3_step` call in
   `EIF_ENTER_C` / `EIF_EXIT_C`. A version test cannot see this failure.

---

## Behavior changes from 3.31.1 to 3.53.4

Read these before upgrading a client (details in [CHANGELOG.md](CHANGELOG.md)):

- **REAL to text uses up to 17 significant digits** (vendor default since 3.52/3.53): values whose 15-digit
  text does not round-trip now render longer, for example `CAST(0.1 + 0.2 AS TEXT)` gives
  `0.30000000000000004` (was `0.3`). `0.1` stays `0.1`. This affects `CAST(... AS TEXT)`, `||`,
  `json_object`/`json` output and `quote()`. `SQLITE_DBCONFIG_FP_DIGITS` could restore 15 digits for the
  `CAST`/`||` paths only, not for JSON or `quote()`; the library does not set it. REALs read back as
  `REAL_64` are unaffected.
- **Five vendor defaults changed:** `MAX_VARIABLE_NUMBER` 999 to 32766, `MAX_FUNCTION_ARG` 127 to 1000,
  `MAX_PAGE_COUNT` 1073741823 to 0xfffffffe, `DIRECT_OVERFLOW_READ` on, `SQLITE_USE_SEH` on under MSVC.
- **Reading the rowid of a VIEW or subquery is an error** (since 3.36.0).
- **Math functions are real** (`sqrt(16.0)` gives `4.0`).
- **`ENABLE_JSON1` no longer appears in `PRAGMA compile_options`**, although every JSON function works.
- **Eiffel hooks are refused** (see above).
- `SQLITE_MAX_ATTACHED` is still 10.

---

## Testing

```bash
/d/prod/ec.sh test -config sqlite_2025.ecf -target sqlite_2025_test
./EIFGENs/sqlite_2025_test/F_code/sqlite_2025.exe
```

The `sqlite_2025_test` target roots at `TEST_APP` (`tests/test_app.e`), which runs every test in
`tests/test_sqlite_library.e` with contracts on. Before 1.1.0 the target rooted at `ANY.default_create`
and ran nothing. simple_sql's own suites exercise this library further.

---

## Directory Structure

```
eiffel_sqlite_2025/
├── Clib/                    C source and build files
│   ├── sqlite3.c            SQLite 3.53.4 amalgamation
│   ├── sqlite3.h            SQLite public header
│   ├── sqlite3ext.h         SQLite extension header
│   ├── esqlite.c            Eiffel-to-C callback glue
│   ├── esqlite.h            Glue header (with EIF_NATURAL compatibility)
│   └── Makefile             nmake build file (the authoritative flags)
├── binding/                 Bind-argument classes
├── internals/               External "C" feature bindings (sqlite_externals.e, ...)
├── support/                 Binding helpers
├── tests/                   TEST_APP runner and TEST_SQLITE_LIBRARY
├── sqlite_*.e               Database, statement, result and source classes
├── sqlite_2025.ecf          ECF library configuration
├── README.md                This file
├── CHANGELOG.md             Version history
├── COMPILE_FLAGS.md         SQLite compile flag documentation
└── LICENSE                  MIT License (see License below for the mixed state)
```

---

## Compatibility

| Component | Version |
|-----------|---------|
| SQLite | 3.53.4 |
| Visual Studio | 2022 |
| Windows | 10/11 x64 |
| EiffelStudio | 25.02 Standard |
| Gobo Eiffel | gobo-25.09 |

### Gobo Eiffel Notes

The `esqlite.h` header includes an `EIF_NATURAL` compatibility macro:

```c
#ifndef EIF_NATURAL
#define EIF_NATURAL EIF_NATURAL_32
#endif
```

---

## License

**The licensing is mixed, and this section says so plainly.** The top-level [LICENSE](LICENSE) file is the
MIT License. However, this library is derived from Eiffel Software's SQLite library, and **39 of the 42
Eiffel source files** still carry Eiffel Software's notice "GPL version 2 (see
http://www.eiffel.com/licensing/gpl.txt)" in their `note` clause. The three that do not are
`internals/sqlite_backup_externals.e`, `tests/test_sqlite_library.e` and `tests/test_app.e`. The MIT file does
not relicense the GPL-2 files. No license was changed in 1.1.0; anyone redistributing this library should
treat those 39 files as GPL-2 and consult Eiffel Software's licensing options
(http://www.eiffel.com/licensing).

SQLite itself is in the **Public Domain**.

---

## Contributing

1. Do **not** commit `.obj` files or compiled libraries (in `.gitignore`)
2. Update README.md and CHANGELOG.md for significant changes
3. Follow the upgrade procedure above for any engine change
4. Run this library's tests and simple_sql's suites; rebuild dependents with `-clean`
5. Update COMPILE_FLAGS.md if modifying SQLite compilation flags
