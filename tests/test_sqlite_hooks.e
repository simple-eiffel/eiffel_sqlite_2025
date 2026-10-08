note
	description: "[
		Hook tests (D8 repair): each Eiffel callback fires with the right data, disabling one hook
		leaves the others working, and an exception in a callback does not corrupt the connection.
	]"
	testing: "type/manual"

class
	TEST_SQLITE_HOOKS

inherit
	TEST_SET_BASE

feature -- Test routines: firing

	test_callbacks_supported
			-- The guard is lifted.
		local
			l_db: SQLITE_DATABASE
		do
			create l_db.make (create {SQLITE_IN_MEMORY_SOURCE})
			assert_true ("supported", l_db.are_eiffel_callbacks_supported)
		end

	test_commit_hook_fires
			-- The commit action runs once per COMMIT; returning False lets it commit.
		local
			l_db: SQLITE_DATABASE
		do
			reset_counts
			l_db := fresh_db
			l_db.set_commit_action (agent on_commit_allow)
			l_db.begin_transaction (True)
			assert_true ("insert", run_modify (l_db, "INSERT INTO t (x) VALUES (1);"))
			l_db.commit
			assert_integers_equal ("one_commit_call", 1, commit_calls)
			assert_false ("committed", l_db.has_error)
			assert_integers_equal ("row_kept", 1, count_rows (l_db))
			l_db.set_commit_action (Void)
			l_db.close
		end

	test_commit_hook_can_abort
			-- A commit action returning True turns the COMMIT into a rollback, and the rollback hook fires.
		local
			l_db: SQLITE_DATABASE
		do
			reset_counts
			l_db := fresh_db
			l_db.set_commit_action (agent on_commit_refuse)
			l_db.set_rollback_action (agent on_rollback)
			l_db.begin_transaction (True)
			assert_true ("insert", run_modify (l_db, "INSERT INTO t (x) VALUES (1);"))
			l_db.commit
			assert_true ("commit_refused", l_db.has_error)
			assert_false ("transaction_ended", l_db.is_in_transaction)
			assert_integers_equal ("rollback_hook_fired", 1, rollback_calls)
			assert_integers_equal ("nothing_kept", 0, count_rows (l_db))
			l_db.set_commit_action (Void)
			l_db.set_rollback_action (Void)
			l_db.close
		end

	test_rollback_hook_fires
			-- The rollback action runs on ROLLBACK.
		local
			l_db: SQLITE_DATABASE
		do
			reset_counts
			l_db := fresh_db
			l_db.set_rollback_action (agent on_rollback)
			l_db.begin_transaction (True)
			assert_true ("insert", run_modify (l_db, "INSERT INTO t (x) VALUES (1);"))
			l_db.rollback
			assert_integers_equal ("one_rollback_call", 1, rollback_calls)
			l_db.set_rollback_action (Void)
			l_db.close
		end

	test_update_hook_data
			-- The update action receives the action code, database, table and rowid of every change.
		local
			l_db: SQLITE_DATABASE
			l_codes: SQLITE_UPDATE_ACTION
		do
			reset_counts
			create l_codes
			l_db := fresh_db
			l_db.set_update_action (agent on_update)
			assert_true ("insert", run_modify (l_db, "INSERT INTO t (id, x) VALUES (7, 1);"))
			assert_integers_equal ("insert_code", l_codes.insert, last_update_code)
			assert_strings_equal ("db_name", "main", last_update_db)
			assert_strings_equal ("table", "t", last_update_table)
			assert_true ("rowid", last_update_row = 7)
			assert_true ("update", run_modify (l_db, "UPDATE t SET x = 2 WHERE id = 7;"))
			assert_integers_equal ("update_code", l_codes.update, last_update_code)
			assert_true ("delete", run_modify (l_db, "DELETE FROM t WHERE id = 7;"))
			assert_integers_equal ("delete_code", l_codes.delete, last_update_code)
			assert_integers_equal ("three_calls", 3, update_calls)
			assert_true ("bulk", run_modify (l_db, "INSERT INTO t (x) WITH RECURSIVE c(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM c WHERE n < 500) SELECT n FROM c;"))
			assert_integers_equal ("one_call_per_row", 503, update_calls)
			l_db.set_update_action (Void)
			l_db.close
		end

	test_progress_handler_fires_and_interrupts
			-- The progress handler is called every `progress_handler_period' instructions with its own
			-- routine and data, and returning True interrupts the statement.
		local
			l_db: SQLITE_DATABASE
		do
			reset_counts
			l_db := fresh_db
			l_db.set_progress_handler_period (100)
			l_db.set_progress_handler (agent on_progress_continue)
			assert_strings_equal ("long_query", "200000", scalar_text (l_db, "WITH RECURSIVE c(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM c WHERE n < 200000) SELECT count(*) FROM c;"))
			assert_true ("called_many_times", progress_calls > 100)
			l_db.set_progress_handler (Void)
			reset_counts
			l_db.set_progress_handler (agent on_progress_stop)
			assert_false ("interrupted", run_modify (l_db, "INSERT INTO t (x) WITH RECURSIVE c(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM c WHERE n < 200000) SELECT n FROM c;"))
			assert_integers_equal ("stopped_at_first_call", 1, progress_calls)
			assert_integers_equal ("nothing_inserted", 0, count_rows (l_db))
			l_db.set_progress_handler (Void)
			l_db.close
		end

	test_busy_handler_fires
			-- The busy handler is called with 0, 1, 2 ... and returning False gives SQLITE_BUSY.
		local
			l_a, l_b: SQLITE_DATABASE
		do
			reset_counts
			make_file_db ("hooks_busy.db")
			create l_a.make_open_read_write ("hooks_busy.db")
			create l_b.make_open_read_write ("hooks_busy.db")
			l_a.begin_transaction (False)
			l_b.set_busy_handler (agent on_busy_three)
			assert_false ("busy_write_fails", run_modify (l_b, "INSERT INTO t (x) VALUES (1);"))
			assert_integers_equal ("four_calls", 4, busy_calls)
			assert_true ("counts_in_order", busy_counts.same_string ("0,1,2,3,"))
			l_a.rollback
			assert_true ("free_write_works", run_modify (l_b, "INSERT INTO t (x) VALUES (2);"))
			l_b.set_busy_handler (Void)
			l_b.close
			l_a.close
			delete_file ("hooks_busy.db")
		end

feature -- Test routines: disabling

	test_disabling_commit_keeps_others
			-- Removing the commit action leaves the update and rollback actions working (before 1.2.0,
			-- removing it removed the update hook).
		local
			l_db: SQLITE_DATABASE
		do
			reset_counts
			l_db := fresh_db
			install_all (l_db)
			l_db.set_commit_action (Void)
			l_db.begin_transaction (True)
			assert_true ("insert", run_modify (l_db, "INSERT INTO t (x) VALUES (1);"))
			l_db.commit
			assert_integers_equal ("no_commit_call", 0, commit_calls)
			assert_integers_equal ("update_still_fires", 1, update_calls)
			l_db.begin_transaction (True)
			assert_true ("bulk_insert", run_modify (l_db, "INSERT INTO t (x) WITH RECURSIVE c(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM c WHERE n < 2000) SELECT n FROM c;"))
			l_db.rollback
			assert_integers_equal ("rollback_still_fires", 1, rollback_calls)
			assert_true ("progress_still_fires", progress_calls > 0)
			remove_all (l_db)
			l_db.close
		end

	test_disabling_rollback_keeps_others
			-- Removing the rollback action leaves the update and commit actions working.
		local
			l_db: SQLITE_DATABASE
		do
			reset_counts
			l_db := fresh_db
			install_all (l_db)
			l_db.set_rollback_action (Void)
			l_db.begin_transaction (True)
			assert_true ("insert", run_modify (l_db, "INSERT INTO t (x) VALUES (1);"))
			l_db.rollback
			assert_integers_equal ("no_rollback_call", 0, rollback_calls)
			l_db.begin_transaction (True)
			assert_true ("insert2", run_modify (l_db, "INSERT INTO t (x) VALUES (2);"))
			l_db.commit
			assert_integers_equal ("update_still_fires", 2, update_calls)
			assert_integers_equal ("commit_still_fires", 1, commit_calls)
			remove_all (l_db)
			l_db.close
		end

	test_disabling_update_and_progress_keeps_others
			-- Removing the update action and the progress handler leaves commit and rollback working.
		local
			l_db: SQLITE_DATABASE
			l_progress_before: INTEGER
		do
			reset_counts
			l_db := fresh_db
			install_all (l_db)
			l_db.set_update_action (Void)
			l_db.set_progress_handler (Void)
			l_progress_before := progress_calls
			l_db.begin_transaction (True)
			assert_true ("insert", run_modify (l_db, "INSERT INTO t (x) WITH RECURSIVE c(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM c WHERE n < 5000) SELECT n FROM c;"))
			l_db.commit
			assert_integers_equal ("no_update_calls", 0, update_calls)
			assert_integers_equal ("no_progress_calls", l_progress_before, progress_calls)
			assert_integers_equal ("commit_still_fires", 1, commit_calls)
			l_db.begin_transaction (True)
			assert_true ("insert2", run_modify (l_db, "INSERT INTO t (x) VALUES (2);"))
			l_db.rollback
			assert_integers_equal ("rollback_still_fires", 1, rollback_calls)
			remove_all (l_db)
			l_db.close
		end

feature -- Test routines: exceptions in callbacks

	test_update_exception_contained
			-- An exception in the update action is caught; the statement and the connection go on.
		local
			l_db: SQLITE_DATABASE
		do
			reset_counts
			l_db := fresh_db
			l_db.set_update_action (agent on_update_raise)
			assert_true ("insert_completes", run_modify (l_db, "INSERT INTO t (x) VALUES (1);"))
			assert_attached ("exception_kept", l_db.last_callback_exception)
			l_db.set_update_action (Void)
			l_db.clear_last_callback_exception
			assert_true ("connection_works", run_modify (l_db, "INSERT INTO t (x) VALUES (2);"))
			assert_integers_equal ("both_rows", 2, count_rows (l_db))
			l_db.close
		end

	test_commit_exception_aborts_commit
			-- An exception in the commit action aborts the commit (rollback) and leaves the connection usable.
		local
			l_db: SQLITE_DATABASE
		do
			reset_counts
			l_db := fresh_db
			l_db.set_commit_action (agent on_commit_raise)
			l_db.begin_transaction (True)
			assert_true ("insert", run_modify (l_db, "INSERT INTO t (x) VALUES (1);"))
			l_db.commit
			assert_true ("commit_failed", l_db.has_error)
			assert_false ("not_in_transaction", l_db.is_in_transaction)
			assert_attached ("exception_kept", l_db.last_callback_exception)
			l_db.set_commit_action (Void)
			assert_true ("connection_works", run_modify (l_db, "INSERT INTO t (x) VALUES (2);"))
			assert_integers_equal ("only_second_row", 1, count_rows (l_db))
			l_db.close
		end

	test_progress_and_busy_exceptions_contained
			-- An exception in the progress handler interrupts the statement; one in the busy handler
			-- stops waiting. The connections stay usable.
		local
			l_a, l_b: SQLITE_DATABASE
		do
			reset_counts
			make_file_db ("hooks_busy2.db")
			create l_a.make_open_read_write ("hooks_busy2.db")
			l_a.set_progress_handler_period (100)
			l_a.set_progress_handler (agent on_progress_raise)
			assert_false ("interrupted", run_modify (l_a, "INSERT INTO t (x) WITH RECURSIVE c(n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM c WHERE n < 100000) SELECT n FROM c;"))
			assert_attached ("progress_exception_kept", l_a.last_callback_exception)
			l_a.set_progress_handler (Void)
			assert_true ("a_works", run_modify (l_a, "INSERT INTO t (x) VALUES (1);"))
			create l_b.make_open_read_write ("hooks_busy2.db")
			l_a.begin_transaction (False)
			l_b.set_busy_handler (agent on_busy_raise)
			assert_false ("busy_write_fails", run_modify (l_b, "INSERT INTO t (x) VALUES (2);"))
			assert_attached ("busy_exception_kept", l_b.last_callback_exception)
			l_a.rollback
			l_b.set_busy_handler (Void)
			assert_true ("b_works", run_modify (l_b, "INSERT INTO t (x) VALUES (3);"))
			l_b.close
			l_a.close
			delete_file ("hooks_busy2.db")
		end

feature -- Test routines: reopen

	test_hooks_survive_reopen
			-- Actions set before `close' are installed again by the next `open'.
		local
			l_db: SQLITE_DATABASE
		do
			reset_counts
			make_file_db ("hooks_reopen.db")
			create l_db.make_open_read_write ("hooks_reopen.db")
			l_db.set_update_action (agent on_update)
			l_db.close
			l_db.open_read_write
			assert_true ("insert", run_modify (l_db, "INSERT INTO t (x) VALUES (1);"))
			assert_integers_equal ("fired_after_reopen", 1, update_calls)
			l_db.set_update_action (Void)
			l_db.close
			delete_file ("hooks_reopen.db")
		end

feature {NONE} -- Callbacks

	commit_calls, rollback_calls, update_calls, progress_calls, busy_calls: INTEGER
	last_update_code: INTEGER
	last_update_row: INTEGER_64

	last_update_db: STRING
		attribute
			create Result.make_empty
		end

	last_update_table: STRING
		attribute
			create Result.make_empty
		end

	busy_counts: STRING
		attribute
			create Result.make_empty
		end

	reset_counts
		do
			commit_calls := 0
			rollback_calls := 0
			update_calls := 0
			progress_calls := 0
			busy_calls := 0
			last_update_code := 0
			last_update_db := ""
			last_update_table := ""
			last_update_row := 0
			busy_counts := ""
		end

	on_commit_allow: BOOLEAN
		do
			commit_calls := commit_calls + 1
		end

	on_commit_refuse: BOOLEAN
		do
			commit_calls := commit_calls + 1
			Result := True
		end

	on_commit_raise: BOOLEAN
		do
			commit_calls := commit_calls + 1
			(create {DEVELOPER_EXCEPTION}).raise
		end

	on_rollback
		do
			rollback_calls := rollback_calls + 1
		end

	on_update (a_action: INTEGER; a_db, a_table: STRING; a_row: INTEGER_64)
		do
			update_calls := update_calls + 1
			last_update_code := a_action
			last_update_db := a_db
			last_update_table := a_table
			last_update_row := a_row
		end

	on_update_raise (a_action: INTEGER; a_db, a_table: STRING; a_row: INTEGER_64)
		do
			update_calls := update_calls + 1
			(create {DEVELOPER_EXCEPTION}).raise
		end

	on_progress_continue: BOOLEAN
		do
			progress_calls := progress_calls + 1
		end

	on_progress_stop: BOOLEAN
		do
			progress_calls := progress_calls + 1
			Result := True
		end

	on_progress_raise: BOOLEAN
		do
			progress_calls := progress_calls + 1
			(create {DEVELOPER_EXCEPTION}).raise
		end

	on_busy_three (a_count: NATURAL): BOOLEAN
		do
			busy_calls := busy_calls + 1
			busy_counts.append (a_count.out + ",")
			Result := a_count < 3
		end

	on_busy_raise (a_count: NATURAL): BOOLEAN
		do
			busy_calls := busy_calls + 1
			(create {DEVELOPER_EXCEPTION}).raise
		end

feature {NONE} -- Helpers

	install_all (a_db: SQLITE_DATABASE)
			-- Commit, rollback, update and progress actions that count.
		do
			a_db.set_commit_action (agent on_commit_allow)
			a_db.set_rollback_action (agent on_rollback)
			a_db.set_update_action (agent on_update)
			a_db.set_progress_handler_period (50)
			a_db.set_progress_handler (agent on_progress_continue)
		end

	remove_all (a_db: SQLITE_DATABASE)
		do
			a_db.set_commit_action (Void)
			a_db.set_rollback_action (Void)
			a_db.set_update_action (Void)
			a_db.set_progress_handler (Void)
		end

	fresh_db: SQLITE_DATABASE
			-- In-memory database with table t (id INTEGER PRIMARY KEY, x INTEGER).
		do
			create Result.make (create {SQLITE_IN_MEMORY_SOURCE})
			Result.open_create_read_write
			assert_true ("table", run_modify (Result, "CREATE TABLE t (id INTEGER PRIMARY KEY, x INTEGER);"))
		end

	make_file_db (a_name: STRING)
		local
			l_db: SQLITE_DATABASE
		do
			delete_file (a_name)
			create l_db.make_create_read_write (a_name)
			assert_true ("table", run_modify (l_db, "CREATE TABLE t (id INTEGER PRIMARY KEY, x INTEGER);"))
			l_db.close
		end

	count_rows (a_db: SQLITE_DATABASE): INTEGER
		do
			Result := scalar_text (a_db, "SELECT count(*) FROM t;").to_integer
		end

	run_modify (a_db: SQLITE_DATABASE; a_sql: STRING): BOOLEAN
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

	scalar_text (a_db: SQLITE_DATABASE; a_sql: STRING): STRING
		local
			l_query: SQLITE_QUERY_STATEMENT
			l_text: STRING
		do
			create l_text.make_empty
			create l_query.make (a_sql, a_db)
			if l_query.is_compiled then
				l_query.execute (agent (a_row: SQLITE_RESULT_ROW; a_into: STRING): BOOLEAN
					do
						if a_into.is_empty and then not a_row.is_null (1) then
							a_into.append (a_row.string_value (1))
						end
						Result := True
					end (?, l_text))
			end
			l_query.cleanup
			Result := l_text
		end

	delete_file (a_name: STRING)
		local
			l_file: RAW_FILE
		do
			create l_file.make_with_name (a_name)
			if l_file.exists then
				l_file.delete
			end
		end

end
