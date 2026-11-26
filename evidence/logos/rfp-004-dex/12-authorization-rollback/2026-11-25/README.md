# RFP-004 #12: Authorization and rollback tests (run 2026-11-25)

- **Issue:** [iftech/qa-audits#12](https://github.com/iftech/qa-audits/issues/12)
- **QA comment:** https://github.com/iftech/qa-audits/issues/12#issuecomment-7167612610

## Code and spec

- Code: [`logos-blockchain/lez-programs@1cfaa5e3446a684e6e9b61cfb243038dae6465ea`](https://github.com/logos-blockchain/lez-programs/tree/1cfaa5e3446a684e6e9b61cfb243038dae6465ea)
- Sequencer and wallet: [`logos-blockchain/logos-execution-zone@d8596eb734bf9c9ce801afb92df06098a2eb098a`](https://github.com/logos-blockchain/logos-execution-zone/tree/d8596eb734bf9c9ce801afb92df06098a2eb098a) (LEZ `v0.2.5-rc2`)
- CLI: [`logos-co/spel@c6f73ce21e4805f8430f03afdbdedf0b7e479a5e`](https://github.com/logos-co/spel/tree/c6f73ce21e4805f8430f03afdbdedf0b7e479a5e) (SPEL CLI `0.7.0`)
- Spec: [`logos-co/rfp@a4323366516228875b61c72d12acb59b3d46cab7`](https://github.com/logos-co/rfp/blob/a4323366516228875b61c72d12acb59b3d46cab7/RFPs/RFP-004-privacy-preserving-dex.md)
- Tools: Rust `1.94.0`; RISC Zero `r0vm` and `cargo-risczero` `3.0.5`; guest builder `r0.1.88.0`; `RISC0_DEV_MODE=1` (no real proofs).

## How to rerun

Unpack the archive and follow the comment's "How to reproduce" block: run `scripts/run-public-smoke.sh`, then `scripts/run-issue-12.sh`.

## Files

| File or folder | What it shows |
| --- | --- |
| `rfp004-12-evidence.tar.gz` | One archive with two folders, below. |
| `logs/ (in the archive)` | Build logs and `final-run/`: for each of the 12 cases, the command log, the receipt, the sequencer log, and account state before and after. `state-evidence.md` is a short summary. |
| `scripts/ (in the archive)` | The run and check scripts: `run-issue-12.sh`, `check-state.py`, `check-concurrency.py`, `render-state-evidence.py`, plus the #10 smoke script and setup notes. |
