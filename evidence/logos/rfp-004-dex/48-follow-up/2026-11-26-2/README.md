# RFP-004 #48: Oracle integration rerun (run 2026-11-26-2)

- **Issue:** [iftech/qa-audits#48](https://github.com/iftech/qa-audits/issues/48)
- **QA comment:** Not yet posted at the time of packaging. See [the issue discussion](https://github.com/iftech/qa-audits/issues/48) for the follow-up.
- **Report:** [`2026-11-26-48-combined-audit-report.md`](../../../../../reports/logos/rfp-004-dex/2026-11-26-48-combined-audit-report.md)
- **Run started:** 2026-11-26 14:19 UTC

## Code and spec

- Code: [`logos-blockchain/lez-programs@1cfaa5e3446a684e6e9b61cfb243038dae6465ea`](https://github.com/logos-blockchain/lez-programs/tree/1cfaa5e3446a684e6e9b61cfb243038dae6465ea)
- Spec: [`logos-co/rfp@a4323366516228875b61c72d12acb59b3d46cab7`](https://github.com/logos-co/rfp/blob/a4323366516228875b61c72d12acb59b3d46cab7/RFPs/RFP-004-privacy-preserving-dex.md)
- Runtime: [`logos-blockchain/logos-execution-zone@d8596eb734bf9c9ce801afb92df06098a2eb098a`](https://github.com/logos-blockchain/logos-execution-zone/tree/d8596eb734bf9c9ce801afb92df06098a2eb098a) (`v0.2.5-rc2`, from the lockfile).
- Tools: Rust and Cargo `1.94.0`; RISC Zero host library, `r0vm` and `cargo-risczero` all `3.0.5`; guest Rust `1.97.0`, guest C++ `2024.1.5`.
- Platform: Ubuntu 24.04.5 LTS; x86_64; 12 virtual CPUs and 17 GiB RAM.
- Environment: Local Logos Execution Zone integration harness. No deployed network.

## Why this run

Match the RISC Zero versions to run the oracle integration suites that the earlier automated audit could not run.

## How to rerun

Check out the code pin and install the versions above. From the repository root, run the stock automated market maker (AMM) and stablecoin integration suites. Then run the two stock private cases with proof generation enabled:

```sh
RISC0_DEV_MODE=1 cargo test --locked -p integration_tests --test amm --test stablecoin -- --test-threads=1
RISC0_DEV_MODE=0 RISC0_EXECUTOR=ipc RISC0_PROVER=ipc cargo test --locked -p integration_tests --test amm amm_add_liquidity_private_lp_holding -- --exact --test-threads=1
RISC0_DEV_MODE=0 RISC0_EXECUTOR=ipc RISC0_PROVER=ipc cargo test --locked -p integration_tests --test stablecoin stablecoin_withdraw_collateral_private_destination -- --exact --test-threads=1
```

These commands use the tests shipped with the pinned revision. They do not include the three extra oracle checks from the original run. The excerpt records those outcomes separately.

## Results

In development mode, all 56 AMM, 30 stablecoin and three extra oracle checks passed. With development mode off, nine AMM and three stablecoin public cases passed. Public transitions did not generate proofs. Only two private cases generated and verified real proofs: adding liquidity to a private holding and withdrawing stablecoin collateral to a private holding. The collateral withdrawal was not an oracle read.

A pass here means a test observed the expected behavior, which can confirm an open finding.

| Finding | What the rerun showed |
| --- | --- |
| DEX-05 | Integration: adding and removing liquidity updated the current price tick but did not record an observation or publish a price. |
| DEX-32 | Not rerun: the tests did not exercise publication of a zero price. The [earlier local-chain result](https://github.com/iftech/qa-audits/issues/15#issuecomment-7194782477) stands. |
| DEX-33 | Integration: publication included observations older than the configured averaging window. |
| DEX-34 | Integration: the stablecoin accepted the initial spot price before the oracle had price history. |
| DEX-35 | Not rerun end to end: no test fed a wallet-created price account to the stablecoin. The [earlier local-chain result](https://github.com/iftech/qa-audits/issues/15#issuecomment-7194782477) stands. |
| DEX-36 | Source only: the oracle had no query that accepted a caller's maximum price age. |
| DEX-37 | Integration: the oracle applied the new price tick to the whole interval since the last record. |
| DEX-38 | Source only: the oracle package still defined the price account type used by the stablecoin. |
| DEX-39 | Integration: token order set the direction of the price. The stablecoin accepted the expected order and rejected the reversed order instead of inverting the price. |
| DEX-40 | Source only in this run: fee accrual used the fixed system clock address. The [separate replay](../2026-11-26/) checked that behavior at runtime. |

## Files

| File or folder | What it shows |
| --- | --- |
| [`logs/suite-excerpts.log`](logs/suite-excerpts.log) | Installed tool versions, suite counts, exit codes and the two private proof test timings. |
