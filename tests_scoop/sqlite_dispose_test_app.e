note
	description: "[
		SCOOP proof that dropped connections are disposed safely whichever
		thread collects them (target sqlite_2025_scoop_test).

		Under SCOOP the collector runs `dispose' on its own thread, in the
		middle of the collection. For a connection opened on another
		processor that thread is foreign; for one opened here it is the
		owner. Both cases are exercised with connections that still hold a
		compiled statement:
		  1. 50 connections opened and dropped on a worker processor, then
		     collected from the root;
		  2. 50 connections opened and dropped on the root, then collected
		     on the root.
		The checks below confirm the connections were really opened; the
		proof itself is that the process survives each collection and exits
		with status 0. Before the fix, case 1 died inside `dispose' on
		SQLITE_DATABASE.is_accessible (the connection belongs to another
		thread).
	]"

class
	SQLITE_DISPOSE_TEST_APP

create
	make

feature {NONE} -- Initialization

	make
		do
			print ("eiffel_sqlite_2025 SCOOP dispose proof%N%N")
			create_database
			report ("a worker opened and dropped 50 connections, then the worker was dropped", open_and_drop_on_a_worker = 50)
			collect
			report ("the root's collection disposed them (" + live_databases.out + " left) and the process lives", live_databases = 0)
			report ("root opened and dropped 50 connections", open_and_drop_here = 50)
			collect
			report ("the owning thread's collection disposed them (" + live_databases.out + " left) and the process lives", live_databases = 0)
			print ("%NResults: " + passed.out + " passed, " + failed.out + " failed%N")
			if failed > 0 then
				print ("TESTS FAILED%N")
			else
				print ("ALL TESTS PASSED%N")
			end
			io.output.flush
		end

feature {NONE} -- Steps

	Database_path: STRING_8 = "sqlite_dispose_proof.db"

	create_database
			-- A file database with one table, written and closed on the root.
		local
			l_db: SQLITE_DATABASE
			l_modify: SQLITE_MODIFY_STATEMENT
		do
			create l_db.make_create_read_write (Database_path)
			create l_modify.make ("CREATE TABLE IF NOT EXISTS t (x INTEGER);", l_db)
			l_modify.execute
			l_modify.cleanup
			l_db.close
		end

	open_and_drop_on_a_worker: INTEGER
			-- 50 connections opened and dropped on a worker processor that is itself
			-- dropped on return (as an HTTP server's request processors are), so
			-- nothing is left to dispose them on their own thread.
		local
			l_worker: separate SQLITE_DISPOSE_WORKER
		do
			create l_worker
			Result := open_and_drop (l_worker)
		end

	open_and_drop (a_worker: separate SQLITE_DISPOSE_WORKER): INTEGER
			-- Have `a_worker' open and drop 50 connections; wait for it.
		do
			a_worker.open_and_drop (Database_path, 50)
			Result := a_worker.opened
		end

	open_and_drop_here: INTEGER
			-- Open and drop 50 connections on this processor.
		local
			l_db: SQLITE_DATABASE
			l_query: SQLITE_QUERY_STATEMENT
			i: INTEGER
		do
			from i := 1 until i > 50 loop
				create l_db.make (create {SQLITE_FILE_SOURCE}.make (Database_path))
				l_db.open_read
				create l_query.make ("SELECT count(*) FROM t;", l_db)
				if l_query.is_compiled then
					Result := Result + 1
				end
				i := i + 1
			end
		end

	collect
			-- Full collections around a pause, so dropped processors wind down and
			-- every dropped object is disposed.
		local
			l_memory: MEMORY
		do
			create l_memory
			l_memory.full_collect;
			(create {EXECUTION_ENVIRONMENT}).sleep (500_000_000)
			l_memory.full_collect
			l_memory.full_collect
		end

	live_databases: INTEGER
			-- SQLITE_DATABASE objects still in memory.
		do
			Result := (create {MEMORY}).objects_instance_of_type (({SQLITE_DATABASE}).type_id).count
		end

feature {NONE} -- Reporting

	passed, failed: INTEGER

	report (a_name: STRING_8; a_ok: BOOLEAN)
		do
			if a_ok then
				passed := passed + 1
				print ("  PASS: " + a_name + "%N")
			else
				failed := failed + 1
				print ("  FAIL: " + a_name + "%N")
			end
			io.output.flush
		end

end
