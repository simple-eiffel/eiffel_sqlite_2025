<p align="center">
  <img src="https://raw.githubusercontent.com/ljr1981/claude_eiffel_op_docs/main/artwork/LOGO-3.png" alt="simple_ library logo" width="400">
</p>

# Eiffel SQLite 2025

**Modern SQLite 3.51.1 wrapper for Eiffel with FTS5, JSON1, and advanced features.**

A production-ready SQLite binding for Eiffel applications, designed to work seamlessly with the [simple_sql](https://github.com/ljr1981/simple_sql) high-level API library.

## Why This Library?

The standard Eiffel SQLite library uses SQLite 3.31.1 (x86) with limited features. This library provides:

| Feature | Standard Library | eiffel_sqlite_2025 |
|---------|-----------------|-------------------|
| SQLite Version | 3.31.1 | **3.51.1** |
| Architecture | x86 (32-bit) | **x64 (64-bit)** |
| FTS5 Full-Text Search | No | **Yes** |
| JSON1 Extension | No | **Yes** |
| RTREE Spatial Index | No | **Yes** |
| GEOPOLY | No | **Yes** |
| Math Functions | No | **Yes** |
| Runtime Linking | /MD (dynamic) | **/MT (static)** |

## Features

### SQLite Extensions Enabled

- **FTS5**: Full-text search with BM25 ranking, Boolean queries, phrase matching
- **JSON1**: JSON functions (`json_extract`, `json_set`, `json_array`, etc.)
- **RTREE**: Spatial indexing for geographic/geometric data
- **GEOPOLY**: Geographic polygon queries and operations
- **Math Functions**: `sin`, `cos`, `tan`, `log`, `exp`, `sqrt`, etc.
- **Column Metadata**: Enhanced schema introspection

### Technical Specifications

- **SQLite Version**: 3.51.1 (November 2025)
- **Architecture**: x64 native (64-bit Windows)
- **Runtime**: Static linking (/MT) - no DLL dependencies
- **Thread Safety**: SQLITE_THREADSAFE=1
- **Compatibility**: EiffelStudio 25.02+, Gobo Eiffel (gobo-25.09+)

For complete compile flag documentation, see [COMPILE_FLAGS.md](COMPILE_FLAGS.md).

---

## Integration with simple_sql

This library serves as the foundation for [simple_sql](https://github.com/ljr1981/simple_sql), a high-level SQLite API for Eiffel. Together they provide:

```
┌─────────────────────────────────────────────────────────────┐
│                      YOUR APPLICATION                        │
├─────────────────────────────────────────────────────────────┤
│                        simple_sql                            │
│  • Fluent query builders    • Repository pattern            │
│  • Schema migrations        • Audit/change tracking         │
│  • FTS5 full-text search    • JSON1 operations              │
│  • BLOB handling            • Result streaming              │
│  • 250 tests, 100% coverage                                 │
├─────────────────────────────────────────────────────────────┤
│                    eiffel_sqlite_2025                        │
│  • SQLite 3.51.1 C binding  • x64 native                    │
│  • FTS5, JSON1, RTREE       • Static runtime                │
│  • Eiffel external API      • Gobo compatible               │
├─────────────────────────────────────────────────────────────┤
│                     SQLite 3.51.1                            │
│              (Public Domain, embedded)                       │
└─────────────────────────────────────────────────────────────┘
```

### Using with simple_sql

1. Clone both repositories:
   ```cmd
   git clone https://github.com/ljr1981/eiffel_sqlite_2025.git
   git clone https://github.com/ljr1981/simple_sql.git
   ```

2. Set environment variable (adjust path to your clone location):
   ```cmd
   set EIFFEL_SQLITE_2025=C:\path\to\eiffel_sqlite_2025
   ```

3. Build the C library (see Build Instructions below)

4. Add simple_sql to your project - it automatically references eiffel_sqlite_2025

### Using Standalone

If you only need the low-level SQLite binding:

```xml
<library name="sqlite_2025" location="$EIFFEL_SQLITE_2025\sqlite_2025.ecf"/>
```

---

## Build Instructions

### Prerequisites

- Visual Studio 2022 (or 2019+) with C++ Build Tools
- x64 Native Tools Command Prompt
- Environment variable: `EIFFEL_SQLITE_2025` pointing to your clone location

### Option 1: Using Makefile (Recommended)

For EiffelStudio users:

```cmd
:: Open "x64 Native Tools Command Prompt for VS 2022"
set EIFFEL_SQLITE_2025=C:\path\to\eiffel_sqlite_2025
cd %EIFFEL_SQLITE_2025%\Clib
nmake /f Makefile
```

Output: `spec\msvc\win64\lib\sqlite_2025.lib`

### Option 2: Manual Build

For Gobo Eiffel or custom configurations:

```cmd
:: Open "x64 Native Tools Command Prompt for VS 2022"
cd %EIFFEL_SQLITE_2025%\Clib

:: Compile SQLite with all extensions
cl /c /O2 /MT ^
   /DSQLITE_ENABLE_FTS5 ^
   /DSQLITE_ENABLE_JSON1 ^
   /DSQLITE_ENABLE_RTREE ^
   /DSQLITE_ENABLE_GEOPOLY ^
   /DSQLITE_ENABLE_MATH_FUNCTIONS ^
   /DSQLITE_ENABLE_COLUMN_METADATA ^
   /DSQLITE_THREADSAFE=1 ^
   sqlite3.c

:: Compile Eiffel wrapper (adjust include path)
:: For EiffelStudio:
cl /c /O2 /MT /I"%ISE_EIFFEL%\studio\spec\win64\include" /I. esqlite.c

:: For Gobo Eiffel:
cl /c /O2 /MT /I"D:\prod\gobo-gobo-25.09\tool\gec\backend\c\runtime" /I. esqlite.c

:: Create library
lib /OUT:sqlite_2025.lib sqlite3.obj esqlite.obj
```

### Build Notes

| Flag | Purpose |
|------|---------|
| `/MT` | Static runtime linking (required for Eiffel compatibility) |
| `/O2` | Optimization level 2 |
| `SQLITE_ENABLE_FTS5` | Full-text search |
| `SQLITE_THREADSAFE=1` | Thread-safe mode |

**Important:** Do NOT use `/MD` (dynamic runtime) - it causes linker errors with Eiffel projects.

---

## Verification

After building, verify the extensions are enabled:

```eiffel
-- In your Eiffel code or via simple_sql:
result := db.query ("PRAGMA compile_options")
across result.rows as ic loop
    print (ic.string_value ("compile_option"))
end
```

Expected output should include:
- `ENABLE_FTS5`
- `ENABLE_JSON1`
- `ENABLE_RTREE`
- `THREADSAFE=1`

### Test with simple_sql

The simple_sql library includes 250 tests that exercise this library:

```cmd
cd D:\prod\simple_sql
:: Build and run tests in EiffelStudio
```

All 250 tests should pass.

---

## Directory Structure

```
eiffel_sqlite_2025/
├── Clib/                    C source and build files
│   ├── sqlite3.c            SQLite 3.51.1 amalgamation (~240,000 lines)
│   ├── sqlite3.h            SQLite public header
│   ├── esqlite.c            Eiffel-to-C wrapper implementation
│   ├── esqlite.h            Wrapper header (with EIF_NATURAL compatibility)
│   └── Makefile             nmake build file
├── binding/                 Eiffel external declarations
│   └── sqlite_externals.e   External "C" feature bindings
├── support/                 Eiffel helper classes
│   ├── sqlite_database.e    Database connection class
│   ├── sqlite_statement.e   Prepared statement class
│   └── ...                  Other support classes
├── spec/                    Compiled libraries (not in git)
│   └── msvc/win64/lib/      Output location for sqlite_2025.lib
├── sqlite_2025.ecf          ECF library configuration
├── README.md                This file
├── CHANGELOG.md             Version history
├── COMPILE_FLAGS.md         SQLite compile flag documentation
└── LICENSE                  MIT License
```

---

## Version History

### v1.0.0 (November 30, 2025)

- **New:** SQLite 3.51.1 (upgraded from 3.31.1)
- **New:** x64 architecture (upgraded from x86)
- **New:** FTS5, JSON1, RTREE, GEOPOLY, Math Functions enabled
- **New:** EIF_NATURAL compatibility for Gobo Eiffel
- **Fixed:** Static runtime linking (/MT) for Eiffel compatibility
- **Verified:** 250 tests passing with simple_sql

See [CHANGELOG.md](CHANGELOG.md) for full history.

---

## Compatibility

### Tested With

| Component | Version |
|-----------|---------|
| SQLite | 3.51.1 |
| Visual Studio | 2022 (MSVC 19.44) |
| Windows | 10/11 x64 |
| EiffelStudio | 25.02 Standard |
| Gobo Eiffel | gobo-25.09 |
| simple_sql | 0.8 (250 tests passing) |

### Gobo Eiffel Notes

The `esqlite.h` header includes an `EIF_NATURAL` compatibility macro:

```c
#ifndef EIF_NATURAL
#define EIF_NATURAL EIF_NATURAL_32
#endif
```

This ensures compatibility with both EiffelStudio and Gobo Eiffel runtimes.

---

## License

**MIT License** - see [LICENSE](LICENSE) file.

SQLite itself is in the **Public Domain**.

---

## Related Projects

- **[simple_sql](https://github.com/ljr1981/simple_sql)** - High-level SQLite API built on this library
  - Fluent query builders
  - Repository pattern
  - Schema migrations
  - FTS5 full-text search wrapper
  - JSON1 operations
  - Audit/change tracking
  - 250 tests, 100% coverage

---

## Contributing

1. Do **not** commit `.obj` files or compiled libraries (in `.gitignore`)
2. Update README.md and CHANGELOG.md for significant changes
3. Test with both EiffelStudio and Gobo Eiffel if possible
4. Run the full simple_sql test suite (250 tests should pass)
5. Update COMPILE_FLAGS.md if modifying SQLite compilation flags

---

## Support

For issues with:
- **This library (eiffel_sqlite_2025):** SQLite binding, C compilation, linking
- **simple_sql:** High-level API, query builders, migrations, FTS5 wrapper

Both projects developed with AI-assisted development using Claude (Anthropic).

---

**Built for the Eiffel ecosystem. Production-ready. Battle-tested with 250 tests.**
