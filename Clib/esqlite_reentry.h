#ifndef _ESQLITE_REENTRY_H_
#define _ESQLITE_REENTRY_H_

/*
 * Callback trampolines for SQLite hooks that call Eiffel (commit, rollback, update, progress, busy).
 *
 * Header only, on purpose. These functions are compiled inside the client's GENERATED C (they are
 * reached through "C inline use" externals of SQLITE_DATABASE_EXTERNALS), so they are compiled with
 * the client target's own flags: EIF_THREADS is defined exactly when the target is concurrent (SCOOP
 * or threads) and undefined otherwise. That is what makes one library work in both kinds of target:
 *
 *   - Concurrent target: SQLite calls a hook from inside a `blocking' external (sqlite3_step,
 *     sqlite3_prepare_v2, sqlite3_close ...), where the generated code has already left Eiffel
 *     (EIF_ENTER_C). Before touching any Eiffel object the trampoline re-enters the runtime and
 *     synchronizes with a running GC (EIF_ENTER_EIFFEL; RTGC), and leaves it again afterwards. If the
 *     hook fires while the thread is still in Eiffel code (a non-blocking external), nothing changes.
 *   - Non-concurrent target: the macros are empty and no multithreaded runtime symbol is referenced,
 *     so the link works (a prebuilt object compiled with /DEIF_THREADS does not link there).
 *
 * A precompiled esqlite.obj cannot do this: it is compiled once, with one set of flags.
 * The Eiffel routines called back return BOOLEAN (EIF_BOOLEAN, one byte), so they are called through
 * EIF_BOOLEAN-returning pointers, never EIF_INTEGER ones.
 */

#include "esqlite.h"

#if defined(ISE_GC) && defined(EIF_THREADS)
#define ESQ_DECLARE_REENTRY	int esq_reenter
#define ESQ_ENTER			esq_reenter = !eif_is_in_eiffel_code (); if (esq_reenter) { EIF_ENTER_EIFFEL; RTGC; }
#define ESQ_LEAVE			if (esq_reenter) { EIF_EXIT_EIFFEL; }
#define ESQ_REENTRY_MODE	1
#else
#define ESQ_DECLARE_REENTRY	int esq_reenter_unused = 0
#define ESQ_ENTER			(void) esq_reenter_unused;
#define ESQ_LEAVE
#define ESQ_REENTRY_MODE	0
#endif

static int esq_commit_trampoline (void *p_data)
{
	ESQ_DECLARE_REENTRY;
	EIF_CBDATAP l_data = (EIF_CBDATAP) p_data;
	EIF_BOOLEAN l_abort = EIF_FALSE;
	if (l_data != NULL && l_data->func != NULL) {
		ESQ_ENTER
		l_abort = ((EIF_BOOLEAN (*) (EIF_REFERENCE)) l_data->func) (eif_access (l_data->o));
		ESQ_LEAVE
	}
	return l_abort ? 1 : 0;
}

static void esq_rollback_trampoline (void *p_data)
{
	ESQ_DECLARE_REENTRY;
	EIF_CBDATAP l_data = (EIF_CBDATAP) p_data;
	if (l_data != NULL && l_data->func != NULL) {
		ESQ_ENTER
		((void (*) (EIF_REFERENCE)) l_data->func) (eif_access (l_data->o));
		ESQ_LEAVE
	}
}

static void esq_update_trampoline (void *p_data, int a_action, char const *a_db_name, char const *a_table_name, sqlite3_int64 a_row_id)
{
	ESQ_DECLARE_REENTRY;
	EIF_CBDATAP l_data = (EIF_CBDATAP) p_data;
	if (l_data != NULL && l_data->func != NULL) {
		ESQ_ENTER
		((void (*) (EIF_REFERENCE, EIF_INTEGER, EIF_POINTER, EIF_POINTER, EIF_INTEGER_64)) l_data->func) (
			eif_access (l_data->o), (EIF_INTEGER) a_action, (EIF_POINTER) a_db_name, (EIF_POINTER) a_table_name, (EIF_INTEGER_64) a_row_id);
		ESQ_LEAVE
	}
}

static int esq_busy_trampoline (void *p_data, int a_count)
{
	ESQ_DECLARE_REENTRY;
	EIF_CBDATAP l_data = (EIF_CBDATAP) p_data;
	EIF_BOOLEAN l_retry = EIF_FALSE;
	if (l_data != NULL && l_data->func != NULL) {
		ESQ_ENTER
		l_retry = ((EIF_BOOLEAN (*) (EIF_REFERENCE, EIF_NATURAL_32)) l_data->func) (eif_access (l_data->o), (EIF_NATURAL_32) a_count);
		ESQ_LEAVE
	}
	return l_retry ? 1 : 0;
}

static int esq_progress_trampoline (void *p_data)
{
	ESQ_DECLARE_REENTRY;
	EIF_CBDATAP l_data = (EIF_CBDATAP) p_data;
	EIF_BOOLEAN l_interrupt = EIF_FALSE;
	if (l_data != NULL && l_data->func != NULL) {
		ESQ_ENTER
		l_interrupt = ((EIF_BOOLEAN (*) (EIF_REFERENCE)) l_data->func) (eif_access (l_data->o));
		ESQ_LEAVE
	}
	return l_interrupt ? 1 : 0;
}

#endif /* _ESQLITE_REENTRY_H_ */
