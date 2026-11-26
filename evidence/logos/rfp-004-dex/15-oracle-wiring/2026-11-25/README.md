# RFP-004 #15: Cross-RFP oracle checks (run 2026-11-25)

- **Issue:** [iftech/qa-audits#15](https://github.com/iftech/qa-audits/issues/15)
- **QA comment:** https://github.com/iftech/qa-audits/issues/15#issuecomment-7167624882
- **Note:** The linked comment is the source check. These files are from a later runtime run on a local chain.

## Code and spec

- Code: [`logos-blockchain/lez-programs@1cfaa5e3446a684e6e9b61cfb243038dae6465ea`](https://github.com/logos-blockchain/lez-programs/tree/1cfaa5e3446a684e6e9b61cfb243038dae6465ea)
- Sequencer and wallet: [`logos-blockchain/logos-execution-zone@d8596eb734bf9c9ce801afb92df06098a2eb098a`](https://github.com/logos-blockchain/logos-execution-zone/tree/d8596eb734bf9c9ce801afb92df06098a2eb098a) (LEZ `v0.2.5-rc2`)
- CLI: [`logos-co/spel@c6f73ce21e4805f8430f03afdbdedf0b7e479a5e`](https://github.com/logos-co/spel/tree/c6f73ce21e4805f8430f03afdbdedf0b7e479a5e) (SPEL CLI `0.7.0`)
- Spec: [`logos-co/rfp@a4323366516228875b61c72d12acb59b3d46cab7`](https://github.com/logos-co/rfp/blob/a4323366516228875b61c72d12acb59b3d46cab7/RFPs/RFP-004-privacy-preserving-dex.md)
- Tools: Rust `1.94.0`; `r0vm` and `cargo-risczero` `3.0.5`; `RISC0_DEV_MODE=1` (no real proofs).

## How to rerun

Build as in the #10 run folder, then run `run-oracle-wiring.sh <folder with the clones>`. It checks the pinned SHAs before it starts.

## Files

| File or folder | What it shows |
| --- | --- |
| `run-oracle-wiring.sh` | Runs the AMM, TWAP oracle and stablecoin together on a local chain and logs each check as `CHECK <id> <expected> <observed>`. |
| `checks.tsv` | The 27 checks: ID, expected result, observed result, and the rejection message where there is one. |
| `run-output.txt` | Full output of the run: tool versions, program IDs, every command and its result. |
| `sequencer.log` | Sequencer log for the whole run. |
| `accounts/` | Decoded account state at each step: pool, tick, observations, oracle price, stablecoin parameters and redemption state. |
| `tx/` | For each transaction: the command log, the receipt and the matching sequencer log lines. |
| `pdas.txt, twap-pdas.txt, sc-globals.txt, z-*.txt, twap-pdas-rogue.txt` | Derived account addresses used by the run, including the zero-price and wallet-sourced-oracle cases. |
