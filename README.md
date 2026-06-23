# AI-assisted Control Toolbox for Power Electronics

This repository provides an AI-assisted control toolbox for power electronic systems,
with a focus on PMSM drives and data-driven control design.

The toolbox integrates MATLAB/Simulink models with two interconnected App-based interfaces:
a training-oriented main app and a simulation-oriented control dashboard.

---

## Toolbox Architecture

The toolbox consists of three main components:

### 1. AI Control Trainer (Main App)
- Primary entry point of the toolbox
- Training and validation of AI-based controllers
- Neural network configuration (layers, learning rate, batch size, epochs)
- Training/validation loss visualization
- Export of trained model parameters

### 2. PMSM Control Dashboard (Simulation App)
- Launched directly from the AI Control Trainer
- Interfaces with a Simulink PMSM benchmark model
- Closed-loop simulation with PI, MPC, DPC, and AI controllers
- Performance comparison and radar plot visualization

### 3. Simulink PMSM Benchmark Model
- Unified PMSM control benchmark
- Used for both training data generation and controller validation
- Ensures fair and reproducible comparison across control strategies

---

## Typical Workflow

1. Launch the **AI Control Trainer**
2. Load or collect training data from the Simulink PMSM model
3. Configure neural network structure and training parameters
4. Train and validate the AI controller
5. Open the **PMSM Control Dashboard** from the Trainer
6. Run closed-loop simulations and compare control performance

---

## Requirements
- MATLAB R2024b or later (recommended)
- Simulink
- Control System Toolbox
- Deep Learning Toolbox
- Simscape Electrical (if applicable)

---

## License
© 2025 Yuanliaau, Aalborg University.  
Released under the MIT License. See `LICENSE` for details.

---

## Citation
If you use this toolbox in academic work, please cite:

> Y. Li et al., *AI-assisted Control Toolbox for Power Electronics*,  
> Aalborg University, 2025.

---

## Contact
For questions or collaboration:
- yuanli@energy.aau.dk
