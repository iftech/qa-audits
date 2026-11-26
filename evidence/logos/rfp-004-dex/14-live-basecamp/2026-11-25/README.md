# RFP-004 #14: Basecamp DEX journeys (run 2026-11-25)

- **Issue:** [iftech/qa-audits#14](https://github.com/iftech/qa-audits/issues/14)
- **QA comment:** https://github.com/iftech/qa-audits/issues/14#issuecomment-7167628974

## Code and spec

- Code: [`logos-blockchain/lez-programs@1cfaa5e3446a684e6e9b61cfb243038dae6465ea`](https://github.com/logos-blockchain/lez-programs/tree/1cfaa5e3446a684e6e9b61cfb243038dae6465ea) (`amm_ui` 0.3.0 and `amm_module` 0.3.0 with `lez_core` 0.4.2)
- Sequencer and wallet: [`logos-blockchain/logos-execution-zone@d8596eb734bf9c9ce801afb92df06098a2eb098a`](https://github.com/logos-blockchain/logos-execution-zone/tree/d8596eb734bf9c9ce801afb92df06098a2eb098a) (LEZ `v0.2.5-rc2`)
- CLI: [`logos-co/spel@c6f73ce21e4805f8430f03afdbdedf0b7e479a5e`](https://github.com/logos-co/spel/tree/c6f73ce21e4805f8430f03afdbdedf0b7e479a5e) (SPEL CLI `0.7.0`)
- Spec: [`logos-co/rfp@a4323366516228875b61c72d12acb59b3d46cab7`](https://github.com/logos-co/rfp/blob/a4323366516228875b61c72d12acb59b3d46cab7/RFPs/RFP-004-privacy-preserving-dex.md)
- Mode: `RISC0_DEV_MODE=1` (no real proofs), local chain on loopback.

## How to rerun

Unpack `rfp004-14-live-evidence.tar.gz` and follow its build scripts in order (chain, tools, guests, packages), as described in the comment's "Reproduction, environment and evidence" block.

## Files

| File or folder | What it shows |
| --- | --- |
| `explore-after-create.png` | Explore page right after pool creation: the new pool is not listed. |
| `explore-manually-registered.png` | Explore page after the pool was added to the local registry by hand: the pool is listed. |
| `rfp004-14-live-evidence.tar.gz` | Everything else: screenshots of each journey, raw and decoded chain state, the sequencer rejection trace, signed-argument summaries, package hashes, build logs and the build and run scripts. |
