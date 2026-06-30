# Cycle-by-Cycle Data Flow

This document shows exactly what data each PE receives at each clock cycle.

## Matrix Values
```
A = | 1 2 3 |     B = | 7 8 9 |
    | 4 5 6 |         | 6 5 4 |
    | 7 8 9 |         | 3 2 1 |
```

## Skewed Inputs

### A rows entering from left (after skewing):
```
Cycle:    1    2    3    4    5
Row 0:   [1]  [2]  [3]   0    0
Row 1:    0   [4]  [5]  [6]   0
Row 2:    0    0   [7]  [8]  [9]
```

### B columns entering from top (after skewing):
```
Cycle:    1    2    3    4    5
Col 0:   [7]  [6]  [3]   0    0
Col 1:    0   [8]  [5]  [2]   0
Col 2:    0    0   [9]  [4]  [1]
```

## What PE[0][0] Sees and Accumulates
PE[0][0] = C[0][0] = A row 0 dot B col 0

| Cycle | a_in | b_in | Product | acc |
|-------|------|------|---------|-----|
|   1   |  1   |  7   |    7    |  7  |
|   2   |  2   |  6   |   12    | 19  |
|   3   |  3   |  3   |    9    | 28  |

Final: acc = 28 ✓

## What PE[0][1] Sees and Accumulates
PE[0][1] = C[0][1] = A row 0 dot B col 1
Note: A arrives from PE[0][0] one cycle later, B col 1 is skewed one cycle

| Cycle | a_in | b_in | Product | acc |
|-------|------|------|---------|-----|
|   2   |  1   |  8   |    8    |  8  |
|   3   |  2   |  5   |   10    | 18  |
|   4   |  3   |  2   |    6    | 24  |

Final: acc = 24 ✓

## What PE[1][0] Sees and Accumulates
PE[1][0] = C[1][0] = A row 1 dot B col 0
Note: A row 1 is skewed 1 cycle, B arrives from PE[0][0] one cycle later

| Cycle | a_in | b_in | Product | acc |
|-------|------|------|---------|-----|
|   2   |  4   |  7   |   28    | 28  |
|   3   |  5   |  6   |   30    | 58  |
|   4   |  6   |  3   |   18    | 76  |

Final: acc = 76 ✓

## Key Insight From This Table

Every PE along the same anti-diagonal computes at the same cycle range.
- PE[0][0] computes cycles 1-3
- PE[0][1] and PE[1][0] compute cycles 2-4  (one diagonal away)
- PE[0][2], PE[1][1], PE[2][0] compute cycles 3-5  (two diagonals away)

This is why the skewing works: it ensures correct A and B elements
arrive at each PE at the same cycle.