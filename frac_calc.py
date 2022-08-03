import sys

best_n = 0
best_m = 0
best_d = 999999999

REF_CLK = float(sys.argv[1])
TARGET_CLK = float(sys.argv[2]) # 34.28714 / 4

for n in range(1,1023):
    for m in range(1,1023):
        clk = REF_CLK * n / m
        d = abs(TARGET_CLK - clk)
        if d < best_d:
            best_n = n
            best_m = m
            best_d = d

print(f"n={best_n}, m={best_m}, freq={REF_CLK * best_n / best_m}")

