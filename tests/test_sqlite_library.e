note
	description: "Test eiffel_sqlite_2025 library basic operations"
	testing: "type/manual"

class
	TEST_SQLITE_LIBRARY

inherit
	TEST_SET_BASE
		redefine
			on_prepare
		end

	SQLITE_SHARED_API
		undefine
			default_create
		end

feature {NONE} -- Events

	on_prepare
			-- <Precursor>
		do
			Precursor
		end

feature -- Test routines

	test_database_opens
			-- Test that in-memory database opens successfully
		note
			testing: "covers/{SQLITE_DATABASE}.make"
			testing: "covers/{SQLITE_DATABASE}.open_create_read_write"
		local
			l_db: SQLITE_DATABASE
		do
			create l_db.make (create {SQLITE_IN_MEMORY_SOURCE})
			l_db.open_create_read_write

			assert ("database_open", not l_db.is_closed)
			assert ("database_writable", l_db.is_writable)

			l_db.close
		end

	test_interface_usable_after_open
			-- Test that is_interface_usable returns True after opening database
		note
			testing: "covers/{SQLITE_DATABASE}.is_interface_usable"
		local
			l_db: SQLITE_DATABASE
		do
			create l_db.make (create {SQLITE_IN_MEMORY_SOURCE})
			l_db.open_create_read_write

			assert ("interface_usable", l_db.is_interface_usable)

			l_db.close
		end

	test_create_table
			-- Test CREATE TABLE statement execution
		note
			testing: "covers/{SQLITE_MODIFY_STATEMENT}.execute"
			testing: "execution/isolated"
		local
			l_db: SQLITE_DATABASE
			l_stmt: SQLITE_MODIFY_STATEMENT
		do
			create l_db.make (create {SQLITE_IN_MEMORY_SOURCE})
			l_db.open_create_read_write

			create l_stmt.make ("CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT);", l_db)
			l_stmt.execute

			assert ("no_error_creating_table", not l_db.has_error)
			assert ("interface_still_usable", l_db.is_interface_usable)

			l_db.close
		end

	test_create_trigger
			-- Test CREATE TRIGGER statement execution
			-- This is the critical test to verify triggers work
		note
			testing: "covers/{SQLITE_MODIFY_STATEMENT}.execute"
			testing: "execution/isolated"
		local
			l_db: SQLITE_DATABASE
			l_stmt: SQLITE_MODIFY_STATEMENT
		do
			create l_db.make (create {SQLITE_IN_MEMORY_SOURCE})
			l_db.open_create_read_write

			-- First create the table
			create l_stmt.make ("CREATE TABLE test (id INTEGER PRIMARY KEY, name TEXT);", l_db)
			l_stmt.execute
			assert ("table_created", not l_db.has_error)

			-- Check interface is still usable before trigger
			assert ("interface_usable_before_trigger", l_db.is_interface_usable)

			-- Now create the trigger
			create l_stmt.make ("CREATE TRIGGER test_trigger AFTER INSERT ON test BEGIN INSERT INTO test (name) VALUES ('triggered'); END;", l_db)
			l_stmt.execute

			-- These assertions will reveal the issue
			assert ("no_error_creating_trigger", not l_db.has_error)
			assert ("interface_usable_after_trigger", l_db.is_interface_usable)

			l_db.close
		end

	test_create_trigger_with_json
			-- Test CREATE TRIGGER with json_object (like audit triggers use)
		note
			testing: "covers/{SQLITE_MODIFY_STATEMENT}.execute"
			testing: "execution/isolated"
		local
			l_db: SQLITE_DATABASE
			l_stmt: SQLITE_MODIFY_STATEMENT
		do
			create l_db.make (create {SQLITE_IN_MEMORY_SOURCE})
			l_db.open_create_read_write

			-- Create source table
			create l_stmt.make ("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT, age INTEGER);", l_db)
			l_stmt.execute
			assert ("users_table_created", not l_db.has_error)

			-- Create audit table
			create l_stmt.make ("CREATE TABLE users_audit (audit_id INTEGER PRIMARY KEY, operation TEXT, new_values TEXT);", l_db)
			l_stmt.execute
			assert ("audit_table_created", not l_db.has_error)

			-- Create trigger with json_object (exactly like simple_sql_audit does)
			create l_stmt.make (
				"CREATE TRIGGER users_audit_insert AFTER INSERT ON users FOR EACH ROW BEGIN " +
				"INSERT INTO users_audit (operation, new_values) VALUES ('INSERT', json_object('id', NEW.id, 'name', NEW.name, 'age', NEW.age)); END;",
				l_db
			)
			l_stmt.execute

			-- The critical assertions
			assert ("no_error_creating_json_trigger", not l_db.has_error)
			assert ("interface_usable_after_json_trigger", l_db.is_interface_usable)

			l_db.close
		end


feature -- Test routines: engine (3.53.4 upgrade)

	test_linked_engine_version
			-- The linked engine is 3.53.4, as the header, the object and the runtime all report.
		note
			testing: "covers/{SQLITE_API}.version"
		local
			l_db: SQLITE_DATABASE
		do
			assert_strings_equal ("api_version", "3.53.4", sqlite_api.version)
			assert_true ("version_number", sqlite_api.version_number = 3053004)
			create l_db.make (create {SQLITE_IN_MEMORY_SOURCE})
			l_db.open_create_read_write
			assert_strings_equal ("sql_version", "3.53.4", scalar_text (l_db, "SELECT sqlite_version();"))
			l_db.close
		end

	test_real_text_has_17_digits
			-- Documented behavior change: REAL to TEXT renders 17 significant digits since 3.48.
		local
			l_db: SQLITE_DATABASE
		do
			create l_db.make (create {SQLITE_IN_MEMORY_SOURCE})
			l_db.open_create_read_write
			assert_strings_equal ("sum_text", "0.30000000000000004", scalar_text (l_db, "SELECT CAST(0.1 + 0.2 AS TEXT);"))
			assert_strings_equal ("round_trip_kept", "0.1", scalar_text (l_db, "SELECT CAST(0.1 AS TEXT);"))
			l_db.close
		end

	test_math_functions_available
			-- SQLITE_ENABLE_MATH_FUNCTIONS is now effective (3.31.1 had no math functions).
		local
			l_db: SQLITE_DATABASE
		do
			create l_db.make (create {SQLITE_IN_MEMORY_SOURCE})
			l_db.open_create_read_write
			assert_strings_equal ("sqrt", "4.0", scalar_text (l_db, "SELECT sqrt(16.0);"))
			l_db.close
		end

	test_json_still_available
			-- JSON is built in since 3.38; ENABLE_JSON1 is no longer needed.
		local
			l_db: SQLITE_DATABASE
		do
			create l_db.make (create {SQLITE_IN_MEMORY_SOURCE})
			l_db.open_create_read_write
			assert_strings_equal ("json", "{%"a%":1}", scalar_text (l_db, "SELECT json_object('a', 1);"))
			assert_strings_equal ("fts5", "1", scalar_text (l_db, "SELECT sqlite_compileoption_used('ENABLE_FTS5');"))
			l_db.close
		end

feature -- Test routines: callback guard

	test_callbacks_reported_unsupported
			-- The guard constant reports that Eiffel callbacks may not be installed.
		local
			l_db: SQLITE_DATABASE
		do
			create l_db.make (create {SQLITE_IN_MEMORY_SOURCE})
			assert_false ("unsupported", l_db.are_eiffel_callbacks_supported)
		end

	test_callback_setters_refuse_eiffel_routines
			-- Each of the five setters refuses an attached routine and installs nothing.
		local
			l_db: SQLITE_DATABASE
		do
			create l_db.make (create {SQLITE_IN_MEMORY_SOURCE})
			l_db.open_create_read_write
			assert_true ("commit_refused", is_refused (agent l_db.set_commit_action (agent: BOOLEAN do end)))
			assert_void ("commit_not_set", l_db.commit_action)
			assert_true ("rollback_refused", is_refused (agent l_db.set_rollback_action (agent do end)))
			assert_void ("rollback_not_set", l_db.rollback_action)
			assert_true ("update_refused", is_refused (agent l_db.set_update_action (agent (a: INTEGER; d, t: STRING; r: INTEGER_64) do end)))
			assert_void ("update_not_set", l_db.update_action)
			assert_true ("progress_refused", is_refused (agent l_db.set_progress_handler (agent: BOOLEAN do end)))
			assert_void ("progress_not_set", l_db.progress_handler)
			assert_true ("busy_refused", is_refused (agent l_db.set_busy_handler (agent (c: NATURAL): BOOLEAN do end)))
			assert_void ("busy_not_set", l_db.busy_handler)
			l_db.close
		end

	test_callback_setters_accept_void
			-- Void (unset) stays accepted, and the C busy timeout is untouched by the guard.
		local
			l_db: SQLITE_DATABASE
		do
			create l_db.make (create {SQLITE_IN_MEMORY_SOURCE})
			l_db.open_create_read_write
			l_db.set_commit_action (Void)
			l_db.set_rollback_action (Void)
			l_db.set_update_action (Void)
			l_db.set_progress_handler (Void)
			l_db.set_busy_handler (Void)
			assert_void ("no_commit_action", l_db.commit_action)
			l_db.set_busy_timeout (250)
			assert_true ("busy_timeout_set", l_db.busy_timeout = 250)
			l_db.close
		end

feature -- Test routines: URI file names (D7)

	test_attach_uri_read_only_refuses_writes
			-- ATTACH 'file:...?mode=ro' attaches read-only: reads work, a write fails.
		local
			l_db: SQLITE_DATABASE
		do
			make_fixture ("uri_ro_fixture.db")
			create l_db.make (create {SQLITE_IN_MEMORY_SOURCE})
			l_db.open_create_read_write
			assert_true ("attach_ok", run_modify (l_db, "ATTACH DATABASE 'file:uri_ro_fixture.db?mode=ro' AS ro;"))
			assert_strings_equal ("read_ok", "1", scalar_text (l_db, "SELECT count(*) FROM ro.t;"))
			assert_false ("insert_refused", run_modify (l_db, "INSERT INTO ro.t (id) VALUES (2);"))
			assert_false ("create_refused", run_modify (l_db, "CREATE TABLE ro.t2 (x INTEGER);"))
			assert_true ("detach_ok", run_modify (l_db, "DETACH DATABASE ro;"))
			l_db.close
			assert_false ("no_alternate_stream_file", file_exists ("file:uri_ro_fixture.db?mode=ro"))
			delete_file ("uri_ro_fixture.db")
		end

	test_attach_uri_read_only_missing_file_errors
			-- A missing file attached with mode=ro is an error, and no file is created.
		local
			l_db: SQLITE_DATABASE
		do
			delete_file ("uri_ro_missing.db")
			create l_db.make (create {SQLITE_IN_MEMORY_SOURCE})
			l_db.open_create_read_write
			assert_false ("attach_fails", run_modify (l_db, "ATTACH DATABASE 'file:uri_ro_missing.db?mode=ro' AS ro;"))
			l_db.close
			assert_false ("not_created", file_exists ("uri_ro_missing.db"))
		end

	test_plain_path_with_hash_unchanged
			-- A plain (non-URI) file name containing '#' still opens the file of exactly that name.
		local
			l_db: SQLITE_DATABASE
		do
			delete_file ("plain#name.db")
			create l_db.make_create_read_write ("plain#name.db")
			assert_true ("created_table", run_modify (l_db, "CREATE TABLE t (id INTEGER);"))
			l_db.close
			assert_true ("file_has_exact_name", file_exists ("plain#name.db"))
			delete_file ("plain#name.db")
		end

	test_main_database_by_uri_read_only
			-- A main database opened by a "file:" URI with mode=ro is read-only.
		local
			l_db: SQLITE_DATABASE
		do
			make_fixture ("uri_main_fixture.db")
			create l_db.make (create {SQLITE_FILE_SOURCE}.make ("file:uri_main_fixture.db?mode=ro"))
			l_db.open_create_read_write
			assert_strings_equal ("read_ok", "1", scalar_text (l_db, "SELECT count(*) FROM t;"))
			assert_false ("insert_refused", run_modify (l_db, "INSERT INTO t (id) VALUES (2);"))
			l_db.close
			delete_file ("uri_main_fixture.db")
		end

feature -- Test routines: transaction state (F-9 e)

	test_commit_failure_keeps_transaction_open
			-- A COMMIT that fails (deferred foreign key violation) leaves the transaction open and says so.
		local
			l_db: SQLITE_DATABASE
		do
			create l_db.make (create {SQLITE_IN_MEMORY_SOURCE})
			l_db.open_create_read_write
			assert_true ("fk_on", run_modify (l_db, "PRAGMA foreign_keys = ON;"))
			assert_true ("parent", run_modify (l_db, "CREATE TABLE p (id INTEGER PRIMARY KEY);"))
			assert_true ("child", run_modify (l_db, "CREATE TABLE c (pid INTEGER REFERENCES p (id) DEFERRABLE INITIALLY DEFERRED);"))
			l_db.begin_transaction (True)
			assert_true ("in_transaction", l_db.is_in_transaction)
			assert_true ("orphan_inserted", run_modify (l_db, "INSERT INTO c (pid) VALUES (42);"))
			l_db.commit
			assert_true ("commit_failed_reported", l_db.has_error)
			assert_true ("still_in_transaction", l_db.is_in_transaction)
			assert_false ("engine_agrees", l_db.is_autocommit)
			l_db.rollback
			assert_false ("rolled_back", l_db.is_in_transaction)
			assert_true ("engine_autocommit", l_db.is_autocommit)
			assert_strings_equal ("no_orphan_kept", "0", scalar_text (l_db, "SELECT count(*) FROM c;"))
			l_db.close
		end

	test_commit_success_ends_transaction
			-- A successful COMMIT ends the transaction.
		local
			l_db: SQLITE_DATABASE
		do
			create l_db.make (create {SQLITE_IN_MEMORY_SOURCE})
			l_db.open_create_read_write
			assert_true ("table", run_modify (l_db, "CREATE TABLE t (id INTEGER);"))
			l_db.begin_transaction (True)
			assert_true ("insert", run_modify (l_db, "INSERT INTO t (id) VALUES (1);"))
			l_db.commit
			assert_false ("no_error", l_db.has_error)
			assert_false ("not_in_transaction", l_db.is_in_transaction)
			assert_strings_equal ("committed", "1", scalar_text (l_db, "SELECT count(*) FROM t;"))
			l_db.close
		end

	test_begin_failure_leaves_no_transaction
			-- BEGIN EXCLUSIVE refused (another connection holds the lock) does not claim a transaction.
		local
			l_a, l_b: SQLITE_DATABASE
		do
			make_fixture ("busy_fixture.db")
			create l_a.make_open_read_write ("busy_fixture.db")
			create l_b.make_open_read_write ("busy_fixture.db")
			l_a.begin_transaction (False)
			assert_true ("a_holds_exclusive", l_a.is_in_transaction)
			l_b.begin_transaction (False)
			assert_true ("b_busy_reported", l_b.has_error)
			assert_false ("b_not_in_transaction", l_b.is_in_transaction)
			l_a.rollback
			l_b.close
			l_a.close
			delete_file ("busy_fixture.db")
		end

feature {NONE} -- Helpers

	make_fixture (a_name: STRING)
			-- Create database file `a_name' holding table t with one row.
		local
			l_db: SQLITE_DATABASE
		do
			delete_file (a_name)
			create l_db.make_create_read_write (a_name)
			assert_true ("fixture_table", run_modify (l_db, "CREATE TABLE t (id INTEGER PRIMARY KEY);"))
			assert_true ("fixture_row", run_modify (l_db, "INSERT INTO t (id) VALUES (1);"))
			l_db.close
		end

	run_modify (a_db: SQLITE_DATABASE; a_sql: STRING): BOOLEAN
			-- Compile and execute `a_sql'; did it succeed?
		local
			l_stmt: SQLITE_MODIFY_STATEMENT
		do
			create l_stmt.make (a_sql, a_db)
			if l_stmt.is_compiled then
				l_stmt.execute
				Result := not l_stmt.has_error
			end
			l_stmt.cleanup
		end

	file_exists (a_name: STRING): BOOLEAN
			-- Does file `a_name' exist in the current folder?
		do
			Result := (create {RAW_FILE}.make_with_name (a_name)).exists
		end

	delete_file (a_name: STRING)
			-- Delete file `a_name' if it exists.
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_name (a_name)
			if l_file.exists then
				l_file.delete
			end
		end

	is_refused (a_setter: PROCEDURE): BOOLEAN
			-- Does calling `a_setter' raise (precondition or the guard's DEVELOPER_EXCEPTION)?
		local
			l_raised: BOOLEAN
		do
			if not l_raised then
				a_setter.call (Void)
			end
			Result := l_raised
		rescue
			l_raised := True
			retry
		end

	scalar_text (a_db: SQLITE_DATABASE; a_sql: STRING): STRING
			-- First column of the first row of `a_sql', as text ("" when NULL or no row).
		local
			l_query: SQLITE_QUERY_STATEMENT
			l_text: STRING
		do
			create l_text.make_empty
			create l_query.make (a_sql, a_db)
			assert_true ("compiled: " + a_sql, l_query.is_compiled)
			l_query.execute (agent (a_row: SQLITE_RESULT_ROW; a_into: STRING): BOOLEAN
				do
					if a_into.is_empty and then not a_row.is_null (1) then
						a_into.append (a_row.string_value (1))
					end
					Result := True
				end (?, l_text))
			l_query.cleanup
			Result := l_text
		end

end
