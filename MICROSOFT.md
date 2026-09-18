# Microsoft / Windows plan

## Recommendation

Support **Windows through WSL 2 first**. Cynthia is Python-based but it
orchestrates Data Brain's Bash tools and invokes its pinned local scorer, so
WSL is the smallest truthful compatibility target.

Cynthia itself does not require SQLite. Data Brain's retrieval layer requires
the normal `sqlite3` command-line package inside WSL; no hosted database or
Microsoft service is needed.

## Minimal implementation phases

1. Run Cynthia's unit suite under Windows Python and under WSL Python. Keep
   every subprocess invocation as an argv list, never a shell string.
2. Make public setup independent of the author's home layout: the current
   bridge needs an explicit Data Brain root and setup must either include its
   synthetic integration suites or declare them separately. Run the Data Brain
   bridge in WSL after its POSIX portability fixes land. Do not publish a
   Windows-native recall claim before this succeeds.
3. Add CI for the Python-only Cynthia tests on Windows and Ubuntu. Add the
   integrated setup test only after a disposable Data Brain fixture exists.
4. Consider a native PowerShell adapter only if WSL is not acceptable; it is a
   separate implementation, not a SQLite-install tweak.

## Acceptance

The manifest preflight, approval gates, local-only route, metadata-only recall
bridge, and E2E receipt must behave identically on the tested Windows/WSL
fixture and continue to keep note content out of Cynthia receipts.
