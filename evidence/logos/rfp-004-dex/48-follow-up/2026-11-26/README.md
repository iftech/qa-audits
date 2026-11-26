# RFP-004 #48: Four finding replays (run 2026-11-26)

- **Issue:** [iftech/qa-audits#48](https://github.com/iftech/qa-audits/issues/48)
- **QA comment:** Not yet posted at the time of packaging. See [the issue discussion](https://github.com/iftech/qa-audits/issues/48) for the follow-up.
- **Report:** [`2026-11-26-48-combined-audit-report.md`](../../../../../reports/logos/rfp-004-dex/2026-11-26-48-combined-audit-report.md)
- **Run started:** 2026-11-26 14:18:55 UTC (first recorded test build; Rust tests began at 14:19:09 UTC).

## Code and spec

- Code: [`logos-blockchain/lez-programs@1cfaa5e3446a684e6e9b61cfb243038dae6465ea`](https://github.com/logos-blockchain/lez-programs/tree/1cfaa5e3446a684e6e9b61cfb243038dae6465ea)
- Spec: [`logos-co/rfp@a4323366516228875b61c72d12acb59b3d46cab7`](https://github.com/logos-co/rfp/blob/a4323366516228875b61c72d12acb59b3d46cab7/RFPs/RFP-004-privacy-preserving-dex.md)
- Tools: Rust `1.94.0` (repository pin); C++17 compiler for the native module harness; Python 3 for source checks.
- Platform: Linux; x86_64, from the active Rust target. The distribution release was not recorded.
- Environment: Local host tests and fixtures, with no sequencer or zero-knowledge proving.

## Why this run

Replay the four automated-audit findings for which no test had replayed successfully.

## How to rerun

At the pinned revision, run the stock Rust suites from the repository root:

```sh
cargo test --locked -p amm_program -p amm_ffi -p stablecoin_program --lib --no-fail-fast
```

That command reruns the stock tests only. The four original checks used additional test fixtures and source assertions not included here. Read [the recorded results](logs/replay-excerpts.log) for their outcomes. A reproduction counted only if the test reached its expected assertion, not if setup failed.

## Results

| Finding | What the replay showed |
| --- | --- |
| DEX-16 | The native exchange module and its Rust interface returned a public wallet holding but hid the same holding when it was marked private. The wallet was a fixture. Source review tied the public list to the swap picker; the run did not drive the QML interface or a private trade. |
| DEX-39 | The exchange's oracle output changed price direction when the pool's token order changed. This host test did not run a stablecoin transaction. |
| DEX-40 | The stablecoin fee accrual test accepted the built-in system clock and rejected a clock at a different address. |
| DEX-41 | The program accepted a fee outside the presets, but the client API still advertised only the old fixed list. Source checks found that the app forwards the list and the interface docs still describe it as enforced by the program. |

Three Rust assertions and one native assertion failed as expected for these findings. The other 515 Rust tests passed, including the fee control. Both source checks confirmed their expected mismatches. The standard Nix C++ suite did not run because the dependency build stopped; it is not part of the result.

## Files

| File or folder | What it shows |
| --- | --- |
| [`logs/replay-excerpts.log`](logs/replay-excerpts.log) | Native assertion, Rust test outcomes, source checks and the interrupted Nix attempt. |
