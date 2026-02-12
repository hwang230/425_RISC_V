# 425_RISC_V

This repository contains the source code for the **Write-Back Cache** project as part of **ECSE 425: Computer Architecture**. 

## 🏗️ Architecture Overview
To ensure high testability and clean design, the cache is implemented using a modular approach. This allows for individual **Unit Testing** of each component before final integration into the top-level `cache.vhd` entity.


### Modules
1. **`fsm_logic.vhd`**: The controller responsible for state transitions, hit/miss detection, and coordinating write-back/allocate sequences.
2. **`cache_storage.vhd`**: The internal memory array housing 32 blocks (128 bits each), including Valid and Dirty bit management.
3. **`avalon_bus.vhd`**: The interface logic that handles the **Avalon-MM** protocol, bridging 32-bit CPU requests to the 8-bit main memory via 16-cycle bursts.

---

## 🧪 Verification Strategy
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
* **Unit Tests**: Located in `/tests/unit`. These should be passed individually by module owners before integration.
* **Integration Test**: Run `cache_tb.vhd` against the full `cache.vhd` top-level to verify end-to-end Avalon timing.



---

## 🛠️ Development Workflow
* **Branching**: Create a feature branch for your specific module (e.g., `git checkout -b feature-fsm`).
* **Commits**: Commit often after passing local unit tests to ensure the main branch remains stable.
* **Synchronization**: Ensure all internal ports match the agreed-upon interface spec in the source files.