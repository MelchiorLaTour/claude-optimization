# Microsoft / Windows plan

## Recommendation

Support **Windows through WSL 2 first**. Cynthia is Python-based but it
orchestrates Data Brain's Bash tools and invokes its pinned local scorer, so
WSL is the smallest truthful compatibility target. The isolated WSL
implementation is in [`windows/`](windows/README.md); `cynthia/` stays unchanged.

Cynthia itself does not require SQLite. Data Brain's retrieval layer requires
the normal `sqlite3` command-line package inside WSL; no hosted database or
Microsoft service is needed.

## What it provides

`windows/run-tests-wsl.sh` runs Cynthia's existing suite from WSL.
`windows/cynthia-wsl-readiness.py` runs the Cynthia suite plus Data Brain's
WSL verifier and writes a content-free combined receipt. Native PowerShell
remains a separate implementation.

## Acceptance

The manifest preflight, approval gates, local-only route, metadata-only recall
bridge, and E2E receipt must behave identically on the tested Windows/WSL
fixture and continue to keep note content out of Cynthia receipts.
