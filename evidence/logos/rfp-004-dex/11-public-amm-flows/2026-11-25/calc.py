"""Independent AMM arithmetic (integer floor/ceil), used to pick boundary arguments."""
import sys
D = 10_000
def ceil_div(a, b): return -(-a // b)
def in_out(r_in, r_out, amt, fee):
    eff = amt * (D - fee) // D
    return eff, r_out * eff // (r_in + eff)
def out_in(r_in, r_out, out, fee):
    eff = ceil_div(r_in * out, r_out - out)
    return eff, ceil_div(eff * D, D - fee)
def add(ra, rb, s, max_a, max_b):
    act_a = min(ra * max_b // rb, max_a); act_b = min(rb * max_a // ra, max_b)
    return act_a, act_b, min(s * act_a // ra, s * act_b // rb)
def remove(ra, rb, s, lp): return ra * lp // s, rb * lp // s
if __name__ == "__main__":
    op, *a = sys.argv[1:]; a = list(map(int, a))
    if op == "in_out": print(in_out(*a)[1])
    elif op == "out_in": print(out_in(*a)[1])
    elif op == "add": print(add(*a)[2])
    elif op == "remove": print(*remove(*a))
