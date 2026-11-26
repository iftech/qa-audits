#!/usr/bin/env bash
set -euo pipefail
umask 077

ROOT=$(realpath "${1:-"$HOME/repos"}")
PROGRAMS="$ROOT/lez-programs"
LEZ="$ROOT/logos-execution-zone"
SPEL_REPO="$ROOT/spel"
WALLET="$LEZ/target/release/wallet"
SEQ="$LEZ/target/release/sequencer_service"
SPEL="$SPEL_REPO/target/release/spel"
PDAS="$PROGRAMS/target/debug/examples/amm_pdas"
PORT=${PORT:-3040}
URL="http://127.0.0.1:$PORT"
RUN_DIR=$(mktemp -d "${RUN_PARENT:-$HOME}/rfp004-smoke.XXXXXX")
export LEE_WALLET_HOME_DIR="$RUN_DIR/wallet"
export RISC0_DEV_MODE=1
export RISC0_SERVER_PATH="$(command -v r0vm)"
export RUST_LOG=warn

[[ $(git -C "$PROGRAMS" rev-parse HEAD) == 1cfaa5e3446a684e6e9b61cfb243038dae6465ea ]]
[[ $(git -C "$LEZ" rev-parse HEAD) == d8596eb734bf9c9ce801afb92df06098a2eb098a ]]
[[ $(git -C "$SPEL_REPO" rev-parse HEAD) == c6f73ce21e4805f8430f03afdbdedf0b7e479a5e ]]
[[ $("$RISC0_SERVER_PATH" --version) == 'risc0-r0vm 3.0.5' ]]
for binary in "$WALLET" "$SEQ" "$SPEL" "$PDAS"; do
    [[ -x "$binary" ]] || { echo "Build first; missing $binary" >&2; exit 1; }
done
cd "$PROGRAMS"
for program in token twap_oracle amm; do
    [[ -s target/guest/$program.bin ]] || { echo "Build first; missing $program.bin" >&2; exit 1; }
done

mkdir -p "$LEE_WALLET_HOME_DIR" "$RUN_DIR/chain"
exec > >(tee "$RUN_DIR/public-smoke.log") 2>&1
log_cmd() { printf '$'; printf ' %q' "$@"; printf '\n'; }
run() { log_cmd "$@"; "$@"; }
rpc() {
    local method=$1 params=${2:-'[]'}
    curl -fsS --max-time 5 -H 'Content-Type: application/json' --data \
        "$(jq -nc --arg method "$method" --argjson params "$params" \
            '{jsonrpc:"2.0",id:1,method:$method,params:$params}')" "$URL" || return
    printf '\n'
}

echo "Run directory: $RUN_DIR"
echo "RISC0_DEV_MODE=$RISC0_DEV_MODE; RISC0_SERVER_PATH=$RISC0_SERVER_PATH"
run rustc +1.94.0 --version
run cargo +1.94.0 --version
run cargo +1.94.0 risczero --version
run "$RISC0_SERVER_PATH" --version
run "$SEQ" --version
run "$WALLET" --version
echo "SPEL CLI package $(sed -n 's/^version = "\(.*\)"/\1/p' "$SPEL_REPO/spel-cli/Cargo.toml" | head -n 1) @ $(git -C "$SPEL_REPO" rev-parse HEAD)"
if rpc checkHealth >/dev/null 2>&1; then
    echo "Port $PORT is already in use; select another with PORT=." >&2
    exit 1
fi

jq 'del(.gossip) | .metrics_address = null | .block_create_timeout = "2s"' \
    "$LEZ/lez/sequencer/service/configs/debug/sequencer_config.json" > "$RUN_DIR/sequencer.json"
jq --arg url "$URL" '.sequencers = [{sequencer_addr:$url}] | .seq_poll_timeout = "1s"' \
    "$LEZ/lez/wallet/configs/debug/wallet_config.json" > "$LEE_WALLET_HOME_DIR/wallet_config.json"
seq_args=("$SEQ" "$RUN_DIR/sequencer.json" --home "$RUN_DIR/chain"
    --listen-address 127.0.0.1 --port "$PORT")
log_cmd env RUST_LOG=info,kameo=warn RISC0_DEV_MODE=1 "${seq_args[@]}"
nohup env RUST_LOG=info,kameo=warn "${seq_args[@]}" > "$RUN_DIR/sequencer.log" 2>&1 </dev/null &
seq_pid=$!
cleanup() {
    local rc=$?
    if [[ $rc == 0 && ${KEEP_SEQUENCER:-0} == 1 ]]; then
        echo "Sequencer left running at $URL (PID $seq_pid)."
    else
        kill "$seq_pid" 2>/dev/null || true
        wait "$seq_pid" 2>/dev/null || true
    fi
    if (( rc != 0 )); then tail -45 "$RUN_DIR/sequencer.log"; fi
}
trap cleanup EXIT
for ((attempt=0; attempt<60; attempt++)); do
    kill -0 "$seq_pid"
    if rpc checkHealth 2>/dev/null | jq -e 'has("result")' >/dev/null; then break; fi
    sleep 1
done
run rpc checkHealth | tee "$RUN_DIR/health.json"
tail -n 1 "$RUN_DIR/health.json" | jq -e 'has("result")' >/dev/null
run rpc getChannelId
run sha256sum "$RUN_DIR/sequencer.json" "$LEE_WALLET_HOME_DIR/wallet_config.json"

# First-run wallet prints a recovery phrase. Do not put it in the transcript.
log_cmd "$WALLET" account new public --label namespace-owner
"$WALLET" account new public --label namespace-owner \
    <<< "$(openssl rand -hex 24)" >/dev/null
for label in definition-a definition-b holding-a holding-b holding-lp; do
    run "$WALLET" account new public --label "$label"
done
id() {
    local resolved
    resolved=$("$WALLET" account id --account-id "$1" | sed -n '1p') || return 1
    [[ $resolved =~ ^[1-9A-HJ-NP-Za-km-z]{32,44}$ ]] || return 1
    printf '%s\n' "$resolved"
}
OWNER=$(id namespace-owner)
DEF_A=$(id definition-a); DEF_B=$(id definition-b)
HOLD_A=$(id holding-a); HOLD_B=$(id holding-b); HOLD_LP=$(id holding-lp)
printf 'Namespace owner: %s\nDefinition A: %s\nDefinition B: %s\nTrader A: %s\nTrader B: %s\nTrader LP: %s\n' \
    "$OWNER" "$DEF_A" "$DEF_B" "$HOLD_A" "$HOLD_B" "$HOLD_LP"

# Only for the upstream loopback debug genesis; never use the published key elsewhere.
source "$SPEL_REPO/scripts/lib/fee-payer.sh"
FEE_PAYER=$(lez_fee_payer "$WALLET" '')
[[ $FEE_PAYER =~ ^[1-9A-HJ-NP-Za-km-z]{32,44}$ ]]
echo "Imported pinned SPEL debug-genesis fee payer: $FEE_PAYER"
run rpc getAccountBalance "[\"$FEE_PAYER\"]"

deploy() {
    local name=$1 expected_image=$2 binary="target/guest/$1.bin" image header
    log_cmd "$SPEL" program-id "$binary" --format hex >&2
    image=$("$SPEL" program-id "$binary" --format hex)
    [[ $image == "$expected_image" ]] || { echo "ImageID mismatch for $name: $image" >&2; return 1; }
    echo "$name ImageID: $image" >&2
    sha256sum "$binary" >&2
    log_cmd "$SPEL" deploy "$binary" --fee-payer "$FEE_PAYER" --immutable >&2
    if ! header=$("$SPEL" deploy "$binary" --fee-payer "$FEE_PAYER" --immutable \
        2>"$RUN_DIR/$name.deploy.log"); then
        tail -c 4500 "$RUN_DIR/$name.deploy.log" >&2
        return 1
    fi
    [[ $header =~ ^[1-9A-HJ-NP-Za-km-z]{32,44}$ ]] || return 1
    grep -E 'Deploying |header account:|Program deployed\.' "$RUN_DIR/$name.deploy.log" >&2
    echo "$name program header: $header" >&2
    log_cmd rpc getAccount "[\"$header\"]" >&2
    rpc getAccount "[\"$header\"]" | tee "$RUN_DIR/$name.header.json" | python3 -c '
import json, sys
header = bytes(json.load(sys.stdin)["result"]["data"])
assert len(header) == 65 and header[-1] == 1, "Not an immutable program header"
assert header[:32].hex() == sys.argv[1], "On-chain ImageID differs from local ImageID"
print("On-chain immutable header ImageID:", header[:32].hex())
' "$image" >&2 || return 1
    printf '%s\n' "$header"
}
TOKEN=$(deploy token 057e9cc28c7bd70645f74fa2c38e9880e532d369bda31a4bbaa24f5f1e93a6bc)
TWAP=$(deploy twap_oracle 979279c5fa38173abf0d35370e2c481303ec28f959c7eeb98ab74a7e90ce3edd)
AMM=$(deploy amm a69de4104f829dadb356f05f46ea1d79fc819618f2ebedb341d5b2e041d8bd79)

POOL_IDL=artifacts/amm-idl.json
TOKEN_IDL=artifacts/token-idl.json
TWAP_IDL=artifacts/twap_oracle-idl.json
SUPPLY=1000000
DEPOSIT_A=100000
DEPOSIT_B=200000
TRADE_IN=10000
MIN_OUT=18000
SWAP_FEE=30
PROTOCOL_FEE=2500
NONCE=$(printf '%064d' 0)
DEADLINE=18446744073709551615
CLOCK=4BdcjoXkq786TMWcBGGHqcxeLYMZmn17rL4eM9ZyRWNU

tx() {
    local name=$1 idl=$2 program=$3 hash
    shift 3
    run "$SPEL" --idl "$idl" --program "$program" --fee-payer "$FEE_PAYER" -- "$@" \
        2>&1 | tee "$RUN_DIR/$name.tx.log"
    hash=$(awk '/tx_hash:/ {print $2}' "$RUN_DIR/$name.tx.log")
    [[ $hash =~ ^[0-9a-f]{64}$ ]]
    log_cmd rpc getTransaction "[\"$hash\"]"
    rpc getTransaction "[\"$hash\"]" | tee "$RUN_DIR/$name.receipt.json" | python3 -c '
import base64, json, sys
response = json.load(sys.stdin)
transaction, block = response["result"]
assert base64.b64decode(transaction, validate=True)[0] == 0, "Not a public LEZ transaction"
print("Sequencer getTransaction: public transaction in block", block)
'
}
inspect() {
    local name=$1 idl=$2 account=$3 type=$4
    log_cmd "$SPEL" --idl "$idl" inspect "$account" --type "$type"
    "$SPEL" --idl "$idl" inspect "$account" --type "$type" | tee "$RUN_DIR/$name.json"
}

tx token-a "$TOKEN_IDL" "$TOKEN" new-fungible-definition --name 'QA Token A' \
    --total-supply "$SUPPLY" --mint-authority none \
    --definition-target-account "$DEF_A" --holding-target-account "$HOLD_A"
tx token-b "$TOKEN_IDL" "$TOKEN" new-fungible-definition --name 'QA Token B' \
    --total-supply "$SUPPLY" --mint-authority none \
    --definition-target-account "$DEF_B" --holding-target-account "$HOLD_B"

run "$PDAS" "$AMM" "$OWNER" "$TWAP" "$DEF_A" "$DEF_B" | tee "$RUN_DIR/pdas.txt"
pda() { awk -v key="$1" '$1 == key {print $2}' "$RUN_DIR/pdas.txt"; }
CONFIG=$(pda config); POOL=$(pda pool)
VAULT_A=$(pda vault_a); VAULT_B=$(pda vault_b)
LP_DEF=$(pda pool_definition_lp); LP_LOCK=$(pda lp_lock_holding)
TICK=$(pda current_tick_account); FEE_A=$(pda protocol_fee_a)

tx initialize "$POOL_IDL" "$AMM" initialize --owner "$OWNER" --config "$CONFIG" \
    --nonce "$NONCE" --token-program-id "$TOKEN" --twap-oracle-program-id "$TWAP" \
    --authority "$OWNER" --swap-fee-bps "$SWAP_FEE" --protocol-fee-bps "$PROTOCOL_FEE"
inspect config "$POOL_IDL" "$CONFIG" AmmConfig

tx pool-create "$POOL_IDL" "$AMM" new-definition --config "$CONFIG" --pool "$POOL" \
    --vault-a "$VAULT_A" --vault-b "$VAULT_B" --pool-definition-lp "$LP_DEF" \
    --lp-lock-holding "$LP_LOCK" --user-holding-a "$HOLD_A" --user-holding-b "$HOLD_B" \
    --user-holding-lp "$HOLD_LP" --current-tick-account "$TICK" --clock "$CLOCK" \
    --token-a-amount "$DEPOSIT_A" --token-b-amount "$DEPOSIT_B" --deadline "$DEADLINE"

snapshot() {
    local phase=$1
    inspect "$phase.pool" "$POOL_IDL" "$POOL" PoolDefinition
    inspect "$phase.vault-a" "$TOKEN_IDL" "$VAULT_A" TokenHolding
    inspect "$phase.vault-b" "$TOKEN_IDL" "$VAULT_B" TokenHolding
    inspect "$phase.trader-a" "$TOKEN_IDL" "$HOLD_A" TokenHolding
    inspect "$phase.trader-b" "$TOKEN_IDL" "$HOLD_B" TokenHolding
    inspect "$phase.tick" "$TWAP_IDL" "$TICK" CurrentTickAccount
}
snapshot before
inspect lp-lock "$TOKEN_IDL" "$LP_LOCK" TokenHolding
inspect trader-lp "$TOKEN_IDL" "$HOLD_LP" TokenHolding
log_cmd rpc getAccount "[\"$FEE_A\"]"
rpc getAccount "[\"$FEE_A\"]" | tee "$RUN_DIR/before.protocol-fee-a.raw.json"

tx swap "$POOL_IDL" "$AMM" swap-exact-input --config "$CONFIG" --pool "$POOL" \
    --vault-a "$VAULT_A" --vault-b "$VAULT_B" --user-input-holding "$HOLD_A" \
    --user-output-holding "$HOLD_B" --current-tick-account "$TICK" --clock "$CLOCK" \
    --protocol-fee-holding "$FEE_A" --swap-amount-in "$TRADE_IN" \
    --min-amount-out "$MIN_OUT" --deadline "$DEADLINE"
snapshot after
inspect after.protocol-fee-a "$TOKEN_IDL" "$FEE_A" TokenHolding

python3 - "$RUN_DIR" "$SUPPLY" "$DEPOSIT_A" "$DEPOSIT_B" "$TRADE_IN" "$MIN_OUT" \
    "$SWAP_FEE" "$PROTOCOL_FEE" <<'PY'
import json, math, sys
from pathlib import Path

folder = Path(sys.argv[1])
supply, a, b, gross, minimum, fee_bps, protocol_bps = map(int, sys.argv[2:])
read = lambda name: json.loads((folder / f"{name}.json").read_text())
bal = lambda name: int(read(name)["Fungible"]["balance"])
reserves = lambda pool: (int(pool["reserve_a"]), int(pool["reserve_b"]))

effective = gross * (10_000 - fee_bps) // 10_000
out = b * effective // (a + effective)
protocol = (gross - effective) * protocol_bps // 10_000
before, after = read("before.pool"), read("after.pool")
assert reserves(before) == (a, b)
assert (bal("before.trader-a"), bal("before.trader-b")) == (supply-a, supply-b)
assert int(before["liquidity_pool_supply"]) == math.isqrt(a*b)
assert bal("lp-lock") == 1000
assert bal("trader-lp") == math.isqrt(a*b)-1000
assert out >= minimum
assert reserves(after) == (a+gross-protocol, b-out)
for phase, pool in [("before", before), ("after", after)]:
    assert (bal(f"{phase}.vault-a"), bal(f"{phase}.vault-b")) == reserves(pool)
assert (bal("after.trader-a"), bal("after.trader-b")) == (supply-a-gross, supply-b+out)
assert read("before.protocol-fee-a.raw")["result"]["data"] == []
assert bal("after.protocol-fee-a") == protocol
assert after["liquidity_pool_supply"] == before["liquidity_pool_supply"]
assert (a+gross-protocol)*(b-out) >= a*b
assert int(read("after.tick")["tick"]) < int(read("before.tick")["tick"])
assert int(read("after.tick")["last_updated"]) > int(read("before.tick")["last_updated"])
create_block = read("pool-create.receipt")["result"][1]
swap_block = read("swap.receipt")["result"][1]
assert swap_block > create_block
print(f"PASS: public pool create (block {create_block}) and swap (block {swap_block}); "
      f"{gross} A in, {out} B out, {protocol} A protocol fee.")
PY
