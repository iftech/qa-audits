#!/usr/bin/env python3
"""Independent checker for run-public-flows.sh.

Replays every case on a pure-Python model of the AMM spec (integer floor/ceil
maths written from the issue text and the AMM formulas, not from chain output),
then compares every tracked account on chain with the model after each case.
Usage: check-public-flows.py <RUN_DIR>
"""
import json, math, sys
from decimal import Decimal, getcontext
from pathlib import Path

getcontext().prec = 80
D, FEE, PFEE, MIN_LIQ = 10_000, 30, 2_500, 1_000
SUPPLY, U128_MAX = 1_000_000, 2**128 - 1
run = Path(sys.argv[1])
cases = [json.loads(l) for l in (run / "cases.jsonl").read_text().splitlines() if l.strip()]
snap = lambda tag: json.loads((run / "snap" / tag / "all.json").read_text())

POOLS = {  # pool, vault_a, vault_b, user_a, user_b, user_lp, lp_lock, fee_a, fee_b, tick
    "main": ("pool", "vault-a", "vault-b", "trader-a", "trader-b", "trader-lp", "lp-lock", "fee-a", "fee-b", "tick"),
    "ac": ("pool-ac", "vault-ac-a", "vault-ac-c", "trader-a", "trader-c", "trader-lp-ac2", "lp-lock-ac", None, None, "tick-ac"),
    "xy": ("pool-xy", "vault-xy-x", "vault-xy-y", "trader-x", "trader-y", "trader-lp-xy", "lp-lock-xy", "fee-xy-x", None, "tick-xy"),
}
POOLS["ac1"] = POOLS["ac"][:5] + ("trader-lp-ac",) + POOLS["ac"][6:]
POOLS["new"] = POOLS["main"][:5] + ("trader-lp-new",) + POOLS["main"][6:]
POOLS["new2"] = POOLS["main"][:5] + ("trader-lp-new2",) + POOLS["main"][6:]
POOL_OF = {"C39": "new", "C40": "new", "C41": "new2", "C03": "ac1", "C04": "ac1", "C04b": "ac", "C05": "ac", "C06": "ac", "C36": "xy", "C37": "xy", "C38": "xy"}
REVERSED = {"C08", "C11"}  # B -> A swaps

def ceil_div(a, b): return -(-a // b)
def price_q64(ra, rb): return min((rb << 64) // ra, U128_MAX)
def tick_of(price):
    """Largest tick t with 1.0001^(t/2) <= sqrtPriceX96 / 2^96 (Uniswap V3 definition)."""
    sqrt_x96 = math.isqrt(price << 128)
    t = int(((Decimal(sqrt_x96) / (Decimal(2) ** 96)).ln() * 2 / Decimal("1.0001").ln()).to_integral_value(rounding="ROUND_FLOOR"))
    return t

def bal(s, k):
    v = s.get(k, {})
    return None if v.get("uninitialized") else int(v["Fungible"]["balance"])
def pool_of(s, k):
    v = s.get(k, {})
    return None if v.get("uninitialized") else (int(v["reserve_a"]), int(v["reserve_b"]), int(v["liquidity_pool_supply"]))
def tick(s, k):
    v = s.get(k, {})
    return None if v.get("uninitialized") else (int(v["tick"]), int(v["last_updated"]))

class Reject(Exception): pass
def need(cond, why):
    if not cond: raise Reject(why)

def model(case, s):
    """Return (expected state dict of balances/pools/ticks, outcome, note)."""
    a = {k.lstrip("-"): v for k, v in zip(case["args"][1::2], case["args"][2::2])}; op = case["args"][0]
    g = lambda k: int(a[k])
    cid = case["id"].split("-")[0]
    P, VA, VB, UA, UB, ULP, LOCK, FA, FB, T = POOLS[POOL_OF.get(cid, "main")]
    bals = {k: bal(s, k) for k in s if "pool" not in k[:4] and not k.startswith(("tick", "raw-"))}
    pools = {k: pool_of(s, k) for k in [v[0] for v in POOLS.values()]}
    ticks = {k: tick(s, k) for k in [v[9] for v in POOLS.values()]}
    exp = {"bal": dict(bals), "pool": dict(pools), "tick_value": {}, "tick_moves": set()}
    now = max([t[1] for t in ticks.values() if t] or [0])  # latest chain timestamp seen (ms)
    note = ""
    def set_tick(ra, rb):
        exp["tick_value"][T] = tick_of(price_q64(ra, rb)); exp["tick_moves"].add(T)
    try:
        if "deadline" in a:
            need(g("deadline") > now, f"deadline {g('deadline')} <= chain time >= {now}")
        if op == "new-definition":
            x, y = g("token-a-amount"), g("token-b-amount")
            need(pools[P] is None, "pool already exists")
            need(x > 0 and y > 0, "zero deposit")
            lp = math.isqrt(x * y)
            need(lp > MIN_LIQ, f"initial LP {lp} <= MINIMUM_LIQUIDITY")
            need(bals[UA] >= x and bals[UB] >= y, "balance")
            b = exp["bal"]; b[UA] -= x; b[UB] -= y; b[VA] = x; b[VB] = y
            b[ULP] = (b[ULP] or 0) + lp - MIN_LIQ; b[LOCK] = MIN_LIQ
            exp["pool"][P] = (x, y, lp); set_tick(x, y)
            note = f"LP = isqrt({x}*{y}) = {lp}; user {lp - MIN_LIQ}, locked {MIN_LIQ}"
        elif op in ("swap-exact-input", "swap-exact-output"):
            ra, rb, S = pools[P]
            rev = cid in REVERSED
            r_in, r_out = (rb, ra) if rev else (ra, rb)
            u_in, u_out, v_in, v_out, f_in = (UB, UA, VB, VA, FB) if rev else (UA, UB, VA, VB, FA)
            if op == "swap-exact-input":
                amt, mn = g("swap-amount-in"), g("min-amount-out")
                need(amt > 0, "zero input")
                eff = amt * (D - FEE) // D
                need(eff > 0, "effective input rounds to 0")
                out = r_out * eff // (r_in + eff)
                need(out >= mn, f"out {out} < min {mn}"); need(out > 0, "zero output")
                gross = amt
                note = f"eff = floor({amt}*9970/10000) = {eff}; out = floor({r_out}*{eff}/({r_in}+{eff})) = {out}"
            else:
                out, mx = g("exact-amount-out"), g("max-amount-in")
                need(out > 0, "zero output"); need(out < r_out, "output >= reserve")
                eff = ceil_div(r_in * out, r_out - out)
                gross = ceil_div(eff * D, D - FEE)
                need(gross <= U128_MAX, "required input exceeds u128")
                need(gross <= mx, f"required in {gross} > max {mx}")
                note = f"eff = ceil({r_in}*{out}/({r_out}-{out})) = {eff}; in = ceil({eff}*10000/9970) = {gross}"
            need(bals[u_in] >= gross, "input balance too low")
            prot = (gross - eff) * PFEE // D
            note += f"; fee {gross - eff}, protocol {prot}"
            b = exp["bal"]; b[u_in] -= gross; b[u_out] += out
            b[v_in] += gross - prot; b[v_out] -= out
            if prot or b.get(f_in) is not None: b[f_in] = (b[f_in] or 0) + prot
            r_in2, r_out2 = r_in + gross - prot, r_out - out
            ra2, rb2 = (r_out2, r_in2) if rev else (r_in2, r_out2)
            exp["pool"][P] = (ra2, rb2, S); set_tick(ra2, rb2)
        elif op == "add-liquidity":
            ra, rb, S = pools[P]
            mx_a, mx_b, mn = g("max-amount-to-add-token-a"), g("max-amount-to-add-token-b"), g("min-amount-liquidity")
            need(mn > 0, "min LP is 0")
            act_a = min(ra * mx_b // rb, mx_a); act_b = min(rb * mx_a // ra, mx_b)
            need(act_a > 0 and act_b > 0, "zero deposit")
            lp = min(S * act_a // ra, S * act_b // rb)
            need(lp > 0, "zero LP"); need(lp >= mn, f"LP {lp} < min {mn}")
            need(bals[UA] >= act_a and bals[UB] >= act_b, "balance")
            b = exp["bal"]; b[UA] -= act_a; b[UB] -= act_b; b[VA] += act_a; b[VB] += act_b; b[ULP] = (b[ULP] or 0) + lp
            exp["pool"][P] = (ra + act_a, rb + act_b, S + lp); set_tick(ra + act_a, rb + act_b)
            note = f"deposit {act_a} A / {act_b} B; LP = min(floor({S}*{act_a}/{ra}), floor({S}*{act_b}/{rb})) = {lp}"
        elif op == "remove-liquidity":
            ra, rb, S = pools[P]
            amt, mn_a, mn_b = g("remove-liquidity-amount"), g("min-amount-to-remove-token-a"), g("min-amount-to-remove-token-b")
            need(amt > 0, "zero LP"); need(mn_a > 0 and mn_b > 0, "zero minimum")
            need(amt <= bals[ULP], "more LP than user holds")
            need(S - amt >= MIN_LIQ, "would burn locked LP")
            wa, wb = ra * amt // S, rb * amt // S
            need(wa >= mn_a and wb >= mn_b, f"out {wa}/{wb} < min {mn_a}/{mn_b}")
            b = exp["bal"]; b[UA] += wa; b[UB] += wb; b[VA] -= wa; b[VB] -= wb; b[ULP] -= amt
            exp["pool"][P] = (ra - wa, rb - wb, S - amt); set_tick(ra - wa, rb - wb)
            note = f"out A = floor({ra}*{amt}/{S}) = {wa}; out B = floor({rb}*{amt}/{S}) = {wb}"
        elif op == "transfer":
            amt = g("amount-to-transfer"); need(bals["trader-a"] >= amt, "balance")
            b = exp["bal"]; b["trader-a"] -= amt; b["vault-a"] += amt
            note = f"vault A +{amt}; pool reserves unchanged"
        elif op == "sync-reserves":
            ra, rb, S = pools[P]; va, vb = bals[VA], bals[VB]
            need(va >= ra and vb >= rb, "vault below reserve")
            exp["pool"][P] = (va, vb, S); set_tick(va, vb)
            note = f"reserves ({ra}, {rb}) -> vaults ({va}, {vb})"
        outcome = "ok"
    except Reject as e:
        exp = {"bal": bals, "pool": pools, "tick_value": {}, "tick_moves": set()}
        outcome, note = "reject", str(e)
    return exp, outcome, note

def conservation(s):
    errs = []
    sums = {
        "A": (["trader-a", "vault-a", "fee-a", "vault-ac-a"], SUPPLY),
        "B": (["trader-b", "vault-b", "fee-b"], SUPPLY),
        "C": (["trader-c", "vault-ac-c"], SUPPLY),
        "X": (["trader-x", "vault-xy-x", "fee-xy-x"], U128_MAX),
        "Y": (["trader-y", "vault-xy-y"], U128_MAX),
    }
    for tok, (keys, total) in sums.items():
        got = sum(bal(s, k) or 0 for k in keys)
        if got != total: errs.append(f"token {tok} sum {got} != supply {total}")
    lp_holders = {"main": ["trader-lp", "trader-lp-new", "trader-lp-new2", "lp-lock"],
                  "ac": ["trader-lp-ac", "trader-lp-ac2", "lp-lock-ac"], "xy": ["trader-lp-xy", "lp-lock-xy"]}
    for name, keys in lp_holders.items():
        p = pool_of(s, POOLS[name][0])
        if p and sum(bal(s, k) or 0 for k in keys) != p[2]:
            errs.append(f"{name}: user LP + locked LP != pool LP supply")
    return errs

results = []
for c in cases:
    before, after = snap(c["prev"]), snap(c["tag"])
    exp, outcome, note = model(c, before)
    diffs = []
    for k, v in exp["bal"].items():
        if bal(after, k) != v: diffs.append(f"{k}: expected {v}, actual {bal(after, k)}")
    for k, v in exp["pool"].items():
        if pool_of(after, k) != v: diffs.append(f"{k}: expected {v}, actual {pool_of(after, k)}")
    for T in sorted({v[9] for v in POOLS.values()}):
        tb, ta = tick(before, T), tick(after, T)
        if T in exp["tick_moves"]:
            if ta is None or ta[0] != exp["tick_value"][T]:
                diffs.append(f"{T}: expected tick {exp['tick_value'][T]}, actual {ta}")
            elif tb is not None and ta[1] <= tb[1]:
                diffs.append(f"{T}: last_updated did not advance ({tb[1]} -> {ta[1]})")
        elif ta != tb:
            diffs.append(f"{T}: changed on a case that should not touch it ({tb} -> {ta})")
    diffs += conservation(after)
    # constant-product / share-value checks on accepted pool cases
    P = POOLS[POOL_OF.get(c["id"].split("-")[0], "main")][0]
    pb, pa = pool_of(before, P), pool_of(after, P)
    k_note = ""
    if outcome == "ok" and pb and pa and pb != pa:
        if pa[2] == pb[2]:
            k_note = f"k {pb[0]*pb[1]} -> {pa[0]*pa[1]}"
            if pa[0] * pa[1] < pb[0] * pb[1]: diffs.append("constant product decreased")
        else:
            k_note = "k/LP^2 non-decreasing" if pa[0]*pa[1]*pb[2]**2 >= pb[0]*pb[1]*pa[2]**2 else "k/LP^2 DECREASED"
            if "DECREASED" in k_note: diffs.append("value per LP share decreased")
    status = "Pass" if outcome == c["expect"] and not diffs else "Fail"
    if outcome != c["expect"]: diffs.insert(0, f"model outcome {outcome} != planned {c['expect']}")
    results.append({**c, "model_outcome": outcome, "status": status, "calc": note, "k": k_note, "diffs": diffs,
                    "tick_before": tick(before, POOLS[POOL_OF.get(c["id"].split("-")[0], 'main')][9]),
                    "tick_after": tick(after, POOLS[POOL_OF.get(c["id"].split("-")[0], 'main')][9]),
                    "pool_before": pb, "pool_after": pa})

(run / "results.json").write_text(json.dumps(results, indent=1, default=str))
print("\n| Case | Expect | Status | Independent calculation | Pool before -> after (rA, rB, LP) | Tick before -> after |")
print("|---|---|---|---|---|---|")
for r in results:
    print(f"| {r['tag']} {r['summary']} | {r['expect']} | {r['status']} | {r['calc']} {('; ' + r['k']) if r['k'] else ''} | "
          f"{r['pool_before']} -> {r['pool_after']} | {r['tick_before']} -> {r['tick_after']} |")
fails = [r for r in results if r["status"] != "Pass"]
for r in fails: print(f"FAIL {r['tag']}:", "; ".join(r["diffs"]))
print(f"\nSUMMARY: {len(results) - len(fails)} Pass, {len(fails)} Fail of {len(results)} cases")
sys.exit(1 if fails else 0)
