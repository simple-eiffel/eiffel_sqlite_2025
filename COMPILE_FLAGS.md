# SQLite Compile Flags

This document explains the SQLite compile-time options used in this project.

## Enabled Features

### SQLITE_THREADSAFE=1
Enables full thread-safety with serialized mode as default. SQLite will be safe to use in multi-threaded applications.

**Documentation**: https://www.sqlite.org/threadsafe.html

### SQLITE_ENABLE_FTS5
Enables the FTS5 full-text search extension. FTS5 is the latest and most advanced full-text search module in SQLite, featuring:
- BM25 ranking algorithm
- Phrase queries
- NEAR queries
- Boolean operators (AND, OR, NOT)
- Column filters
- Custom tokenizers

**Documentation**: https://www.sqlite.org/fts5.html

### SQLITE_ENABLE_JSON1
Since SQLite 3.38.0 the JSON functions are built in and this flag has no effect; it is kept so the flags stay
unchanged. `PRAGMA compile_options` no longer lists it on 3.53.4, but the functions work. They include:
- `json()` - Validate and minify JSON
- `json_array()` - Create JSON arrays
- `json_object()` - Create JSON objects
- `json_extract()` - Extract values from JSON
- `json_insert()`, `json_replace()`, `json_set()` - Modify JSON
- `json_each()`, `json_tree()` - Parse JSON into table format

**Documentation**: https://www.sqlite.org/json1.html

### SQLITE_ENABLE_RTREE
Enables the R*Tree index extension for efficient range queries on multi-dimensional data. Useful for:
- Geographic information systems (GIS)
- Bounding box queries
- Spatial indexing
- Game development (collision detection)

**Documentation**: https://www.sqlite.org/rtree.html

### SQLITE_ENABLE_GEOPOLY
Enables the Geopoly extension for geographic polygon queries. Extends R-Tree with:
- Geographic polygon storage
- Point-in-polygon tests
- Polygon overlap detection
- Area calculations

**Documentation**: https://www.sqlite.org/geopoly.html

### SQLITE_ENABLE_MATH_FUNCTIONS
Enables additional mathematical functions. **Effective only since library 1.1.0:** the flag was passed before,
but SQLite 3.31.1 ignored it (math functions arrived in 3.35.0). Functions:
- Trigonometric: `acos()`, `asin()`, `atan()`, `atan2()`, `cos()`, `sin()`, `tan()`
- Logarithmic: `log()`, `log10()`, `log2()`, `exp()`
- Power: `pow()`, `sqrt()`
- Rounding: `ceil()`, `floor()`, `trunc()`
- Other: `degrees()`, `radians()`, `pi()`

**Documentation**: https://www.sqlite.org/lang_mathfunc.html

### SQLITE_ENABLE_COLUMN_METADATA
Enables functions to retrieve metadata about table columns:
- `sqlite3_column_database_name()`
- `sqlite3_column_table_name()`
- `sqlite3_column_origin_name()`

Useful for introspection and building dynamic database tools.

**Documentation**: https://www.sqlite.org/c3ref/column_database_name.html

## Security Features

### SQLITE_OMIT_LOAD_EXTENSION
Disables the ability to load external shared libraries at runtime. This prevents:
- Loading potentially malicious extensions
- Security vulnerabilities from dynamic code loading
- Ensures the SQLite build is self-contained

**Why enabled**: Security best practice, especially for embedded/library use.

**Documentation**: https://www.sqlite.org/loadext.html

## Vendor defaults that changed with 3.53.4 (not pinned)

Library 1.1.0 moved from SQLite 3.31.1 to 3.53.4 with the flags above unchanged. Five defaults that the
flags do not set changed in effect. They are accepted as the vendor ships them; none removes a capability.

| Default | 3.31.1 | 3.53.4 | Since |
|---------|--------|--------|-------|
| `SQLITE_MAX_VARIABLE_NUMBER` | 999 | 32766 | 3.32.0 |
| `SQLITE_MAX_FUNCTION_ARG` | 127 | 1000 | 3.48.0 |
| `SQLITE_MAX_PAGE_COUNT` | 1073741823 | 0xfffffffe | 3.45.0 |
| `SQLITE_DIRECT_OVERFLOW_READ` | off | on | 3.45.0 |
| `SQLITE_USE_SEH` (MSVC) | absent | on | 3.44.0 |

`SQLITE_USE_SEH`'s exception filter handles only in-page errors inside WAL `-shm` code and passes every other
exception on, so it does not interfere with the Eiffel runtime. To pin any of these, add the `/D` flag to
`SQLITE_FLAGS` in `Clib/Makefile` and record the change here. `SQLITE_MAX_ATTACHED` is 10 on both versions.

`PRAGMA compile_options` on 3.53.4 also lists about 35 default and limit rows that 3.31.1 did not list: in
3.53.4 the option table is compiled after the default definitions, so defaults are reported too.

## Not used: EIF_THREADS

Do not add `/DEIF_THREADS` to the `esqlite.c` build. It is inert for the stock `esqlite.c`, and re-entry code
that depends on it breaks every non-concurrent (`concurrency use="none"`) link.

## Modifying Compile Flags

To add or remove features, edit the `SQLITE_FLAGS` section in `Clib/Makefile`:

```makefile
SQLITE_FLAGS = /DSQLITE_THREADSAFE=1 \
               /DSQLITE_ENABLE_FTS5 \
               /DSQLITE_ENABLE_JSON1 \
               # Add your flags here
```

After modifying flags, rebuild:

```cmd
cd Clib
nmake /f Makefile clean
nmake /f Makefile
```

## Additional Resources

- [SQLite Compile-Time Options](https://www.sqlite.org/compile.html) - Complete list of all available options
- [SQLite Recommended Compile-Time Options](https://www.sqlite.org/compile.html#recommended_compile_time_options)
- [SQLite Extensions](https://www.sqlite.org/loadext.html) - Available extensions and their features
