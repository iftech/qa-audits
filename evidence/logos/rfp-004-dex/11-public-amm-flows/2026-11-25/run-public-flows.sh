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
RUN_DIR=$(mktemp -d "${RUN_PARENT:-$HOME}/rfp004-flows.XXXXXX")
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
exec > >(tee "$RUN_DIR/public-flows.log") 2>&1
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
for label in definition-a definition-b holding-a holding-b holding-lp definition-c holding-c holding-lp-ac holding-lp-ac2 holding-lp-new holding-lp-new2 definition-x definition-y holding-x holding-y holding-lp-xy; do
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

NONCE=$(printf '%064d' 0)
DEADLINE=18446744073709551615
DEADLINE_PAST=1
CLOCK=4BdcjoXkq786TMWcBGGHqcxeLYMZmn17rL4eM9ZyRWNU
U128_MAX=340282366920938463463374607431768211455
CALC="python3 $(dirname "$(realpath "$0")")/calc.py"
mkdir -p "$RUN_DIR/snap"
: > "$RUN_DIR/cases.jsonl"

# tx: never aborts. spel may print "Transaction confirmed" for a rejected
# instruction, so the checker decides the outcome from on-chain state.
tx() {
    local name=$1 idl=$2 program=$3 hash
    shift 3
    log_cmd "$SPEL" --idl "$idl" --program "$program" --fee-payer "$FEE_PAYER" -- "$@"
    "$SPEL" --idl "$idl" --program "$program" --fee-payer "$FEE_PAYER" -- "$@" \
        > "$RUN_DIR/$name.tx.log" 2>&1 || echo "(spel exit code $?)" >> "$RUN_DIR/$name.tx.log"
    grep -E 'tx_hash:|confirmed|rror|panick|failed' "$RUN_DIR/$name.tx.log" | cut -c1-400 || true
    hash=$(awk '/tx_hash:/ {print $2}' "$RUN_DIR/$name.tx.log" | head -n1)
    if [[ $hash =~ ^[0-9a-f]{64}$ ]]; then
        rpc getTransaction "[\"$hash\"]" > "$RUN_DIR/$name.receipt.json" 2>/dev/null || true
        python3 -c 'import json,sys
try:
    r=json.load(open(sys.argv[1])).get("result")
    print("getTransaction block:", r[1] if r else None)
except Exception as e: print("getTransaction: no result", e)' "$RUN_DIR/$name.receipt.json"
    else
        echo "no tx_hash"
    fi
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
DEF_C=$(id definition-c); HOLD_C=$(id holding-c); HOLD_LP_AC=$(id holding-lp-ac); HOLD_LP_AC2=$(id holding-lp-ac2)
HOLD_LP_NEW=$(id holding-lp-new); HOLD_LP_NEW2=$(id holding-lp-new2)
DEF_X=$(id definition-x); DEF_Y=$(id definition-y)
HOLD_X=$(id holding-x); HOLD_Y=$(id holding-y); HOLD_LP_XY=$(id holding-lp-xy)
tx token-c "$TOKEN_IDL" "$TOKEN" new-fungible-definition --name 'QA Token C' \
    --total-supply "$SUPPLY" --mint-authority none \
    --definition-target-account "$DEF_C" --holding-target-account "$HOLD_C"
tx token-x "$TOKEN_IDL" "$TOKEN" new-fungible-definition --name 'QA Token X' \
    --total-supply "$U128_MAX" --mint-authority none \
    --definition-target-account "$DEF_X" --holding-target-account "$HOLD_X"
tx token-y "$TOKEN_IDL" "$TOKEN" new-fungible-definition --name 'QA Token Y' \
    --total-supply "$U128_MAX" --mint-authority none \
    --definition-target-account "$DEF_Y" --holding-target-account "$HOLD_Y"

run "$PDAS" "$AMM" "$OWNER" "$TWAP" "$DEF_A" "$DEF_B" | tee "$RUN_DIR/pdas.txt"
run "$PDAS" "$AMM" "$OWNER" "$TWAP" "$DEF_A" "$DEF_C" | tee "$RUN_DIR/pdas-ac.txt"
run "$PDAS" "$AMM" "$OWNER" "$TWAP" "$DEF_X" "$DEF_Y" | tee "$RUN_DIR/pdas-xy.txt"
pda() { awk -v key="$2" '$1 == key {print $2}' "$RUN_DIR/$1"; }
CONFIG=$(pda pdas.txt config); POOL=$(pda pdas.txt pool)
VAULT_A=$(pda pdas.txt vault_a); VAULT_B=$(pda pdas.txt vault_b)
LP_DEF=$(pda pdas.txt pool_definition_lp); LP_LOCK=$(pda pdas.txt lp_lock_holding)
TICK=$(pda pdas.txt current_tick_account)
FEE_A=$(pda pdas.txt protocol_fee_a); FEE_B=$(pda pdas.txt protocol_fee_b)
POOL_AC=$(pda pdas-ac.txt pool); VAULT_AC_A=$(pda pdas-ac.txt vault_a); VAULT_AC_C=$(pda pdas-ac.txt vault_b)
LP_DEF_AC=$(pda pdas-ac.txt pool_definition_lp); LP_LOCK_AC=$(pda pdas-ac.txt lp_lock_holding)
TICK_AC=$(pda pdas-ac.txt current_tick_account)
POOL_XY=$(pda pdas-xy.txt pool); VAULT_XY_X=$(pda pdas-xy.txt vault_a); VAULT_XY_Y=$(pda pdas-xy.txt vault_b)
LP_DEF_XY=$(pda pdas-xy.txt pool_definition_lp); LP_LOCK_XY=$(pda pdas-xy.txt lp_lock_holding)
TICK_XY=$(pda pdas-xy.txt current_tick_account); FEE_XY_X=$(pda pdas-xy.txt protocol_fee_a)

tx initialize "$POOL_IDL" "$AMM" initialize --owner "$OWNER" --config "$CONFIG" \
    --nonce "$NONCE" --token-program-id "$TOKEN" --twap-oracle-program-id "$TWAP" \
    --authority "$OWNER" --swap-fee-bps "$SWAP_FEE" --protocol-fee-bps "$PROTOCOL_FEE"
inspect config "$POOL_IDL" "$CONFIG" AmmConfig

# name|idl|account|type for every account the checker tracks.
ACCOUNTS=(
  "pool|$POOL_IDL|$POOL|PoolDefinition" "vault-a|$TOKEN_IDL|$VAULT_A|TokenHolding"
  "vault-b|$TOKEN_IDL|$VAULT_B|TokenHolding" "trader-a|$TOKEN_IDL|$HOLD_A|TokenHolding"
  "trader-b|$TOKEN_IDL|$HOLD_B|TokenHolding" "trader-lp|$TOKEN_IDL|$HOLD_LP|TokenHolding"
  "lp-lock|$TOKEN_IDL|$LP_LOCK|TokenHolding" "fee-a|$TOKEN_IDL|$FEE_A|TokenHolding"
  "fee-b|$TOKEN_IDL|$FEE_B|TokenHolding" "tick|$TWAP_IDL|$TICK|CurrentTickAccount"
  "pool-ac|$POOL_IDL|$POOL_AC|PoolDefinition" "vault-ac-a|$TOKEN_IDL|$VAULT_AC_A|TokenHolding"
  "vault-ac-c|$TOKEN_IDL|$VAULT_AC_C|TokenHolding" "trader-c|$TOKEN_IDL|$HOLD_C|TokenHolding"
  "trader-lp-ac|$TOKEN_IDL|$HOLD_LP_AC|TokenHolding" "lp-lock-ac|$TOKEN_IDL|$LP_LOCK_AC|TokenHolding"
  "tick-ac|$TWAP_IDL|$TICK_AC|CurrentTickAccount" "trader-lp-ac2|$TOKEN_IDL|$HOLD_LP_AC2|TokenHolding"
  "trader-lp-new|$TOKEN_IDL|$HOLD_LP_NEW|TokenHolding" "trader-lp-new2|$TOKEN_IDL|$HOLD_LP_NEW2|TokenHolding"
  "pool-xy|$POOL_IDL|$POOL_XY|PoolDefinition" "vault-xy-x|$TOKEN_IDL|$VAULT_XY_X|TokenHolding"
  "vault-xy-y|$TOKEN_IDL|$VAULT_XY_Y|TokenHolding" "trader-x|$TOKEN_IDL|$HOLD_X|TokenHolding"
  "trader-y|$TOKEN_IDL|$HOLD_Y|TokenHolding" "trader-lp-xy|$TOKEN_IDL|$HOLD_LP_XY|TokenHolding"
  "lp-lock-xy|$TOKEN_IDL|$LP_LOCK_XY|TokenHolding" "fee-xy-x|$TOKEN_IDL|$FEE_XY_X|TokenHolding"
  "tick-xy|$TWAP_IDL|$TICK_XY|CurrentTickAccount"
)
snap() {
    local dir="$RUN_DIR/snap/$1" entry name idl acct type pids=()
    mkdir -p "$dir"
    for entry in "${ACCOUNTS[@]}"; do
        IFS='|' read -r name idl acct type <<< "$entry"
        ( "$SPEL" --idl "$idl" inspect "$acct" --type "$type" > "$dir/$name.json" 2>/dev/null \
            || echo '{"uninitialized": true}' > "$dir/$name.json" ) &
        pids+=($!)
    done
    wait "${pids[@]}"
    # Raw account records (nonce, balance, data) of the fresh LP holdings.
    for entry in "lp-ac|$HOLD_LP_AC" "lp-ac2|$HOLD_LP_AC2" "lp-xy|$HOLD_LP_XY" "lp|$HOLD_LP" "lp-new|$HOLD_LP_NEW" "lp-new2|$HOLD_LP_NEW2"; do
        IFS='|' read -r name acct <<< "$entry"
        rpc getAccount "[\"$acct\"]" > "$dir/raw-$name.json" 2>/dev/null || echo '{}' > "$dir/raw-$name.json"
    done
    python3 - "$dir" <<'PY'
import json, sys, pathlib
d = pathlib.Path(sys.argv[1]); out = {}
for f in sorted(d.glob("*.json")):
    if f.name == "all.json": continue
    try: out[f.stem] = json.loads(f.read_text())
    except Exception: out[f.stem] = {"unparsed": f.read_text()[:300]}
(d / "all.json").write_text(json.dumps(out, indent=1, sort_keys=True))
PY
}
val() { jq -r "$2" "$RUN_DIR/snap/$LAST/$1.json"; }
LAST=S00-setup
snap "$LAST"
step=0
# case <id> <expect ok|reject> <summary> <idl> <program> <spel args...>
case_() {
    local cid=$1 expect=$2 summary=$3 idl=$4 program=$5 tag
    shift 5
    step=$((step + 1)); tag=$(printf 'S%02d-%s' "$step" "$cid")
    echo; echo "=== $tag: $summary (expect $expect) ==="
    tx "$tag" "$idl" "$program" "$@"
    snap "$tag"
    python3 -c 'import json, sys; print(json.dumps(dict(zip(["id", "tag", "prev", "expect", "summary"], sys.argv[1:6]), args=sys.argv[6:])))' \
        "$cid" "$tag" "$LAST" "$expect" "$summary" "$@" >> "$RUN_DIR/cases.jsonl"
    LAST=$tag
}
POOLARGS=(--config "$CONFIG" --pool "$POOL" --vault-a "$VAULT_A" --vault-b "$VAULT_B")
SWAP_AB=("${POOLARGS[@]}" --user-input-holding "$HOLD_A" --user-output-holding "$HOLD_B"
    --current-tick-account "$TICK" --clock "$CLOCK" --protocol-fee-holding "$FEE_A")
SWAP_BA=("${POOLARGS[@]}" --user-input-holding "$HOLD_B" --user-output-holding "$HOLD_A"
    --current-tick-account "$TICK" --clock "$CLOCK" --protocol-fee-holding "$FEE_B")
LIQ=("${POOLARGS[@]}" --pool-definition-lp "$LP_DEF" --user-holding-a "$HOLD_A"
    --user-holding-b "$HOLD_B" --user-holding-lp "$HOLD_LP" --current-tick-account "$TICK" --clock "$CLOCK")
CREATE=("${LIQ[@]}" --lp-lock-holding "$LP_LOCK")
CREATE_AC=(--config "$CONFIG" --pool "$POOL_AC" --vault-a "$VAULT_AC_A" --vault-b "$VAULT_AC_C"
    --pool-definition-lp "$LP_DEF_AC" --lp-lock-holding "$LP_LOCK_AC" --user-holding-a "$HOLD_A"
    --user-holding-b "$HOLD_C" --user-holding-lp "$HOLD_LP_AC" --current-tick-account "$TICK_AC" --clock "$CLOCK")
CREATE_AC2=("${CREATE_AC[@]}"); CREATE_AC2[17]=$HOLD_LP_AC2
[[ ${CREATE_AC2[16]} == --user-holding-lp ]]
LIQ_AC=("${CREATE_AC2[@]:0:10}" "${CREATE_AC2[@]:12}")
CREATE_XY=(--config "$CONFIG" --pool "$POOL_XY" --vault-a "$VAULT_XY_X" --vault-b "$VAULT_XY_Y"
    --pool-definition-lp "$LP_DEF_XY" --lp-lock-holding "$LP_LOCK_XY" --user-holding-a "$HOLD_X"
    --user-holding-b "$HOLD_Y" --user-holding-lp "$HOLD_LP_XY" --current-tick-account "$TICK_XY" --clock "$CLOCK")
SWAP_XY=(--config "$CONFIG" --pool "$POOL_XY" --vault-a "$VAULT_XY_X" --vault-b "$VAULT_XY_Y"
    --user-input-holding "$HOLD_X" --user-output-holding "$HOLD_Y" --current-tick-account "$TICK_XY"
    --clock "$CLOCK" --protocol-fee-holding "$FEE_XY_X")
reserves() { RA=$(val pool .reserve_a); RB=$(val pool .reserve_b); LPS=$(val pool .liquidity_pool_supply); }
F=$SWAP_FEE

# --- Pool creation and minimum liquidity ---
case_ C01-create ok "create pool A/B 100000/200000" "$POOL_IDL" "$AMM" new-definition "${CREATE[@]}" \
    --token-a-amount 100000 --token-b-amount 200000 --deadline "$DEADLINE"
case_ C02-create-again reject "create the same pool again" "$POOL_IDL" "$AMM" new-definition "${CREATE[@]}" \
    --token-a-amount 1000 --token-b-amount 2000 --deadline "$DEADLINE"
case_ C03-min-liq-below reject "first deposit 1000/1000 (sqrt = 1000, not > MINIMUM_LIQUIDITY)" "$POOL_IDL" "$AMM" \
    new-definition "${CREATE_AC[@]}" --token-a-amount 1000 --token-b-amount 1000 --deadline "$DEADLINE"
case_ C04-min-liq-boundary ok "first deposit 1001/1001 (user gets 1 LP)" "$POOL_IDL" "$AMM" \
    new-definition "${CREATE_AC[@]}" --token-a-amount 1001 --token-b-amount 1001 --deadline "$DEADLINE"
case_ C04b-min-liq-boundary-fresh-lp ok "first deposit 1001/1001 again, with a never-used LP holding" "$POOL_IDL" "$AMM" \
    new-definition "${CREATE_AC2[@]}" --token-a-amount 1001 --token-b-amount 1001 --deadline "$DEADLINE"
case_ C05-remove-to-lock ok "remove the user's only 1 LP from pool A/C" "$POOL_IDL" "$AMM" remove-liquidity "${LIQ_AC[@]}" \
    --remove-liquidity-amount 1 --min-amount-to-remove-token-a 1 --min-amount-to-remove-token-b 1 --deadline "$DEADLINE"
case_ C06-remove-locked reject "remove 1 LP more from pool A/C (only locked LP left)" "$POOL_IDL" "$AMM" remove-liquidity "${LIQ_AC[@]}" \
    --remove-liquidity-amount 1 --min-amount-to-remove-token-a 1 --min-amount-to-remove-token-b 1 --deadline "$DEADLINE"

# --- Exact-input swaps ---
reserves; OUT=$($CALC in_out "$RA" "$RB" 10000 $F)
case_ C07-swap-in-ab ok "swap exact 10000 A in, min out = expected" "$POOL_IDL" "$AMM" swap-exact-input "${SWAP_AB[@]}" \
    --swap-amount-in 10000 --min-amount-out "$OUT" --deadline "$DEADLINE"
reserves; OUT=$($CALC in_out "$RB" "$RA" 5000 $F)
case_ C08-swap-in-ba ok "swap exact 5000 B in (reverse direction), min out = expected" "$POOL_IDL" "$AMM" swap-exact-input "${SWAP_BA[@]}" \
    --swap-amount-in 5000 --min-amount-out "$OUT" --deadline "$DEADLINE"
reserves; OUT=$($CALC in_out "$RA" "$RB" 1000 $F)
case_ C09-swap-in-slippage reject "swap exact 1000 A in, min out = expected + 1" "$POOL_IDL" "$AMM" swap-exact-input "${SWAP_AB[@]}" \
    --swap-amount-in 1000 --min-amount-out "$((OUT + 1))" --deadline "$DEADLINE"

# --- Exact-output swaps ---
reserves; IN=$($CALC out_in "$RA" "$RB" 1000 $F)
case_ C10-swap-out-ab ok "swap for exact 1000 B out, max in = expected" "$POOL_IDL" "$AMM" swap-exact-output "${SWAP_AB[@]}" \
    --exact-amount-out 1000 --max-amount-in "$IN" --deadline "$DEADLINE"
reserves; IN=$($CALC out_in "$RB" "$RA" 777 $F)
case_ C11-swap-out-ba ok "swap for exact 777 A out (reverse direction), max in = expected" "$POOL_IDL" "$AMM" swap-exact-output "${SWAP_BA[@]}" \
    --exact-amount-out 777 --max-amount-in "$IN" --deadline "$DEADLINE"
reserves; IN=$($CALC out_in "$RA" "$RB" 1000 $F)
case_ C12-swap-out-slippage reject "swap for exact 1000 B out, max in = expected - 1" "$POOL_IDL" "$AMM" swap-exact-output "${SWAP_AB[@]}" \
    --exact-amount-out 1000 --max-amount-in "$((IN - 1))" --deadline "$DEADLINE"
reserves
case_ C13-swap-out-all reject "swap for exact out = whole reserve B" "$POOL_IDL" "$AMM" swap-exact-output "${SWAP_AB[@]}" \
    --exact-amount-out "$RB" --max-amount-in 900000 --deadline "$DEADLINE"

# --- Zero and dust amounts ---
case_ C14-swap-in-zero reject "swap exact 0 A in" "$POOL_IDL" "$AMM" swap-exact-input "${SWAP_AB[@]}" \
    --swap-amount-in 0 --min-amount-out 0 --deadline "$DEADLINE"
case_ C15-swap-in-dust reject "swap exact 1 A in (fee rounds effective input to 0)" "$POOL_IDL" "$AMM" swap-exact-input "${SWAP_AB[@]}" \
    --swap-amount-in 1 --min-amount-out 0 --deadline "$DEADLINE"
case_ C16-swap-out-zero reject "swap for exact 0 B out" "$POOL_IDL" "$AMM" swap-exact-output "${SWAP_AB[@]}" \
    --exact-amount-out 0 --max-amount-in 1000 --deadline "$DEADLINE"
case_ C17-add-zero reject "add liquidity with max 0 A and 0 B" "$POOL_IDL" "$AMM" add-liquidity "${LIQ[@]}" \
    --min-amount-liquidity 1 --max-amount-to-add-token-a 0 --max-amount-to-add-token-b 0 --deadline "$DEADLINE"
case_ C18-remove-zero reject "remove 0 LP" "$POOL_IDL" "$AMM" remove-liquidity "${LIQ[@]}" \
    --remove-liquidity-amount 0 --min-amount-to-remove-token-a 1 --min-amount-to-remove-token-b 1 --deadline "$DEADLINE"
case_ C19-swap-in-over-balance reject "swap exact in more A than the trader holds" "$POOL_IDL" "$AMM" swap-exact-input "${SWAP_AB[@]}" \
    --swap-amount-in 5000000 --min-amount-out 1 --deadline "$DEADLINE"

# --- Deadlines (timestamp validity window ..deadline) ---
case_ C20-deadline-swap reject "swap with deadline in the past (1 ms)" "$POOL_IDL" "$AMM" swap-exact-input "${SWAP_AB[@]}" \
    --swap-amount-in 1000 --min-amount-out 1 --deadline "$DEADLINE_PAST"
case_ C21-deadline-swap-out reject "exact-output swap with deadline in the past" "$POOL_IDL" "$AMM" swap-exact-output "${SWAP_AB[@]}" \
    --exact-amount-out 100 --max-amount-in 1000 --deadline "$DEADLINE_PAST"
case_ C22-deadline-add reject "add liquidity with deadline in the past" "$POOL_IDL" "$AMM" add-liquidity "${LIQ[@]}" \
    --min-amount-liquidity 1 --max-amount-to-add-token-a 1000 --max-amount-to-add-token-b 2000 --deadline "$DEADLINE_PAST"
case_ C23-deadline-remove reject "remove liquidity with deadline in the past" "$POOL_IDL" "$AMM" remove-liquidity "${LIQ[@]}" \
    --remove-liquidity-amount 100 --min-amount-to-remove-token-a 1 --min-amount-to-remove-token-b 1 --deadline "$DEADLINE_PAST"
NOW=$(val tick .last_updated)
case_ C24-deadline-near-past reject "swap with deadline = last tick timestamp (already passed)" "$POOL_IDL" "$AMM" swap-exact-input "${SWAP_AB[@]}" \
    --swap-amount-in 1000 --min-amount-out 1 --deadline "$NOW"
case_ C25-deadline-future ok "swap with deadline = now + 10 minutes" "$POOL_IDL" "$AMM" swap-exact-input "${SWAP_AB[@]}" \
    --swap-amount-in 1000 --min-amount-out 1 --deadline "$((NOW + 600000))"

# --- Add and remove liquidity ---
reserves; LPX=$($CALC add "$RA" "$RB" "$LPS" 10000 30000)
case_ C26-add ok "add liquidity max 10000 A / 30000 B, min LP = expected" "$POOL_IDL" "$AMM" add-liquidity "${LIQ[@]}" \
    --min-amount-liquidity "$LPX" --max-amount-to-add-token-a 10000 --max-amount-to-add-token-b 30000 --deadline "$DEADLINE"
reserves; LPX=$($CALC add "$RA" "$RB" "$LPS" 7 1000000)
case_ C27-add-tiny ok "add liquidity max 7 A (B side unconstrained), min LP = expected" "$POOL_IDL" "$AMM" add-liquidity "${LIQ[@]}" \
    --min-amount-liquidity "$LPX" --max-amount-to-add-token-a 7 --max-amount-to-add-token-b 1000000 --deadline "$DEADLINE"
reserves; LPX=$($CALC add "$RA" "$RB" "$LPS" 10000 30000)
case_ C28-add-slippage reject "add liquidity, min LP = expected + 1" "$POOL_IDL" "$AMM" add-liquidity "${LIQ[@]}" \
    --min-amount-liquidity "$((LPX + 1))" --max-amount-to-add-token-a 10000 --max-amount-to-add-token-b 30000 --deadline "$DEADLINE"
reserves; read -r WA WB <<< "$($CALC remove "$RA" "$RB" "$LPS" 5000)"
case_ C29-remove ok "remove 5000 LP, min out = expected" "$POOL_IDL" "$AMM" remove-liquidity "${LIQ[@]}" \
    --remove-liquidity-amount 5000 --min-amount-to-remove-token-a "$WA" --min-amount-to-remove-token-b "$WB" --deadline "$DEADLINE"
reserves; read -r WA WB <<< "$($CALC remove "$RA" "$RB" "$LPS" 5000)"
case_ C30-remove-slippage reject "remove 5000 LP, min A = expected + 1" "$POOL_IDL" "$AMM" remove-liquidity "${LIQ[@]}" \
    --remove-liquidity-amount 5000 --min-amount-to-remove-token-a "$((WA + 1))" --min-amount-to-remove-token-b "$WB" --deadline "$DEADLINE"
ULP=$(val trader-lp .Fungible.balance)
case_ C31-remove-over-balance reject "remove 1 LP more than the user holds" "$POOL_IDL" "$AMM" remove-liquidity "${LIQ[@]}" \
    --remove-liquidity-amount "$((ULP + 1))" --min-amount-to-remove-token-a 1 --min-amount-to-remove-token-b 1 --deadline "$DEADLINE"

# --- Donation and sync ---
case_ C32-donate ok "donate 5000 A straight to vault A (token transfer, no AMM call)" "$TOKEN_IDL" "$TOKEN" transfer \
    --sender "$HOLD_A" --recipient "$VAULT_A" --amount-to-transfer 5000
reserves; OUT=$($CALC in_out "$RA" "$RB" 2000 $F)
case_ C33-swap-after-donate ok "swap 2000 A in after the donation, min out = expected from recorded reserves" "$POOL_IDL" "$AMM" swap-exact-input "${SWAP_AB[@]}" \
    --swap-amount-in 2000 --min-amount-out "$OUT" --deadline "$DEADLINE"
case_ C34-sync ok "sync reserves to vault balances" "$POOL_IDL" "$AMM" sync-reserves \
    --config "$CONFIG" --pool "$POOL" --vault-a "$VAULT_A" --vault-b "$VAULT_B" --current-tick-account "$TICK" --clock "$CLOCK"
case_ C35-sync-noop ok "sync again with no donation" "$POOL_IDL" "$AMM" sync-reserves \
    --config "$CONFIG" --pool "$POOL" --vault-a "$VAULT_A" --vault-b "$VAULT_B" --current-tick-account "$TICK" --clock "$CLOCK"

# --- New liquidity provider after a rejected attempt (follow-up to C04) ---
LIQ_NEW=("${LIQ[@]}"); LIQ_NEW[15]=$HOLD_LP_NEW; [[ ${LIQ_NEW[14]} == --user-holding-lp ]]
LIQ_NEW2=("${LIQ[@]}"); LIQ_NEW2[15]=$HOLD_LP_NEW2
reserves; LPX=$($CALC add "$RA" "$RB" "$LPS" 1000 1000000)
case_ C39-add-new-lp-rejected reject "new LP holding: add 1000 A, min LP = expected + 1" "$POOL_IDL" "$AMM" add-liquidity "${LIQ_NEW[@]}" \
    --min-amount-liquidity "$((LPX + 1))" --max-amount-to-add-token-a 1000 --max-amount-to-add-token-b 1000000 --deadline "$DEADLINE"
case_ C40-add-new-lp-after-reject ok "same LP holding: add 1000 A, min LP = expected" "$POOL_IDL" "$AMM" add-liquidity "${LIQ_NEW[@]}" \
    --min-amount-liquidity "$LPX" --max-amount-to-add-token-a 1000 --max-amount-to-add-token-b 1000000 --deadline "$DEADLINE"
reserves; LPX=$($CALC add "$RA" "$RB" "$LPS" 1000 1000000)
case_ C41-add-new-lp-fresh ok "never-used LP holding: add 1000 A, min LP = expected" "$POOL_IDL" "$AMM" add-liquidity "${LIQ_NEW2[@]}" \
    --min-amount-liquidity "$LPX" --max-amount-to-add-token-a 1000 --max-amount-to-add-token-b 1000000 --deadline "$DEADLINE"

# --- Extreme amounts (u128::MAX supply tokens) ---
case_ C36-create-huge ok "create pool X/Y with 2^100 / 2^100" "$POOL_IDL" "$AMM" new-definition "${CREATE_XY[@]}" \
    --token-a-amount 1267650600228229401496703205376 --token-b-amount 1267650600228229401496703205376 --deadline "$DEADLINE"
LAST_RX=1267650600228229401496703205376
OUT=$($CALC in_out "$LAST_RX" "$LAST_RX" 170141183460469231731687303715884105728 $F)
case_ C37-swap-huge ok "swap exact 2^127 X in on pool X/Y, min out = expected" "$POOL_IDL" "$AMM" swap-exact-input "${SWAP_XY[@]}" \
    --swap-amount-in 170141183460469231731687303715884105728 --min-amount-out "$OUT" --deadline "$DEADLINE"
RY=$(val pool-xy .reserve_b); RY_MINUS_1=$(python3 -c "print(int('$RY') - 1)")
case_ C38-swap-out-overflow reject "swap for exact out = reserve Y - 1 (input would exceed u128)" "$POOL_IDL" "$AMM" swap-exact-output "${SWAP_XY[@]}" \
    --exact-amount-out "$RY_MINUS_1" --max-amount-in "$U128_MAX" --deadline "$DEADLINE"

for program in token twap_oracle amm; do sha256sum "target/guest/$program.bin"; done
python3 "$(dirname "$(realpath "$0")")/check-public-flows.py" "$RUN_DIR"
