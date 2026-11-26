# RFP-004: Privacy-Preserving Decentralized Exchange (DEX)

| Item | Link |
| --- | --- |
| Code | [`logos-blockchain/lez-programs@1cfaa5e3446a684e6e9b61cfb243038dae6465ea`][pin] |
| Specification | [RFP-004 @ `a4323366516228875b61c72d12acb59b3d46cab7`][rfp] |
| Report issue | [iftech/qa-audits#48](https://github.com/iftech/qa-audits/issues/48) |
| Tracking | [Epic #2](https://github.com/iftech/qa-audits/issues/2) |

**Result:** Fail under a retrospective rule. Four High findings drive the result: DEX-01, DEX-08, DEX-16 and DEX-33. No other finding changes the result. The team had not set a pass rule before testing, so this is not a formal verdict against agreed criteria.

**Status:** Final

**Version:** Report v1, 2026-11-26. Includes three follow-up runs at the same code revision. Replaces #9 as the current reference.

## Summary

QA checked [Request for Proposal 004][rfp], the privacy-preserving exchange, at [`lez-programs@1cfaa5e`][pin]. Users cannot make private trades from the client. Admins cannot fully manage fees, and the oracle can average over a longer period than configured.

**Scope:** Rust tests, source checks, local-chain runs and live Basecamp journeys.

**Follow-up coverage:** [Four finding replays][e48-replays] ran against program or client code. [Oracle integration][e48-oracle] ran with matching RISC Zero 3.0.5 tools. [Local reliability tests][e48-reliability] ran for R.1–R.4. The result and finding statuses did not change.

**Not tested:** Public testnet, multi-sequencer load, or fixes. Real proofs were limited to the [private-operation run][i13c] and two cases in the [oracle rerun][e48-oracle]. See [coverage limits](#coverage-limits).

Earlier baseline: [#9][i9].

<details>
<summary>Severity and pass rule</summary>

- **High:** breaks a core requirement, or loses or locks funds.
- **Medium:** a requirement is partly met, or the behaviour is unsafe only in some setups.
- **Low:** a small gap with limited impact.
- **Informational:** no requirement is broken.

This rule was set after testing. Future audits should agree on the rule before testing.

Fail if any High finding labelled Code bug is open; Pass with findings if only Medium, Low or Informational findings are open; Pass if none are open.

</details>

## Counts and results

| Class | High | Medium | Low | Info | Total |
| --- | ---: | ---: | ---: | ---: | ---: |
| Code bug | 4 | 23 | 8 | 1 | 36 |
| Outdated spec | 0 | 0 | 0 | 0 | 0 |
| Unclear spec | 0 | 3 | 5 | 3 | 11 |
| Deferred scope | 0 | 0 | 0 | 0 | 0 |
| **Total** | 4 | 26 | 13 | 4 | 47 |

### Findings index

| ID | Finding | Severity | Status |
|---|---|---|---|
| [DEX-01](#dex-01) | Fees and admin control cannot change fully | High | Open |
| [DEX-02](#dex-02) | No fixed recipient for protocol fees | Medium | Open |
| [DEX-03](#dex-03) | Associated token accounts cannot fund swaps or deposits | Medium | Open |
| [DEX-04](#dex-04) | Swaps can credit another namespace's vault | Low | Open |
| [DEX-05](#dex-05) | Pool actions do not record price history | Medium | Open |
| [DEX-06](#dex-06) | Swaps cannot create a receiving account | Low | Open |
| [DEX-07](#dex-07) | Simultaneous swaps pass on one sequencer only | Medium | Open |
| [DEX-08](#dex-08) | Clients lack namespace admin actions | High | Open |
| [DEX-09](#dex-09) | Swap preview hides the fee split and miscounts small fees | Medium | Open |
| [DEX-10](#dex-10) | Confirmation omits price and expected output | Medium | Open |
| [DEX-11](#dex-11) | Pool analytics are incomplete | Medium | Open |
| [DEX-12](#dex-12) | Swap errors hide the cause | Medium | Open |
| [DEX-13](#dex-13) | Network fee estimates are missing | Medium | Open |
| [DEX-14](#dex-14) | The app hides the active namespace | Low | Open |
| [DEX-15](#dex-15) | Basecamp install guide builds the wrong wallet module | Medium | Open |
| [DEX-16](#dex-16) | Clients cannot run private operations | High | Open |
| [DEX-17](#dex-17) | No preview of private transaction disclosures | Medium | Open |
| [DEX-18](#dex-18) | No check for a private return account | Medium | Open |
| [DEX-19](#dex-19) | No fresh account for each private operation | Medium | Open |
| [DEX-20](#dex-20) | CI skips standalone sequencer tests | Medium | Open |
| [DEX-21](#dex-21) | Some required behaviours have no test | Medium | Open |
| [DEX-22](#dex-22) | Full transactions lack benchmarks | Medium | Open |
| [DEX-23](#dex-23) | Operator guides have broken links and missing steps | Medium | Open |
| [DEX-24](#dex-24) | Test guide wrongly promises wallet encryption | Low | Open |
| [DEX-25](#dex-25) | No deployment address for this revision | Low | Open |
| [DEX-26](#dex-26) | Developer guide submission not found | Low | Open |
| [DEX-27](#dex-27) | App design submission not found | Informational | Open |
| [DEX-28](#dex-28) | A rejected pool creation breaks the new LP account | Medium | Open |
| [DEX-29](#dex-29) | Protocol fee rounds to 0 on small swaps | Informational | Open |
| [DEX-30](#dex-30) | Oversized exact-output swap fails with a panic | Informational | Open |
| [DEX-31](#dex-31) | Rejected actions still charge the signer | Informational | Open |
| [DEX-32](#dex-32) | Published TWAP price can be zero | Medium | Open |
| [DEX-33](#dex-33) | TWAP window comes from the oldest record, not the set window | High | Open |
| [DEX-34](#dex-34) | Seed spot price reads as a fresh TWAP | Medium | Open |
| [DEX-35](#dex-35) | Stablecoin accepts a wallet-created price account after admin selection | Medium | Open |
| [DEX-36](#dex-36) | Oracle has no TWAP query with a maximum age | Medium | Open |
| [DEX-37](#dex-37) | Record step credits a new tick with the whole gap | Medium | Open |
| [DEX-38](#dex-38) | Price account type lives in the TWAP program crate | Low | Open |
| [DEX-39](#dex-39) | Price direction follows pool token order | Low | Open |
| [DEX-40](#dex-40) | Stablecoin uses a fixed clock account | Low | Open |
| [DEX-41](#dex-41) | Module and app still show the old fee-tier list | Low | Open |
| [DEX-42](#dex-42) | Rejected swap looks successful | Medium | Open |
| [DEX-43](#dex-43) | LP lock is missing from the confirmation | Low | Open |
| [DEX-44](#dex-44) | New pool does not appear in Explore or Positions | Medium | Open |
| [DEX-45](#dex-45) | Token decimals are ignored | Medium | Open |
| [DEX-46](#dex-46) | Balances stay stale after a trade | Low | Open |
| [DEX-47](#dex-47) | Remove-liquidity view keeps old balances and reserves | Low | Open |

<details>
<summary>Evidence breakdown and finding labels</summary>

| Strongest evidence per finding | Count |
|---|---:|
| Live journey (Basecamp on a local chain) | 7 |
| Runtime log (local-chain transactions) | 11 |
| Oracle integration test | 3 |
| Host replay (runs program or client code) | 2 |
| Bork proof test (runs program or client code) | 13 |
| Source only (Bork source check) | 6 |
| Source only (other) | 5 |

A Bork source check reads source code or docs. It does not run the program or client. Bork used direct tests or development mode, not real proving.

**Triage:** Code bug means the code should change. Outdated spec means the code follows an agreed design and the spec needs updating. Unclear spec means the spec owner must decide. Deferred scope means the spec owner has moved the work to a later milestone.

**Status:** Open means the finding is unresolved. Mark it Fixed only after checking the fix and naming the fix commit.

IDs DEX-01 to DEX-27 keep the numbers from [#9][i9]. DEX-28 and later are new. QA assigned severity to DEX-42 through DEX-47 because [#14][i14] did not provide it. Other severities come from the source reports.

</details>

## Findings

If a finding link does not open its group, expand the area below.

[Program](#findings-program) · [Public client (SDK and app)](#findings-public-client) · [Private client](#findings-private-client) · [Tests and docs](#findings-tests-and-docs) · [New runtime findings](#findings-runtime) · [Oracle chain](#findings-oracle) · [Basecamp app (live)](#findings-basecamp)

<a id="findings-program"></a>

<details>
<summary>Program: findings and evidence</summary>

<a id="dex-01"></a>

### DEX-01: Fees and admin control cannot change fully

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| High | Open | Code bug | F.6, F.11, R.4, U.12, S.5 | Bork proof test | [code][c-upd], [#9][i9] |

`Initialize` writes the trading fee and protocol fee once; `UpdateConfig` only moves the admin key. No instruction sets either fee, sets a treasury, or renounces admin. Add these instructions and test that earned fees do not change.

<details>
<summary>Evidence</summary>

- Code: [`update_config.rs:23-52`][c-upd], [`core/src/lib.rs:36-290`][c-core-ix].
- Bork findings F-ff177004, F-8cdb0cf8, F-34241e3b, F-365f31bf: each Rust test calls the program and fails on its own assertion (exit 101).
- The [R.4 reliability tests][e48-reliability] confirmed the fee-update gap: rotating the admin kept fees unchanged. There is no fee-update instruction, so the run could not test whether an update affects only later trades.
- First reported as DEX-01 in [#9][i9].

</details>

<a id="dex-02"></a>

### DEX-02: No fixed recipient for protocol fees

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Code bug | F.11, F.13, F.14 | Bork proof test | [code][c-core-fee], [#9][i9], [#12][i12c], [files][e12] |

The namespace config stores no treasury address. A protocol-fee withdrawal goes to any holding the caller supplies. Store the treasury in the config and reject other destinations.

<details>
<summary>Evidence</summary>

- Code: [`core/src/lib.rs:584-605`][c-core-fee]. Bork F-00ce0ca6 (Rust test, exit 101).
- [#12][i12c] found that this revision does check the supplied fee account address, and asks the spec owner whether that is enough (decision 5).

</details>

<a id="dex-03"></a>

### DEX-03: Associated token accounts cannot fund swaps or deposits

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Code bug | F.8 | Bork proof test | [#9][i9] |

A swap or deposit authorised by the owner of an associated token account (ATA) is refused. Accept ATA owner authorisation in both paths.

<details>
<summary>Evidence</summary>

- Bork proof test from the 2026-11-24 run, reported in [#9][i9]. The 2026-11-25 rerun did not raise it again, so it has one test run only.

</details>

<a id="dex-04"></a>

### DEX-04: Swaps can credit another namespace's vault

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Low | Open | Code bug | R.2, F.14 | Bork proof test | [Bork report][i9], [NS-03 runtime files][e12], [AMM source][c-swap-user] |

Keep DEX-04 as a code bug. Both swap modes accepted a foreign vault as the recipient in direct AMM tests. NS-03 still passes: it checked that the pool rejects a replacement for one of its own vaults, not that it rejects a foreign recipient.

<details>
<summary>Evidence</summary>

- Bork proof test `F-5c24fe5b` from the 2026-11-24 run, reported in [#9][i9]; it was not raised again on 2026-11-25.
- The original Bork patch was not present in the available checkout, so its exact mode and direction could not be independently recovered. Its finding text says the foreign account was used as the recipient, which is distinct from NS-03's pool-vault argument.
- At the pinned revision, the AMM accepted a synthetic foreign vault in either user holding slot in both modes. All four rejection assertions failed; the other 149 tests passed. These tests called the AMM directly. They did not execute the chained token transfers or show a balance change on a running chain.
- Follow-up results from `RISC0_DEV_MODE=1 cargo test -p amm_program -- --nocapture`: exact-input/foreign input — accepted (error text: `none`); exact-input/foreign output — accepted (`none`); exact-output/foreign input — accepted (`none`); exact-output/foreign output — accepted (`none`). The assertion failures are the expected evidence that the requested rejection is missing.
- The AMM checks the user holdings' Token Program ownership but does not reject a vault from another namespace ([`swap.rs:216–223`][c-swap-user], [`swap.rs:496–503`][c-swap-user-out]). Both modes use the supplied recipient in the chained output transfer ([`swap.rs:383–407`][c-swap-transfer-in], [`swap.rs:660–684`][c-swap-transfer-out]). The input-side result does not show that an unauthorized debit can succeed; the Token Program still checks sender authorization.
- NS-03 in [#12][i12c] was a different case: it used exact-input A→B, but supplied namespace B's vault in the pool's `vault_b` account slot. `validate_swap_setup` rejected it at [`swap.rs:27-34`][c-swap-vaults] with `Vault B was not provided`, before the user holding slots were examined. It did not test a foreign recipient or input holding, so it does not contradict DEX-04.
- The [R.2 reliability rerun][e48-reliability] checked the foreign-recipient gap in source only. Its passing namespace tests did not exercise that case.

</details>

<a id="dex-05"></a>

### DEX-05: Pool actions do not record price history

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Unclear spec | RFP-004 F.10, RFP-019 F.1 | Runtime log | [code][c-swap-tick], [#15][i15], [files][e15] |

Swaps and liquidity changes update only the current tick. A price observation is added, and a price published, only when someone separately calls `RecordTick` and `PublishPrice`. Either update both specs to describe this separate step, or record the observation inside each pool action (decision 1).

<details>
<summary>Evidence</summary>

- Runtime ([#15][i15] runtime check, [`checks.tsv`][e15c]): swaps changed the current tick but not the observation buffer or the published price (checks A1, A2, A3). After `RecordTick`, `PublishPrice` updated the price.
- [Oracle integration][e48-oracle]: adding and removing liquidity also updated the tick without recording an observation or publishing a price.
- Code: [`swap.rs:121-142`][c-swap-tick]. Bork F-f78733f5 (Rust test, exit 101).
- [#9][i9] called this an outdated spec. RFP-019 F.1 says no off-chain keeper should be needed, so the spec owner must choose.

</details>

<a id="dex-06"></a>

### DEX-06: Swaps cannot create a receiving account

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Low | Open | Unclear spec | P.1, P.1 (perf), F.4 | Runtime log | [code][c-swap-out], [#13][i13c], [files][e13] |

A swap needs the output holding to exist already, so a first-time buyer needs an extra transaction. In [#13][i13c], a private swap into a new private holding was refused for the same reason. Decide whether P.1 requires creating the holding (decision 2).

<details>
<summary>Evidence</summary>

- Runtime: [#13][i13c] rows 28 and 29.
- Code: [`swap.rs:216-223`][c-swap-out]. Bork F-227cc351: the test shows the behaviour, but the Bork verifier disputed that it breaks the requirement.

</details>

<a id="dex-07"></a>

### DEX-07: Simultaneous swaps pass on one sequencer only

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Unclear spec | R.1 | Runtime log | [#12][i12c], [files][e12] |

Concurrent swaps in [#12][i12c] (CONC-01) gave correct balances on one dev-mode sequencer. Nothing tested more load or more than one sequencer. Decide what load R.1 needs (decision 6).

</details>

<a id="findings-public-client"></a>

<details>
<summary>Public client (SDK and app): findings and evidence</summary>

<a id="dex-08"></a>

### DEX-08: Clients lack namespace admin actions

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| High | Open | Code bug | U.12 | Bork proof test | [code][c-ffi-mod], [#9][i9] |

The SDK has no builder for `Initialize` (namespace creation), and the mini-app has no admin screen. Add namespace creation and admin actions to each required client.

<details>
<summary>Evidence</summary>

- Code: [`ffi/src/api/mod.rs:80-220`][c-ffi-mod]. Bork F-44d7ce20 (Rust test, exit 101).

</details>

<a id="dex-09"></a>

### DEX-09: Swap preview hides the fee split and miscounts small fees

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Code bug | U.9, U.11, F.6 | Live journey | [code][c-ffi-swap], [#14][i14live], [files][e14] |

The SDK quote does not return the fee or its LP and protocol shares, and the app never shows the protocol fee. The preview computes the fee with floating point, so a 100-unit swap showed **0.300000 QAA** while the chain charged 1 raw unit. Return the integer fee and split from the SDK and show them.

<details>
<summary>Evidence</summary>

- Live: [#14][i14live], "Small-swap fee rounding" (M1-004-05).
- Code: [`ffi/src/api/swap.rs:148-213`][c-ffi-swap], [`DummySwapState.qml:16-18`][c-dummy], [`PoolsPage.qml:33-53`][c-poolspage].
- Bork F-b80cae7f (Rust test), F-4e83594e and F-96ccd500 (source checks).

</details>

<a id="dex-10"></a>

### DEX-10: Confirmation omits price and expected output

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Code bug | U.9 | Source only (Bork source check) | [code][c-summary], [#9][i9] |

The swap preview and confirmation show no effective price. Show the price and the expected output in both swap modes. Code: [`SwapSummary.qml`][c-summary]; Bork F-2497d74d.

<a id="dex-11"></a>

### DEX-11: Pool analytics are incomplete

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Code bug | U.5, U.11 | Source only (Bork source check) | [code][c-pooldetail], [#9][i9] |

Pool detail shows only an LP fee estimate, with no volume, total value locked or protocol fee revenue. Add these values. Code: [`PoolDetailPage.qml:12-16`][c-pooldetail]; Bork F-5163eacb.

<a id="dex-12"></a>

### DEX-12: Swap errors hide the cause

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Code bug | U.7 | Source only (Bork source check) | [code][c-swapcard], [#9][i9] |

Every swap failure shows **Swap failed (empty response from sequencer).** Show the planning, wallet or sequencer cause. Code: [`SwapCard.qml:516-548`][c-swapcard]; Bork F-6752791b.

<a id="dex-13"></a>

### DEX-13: Network fee estimates are missing

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Code bug | U.8 | Source only (Bork source check) | [code][c-summary], [#14][i14live], [files][e14] |

No network fee estimate appears before a swap, pool creation or liquidity change. The live case in [#14][i14live] was blocked because the screen does not exist. Code: [`SwapSummary.qml:58-80`][c-summary]; Bork F-69df3aa8.

<a id="dex-14"></a>

### DEX-14: The app hides the active namespace

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Low | Open | Code bug | U.10 | Source only (Bork source check) | [code][c-backend], [#9][i9] |

The user cannot pick a namespace or see which one is active. Add a selector and a label. Code: [`AmmUiBackend.cpp:55-62`][c-backend]; Bork F-694a7870.

<a id="dex-15"></a>

### DEX-15: Basecamp install guide builds the wrong wallet module

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Code bug | U.2 | Source only | [#14][i14src], [#9][i9] |

The pinned guide builds `logos_execution_zone` 1.0.0 instead of the required `lez_core` 0.4.2, and omits a package. Fix the guide and check it on a clean Basecamp install. Sources: [#14][i14src] M1-004-07, [#9][i9]; the live run used a corrected setup, so this was not run live.

</details>

<a id="findings-private-client"></a>

<details>
<summary>Private client: findings and evidence</summary>

<a id="dex-16"></a>

### DEX-16: Clients cannot run private operations

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| High | Open | Code bug | F.1, F.3, F.4, U.1, Privacy.1 | Runtime log | [code][c-module], [#13][i13c], [files][e13] |

The programs accept private inputs: 36 tests passed in dev mode and with real proofs. But the SDK and app drop private holdings and send only public transactions, so there is no deshield → swap → re-shield flow. Add the private client path; this becomes deferred scope only if the spec owner defers it (decision 3).

<details>
<summary>Evidence</summary>

- Runtime: [#13][i13c] QA13-01 (program passes) and QA13-02 (7 client cases blocked).
- Code: [`amm_module_impl.cpp:371-391`][c-module]. In the [host replay][e48-replays], the exchange module showed a fixture holding marked public and omitted the same holding when the fixture marked it private. The replay did not run the full app or a trade.

</details>

<a id="dex-17"></a>

### DEX-17: No preview of private transaction disclosures

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Code bug | Privacy.2 | Bork proof test | [code][c-confsum], [#9][i9] |

The confirmation does not list what will be public on-chain and what stays private. Add that list. Code: [`SwapConfirmationSummary.qml:61-126`][c-confsum]; Bork F-f9e9112d. Same decision 3 applies to DEX-17 to DEX-19.

<a id="dex-18"></a>

### DEX-18: No check for a private return account

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Code bug | Privacy.3 | Bork proof test | [code][c-ffi-swap-out], [#9][i9] |

The SDK plans and sends a swap whose output goes to a public holding without warning. Reject a public return account before submission. Code: [`ffi/src/api/swap.rs:340-375`][c-ffi-swap-out]; Bork F-ea1fde0e.

<a id="dex-19"></a>

### DEX-19: No fresh account for each private operation

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Code bug | Privacy.4 | Bork proof test | [code][c-liq], [#13][i13c], [files][e13] |

Plans reuse the user's holdings as signers instead of a fresh, unused public account. Note from [#13][i13c] QA13-04: anyone can send tokens to a fresh public account, so "unused" must be checked just before use. Code: [`ffi/src/api/liquidity.rs:378-392`][c-liq]; Bork F-3fea7038.

</details>

<a id="findings-tests-and-docs"></a>

<details>
<summary>Tests and docs: findings and evidence</summary>

<a id="dex-20"></a>

### DEX-20: CI skips standalone sequencer tests

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Code bug | S.2 | Bork proof test | [code][c-ci], [#9][i9] |

The sequencer-backed end-to-end suite runs only by hand; CI never runs it. Add it to CI. Code: [`ci.yml:193-214`][c-ci]; Bork F-1075811c.

<a id="dex-21"></a>

### DEX-21: Some required behaviours have no test

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Code bug | S.4 | Source only | [#9][i9], [#13][i13c], [files][e13] |

Several hard requirements have no runnable test; [#9][i9] lists them. One example from [#13][i13c] QA13-03: no test pays a private swap into an existing private holding. Add a test for each listed requirement.

<a id="dex-22"></a>

### DEX-22: Full transactions lack benchmarks

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Code bug | P.3 | Bork proof test | [code][c-guest], [#13][i13c], [files][e13] |

No compute or transaction-size figures exist for swap, liquidity changes or pool creation. [#13][i13c] QA13-05 measured that real proving is slow and needs a lot of memory, which shows why the figures matter. Code: [`guest/src/bin/amm.rs:168-389`][c-guest]; Bork F-9a348921.

<a id="dex-23"></a>

### DEX-23: Operator guides have broken links and missing steps

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Code bug | S.5, S.7, U.6 | Source only (Bork source check) | [code][c-mod-readme], [#14][i14src] |

The READMEs point to CLI and protocol-fee guides that do not exist. No guide explains namespace creation, address derivation, or what each action reveals on-chain. The v0.2.5 guide points to the legacy v0.2.4 endpoint ([#14][i14src] M1-004-08).

<details>
<summary>Evidence</summary>

- Code: [`modules/amm/README.md:66-67`][c-mod-readme], [`apps/amm/README.md:216-240`][c-app-readme].
- Bork F-3e723097, F-b3923ec1 (Rust tests that read the docs), F-f8e42079 (source check).

</details>

<a id="dex-24"></a>

### DEX-24: Test guide wrongly promises wallet encryption

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Low | Open | Code bug | S.5 | Source only | [#9][i9] |

The test guide says wallet storage is password-protected; the wallet does not encrypt it. Correct the guide. Source: [#9][i9]; not raised again by Bork on 2026-11-25.

<a id="dex-25"></a>

### DEX-25: No deployment address for this revision

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Low | Open | Code bug | S.1, S.5 | Bork proof test | [code][c-cargo], [#10][i10c], [files][e10] |

The repository records only a v0.2.4 legacy deployment, not one for the v0.2.5 AMM. QA deployed it only on a local chain ([#10][i10c]). Publish the testnet address and its test results. Code: [`programs/amm/Cargo.toml:10-11`][c-cargo]; Bork F-8ad02687.

<a id="dex-26"></a>

### DEX-26: Developer guide submission not found

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Low | Open | Unclear spec | S.6 | Source only | [#9][i9] |

QA found no developer guide submission. It may sit outside the repository; the spec owner should say where (decision 7).

<a id="dex-27"></a>

### DEX-27: App design submission not found

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Informational | Open | Unclear spec | S.8 | Bork proof test | [code][c-app-readme], [#9][i9] |

The repository has no Figma link, mockup or screenshot for the mini-app. It may be submitted elsewhere (decision 7). Code: [`apps/amm/README.md:1-30`][c-app-readme]; Bork F-377cb6ea.

</details>

<a id="findings-runtime"></a>

<details>
<summary>New runtime findings: findings and evidence</summary>

<a id="dex-28"></a>

### DEX-28: A rejected pool creation breaks the new LP account

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Code bug | F.2 | Runtime log | [#11][i11c], [files][e11] |

Pool creation needs the new LP account to sign. If the transaction is rejected, LEZ still raises that account's nonce, and the token program then refuses it as "not new", so the user must pick a new LP account. Accept an empty account with a non-zero nonce, or let the user retry. Source: [#11][i11c] F1, cases C03, C04, C04b.

<a id="dex-29"></a>

### DEX-29: Protocol fee rounds to 0 on small swaps

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Informational | Open | Unclear spec | F.11 | Runtime log | [#11][i11c], [files][e11] |

`protocol_fee_amount` rounds down, so a swap with a fee of 2 or 3 raw units pays no protocol fee. Decide whether rounding down is intended (decision 8). Source: [#11][i11c] F2, cases C10, C25.

<a id="dex-30"></a>

### DEX-30: Oversized exact-output swap fails with a panic

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Informational | Open | Code bug | U.7 | Runtime log | [#11][i11c], [files][e11] |

An exact-output swap that needs more than a u128 input hits an overflow panic in `mul_div_ceil`, not a clear error. Return a named error. Source: [#11][i11c] F3, case C38.

<a id="dex-31"></a>

### DEX-31: Rejected actions still charge the signer

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Informational | Open | Unclear spec | R.3 | Runtime log | [#12][i12c], [files][e12] |

A rejected action is still included in a block. Program state rolls back, but the signer's nonce and fee still change. Decide whether R.3 "rollback" allows this (decision 4). Source: [#12][i12c].

</details>

<a id="findings-oracle"></a>

<details>
<summary>Oracle chain: findings and evidence</summary>

<a id="dex-32"></a>

### DEX-32: Published TWAP price can be zero

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Code bug | RFP-019 F.4 | Runtime log | [code][c-publish], [#15][i15], [files][e15] |

For ticks below about −443,636, `PublishPrice` stores a price of 0. RFP-019 F.4 says to reject a zero price before writing it. Reject it.

<details>
<summary>Evidence</summary>

- Runtime ([#15][i15] runtime check, [`checks.tsv`][e15c]): checks Z1 (publish accepted) and Z1b (stored price 0).
- The [oracle rerun][e48-oracle] did not cover this very-low-tick case. The local-chain result still stands.
- Code: [`publish_price.rs:228-234`][c-publish]. Bork F-bee745cf (Rust test, exit 101).

</details>

<a id="dex-33"></a>

### DEX-33: TWAP window comes from the oldest record, not the set window

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| High | Open | Code bug | RFP-019 F.1, F.3 | Oracle integration test | [code][c-publish-win], [rerun][e48-oracle] |

`PublishPrice` averages from the oldest buffer entry instead of `window_duration`. The integration test confirmed that the average included observations older than the configured window. Average over the configured window.

<a id="dex-34"></a>

### DEX-34: Seed spot price reads as a fresh TWAP

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Unclear spec | RFP-019 F.1, F.4 | Runtime log | [code][c-create-opa], [#15][i15], [files][e15] |

Creating the price account writes the current spot price with a fresh timestamp. The stablecoin cannot tell it from a real TWAP. Decide whether a seed price is allowed before the first TWAP (decision 9).

<details>
<summary>Evidence</summary>

- Runtime ([#15][i15] runtime check, [`checks.tsv`][e15c]): the AMM created the price account with a seed price that the stablecoin read.
- [Oracle integration][e48-oracle] confirmed that the stablecoin accepts the initial spot price before the oracle has price history.
- Code: [`create_oracle_price_account.rs:83-101`][c-create-opa]. Bork F-d7672a36.

</details>

<a id="dex-35"></a>

### DEX-35: Stablecoin accepts a wallet-created price account after admin selection

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Code bug | RFP-019 F.5 | Runtime log | [code][c-twap-core], [#15][i15], [files][e15] |

The TWAP oracle has no owner or source registry. In the runtime check, a wallet created a price account with the right token pair. The stablecoin read it after an admin selected it. Add the owner-managed source list, and decide whether the stablecoin should also pin the source (decision 10).

<details>
<summary>Evidence</summary>

- Runtime ([#15][i15] runtime check, [`checks.tsv`][e15c]): An admin selected the wallet-created account (P2). The stablecoin then read its price (P3).
- The [oracle rerun][e48-oracle] did not test this path end to end. The local-chain result still stands.
- Code: [`twap_oracle/core/src/lib.rs:28-172`][c-twap-core]. Bork F-5901978a.

</details>

<a id="dex-36"></a>

### DEX-36: Oracle has no TWAP query with a maximum age

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Code bug | RFP-019 F.3, F.6 | Bork proof test | [code][c-twap-core] |

There is no query that returns the TWAP with its observation times, and no `maxAge` parameter. Add it. Code: [`twap_oracle/core/src/lib.rs:28-172`][c-twap-core]; Bork F-2ef6b4a6.

The [oracle rerun][e48-oracle] confirmed the missing query by reading source only.

<a id="dex-37"></a>

### DEX-37: Record step credits a new tick with the whole gap

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Code bug | RFP-019 F.1 | Oracle integration test | [code][c-record], [rerun][e48-oracle] |

`RecordTick` ignores `last_updated`. The integration test confirmed that the newest tick counted for the whole time since the last record. Use the tick's own update time.

<a id="dex-38"></a>

### DEX-38: Price account type lives in the TWAP program crate

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Low | Open | Unclear spec | RFP-019 F.4 | Source only | [code][c-opa-type] |

`OraclePriceAccount` is defined in `twap_oracle_core`, so the stablecoin depends on the TWAP crate. The [oracle rerun][e48-oracle] confirmed this by reading source only. Decide whether F.4's "standard" account must live in a shared crate.

<a id="dex-39"></a>

### DEX-39: Price direction follows pool token order

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Low | Open | Unclear spec | RFP-019 F.4 | Oracle integration test | [code][c-amm-opa], [#15][i15], [rerun][e48-oracle] |

The [host replay][e48-replays] confirmed that pool token order sets the price direction. The oracle integration test also confirmed that the stablecoin accepts the expected order and rejects the reversed order rather than inverting the price. Decide which token is base (decision 11).

<a id="dex-40"></a>

### DEX-40: Stablecoin uses a fixed clock account

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Low | Open | Unclear spec | RFP-013 F.8 | Host replay | [code][c-clock], [replay][e48-replays] |

The stablecoin uses a fixed system clock, while RFP-013 F.8 asks for a clock set per deployment. The host replay accepted the fixed clock and rejected another clock address. The [oracle rerun][e48-oracle] confirmed the fixed address by reading source only. Confirm whether one fixed system clock is acceptable.

<a id="dex-41"></a>

### DEX-41: Module and app still show the old fee-tier list

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Low | Open | Code bug | F.11 | Host replay | [code][c-fee-tiers], [replay][e48-replays] |

The host replay confirmed that the program accepts a fee outside the fixed list that the client API still advertises. Source checks traced the list to the app and found that the interface docs still describe it as enforced by the program. Remove the fixed list.

</details>

<a id="findings-basecamp"></a>

<details>
<summary>Basecamp app (live): findings and evidence</summary>

<a id="dex-42"></a>

### DEX-42: Rejected swap looks successful

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Code bug | U.7 | Live journey | [#14][i14live], [files][e14] |

An over-balance swap was included in block 519 and rejected with **Insufficient balance**, but the app showed a green **Swap submitted** and no error. Show the result as pending until execution is known. Source: [#14][i14live] M1-004-01.

<a id="dex-43"></a>

### DEX-43: LP lock is missing from the confirmation

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Low | Open | Code bug | U.9 | Live journey | [#14][i14live], [files][e14] |

The pool creation form shows the 1,000 raw LP lock; the final confirmation does not. Show it in the confirmation. Source: [#14][i14live] M1-004-02.

<a id="dex-44"></a>

### DEX-44: New pool does not appear in Explore or Positions

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Code bug | U.5 | Live journey | [#14][i14live], [files][e14] |

After a confirmed pool creation, Explore and Positions were empty. It appeared only after editing the local registry and restarting. Discover confirmed pools automatically. Source: [#14][i14live] M1-004-03.

<a id="dex-45"></a>

### DEX-45: Token decimals are ignored

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Medium | Open | Code bug | U.9 | Live journey | [#14][i14live], [files][e14] |

The app showed 100 raw units as **100 QAA**, although QAA has two decimals (so 1.00 QAA). Apply each token's decimals. Source: [#14][i14live] M1-004-04.

<a id="dex-46"></a>

### DEX-46: Balances stay stale after a trade

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Low | Open | Code bug | U.5 | Live journey | [#14][i14live], [files][e14] |

Trade and New Position kept showing 1,000,000 raw units after the balances changed on-chain. Refresh after each executed transaction. Source: [#14][i14live] M1-004-06.

<a id="dex-47"></a>

### DEX-47: Remove-liquidity view keeps old balances and reserves

| Severity | Status | Triage | Requirement | Evidence type | Links |
|---|---|---|---|---|---|
| Low | Open | Code bug | U.5 | Live journey | [#14][i14live], [files][e14] |

A funded LP holding showed zero until the user switched away and back. After removal, pool detail kept the old reserves and supply until reopened. Refresh both after execution. Source: [#14][i14live], new in the live run.

</details>

<details>
<summary>Checked and not a defect</summary>

- Pool creation, exact-input and exact-output swaps, and adding and removing liquidity matched quotes on the local chain and in Basecamp ([#10][i10c], [#11][i11c] 41 of 42 cases, [#14][i14live] 7 passes). C20 was rejected for insufficient balance, so it did not verify the exact-input deadline check.
- Authorisation, namespace and rollback cases: 12 of 12 passed ([#12][i12c]). The run marked AUTH-02, AUTH-04 and NS-01 as Blocked. They count as passes after review of the rejection logs. The Token Program ownership check rejected NS-01, so the case did not verify the protocol-fee address check.
- Private and group-authority program flows: 36 tests passed in dev mode and with real proofs ([#13][i13c]).
- The [#15 source review][i15c] found no mismatch in spot-price direction and encoding, time units, price scaling, or ownership of AMM-created price accounts. In the [runtime checks][e15c], publishing rejected stale observations. Strict stablecoin reads rejected stale or absent prices. Soft reads succeeded without changing redemption. Acceptance of a wallet-sourced price after admin selection is tracked in [DEX-35](#dex-35).

</details>

<a id="coverage-limits"></a>
<details>
<summary>Limits</summary>

- Bork used dev-mode or native tests, not real proving. At least 10 of its 35 replayed tests read source or docs text; they show something is missing in the source, not runtime behaviour.
- The first oracle run had mismatched RISC Zero tools. The [follow-up][e48-oracle] used matching 3.0.5 tools and ran the integration suites. It did not retest DEX-32 or DEX-35 end to end; the [#15 runtime results][e15] still apply. Only two cases generated real proofs in the follow-up: adding liquidity and withdrawing collateral into private holdings.
- The first automated run did not test reliability. The [follow-up][e48-reliability] ran ten local tests across R.1–R.4. R.1 checked sequential swaps and stale-quote rejection, not concurrent swaps. Stricter checks also passed for the exact treasury share (R.3) and token A fee accounting (R.4). These were local test assertions, not real proofs or a check of fee updates on later trades.
- The [four replays][e48-replays] ran program or client code, not the full app or a private trade.
- Tests on a running chain used one local sequencer. No public testnet or multi-sequencer load tests ran.
- C20 in [#11][i11c] did not verify the exact-input deadline check. NS-01 in [#12][i12c] did not verify the protocol-fee address check.
- Bork runs used Claude models to write and check findings; each finding was then matched by hand to the earlier reports.

</details>

<details>
<summary>Glossary</summary>

- **RFP**: the published request that defines what the DEX must do. F, U, R, P, S and Privacy numbers are its sections (functionality, usability, reliability, performance, supportability, privacy).
- **LEZ**: the Logos Execution Zone, the chain these programs run on. **Sequencer**: the node that orders transactions into blocks.
- **Namespace**: a group of pools with its own fees and admin.
- **AMM**: automated market maker. **TWAP**: time-weighted average price. **Tick**: the pool's price as a log-scale number. **Crank**: a separate call that anyone must make to move a process on.
- **Bork**: an automated audit tool that writes a finding, a proof test, and a check by a second model.
- **Deshield / re-shield**: move tokens from a private holding to a public one, and back.
- **Dev mode**: proofs are skipped so tests run fast. **Real proving** creates the zero-knowledge proof.

</details>

## Evidence

| Issue | Run | What it shows |
| --- | --- | --- |
| [#10 Pinned test environment](https://github.com/iftech/qa-audits/issues/10) | [2026-11-25](../../../evidence/logos/rfp-004-dex/10-pinned-environment/2026-11-25/) | Pins and local-chain setup |
| [#11 Public market maker flows](https://github.com/iftech/qa-audits/issues/11) | [2026-11-25](../../../evidence/logos/rfp-004-dex/11-public-amm-flows/2026-11-25/) | Swap and liquidity results on the local chain |
| [#12 Authorization and rollback](https://github.com/iftech/qa-audits/issues/12) | [2026-11-25](../../../evidence/logos/rfp-004-dex/12-authorization-rollback/2026-11-25/) | Namespace checks, rollback and concurrency |
| [#13 Private and group authority](https://github.com/iftech/qa-audits/issues/13) | [2026-11-25](../../../evidence/logos/rfp-004-dex/13-private-group-authority/2026-11-25/) | Private operations and real-proof results |
| [#14 Basecamp journeys](https://github.com/iftech/qa-audits/issues/14) | [2026-11-25](../../../evidence/logos/rfp-004-dex/14-live-basecamp/2026-11-25/) | Live client checks |
| [#15 Cross-RFP oracle checks](https://github.com/iftech/qa-audits/issues/15) | [2026-11-25](../../../evidence/logos/rfp-004-dex/15-oracle-wiring/2026-11-25/) | Oracle and stablecoin results on the local chain |
| [#48 Follow-up][i48-follow-up] | [Four finding replays][e48-replays] | Program and client checks for DEX-16, DEX-39, DEX-40 and DEX-41 |
| [#48 Follow-up][i48-follow-up] | [Oracle integration][e48-oracle] | Matching RISC Zero tools, oracle and stablecoin tests, and two private proofs |
| [#48 Follow-up][i48-follow-up] | [Reliability][e48-reliability] | Local tests for R.1–R.4 and stricter checks for the treasury share and fee accounting |

<details>
<summary>How to reproduce the runtime and live checks</summary>

- **Runtime and live checks**: each issue has a folder under [`evidence/logos/rfp-004-dex/`][ev] ([#10][e10], [#11][e11], [#12][e12], [#13][e13], [#14][e14], [#15][e15]). Its `README.md` lists the pins, the script and how to rerun it. The [#10 folder][e10] explains how to build the pinned local chain.
- **Oracle runtime check (#15)**: run `run-oracle-wiring.sh` from the [#15 folder][e15] with the #10 builds; [`checks.tsv`][e15c] lists each expected and observed result.
- **Follow-up checks (#48):** the [replay][e48-replays], [oracle][e48-oracle] and [reliability][e48-reliability] folders record the tool versions, test results and commands for the tests available in the public repository.
- **Automated audit (Bork):** The full patches, commands, environment and tool settings are in an internal QA workspace and are not public. The finding details link to public source and audit evidence where available.

</details>

## Decisions for the specification owner

1. RFP-004 F.10 and RFP-019 F.1: must each pool action record the price observation, or is a separate permissionless `RecordTick` call acceptable? (DEX-05)
2. P.1: must a swap create the receiving holding, including a new private holding? (DEX-06)
3. Are the private client paths (DEX-16 to DEX-19) due in this milestone or a later one?
4. R.3: is it acceptable that a rejected action still changes the signer's nonce and fee? (DEX-31)
5. F.11: is checking the supplied fee account address enough, or must the config store a treasury? (DEX-02)
6. R.1: what load and how many sequencers must the concurrency test use? (DEX-07)
7. S.6 and S.8: where are the developer guide and the app design submitted? (DEX-26, DEX-27)
8. F.11: should the protocol fee round down to 0 on small swaps? (DEX-29)
9. RFP-019: may the price account hold a seed spot price before the first TWAP? (DEX-34)
10. RFP-019 F.5: should the stablecoin pin the price source, or trust any oracle-owned account with the right pair? (DEX-35)
11. RFP-019 F.4: which token is base when the pool's token order differs from the stablecoin's pair? (DEX-39)
12. RFP-019 F.4 and RFP-013 F.8: must the price account type sit in a shared crate, and may the clock be fixed? (DEX-38, DEX-40)


[pin]: https://github.com/logos-blockchain/lez-programs/tree/1cfaa5e3446a684e6e9b61cfb243038dae6465ea
[rfp]: https://github.com/logos-co/rfp/blob/a4323366516228875b61c72d12acb59b3d46cab7/RFPs/RFP-004-privacy-preserving-dex.md
[e10]: ../../../evidence/logos/rfp-004-dex/10-pinned-environment/2026-11-25
[e11]: ../../../evidence/logos/rfp-004-dex/11-public-amm-flows/2026-11-25
[e12]: ../../../evidence/logos/rfp-004-dex/12-authorization-rollback/2026-11-25
[e13]: ../../../evidence/logos/rfp-004-dex/13-private-group-authority/2026-11-25
[e14]: ../../../evidence/logos/rfp-004-dex/14-live-basecamp/2026-11-25
[e15]: ../../../evidence/logos/rfp-004-dex/15-oracle-wiring/2026-11-25
[e15c]: ../../../evidence/logos/rfp-004-dex/15-oracle-wiring/2026-11-25/checks.tsv
[e48-replays]: ../../../evidence/logos/rfp-004-dex/48-follow-up/2026-11-26/
[e48-oracle]: ../../../evidence/logos/rfp-004-dex/48-follow-up/2026-11-26-2/
[e48-reliability]: ../../../evidence/logos/rfp-004-dex/48-follow-up/2026-11-26-3/
[i48-follow-up]: https://github.com/iftech/qa-audits/issues/48#issuecomment-7196517760
[ev]: ../../../evidence/logos/rfp-004-dex
[i9]: https://github.com/iftech/qa-audits/issues/9
[i10c]: https://github.com/iftech/qa-audits/issues/10#issuecomment-7167609314
[i11c]: https://github.com/iftech/qa-audits/issues/11#issuecomment-7167612011
[i12c]: https://github.com/iftech/qa-audits/issues/12#issuecomment-7167612610
[i13c]: https://github.com/iftech/qa-audits/issues/13#issuecomment-7167697617
[i14]: https://github.com/iftech/qa-audits/issues/14
[i14src]: https://github.com/iftech/qa-audits/issues/14#issuecomment-7138645059
[i14live]: https://github.com/iftech/qa-audits/issues/14#issuecomment-7167628974
[i15]: https://github.com/iftech/qa-audits/issues/15
[i15c]: https://github.com/iftech/qa-audits/issues/15#issuecomment-7167624882
[c-upd]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/programs/amm/src/update_config.rs#L23-L52
[c-core-ix]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/programs/amm/core/src/lib.rs#L36-L290
[c-core-fee]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/programs/amm/core/src/lib.rs#L584-L605
[c-swap-tick]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/programs/amm/src/swap.rs#L121-L142
[c-swap-vaults]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/programs/amm/src/swap.rs#L15-L34
[c-swap-user]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/programs/amm/src/swap.rs#L203-L223
[c-swap-user-out]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/programs/amm/src/swap.rs#L483-L503
[c-swap-transfer-in]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/programs/amm/src/swap.rs#L383-L407
[c-swap-transfer-out]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/programs/amm/src/swap.rs#L660-L684
[c-swap-out]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/programs/amm/src/swap.rs#L216-L223
[c-ffi-mod]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/modules/amm/ffi/src/api/mod.rs#L80-L220
[c-ffi-swap]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/modules/amm/ffi/src/api/swap.rs#L148-L213
[c-ffi-swap-out]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/modules/amm/ffi/src/api/swap.rs#L340-L375
[c-liq]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/modules/amm/ffi/src/api/liquidity.rs#L378-L392
[c-fee-tiers]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/modules/amm/ffi/src/api/fee.rs#L1-L18
[c-module]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/modules/amm/src/amm_module_impl.cpp#L371-L391
[c-summary]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/apps/amm/qml/components/swap/SwapSummary.qml
[c-confsum]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/apps/amm/qml/components/swap/SwapConfirmationSummary.qml#L61-L126
[c-swapcard]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/apps/amm/qml/components/swap/SwapCard.qml#L516-L548
[c-dummy]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/apps/amm/qml/state/DummySwapState.qml#L16-L18
[c-poolspage]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/apps/amm/qml/pages/PoolsPage.qml#L33-L53
[c-pooldetail]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/apps/amm/qml/pages/PoolDetailPage.qml#L12-L16
[c-backend]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/apps/amm/src/AmmUiBackend.cpp#L55-L62
[c-app-readme]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/apps/amm/README.md
[c-mod-readme]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/modules/amm/README.md#L66-L67
[c-ci]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/.github/workflows/ci.yml#L193-L214
[c-guest]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/programs/amm/methods/guest/src/bin/amm.rs#L168-L389
[c-cargo]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/programs/amm/Cargo.toml#L10-L11
[c-publish]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/programs/twap_oracle/src/publish_price.rs#L228-L234
[c-publish-win]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/programs/twap_oracle/src/publish_price.rs#L144-L231
[c-create-opa]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/programs/twap_oracle/src/create_oracle_price_account.rs#L83-L101
[c-amm-opa]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/programs/amm/src/create_oracle_price_account.rs#L100-L140
[c-twap-core]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/programs/twap_oracle/core/src/lib.rs#L28-L172
[c-opa-type]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/programs/twap_oracle/core/src/lib.rs#L365-L408
[c-record]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/programs/twap_oracle/src/record_tick.rs#L106-L133
[c-clock]: https://github.com/logos-blockchain/lez-programs/blob/1cfaa5e3446a684e6e9b61cfb243038dae6465ea/programs/stablecoin/src/accrue_stability_fee.rs#L162-L173
