# RFP-004 #48: Reliability rerun (run 2026-11-26-3)

- **Issue:** [iftech/qa-audits#48](https://github.com/iftech/qa-audits/issues/48)
- **QA comment:** Not yet posted at the time of packaging. See [the issue discussion](https://github.com/iftech/qa-audits/issues/48) for the follow-up.
- **Report:** [`2026-11-26-48-combined-audit-report.md`](../../../../../reports/logos/rfp-004-dex/2026-11-26-48-combined-audit-report.md)
- **Run started:** 2026-11-26 14:36:35 UTC (worker run timestamp)

## Code and spec

- Code: [`logos-blockchain/lez-programs@1cfaa5e3446a684e6e9b61cfb243038dae6465ea`](https://github.com/logos-blockchain/lez-programs/tree/1cfaa5e3446a684e6e9b61cfb243038dae6465ea)
- Spec: [`logos-co/rfp@a4323366516228875b61c72d12acb59b3d46cab7`](https://github.com/logos-co/rfp/blob/a4323366516228875b61c72d12acb59b3d46cab7/RFPs/RFP-004-privacy-preserving-dex.md)
- Tools: Bork (the automated audit tool) at `8cd4a026cd5dd0f49d9dc9ce3bf6a0cbaceea2a3`; Rust `1.94.0` (repository pin). The Mac worker had `r0vm` `3.1.0` while the target locked `risc0-zkvm` `3.0.5`.
- Platform: macOS on a Mac mini and a Linux virtual machine for independent verification. OS releases, the Mac mini model and the virtual CPU architecture were not recorded.
- Environment: Container on the Mac (`bork/worker-logos-rfp:risc0`, image ID `sha256:77d39dd2437d4e09e6ad7c9b01ead8a206ea643a5c7cb09764088b13e8408d5b`); synthetic ledger on both hosts. No deployed network.
- Audit settings: full `audit-spec` workflow, RFP-004 [Hard Requirements: Reliability](https://github.com/logos-co/rfp/blob/a4323366516228875b61c72d12acb59b3d46cab7/RFPs/RFP-004-privacy-preserving-dex.md#reliability), R.1–R.4. Scan used Claude Opus 5.5, verify and merge used Claude Sonnet 5.5.

## Why this run

Run the reliability checks that did not execute in the earlier automated audit.

## How to rerun

At the pinned revision, rerun the same stock library check from the repository root:

```sh
RISC0_DEV_MODE=1 cargo test --locked -p amm_program --lib
```

The requirement-specific tests used an audit-only patch. This bundle records their outcomes and does not contain that patch, the internal audit inputs or the worker transcript. The stock library command does not replace the ten requirement tests.

## Results

All ten host-side tests passed on both the Mac worker and the verification virtual machine. The virtual machine also ran the stock library check (149 passed). The Mac scan transcript records its stock library check; the Mac harness did not produce a separate replay or gate log. These are test assertions, not zero-knowledge proofs.

| Requirement | Passed per host | What the tests showed |
| --- | ---: | --- |
| R.1: Pool state | 2 | Sequential swaps preserved consistency, and the second swap rejected a stale quote. The test did not run transactions concurrently or check rollback on a running chain. |
| R.2: Namespace isolation | 2 | Namespaces stayed separate for the tested inputs. The foreign-recipient gap (DEX-04) was confirmed by reading code only, not by these tests. The passing tests do not overturn the earlier report evidence. |
| R.3: Fee split | 1 | The two fee shares added up for the sampled swaps, but the original test would also pass with zero treasury credit. Dust trades that produce zero output were outside the tested cases. |
| R.4: Fee updates | 5 | No instruction changed the fees, and rotating the admin left them unchanged. This confirms only the fee-update part of DEX-01. The original later-swap assertion checked token B, not token A, where the fees had accrued. |

The virtual machine reran stricter checks at the same code revision. R.3 required the exact rounded treasury share and passed (one test). R.4 checked token A's output, reserve, vault and treasury and passed (five tests). These are separate from the original ten tests. Neither run could check whether an actual fee update would affect only later trades.

## Files

| File or folder | What it shows |
| --- | --- |
| [`logs/mac-scan-excerpts.log`](logs/mac-scan-excerpts.log) | Final result table from the Mac scan transcript, not a harness log. |
| [`logs/vm-gate-excerpts.log`](logs/vm-gate-excerpts.log) | Test counts and exit codes for all four requirement suites and the stock library check on the virtual machine. |
| [`logs/vm-follow-up-excerpts.log`](logs/vm-follow-up-excerpts.log) | The stricter R.3 and R.4 checks, run separately on the virtual machine. |
