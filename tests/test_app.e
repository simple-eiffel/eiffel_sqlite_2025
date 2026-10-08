note
	description: "Console runner for the eiffel_sqlite_2025 test classes (target sqlite_2025_test)."

class
	TEST_APP

create
	make

feature {NONE} -- Initialization

	make
			-- Run every test and print a summary.
		do
			print ("Running eiffel_sqlite_2025 tests...%N%N")
			create library_tests
			run_test (agent library_tests.test_database_opens, "test_database_opens")
			run_test (agent library_tests.test_interface_usable_after_open, "test_interface_usable_after_open")
			run_test (agent library_tests.test_create_table, "test_create_table")
			run_test (agent library_tests.test_create_trigger, "test_create_trigger")
			run_test (agent library_tests.test_create_trigger_with_json, "test_create_trigger_with_json")
			run_test (agent library_tests.test_linked_engine_version, "test_linked_engine_version")
			run_test (agent library_tests.test_real_text_has_17_digits, "test_real_text_has_17_digits")
			run_test (agent library_tests.test_math_functions_available, "test_math_functions_available")
			run_test (agent library_tests.test_json_still_available, "test_json_still_available")
			run_test (agent library_tests.test_callbacks_reported_supported, "test_callbacks_reported_supported")
			run_test (agent library_tests.test_callback_setters_accept_eiffel_routines, "test_callback_setters_accept_eiffel_routines")
			run_test (agent library_tests.test_callback_setters_accept_void, "test_callback_setters_accept_void")
			run_test (agent library_tests.test_attach_uri_read_only_refuses_writes, "test_attach_uri_read_only_refuses_writes")
			run_test (agent library_tests.test_attach_uri_read_only_missing_file_errors, "test_attach_uri_read_only_missing_file_errors")
			run_test (agent library_tests.test_plain_path_with_hash_unchanged, "test_plain_path_with_hash_unchanged")
			run_test (agent library_tests.test_main_database_by_uri_read_only, "test_main_database_by_uri_read_only")
			run_test (agent library_tests.test_commit_failure_keeps_transaction_open, "test_commit_failure_keeps_transaction_open")
			run_test (agent library_tests.test_commit_success_ends_transaction, "test_commit_success_ends_transaction")
			run_test (agent library_tests.test_begin_failure_leaves_no_transaction, "test_begin_failure_leaves_no_transaction")
			create hook_tests
			print ("Callback re-entry active: " + (create {SQLITE_DATABASE}.make (create {SQLITE_IN_MEMORY_SOURCE})).is_callback_reentry_active.out + "%N")
			run_test (agent hook_tests.test_callbacks_supported, "test_callbacks_supported")
			run_test (agent hook_tests.test_commit_hook_fires, "test_commit_hook_fires")
			run_test (agent hook_tests.test_commit_hook_can_abort, "test_commit_hook_can_abort")
			run_test (agent hook_tests.test_rollback_hook_fires, "test_rollback_hook_fires")
			run_test (agent hook_tests.test_update_hook_data, "test_update_hook_data")
			run_test (agent hook_tests.test_progress_handler_fires_and_interrupts, "test_progress_handler_fires_and_interrupts")
			run_test (agent hook_tests.test_busy_handler_fires, "test_busy_handler_fires")
			run_test (agent hook_tests.test_disabling_commit_keeps_others, "test_disabling_commit_keeps_others")
			run_test (agent hook_tests.test_disabling_rollback_keeps_others, "test_disabling_rollback_keeps_others")
			run_test (agent hook_tests.test_disabling_update_and_progress_keeps_others, "test_disabling_update_and_progress_keeps_others")
			run_test (agent hook_tests.test_update_exception_contained, "test_update_exception_contained")
			run_test (agent hook_tests.test_commit_exception_aborts_commit, "test_commit_exception_aborts_commit")
			run_test (agent hook_tests.test_progress_and_busy_exceptions_contained, "test_progress_and_busy_exceptions_contained")
			run_test (agent hook_tests.test_hooks_survive_reopen, "test_hooks_survive_reopen")
			run_test (agent hook_tests.test_void_actions_on_closed_database, "test_void_actions_on_closed_database")
			print ("%N========================%N")
			print ("Results: " + passed.out + " passed, " + failed.out + " failed%N")
			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
			end
		end

feature {NONE} -- Implementation

	library_tests: TEST_SQLITE_LIBRARY
	hook_tests: TEST_SQLITE_HOOKS

	passed: INTEGER
	failed: INTEGER

	run_test (a_test: PROCEDURE; a_name: STRING)
			-- Run `a_test', print PASS or FAIL with the failing tag, and count it.
		local
			l_retried: BOOLEAN
		do
			if not l_retried then
				a_test.call (Void)
				print ("  PASS: " + a_name + "%N")
				passed := passed + 1
			end
		rescue
			print ("  FAIL: " + a_name)
			if attached {EXCEPTION_MANAGER_FACTORY}.exception_manager.last_exception as l_ex then
				if attached l_ex.description as l_desc then
					print (" [" + {UTF_CONVERTER}.string_32_to_utf_8_string_8 (l_desc) + "]")
				elseif attached l_ex.tag as l_tag then
					print (" [" + {UTF_CONVERTER}.string_32_to_utf_8_string_8 (l_tag) + "]")
				end
			end
			print ("%N")
			failed := failed + 1
			l_retried := True
			retry
		end

end
