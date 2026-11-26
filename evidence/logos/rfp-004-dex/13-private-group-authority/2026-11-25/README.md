# RFP-004 #13: Private and group-authority flows (run 2026-11-25)

- **Issue:** [iftech/qa-audits#13](https://github.com/iftech/qa-audits/issues/13)
- **QA comment:** https://github.com/iftech/qa-audits/issues/13#issuecomment-7167697617

## Code and spec

- Code: [`logos-blockchain/lez-programs@1cfaa5e3446a684e6e9b61cfb243038dae6465ea`](https://github.com/logos-blockchain/lez-programs/tree/1cfaa5e3446a684e6e9b61cfb243038dae6465ea)
- LEZ: [`logos-blockchain/logos-execution-zone@d8596eb734bf9c9ce801afb92df06098a2eb098a`](https://github.com/logos-blockchain/logos-execution-zone/tree/d8596eb734bf9c9ce801afb92df06098a2eb098a) (LEZ `v0.2.5-rc2`), taken from `Cargo.lock`
- Spec: [`logos-co/rfp@a4323366516228875b61c72d12acb59b3d46cab7`](https://github.com/logos-co/rfp/blob/a4323366516228875b61c72d12acb59b3d46cab7/RFPs/RFP-004-privacy-preserving-dex.md)
- Tools: Rust `1.94.0`; `risc0-zkvm`, `r0vm` and `cargo-risczero` `3.0.5`; local CPU prover. Each case ran twice: with `RISC0_DEV_MODE=1` and with real proofs.

## How to rerun

Unpack `rfp004-13-scripts.tgz` and run `bootstrap.sh`, `build.sh`, then `orchestrate.sh`. The comment's "How to reproduce" block lists the steps.

## Files

| File or folder | What it shows |
| --- | --- |
| `rfp004-13-scripts.tgz` | The scripts for the run: setup, build, the case list (`cases.txt`), the dev and real runs, the prover-interrupt test, and the report generator. |
| `rfp004-13-raw.tgz` | Raw output in `run13/`: build log, dev and real suite logs, the interrupt log, and for each case its test log, timing and one `r0vm` log per prover session. |
