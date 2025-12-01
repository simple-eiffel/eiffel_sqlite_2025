note
	description: "[
		SQLite Online Backup API externals.

		Provides access to sqlite3_backup_* functions for performing
		online database backups while the source database is in use.

		Usage:
			1. Call backup_init to start a backup from source to destination
			2. Call backup_step repeatedly to copy pages (or once with -1 for all)
			3. Call backup_finish to complete and clean up

		Progress can be monitored via backup_remaining and backup_pagecount.
	]"
	date: "$Date$"
	revision: "$Revision$"

class
	SQLITE_BACKUP_EXTERNALS

feature -- Backup Operations

	backup_init (a_dest: SQLITE_DATABASE; a_dest_name: STRING_8; a_source: SQLITE_DATABASE; a_source_name: STRING_8): POINTER
			-- Initialize backup from source to destination database
			-- Returns backup handle or default_pointer on failure
		require
			dest_attached: a_dest /= Void
			dest_open: not a_dest.is_closed
			dest_name_valid: not a_dest_name.is_empty
			source_attached: a_source /= Void
			source_open: not a_source.is_closed
			source_name_valid: not a_source_name.is_empty
		local
			l_dest_name: C_STRING
			l_source_name: C_STRING
		do
			create l_dest_name.make (a_dest_name)
			create l_source_name.make (a_source_name)
			Result := {SQLITE_EXTERNALS}.c_sqlite3_backup_init (
				a_dest.internal_db,
				l_dest_name.item,
				a_source.internal_db,
				l_source_name.item
			)
		end

	backup_step (a_backup: POINTER; a_pages: INTEGER): INTEGER
			-- Copy up to a_pages pages from source to destination
			-- Use -1 to copy all remaining pages in one call
			-- Returns SQLITE_OK (0) if more pages remain
			-- Returns SQLITE_DONE (101) if backup completed
			-- Returns error code on failure
		require
			backup_valid: a_backup /= default_pointer
		do
			Result := {SQLITE_EXTERNALS}.c_sqlite3_backup_step (a_backup, a_pages)
		end

	backup_finish (a_backup: POINTER): INTEGER
			-- Finish backup and release all resources
			-- Returns SQLITE_OK (0) on success, error code on failure
		require
			backup_valid: a_backup /= default_pointer
		do
			Result := {SQLITE_EXTERNALS}.c_sqlite3_backup_finish (a_backup)
		end

	backup_remaining (a_backup: POINTER): INTEGER
			-- Number of pages still to be backed up
		require
			backup_valid: a_backup /= default_pointer
		do
			Result := {SQLITE_EXTERNALS}.c_sqlite3_backup_remaining (a_backup)
		ensure
			non_negative: Result >= 0
		end

	backup_pagecount (a_backup: POINTER): INTEGER
			-- Total number of pages in source database
		require
			backup_valid: a_backup /= default_pointer
		do
			Result := {SQLITE_EXTERNALS}.c_sqlite3_backup_pagecount (a_backup)
		ensure
			non_negative: Result >= 0
		end

feature -- Constants

	Sqlite_ok: INTEGER = 0
			-- Successful result

	Sqlite_done: INTEGER = 101
			-- sqlite3_backup_step finished copying all pages

	Main_database: STRING_8 = "main"
			-- Name of main database

	Temp_database: STRING_8 = "temp"
			-- Name of temporary database

note
	copyright: "Copyright (c) 2025"
	license: "MIT License"

end
