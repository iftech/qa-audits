# Reproduce the RFP-004 public smoke test

This runs a fresh LEZ chain on loopback. It deploys token, TWAP and AMM, creates two funded token holdings and an AMM pool, and checks one public exact-input swap from raw chain reads. No public network or live account is used.

## 1. Install build tools

Tested on x86-64 Ubuntu 22.04.5 with 8 logical CPUs and 31 GiB RAM. Allow several GB of Docker and Cargo cache space. Use a working Docker Engine with BuildKit, Rustup, and the official [RISC Zero installer](https://dev.risczero.com/api/zkvm/install). On Ubuntu:

```bash
sudo apt-get update
sudo apt-get install -y build-essential clang cmake curl git jq libclang-dev \
  libpcsclite-dev libssl-dev ninja-build openssl pkg-config protobuf-compiler python3
rustup toolchain install 1.94.0
# rzup is installed by the RISC Zero installer; add its bin directory if needed.
export PATH="$HOME/.risc0/bin:$HOME/.cargo/bin:$PATH"
rzup install r0vm 3.0.5
rzup install cargo-risczero 3.0.5
rzup default r0vm 3.0.5
rzup default cargo-risczero 3.0.5
r0vm --version
cargo risczero --version
```

The guest compiler is in Docker; the host does not need a separate `risc0` Rust toolchain for the commands below. The guest builder tag is `r0.1.88.0`; its observed manifest digest was `sha256:3e12f71bacd27527a61dea96fa0e53e468c99aa261d3a1019b593f6dbd943eb3`. Check it before building; a different digest or ImageID means a different baseline. The Rust host release is `1.94.0 (4a4ef493e 2026-03-02)`.

## 2. Check out exact revisions and build

Run this from a directory outside any checkout. Use a new repo root, or check out the same revisions in existing clean clones. Every Cargo build uses the checked-in lockfile; no dependencies are intentionally updated.

```bash
set -euo pipefail
ROOT="$HOME/rfp004-repos"
mkdir -p "$ROOT"
git clone https://github.com/logos-blockchain/lez-programs.git "$ROOT/lez-programs"
git clone https://github.com/logos-blockchain/logos-execution-zone.git "$ROOT/logos-execution-zone"
git clone https://github.com/logos-co/spel.git "$ROOT/spel"
git -C "$ROOT/lez-programs" checkout --detach 1cfaa5e3446a684e6e9b61cfb243038dae6465ea
git -C "$ROOT/logos-execution-zone" checkout --detach d8596eb734bf9c9ce801afb92df06098a2eb098a
git -C "$ROOT/spel" checkout --detach c6f73ce21e4805f8430f03afdbdedf0b7e479a5e

(cd "$ROOT/lez-programs"; \
  docker buildx imagetools inspect risczero/risc0-guest-builder:r0.1.88.0 \
    | grep -F 'sha256:3e12f71bacd27527a61dea96fa0e53e468c99aa261d3a1019b593f6dbd943eb3'; \
  unset PROGRAMS; \
  RISC0_DOCKER_CONTAINER_TAG=r0.1.88.0 scripts/build-guests.sh; \
  cargo +1.94.0 build --locked -p amm_program --example amm_pdas)
(cd "$ROOT/logos-execution-zone"; \
  cargo +1.94.0 build --locked --release -p sequencer_service --features standalone -p wallet)
(cd "$ROOT/spel"; cargo +1.94.0 build --locked --release -p spel)
```

The default upstream guest build also builds ATA, stablecoin and token mint authority. Only token, TWAP and AMM are used below.

| Lockfile | SHA-256 |
|---|---|
| lez-programs root | `79e97ac8ebbe7429bf1b0735437cc1b8dd6e16ab987ba7028e7a184553af3b98` |
| LEZ root | `945399f86eb6e669f900efde9aea2a039c982332dbc3dc3991b00f87e86c7459` |
| SPEL root | `5bab3fa6ff21e0cf86a7fd51a9048f06c7d499950875c98ef67168796c948a7e` |
| AMM guest | `f63258d8e5e69b7d403ffbd323170039096ce6259141e40477ede5804f008de4` |
| token guest | `5b0f23026c190371a105665bb8cd0fb189edd34a1546070ba5d3f5247a266038` |
| TWAP guest | `e3cc07a6a48739c3aecd87ee308007dcced5b0f8b09e89329790c8ad99130451` |

## 3. Run the smoke test

Save the companion `run-public-smoke.sh` next to this runbook. Use a shell with `r0vm` on PATH:

```bash
KEEP_SEQUENCER=1 bash ./run-public-smoke.sh "$HOME/rfp004-repos"
```

Set `PORT` to use another loopback port (default `3040`). The script prints the new run directory. It has a fresh chain database and wallet. The script disables gossip and metrics, changes the debug block interval to 2 seconds, and sets wallet polling to 1 second. The sequencer uses its `standalone` feature and `RISC0_DEV_MODE=1`. It does not use a Bedrock node. The payer comes from the pinned SPEL helper for the **published debug genesis only**. Do not expose this sequencer or use this payer on another network.

Check the final `PASS` line and save `public-smoke.log`. The transaction receipts, decoded accounts and deployed headers are also written as JSON. Do not share the wallet directory, chain directory or raw sequencer config. Stop the instance with `kill <printed PID>` when finished. Without `KEEP_SEQUENCER=1`, the script stops it automatically. Fresh wallet keys mean fresh header addresses on each run; compare **ImageIDs and state deltas**, not header addresses or transaction hashes across runs.

## 4. Follow-on tests

On the same VM, use the run directory's wallet and the recorded address list in `public-smoke.log`. For a separate session or machine, rerun this setup from the exact revisions; its fresh addresses must be used for every PDA and client config. The public smoke result does not validate private proving, rollback, group authority, Basecamp or Bedrock finality. Use dev mode for quick public iteration; measure a bounded private proof outside dev mode before promising a private QA runtime.
