#!/usr/bin/env bash
# Runtime checks for qa-audits#15 (AMM -> TWAP oracle -> stablecoin) on the issue #10 pinned
# loopback chain, RISC0_DEV_MODE=1. Each check is logged as CHECK <id> <expected> <observed>.
set -euo pipefail
umask 077

ROOT=$(realpath "${1:-"$HOME/rfp004-repos"}")
PROGRAMS="$ROOT/lez-programs"
LEZ="$ROOT/logos-execution-zone"
SPEL_REPO="$ROOT/spel"
WALLET="$LEZ/target/release/wallet"
SEQ="$LEZ/target/release/sequencer_service"
SPEL="$SPEL_REPO/target/release/spel"
EXAMPLES=${EXAMPLES:-"$PROGRAMS/target/debug/examples"}
PORT=${PORT:-3041}
URL="http://127.0.0.1:$PORT"
RUN_DIR=$(mktemp -d "${RUN_PARENT:-$HOME}/rfp004-15.XXXXXX")
export LEE_WALLET_HOME_DIR="$RUN_DIR/wallet"
export RISC0_DEV_MODE=1
export RISC0_SERVER_PATH="$(command -v r0vm)"
export RUST_LOG=warn

[[ $(git -C "$PROGRAMS" rev-parse HEAD) == 1cfaa5e3446a684e6e9b61cfb243038dae6465ea ]]
[[ $(git -C "$LEZ" rev-parse HEAD) == d8596eb734bf9c9ce801afb92df06098a2eb098a ]]
[[ $(git -C "$SPEL_REPO" rev-parse HEAD) == c6f73ce21e4805f8430f03afdbdedf0b7e479a5e ]]
[[ $("$RISC0_SERVER_PATH" --version) == 'risc0-r0vm 3.0.5' ]]
for binary in "$WALLET" "$SEQ" "$SPEL" "$EXAMPLES/amm_pdas" "$EXAMPLES/twap_oracle_pdas" "$EXAMPLES/stablecoin_pdas"; do
    [[ -x "$binary" ]] || { echo "Build first; missing $binary" >&2; exit 1; }
done
cd "$PROGRAMS"
for program in token twap_oracle amm stablecoin; do
    [[ -s target/guest/$program.bin ]] || { echo "Build first; missing $program.bin" >&2; exit 1; }
done

mkdir -p "$LEE_WALLET_HOME_DIR" "$RUN_DIR/chain"
exec > >(tee "$RUN_DIR/oracle-wiring.log") 2>&1
log_cmd() { printf '$'; printf ' %q' "$@"; printf '\n'; }
run() { log_cmd "$@"; "$@"; }
rpc() {
    local method=$1 params=${2:-'[]'}
    curl -fsS --max-time 5 -H 'Content-Type: application/json' --data \
        "$(jq -nc --arg method "$method" --argjson params "$params" \
            '{jsonrpc:"2.0",id:1,method:$method,params:$params}')" "$URL" || return
    printf '\n'
}
check() { [[ $2 == changed || $2 == unchanged || $2 == nonzero || $2 == same-pool ]] && LAST_REASON=""; printf 'CHECK\t%s\t%s\t%s\t%s\n' "$1" "$2" "$3" "${4:-$LAST_REASON}" | tee -a "$RUN_DIR/checks.tsv"; }

echo "Run directory: $RUN_DIR"
run rustc +1.94.0 --version
run cargo +1.94.0 risczero --version
run "$RISC0_SERVER_PATH" --version
run "$SEQ" --version
run "$WALLET" --version
if rpc checkHealth >/dev/null 2>&1; then echo "Port $PORT in use" >&2; exit 1; fi

jq 'del(.gossip) | .metrics_address = null | .block_create_timeout = "2s"' \
    "$LEZ/lez/sequencer/service/configs/debug/sequencer_config.json" > "$RUN_DIR/sequencer.json"
jq --arg url "$URL" '.sequencers = [{sequencer_addr:$url}] | .seq_poll_timeout = "1s"' \
    "$LEZ/lez/wallet/configs/debug/wallet_config.json" > "$LEE_WALLET_HOME_DIR/wallet_config.json"
seq_args=("$SEQ" "$RUN_DIR/sequencer.json" --home "$RUN_DIR/chain" --listen-address 127.0.0.1 --port "$PORT")
nohup env RUST_LOG=info,kameo=warn "${seq_args[@]}" > "$RUN_DIR/sequencer.log" 2>&1 </dev/null &
seq_pid=$!
cleanup() {
    local rc=$?
    kill "$seq_pid" 2>/dev/null || true
    wait "$seq_pid" 2>/dev/null || true
    if (( rc != 0 )); then tail -45 "$RUN_DIR/sequencer.log"; fi
}
trap cleanup EXIT
for ((attempt=0; attempt<60; attempt++)); do
    kill -0 "$seq_pid"
    if rpc checkHealth 2>/dev/null | jq -e 'has("result")' >/dev/null; then break; fi
    sleep 1
done
rpc checkHealth | jq -e 'has("result")' >/dev/null

"$WALLET" account new public --label namespace-owner <<< "$(openssl rand -hex 24)" >/dev/null
LABELS="coll-def coll-hold sc-hold lp-hold borrower admin rogue-source z-def-a z-def-b z-hold-a z-hold-b z-hold-lp rev-lp-hold"
for label in $LABELS; do "$WALLET" account new public --label "$label" >/dev/null; done
id() { "$WALLET" account id --account-id "$1" | sed -n '1p'; }
OWNER=$(id namespace-owner)
COLL_DEF=$(id coll-def); COLL_HOLD=$(id coll-hold); SC_HOLD=$(id sc-hold); LP_HOLD=$(id lp-hold)
BORROWER=$(id borrower); ADMIN=$(id admin); ROGUE=$(id rogue-source)
Z_DEF_A=$(id z-def-a); Z_DEF_B=$(id z-def-b); Z_HOLD_A=$(id z-hold-a); Z_HOLD_B=$(id z-hold-b)
Z_HOLD_LP=$(id z-hold-lp); REV_LP_HOLD=$(id rev-lp-hold)

source "$SPEL_REPO/scripts/lib/fee-payer.sh"
FEE_PAYER=$(lez_fee_payer "$WALLET" '')
echo "Debug-genesis fee payer: $FEE_PAYER"

deploy() {
    local name=$1 expected_image=${2:-} binary="target/guest/$1.bin" image header
    image=$("$SPEL" program-id "$binary" --format hex)
    if [[ -n $expected_image && $image != "$expected_image" ]]; then
        echo "ImageID mismatch for $name: $image" >&2; return 1
    fi
    echo "$name ImageID: $image" >&2
    header=$("$SPEL" deploy "$binary" --fee-payer "$FEE_PAYER" --immutable 2>"$RUN_DIR/$name.deploy.log")
    echo "$name program header: $header" >&2
    printf '%s\n' "$header"
}
TOKEN=$(deploy token 057e9cc28c7bd70645f74fa2c38e9880e532d369bda31a4bbaa24f5f1e93a6bc)
TWAP=$(deploy twap_oracle 979279c5fa38173abf0d35370e2c481303ec28f959c7eeb98ab74a7e90ce3edd)
AMM=$(deploy amm a69de4104f829dadb356f05f46ea1d79fc819618f2ebedb341d5b2e041d8bd79)
SC=$(deploy stablecoin "${STABLECOIN_IMAGE_ID:-}")

AMM_IDL=artifacts/amm-idl.json
TOKEN_IDL=artifacts/token-idl.json
TWAP_IDL=artifacts/twap_oracle-idl.json
SC_IDL=artifacts/stablecoin-idl.json
CLOCK=4BdcjoXkq786TMWcBGGHqcxeLYMZmn17rL4eM9ZyRWNU
DEADLINE=18446744073709551615
NONCE=$(printf '%064d' 0)
Q64=18446744073709551616
WINDOW=${WINDOW:-10240000}        # min_interval = WINDOW/2048 = 5 s, max tail = 4 intervals = 20 s
MIN_INTERVAL_S=$(( WINDOW / 2048 / 1000 ))
MAX_AGE_MS=${MAX_AGE_MS:-60000}
MIN_RATE_GAP_MS=${MIN_RATE_GAP_MS:-1000}

# tx <name> <idl> <program> <args...>: 0 if the program accepted it, 1 if it panicked or never landed.
# A rejected transaction is still "confirmed" and included in a block, so the result comes from the
# guest panic the sequencer logs while executing it.
LAST_REASON=""
tx() {
    local name=$1 idl=$2 program=$3 hash start
    shift 3
    start=$(wc -l < "$RUN_DIR/sequencer.log")
    log_cmd "$SPEL" --idl "$idl" --program "$program" --fee-payer "$FEE_PAYER" -- "$@"
    "$SPEL" --idl "$idl" --program "$program" --fee-payer "$FEE_PAYER" -- "$@" \
        > "$RUN_DIR/$name.tx.log" 2>&1 || true
    hash=$(awk '/tx_hash:/ {print $2}' "$RUN_DIR/$name.tx.log" | tail -n 1)
    [[ $hash =~ ^[0-9a-f]{64}$ ]] || { LAST_REASON="no tx hash"; echo "[$name] no tx hash"; return 1; }
    rpc getTransaction "[\"$hash\"]" > "$RUN_DIR/$name.receipt.json" || true
    sleep 1
    tail -n +"$((start + 1))" "$RUN_DIR/sequencer.log" > "$RUN_DIR/$name.seq.log"
    if grep -q "panicked at" "$RUN_DIR/$name.seq.log"; then
        LAST_REASON=$(grep -A1 -m1 "panicked at" "$RUN_DIR/$name.seq.log" | tail -n 1 | cut -c1-160)
        echo "[$name] REJECTED by program: $LAST_REASON (tx $hash)"
        return 1
    fi
    LAST_REASON=""
    echo "[$name] ACCEPTED in block $(jq '.result[1]' "$RUN_DIR/$name.receipt.json") (tx $hash)"
}
must() { tx "$@" || { echo "FATAL: $1 failed" >&2; exit 1; }; }
expect_ok() { local id=$1; shift; if tx "$id" "$@"; then check "$id" accepted accepted; else check "$id" accepted rejected; fi; }
expect_fail() { local id=$1; shift; if tx "$id" "$@"; then check "$id" rejected accepted; else check "$id" rejected rejected; fi; }
inspect() {
    local name=$1 idl=$2 account=$3 type=$4
    "$SPEL" --idl "$idl" inspect "$account" --type "$type" > "$RUN_DIR/$name.json" 2>"$RUN_DIR/$name.inspect.err" \
        || { echo "[$name] inspect failed: $(tail -n 1 "$RUN_DIR/$name.inspect.err")"; echo null > "$RUN_DIR/$name.json"; }
    echo "[$name] $(jq -c . "$RUN_DIR/$name.json" | cut -c1-400)"
}
field() { awk -v key="$1" '$1 == key {print $2}' "$2"; }
same() { cmp -s "$RUN_DIR/$1.json" "$RUN_DIR/$2.json" && echo unchanged || echo changed; }

# --- PDAs -----------------------------------------------------------------------------------
"$EXAMPLES/stablecoin_pdas" "$SC" globals | tee "$RUN_DIR/sc-globals.txt"
PARAMS=$(field protocol_parameters "$RUN_DIR/sc-globals.txt")
ACCUM=$(field stability_fee_accumulator "$RUN_DIR/sc-globals.txt")
REDEMPTION=$(field redemption_price_state "$RUN_DIR/sc-globals.txt")
SC_DEF=$(field stablecoin_definition "$RUN_DIR/sc-globals.txt")
SC_MASTER=$(field stablecoin_master_holding "$RUN_DIR/sc-globals.txt")
"$EXAMPLES/stablecoin_pdas" "$SC" "$BORROWER" 0 | tee "$RUN_DIR/sc-position.txt"
POSITION=$(field position "$RUN_DIR/sc-position.txt"); POS_VAULT=$(field position_vault "$RUN_DIR/sc-position.txt")

"$EXAMPLES/amm_pdas" "$AMM" "$OWNER" "$TWAP" "$SC_DEF" "$COLL_DEF" | tee "$RUN_DIR/pdas.txt"
"$EXAMPLES/amm_pdas" "$AMM" "$OWNER" "$TWAP" "$COLL_DEF" "$SC_DEF" | tee "$RUN_DIR/pdas-reversed.txt"
CONFIG=$(field config "$RUN_DIR/pdas.txt"); POOL=$(field pool "$RUN_DIR/pdas.txt")
VAULT_A=$(field vault_a "$RUN_DIR/pdas.txt"); VAULT_B=$(field vault_b "$RUN_DIR/pdas.txt")
LP_DEF=$(field pool_definition_lp "$RUN_DIR/pdas.txt"); LP_LOCK=$(field lp_lock_holding "$RUN_DIR/pdas.txt")
TICK=$(field current_tick_account "$RUN_DIR/pdas.txt"); FEE_A=$(field protocol_fee_a "$RUN_DIR/pdas.txt")
if [[ $(field pool "$RUN_DIR/pdas-reversed.txt") == "$POOL" ]]; then
    check O1-pool-pda-order-independent same-pool same-pool
else
    check O1-pool-pda-order-independent same-pool different-pool
fi
"$EXAMPLES/twap_oracle_pdas" "$TWAP" "$POOL" "$WINDOW" | tee "$RUN_DIR/twap-pdas.txt"
OBS=$(field price_observations "$RUN_DIR/twap-pdas.txt"); ORACLE=$(field oracle_price_account "$RUN_DIR/twap-pdas.txt")
"$EXAMPLES/twap_oracle_pdas" "$TWAP" "$ROGUE" "$WINDOW" | tee "$RUN_DIR/twap-pdas-rogue.txt"
ROGUE_ORACLE=$(field oracle_price_account "$RUN_DIR/twap-pdas-rogue.txt")

# --- Tokens, AMM config, stablecoin bound to the not-yet-created AMM oracle --------------------
must coll-token "$TOKEN_IDL" "$TOKEN" new-fungible-definition --name 'QA Collateral' \
    --total-supply 10000000 --mint-authority none \
    --definition-target-account "$COLL_DEF" --holding-target-account "$COLL_HOLD"
must amm-init "$AMM_IDL" "$AMM" initialize --owner "$OWNER" --config "$CONFIG" \
    --nonce "$NONCE" --token-program-id "$TOKEN" --twap-oracle-program-id "$TWAP" \
    --authority "$OWNER" --swap-fee-bps 30 --protocol-fee-bps 2500
expect_ok S1-init-with-absent-oracle "$SC_IDL" "$SC" initialize-program \
    --deployment-authority "$SC" --protocol-parameters "$PARAMS" \
    --stability-fee-accumulator "$ACCUM" --redemption-price-state "$REDEMPTION" \
    --stablecoin-definition "$SC_DEF" --stablecoin-master-holding "$SC_MASTER" \
    --collateral-definition "$COLL_DEF" --market-price-oracle "$ORACLE" --clock "$CLOCK" \
    --freeze-authority-account-id "$ADMIN" \
    --initial-stability-fee-per-millisecond 1000000000001500000000000000 \
    --initial-controller-proportional-gain 1000000000 --initial-controller-integral-gain 0 \
    --initial-minimum-collateralization-ratio 1500000000000000000000000000 \
    --minimum-milliseconds-between-rate-updates "$MIN_RATE_GAP_MS" \
    --maximum-oracle-price-age-milliseconds "$MAX_AGE_MS" \
    --initial-redemption-price 1000000000000000000000000000 --stablecoin-name 'QA Stable' \
    --initial-admin-account-id "$ADMIN" --minimum-debt-amount 10 --debt-ceiling 1000000000000 \
    --market-price-oracle-program-id "$TWAP"
inspect params "$SC_IDL" "$PARAMS" ProtocolParameters
[[ $(jq -r 'type' "$RUN_DIR/params.json") == object ]] || { echo "FATAL: stablecoin not initialised" >&2; exit 1; }

must sc-hold-init "$TOKEN_IDL" "$TOKEN" initialize-account --definition-account "$SC_DEF" \
    --account-to-initialize "$SC_HOLD"
must open-position "$SC_IDL" "$SC" open-position --owner "$BORROWER" --position "$POSITION" \
    --vault "$POS_VAULT" --user-collateral-holding "$COLL_HOLD" --collateral-definition "$COLL_DEF" \
    --protocol-parameters "$PARAMS" --clock "$CLOCK" --position-nonce 0 --initial-collateral-amount 1000000
must generate-debt "$SC_IDL" "$SC" generate-debt --owner "$BORROWER" --position "$POSITION" \
    --stablecoin-definition "$SC_DEF" --user-stablecoin-holding "$SC_HOLD" \
    --stablecoin-master-holding "$SC_MASTER" --stability-fee-accumulator "$ACCUM" \
    --redemption-price-state "$REDEMPTION" --protocol-parameters "$PARAMS" --clock "$CLOCK" --amount 300000
inspect sc-hold "$TOKEN_IDL" "$SC_HOLD" TokenHolding

# --- Stablecoin before the oracle exists --------------------------------------------------------
redemption_tx() {
    local expect=$1 id=$2 mode=$3
    if [[ $mode == strict ]]; then
        "$expect" "$id" "$SC_IDL" "$SC" update-redemption-rate --caller "$ADMIN" --protocol-parameters "$PARAMS" \
            --redemption-price-state "$REDEMPTION" --market-price-oracle "$CUR_ORACLE" --clock "$CLOCK"
    else
        "$expect" "$id" "$SC_IDL" "$SC" refresh-globals --caller "$ADMIN" --protocol-parameters "$PARAMS" \
            --stability-fee-accumulator "$ACCUM" --stablecoin-definition "$SC_DEF" \
            --stablecoin-master-holding "$SC_MASTER" --redemption-price-state "$REDEMPTION" \
            --market-price-oracle "$CUR_ORACLE" --clock "$CLOCK"
    fi
}
CUR_ORACLE=$ORACLE
redemption_tx expect_fail F1-strict-read-absent-oracle strict
inspect redemption-0 "$SC_IDL" "$REDEMPTION" RedemptionPriceState
redemption_tx expect_ok F2-soft-read-absent-oracle soft
inspect redemption-1 "$SC_IDL" "$REDEMPTION" RedemptionPriceState
check F2b-soft-read-leaves-redemption unchanged "$(same redemption-0 redemption-1)"

# --- Real producer: pool with stablecoin as token A, collateral as token B ---------------------------
must pool-create "$AMM_IDL" "$AMM" new-definition --config "$CONFIG" --pool "$POOL" \
    --vault-a "$VAULT_A" --vault-b "$VAULT_B" --pool-definition-lp "$LP_DEF" \
    --lp-lock-holding "$LP_LOCK" --user-holding-a "$SC_HOLD" --user-holding-b "$COLL_HOLD" \
    --user-holding-lp "$LP_HOLD" --current-tick-account "$TICK" --clock "$CLOCK" \
    --token-a-amount 100000 --token-b-amount 200000 --deadline "$DEADLINE"
inspect pool-0 "$AMM_IDL" "$POOL" PoolDefinition
inspect tick-0 "$TWAP_IDL" "$TICK" CurrentTickAccount
expect_fail O2-reversed-pool-rejected "$AMM_IDL" "$AMM" new-definition --config "$CONFIG" --pool "$POOL" \
    --vault-a "$(field vault_a "$RUN_DIR/pdas-reversed.txt")" --vault-b "$(field vault_b "$RUN_DIR/pdas-reversed.txt")" \
    --pool-definition-lp "$LP_DEF" --lp-lock-holding "$LP_LOCK" --user-holding-a "$COLL_HOLD" \
    --user-holding-b "$SC_HOLD" --user-holding-lp "$REV_LP_HOLD" --current-tick-account "$TICK" \
    --clock "$CLOCK" --token-a-amount 200000 --token-b-amount 100000 --deadline "$DEADLINE"

must create-obs "$AMM_IDL" "$AMM" create-price-observations --config "$CONFIG" --pool "$POOL" \
    --current-tick-account "$TICK" --price-observations "$OBS" --clock "$CLOCK" --window-duration "$WINDOW"
must create-oracle "$AMM_IDL" "$AMM" create-oracle-price-account --config "$CONFIG" --pool "$POOL" \
    --oracle-price-account "$ORACLE" --clock "$CLOCK" --window-duration "$WINDOW"
inspect oracle-0 "$TWAP_IDL" "$ORACLE" OraclePriceAccount
inspect obs-0 "$TWAP_IDL" "$OBS" PriceObservations
run rpc getAccount "[\"$ORACLE\"]" > "$RUN_DIR/oracle-0.raw.json"

publish() { tx "$1" "$TWAP_IDL" "$TWAP" publish-price --price-observations "$2" --oracle-price-account "$3" \
    --current-tick-account "$4" --clock "$CLOCK" --price-source-id "$5" --window-duration "$WINDOW"; }
record() { tx "$1" "$TWAP_IDL" "$TWAP" record-tick --price-observations "$2" --current-tick-account "$3" \
    --clock "$CLOCK" --price-source-id "$4" --window-duration "$WINDOW"; }

if publish publish-1obs "$OBS" "$ORACLE" "$TICK" "$POOL"; then check T1-publish-with-1-observation accepted accepted; else check T1-publish-with-1-observation accepted rejected; fi
inspect oracle-1 "$TWAP_IDL" "$ORACLE" OraclePriceAccount
check T1b-publish-1-obs-leaves-oracle unchanged "$(same oracle-0 oracle-1)"

# Seed spot price consumed as a fresh price before any TWAP exists.
redemption_tx expect_ok S2-strict-read-of-seed-spot-price strict
inspect redemption-2 "$SC_IDL" "$REDEMPTION" RedemptionPriceState

# --- AMM activity does not record observations ---------------------------------------------------
swap() { tx "$1" "$AMM_IDL" "$AMM" swap-exact-input --config "$CONFIG" --pool "$POOL" \
    --vault-a "$VAULT_A" --vault-b "$VAULT_B" --user-input-holding "$SC_HOLD" \
    --user-output-holding "$COLL_HOLD" --current-tick-account "$TICK" --clock "$CLOCK" \
    --protocol-fee-holding "$FEE_A" --swap-amount-in "$2" --min-amount-out 1 --deadline "$DEADLINE"; }
sleep $(( MIN_INTERVAL_S + 1 ))
swap swap-1 10000 || { echo "FATAL: swap-1" >&2; exit 1; }
sleep $(( MIN_INTERVAL_S + 1 ))
swap swap-2 10000 || { echo "FATAL: swap-2" >&2; exit 1; }
inspect tick-1 "$TWAP_IDL" "$TICK" CurrentTickAccount
inspect obs-1 "$TWAP_IDL" "$OBS" PriceObservations
inspect oracle-2 "$TWAP_IDL" "$ORACLE" OraclePriceAccount
check A1-swaps-move-current-tick changed "$(same tick-0 tick-1)"
check A2-swaps-record-observation changed "$(same obs-0 obs-1)"
check A3-swaps-publish-price changed "$(same oracle-1 oracle-2)"

# --- Keeper path: permissionless record + publish ---------------------------------------------
if record record-1 "$OBS" "$TICK" "$POOL"; then check T2-record-tick accepted accepted; else check T2-record-tick accepted rejected; fi
inspect obs-2 "$TWAP_IDL" "$OBS" PriceObservations
check T2b-record-tick-adds-observation changed "$(same obs-1 obs-2)"
if publish publish-2 "$OBS" "$ORACLE" "$TICK" "$POOL"; then check T3-publish-twap accepted accepted; else check T3-publish-twap accepted rejected; fi
inspect oracle-3 "$TWAP_IDL" "$ORACLE" OraclePriceAccount
check T3b-publish-updates-oracle changed "$(same oracle-2 oracle-3)"
sleep 2
redemption_tx expect_ok S3-strict-read-of-published-twap strict
inspect redemption-3 "$SC_IDL" "$REDEMPTION" RedemptionPriceState

# --- Freshness: stale tail and stale oracle ---------------------------------------------------
sleep $(( MIN_INTERVAL_S * 4 + 6 ))
if publish publish-stale-tail "$OBS" "$ORACLE" "$TICK" "$POOL"; then check T4-publish-after-stale-tail rejected accepted; else check T4-publish-after-stale-tail rejected rejected; fi
inspect oracle-4 "$TWAP_IDL" "$ORACLE" OraclePriceAccount
NOW_S=$(date +%s); ORACLE_TS_S=$(( $(jq -r '.timestamp' "$RUN_DIR/oracle-4.json") / 1000 ))
WAIT_S=$(( ORACLE_TS_S + MAX_AGE_MS / 1000 + 6 - NOW_S ))
(( WAIT_S > 0 )) && sleep "$WAIT_S"
inspect redemption-4 "$SC_IDL" "$REDEMPTION" RedemptionPriceState
redemption_tx expect_fail F3-strict-read-stale-oracle strict
redemption_tx expect_ok F4-soft-read-stale-oracle soft
inspect redemption-5 "$SC_IDL" "$REDEMPTION" RedemptionPriceState
check F4b-soft-stale-leaves-redemption unchanged "$(same redemption-4 redemption-5)"
if record record-2 "$OBS" "$TICK" "$POOL" && publish publish-3 "$OBS" "$ORACLE" "$TICK" "$POOL"; then
    check T5-record-then-publish-recovers accepted accepted; else check T5-record-then-publish-recovers accepted rejected; fi
inspect oracle-5 "$TWAP_IDL" "$ORACLE" OraclePriceAccount
inspect obs-3 "$TWAP_IDL" "$OBS" PriceObservations

# --- Zero price: a pool whose TWAP rounds to 0 --------------------------------------------------
must z-token-a "$TOKEN_IDL" "$TOKEN" new-fungible-definition --name 'QA Zero A' \
    --total-supply 36893488147419103232 --mint-authority none \
    --definition-target-account "$Z_DEF_A" --holding-target-account "$Z_HOLD_A"
must z-token-b "$TOKEN_IDL" "$TOKEN" new-fungible-definition --name 'QA Zero B' \
    --total-supply 1000 --mint-authority none \
    --definition-target-account "$Z_DEF_B" --holding-target-account "$Z_HOLD_B"
"$EXAMPLES/amm_pdas" "$AMM" "$OWNER" "$TWAP" "$Z_DEF_A" "$Z_DEF_B" | tee "$RUN_DIR/z-pdas.txt"
Z_POOL=$(field pool "$RUN_DIR/z-pdas.txt"); Z_TICK=$(field current_tick_account "$RUN_DIR/z-pdas.txt")
"$EXAMPLES/twap_oracle_pdas" "$TWAP" "$Z_POOL" "$WINDOW" | tee "$RUN_DIR/z-twap-pdas.txt"
Z_OBS=$(field price_observations "$RUN_DIR/z-twap-pdas.txt"); Z_ORACLE=$(field oracle_price_account "$RUN_DIR/z-twap-pdas.txt")
must z-pool "$AMM_IDL" "$AMM" new-definition --config "$CONFIG" --pool "$Z_POOL" \
    --vault-a "$(field vault_a "$RUN_DIR/z-pdas.txt")" --vault-b "$(field vault_b "$RUN_DIR/z-pdas.txt")" \
    --pool-definition-lp "$(field pool_definition_lp "$RUN_DIR/z-pdas.txt")" \
    --lp-lock-holding "$(field lp_lock_holding "$RUN_DIR/z-pdas.txt")" --user-holding-a "$Z_HOLD_A" \
    --user-holding-b "$Z_HOLD_B" --user-holding-lp "$Z_HOLD_LP" --current-tick-account "$Z_TICK" \
    --clock "$CLOCK" --token-a-amount "$Q64" --token-b-amount 1 --deadline "$DEADLINE"
inspect z-tick "$TWAP_IDL" "$Z_TICK" CurrentTickAccount
must z-obs "$AMM_IDL" "$AMM" create-price-observations --config "$CONFIG" --pool "$Z_POOL" \
    --current-tick-account "$Z_TICK" --price-observations "$Z_OBS" --clock "$CLOCK" --window-duration "$WINDOW"
must z-oracle "$AMM_IDL" "$AMM" create-oracle-price-account --config "$CONFIG" --pool "$Z_POOL" \
    --oracle-price-account "$Z_ORACLE" --clock "$CLOCK" --window-duration "$WINDOW"
inspect z-oracle-0 "$TWAP_IDL" "$Z_ORACLE" OraclePriceAccount
sleep $(( MIN_INTERVAL_S + 1 ))
record z-record "$Z_OBS" "$Z_TICK" "$Z_POOL" || true
if publish z-publish "$Z_OBS" "$Z_ORACLE" "$Z_TICK" "$Z_POOL"; then check Z1-publish-zero-twap rejected accepted; else check Z1-publish-zero-twap rejected rejected; fi
inspect z-oracle-1 "$TWAP_IDL" "$Z_ORACLE" OraclePriceAccount
check Z1b-published-price nonzero "$(jq -r '.price' "$RUN_DIR/z-oracle-1.json")"

# --- Consumer trust: pair check and source_id ----------------------------------------------------
set_oracle() { tx "$1" "$SC_IDL" "$SC" set-market-price-oracle --admin "$ADMIN" \
    --protocol-parameters "$PARAMS" --new-oracle "$2" --new-oracle-program-id "$TWAP"; }
if set_oracle bind-wrong-pair "$Z_ORACLE"; then check P1-bind-wrong-pair rejected accepted; else check P1-bind-wrong-pair rejected rejected; fi
must rogue-oracle "$TWAP_IDL" "$TWAP" create-oracle-price-account --oracle-price-account "$ROGUE_ORACLE" \
    --price-source "$ROGUE" --clock "$CLOCK" --base-asset "$SC_DEF" --quote-asset "$COLL_DEF" \
    --initial-price 9223372036854775808 --window-duration "$WINDOW"
inspect rogue-oracle "$TWAP_IDL" "$ROGUE_ORACLE" OraclePriceAccount
if set_oracle bind-wallet-sourced "$ROGUE_ORACLE"; then check P2-bind-wallet-sourced-oracle rejected accepted; else check P2-bind-wallet-sourced-oracle rejected rejected; fi
inspect params-rogue "$SC_IDL" "$PARAMS" ProtocolParameters
CUR_ORACLE=$ROGUE_ORACLE
redemption_tx expect_fail P3-strict-read-wallet-sourced-price strict
inspect redemption-6 "$SC_IDL" "$REDEMPTION" RedemptionPriceState

echo "Run directory: $RUN_DIR"
column -t -s $'\t' "$RUN_DIR/checks.tsv"
