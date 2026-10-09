note
	description: "[
		Opens connections (each with a compiled statement) on its own
		processor and drops them, for SQLITE_DISPOSE_TEST_APP.
	]"

class
	SQLITE_DISPOSE_WORKER

feature -- Access

	opened: INTEGER
			-- Connections opened and dropped so far.

feature -- Basic operations

	open_and_drop (a_path: separate READABLE_STRING_8; a_count: INTEGER)
			-- Open `a_count' read-only connections to `a_path', compile a query on
			-- each, and leave both to the garbage collector.
		require
			positive: a_count > 0
		local
			l_path: STRING_8
			i: INTEGER
		do
			create l_path.make_from_separate (a_path)
			from i := 1 until i > a_count loop
				open_one (l_path)
				opened := opened + 1
				i := i + 1
			end
		ensure
			counted: opened = old opened + a_count
		end

feature {NONE} -- Implementation

	open_one (a_path: STRING_8)
			-- One connection and one compiled (never finalized) statement, both dropped.
		local
			l_db: SQLITE_DATABASE
			l_query: SQLITE_QUERY_STATEMENT
		do
			create l_db.make (create {SQLITE_FILE_SOURCE}.make (a_path))
			l_db.open_read
			create l_query.make ("SELECT count(*) FROM t;", l_db)
			check compiled: l_query.is_compiled end
		end

end
