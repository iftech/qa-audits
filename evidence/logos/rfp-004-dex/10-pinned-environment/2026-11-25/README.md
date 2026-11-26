# RFP-004 #10: Pinned test environment (run 2026-11-25)

- **Issue:** [iftech/qa-audits#10](https://github.com/iftech/qa-audits/issues/10)
- **QA comment:** https://github.com/iftech/qa-audits/issues/10#issuecomment-7167609314

## Code and spec

- Code: [`logos-blockchain/lez-programs@1cfaa5e3446a684e6e9b61cfb243038dae6465ea`](https://github.com/logos-blockchain/lez-programs/tree/1cfaa5e3446a684e6e9b61cfb243038dae6465ea)
- Sequencer and wallet: [`logos-blockchain/logos-execution-zone@d8596eb734bf9c9ce801afb92df06098a2eb098a`](https://github.com/logos-blockchain/logos-execution-zone/tree/d8596eb734bf9c9ce801afb92df06098a2eb098a) (LEZ `v0.2.5-rc2`)
- CLI: [`logos-co/spel@c6f73ce21e4805f8430f03afdbdedf0b7e479a5e`](https://github.com/logos-co/spel/tree/c6f73ce21e4805f8430f03afdbdedf0b7e479a5e) (SPEL CLI `0.7.0`)
- Spec: [`logos-co/rfp@a4323366516228875b61c72d12acb59b3d46cab7`](https://github.com/logos-co/rfp/blob/a4323366516228875b61c72d12acb59b3d46cab7/RFPs/RFP-004-privacy-preserving-dex.md)
- Tools: Rust `1.94.0`; RISC Zero `r0vm` and `cargo-risczero` `3.0.5`; guest builder `r0.1.88.0`; `RISC0_DEV_MODE=1` (no real proofs).

## How to rerun

Follow `setup.md` to build the pinned tools, then run `run-public-smoke.sh` with the folder that holds the three clones. The comment's "How to reproduce" block has the same steps.

## Files

| File or folder | What it shows |
| --- | --- |
| `setup.md` | How to build the pinned environment: revisions, lockfile hashes, build commands. |
| `run-public-smoke.sh` | Starts a fresh local chain, deploys the programs, creates one pool and makes one swap, then checks the chain state. |
| `public-smoke.log` | Full output of that run: commands, transaction hashes and account state before and after. |
