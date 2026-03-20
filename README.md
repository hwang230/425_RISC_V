# 425_RISC_V

This repository contains the source code for the **Write-Back Cache** project as part of **ECSE 425: Computer Architecture**. 

### Modules
1. **`cache.vhd`**: The controller responsible for state transitions, hit/miss detection, and coordinating write-back/allocate sequences.
2. **`cache_storage.vhd`**: The internal memory array housing 32 blocks (128 bits each), including Valid and Dirty bit management.

## Verification Strategy
The goal is to achieve 100% transition coverage of the FSM and verify all reachable functional cases.

### Reachable Case Matrix
| Case | State | Access | Tag | Action |
| :--- | :--- | :--- | :--- | :--- |
| 1-4 | Invalid | R/W | Any | **Miss**: Fetch from Memory |
| 9 | Valid/Clean | Read | Match | **Hit**: Return Data |
| 11 | Valid/Clean | Write | Match | **Hit**: Update + Set Dirty |
| 10/12 | Valid/Clean | R/W | Mismatch | **Miss**: Evict + Fetch |
| 14/16 | Valid/Dirty | R/W | Mismatch | **Write-Back**: Save old block + Fetch new |

### Running Tests
* **Integration Test**: Run `cache_tb.vhd` against the full `cache.vhd` top-level to verify end-to-end Avalon timing.

