# Cynthia for Windows (WSL 2)

This directory is a Windows-specific entry point. It leaves the macOS-ready
Cynthia source unchanged.

Install and configure Data Brain's WSL section first. Then run Cynthia's
portable test suite inside WSL:

```bash
bash windows/run-tests-wsl.sh
```

For a combined local readiness receipt, point Cynthia at the Data Brain WSL
checkout:

```bash
python3 windows/cynthia-wsl-readiness.py --data-brain-root ~/src/data-brain
```

The receipt contains only command outcomes, not note content. A PASS requires
both Data Brain's configured local verification and Cynthia's unit suite.
