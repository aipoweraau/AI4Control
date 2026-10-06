# AI4Control toolbox documentation

This document provides the implementation details that support the AI4Control PMSM benchmark and the online toolbox description.

## Toolbox GUI workflow

The toolbox is organized around two MATLAB app interfaces. The AI Control Trainer, `apptrain.mlapp`, supports PMSM-simulation data loading or generation, neural-network configuration, training and validation loss monitoring, and trained-model export. The PMSM Control Dashboard, `app1.mlapp`, supports closed-loop simulation, controller selection, PMSM benchmark execution, signal visualization, and performance-metric evaluation.

The intended workflow is:

1. Generate or load PMSM simulation data for the AI-controller training task.
2. Configure the neural-network structure and training settings in the training interface.
3. Train and validate the AI controller and export the trained controller parameters.
4. Deploy the trained controller through the same PMSM benchmark used by PI and MPC.
5. Run unified test scenarios and extract the same metrics for every controller.
6. Compare PI, MPC, DPC, trained AI controllers, and user-defined controllers with unified numerical metrics and radar-chart visualization.

The GUI therefore implements the same training-to-evaluation logic described by the benchmark workflow: train if needed, plug the controller into the common PMSM platform, run unified tests, and compare with unified metrics.

## Benchmark architecture

The benchmark separates the common PMSM evaluation environment from controller-specific implementation. The common environment provides:

- measured and reference signals for controller development;
- PMSM plant, inverter, modulation, and coordinate-transformation stages;
- disturbance scenarios and operating-point definitions;
- signal logging and metric extraction;
- robustness and computation-speed assessment;
- a common benchmark timing basis for direct controller comparison.

PI, MPC, and DPC are connected to the same inverter and PMSM plant and are evaluated under identical operating conditions, disturbance profiles, logging procedures, performance metrics, and benchmark sampling frequency. Their internal realizations remain controller-specific. In this toolbox, standardization refers to the common evaluation environment and protocol rather than to an identical controller architecture.

## Controller boundary signals

For the implemented PI, MPC, and DPC controllers, the control outputs are expressed as d- and q-axis voltage references. These outputs pass through the common coordinate-transformation, modulation, inverter, and PMSM stages.

Typical measured and reference signals include:

- d-axis and q-axis currents, `id` and `iq`;
- current references, including `iqref`;
- electrical speed, `omega_e`;
- rotor position;
- dc-link voltage;
- load torque, speed command, or other operating-point and disturbance variables when required.

The DPC training input used in the revised study is:

```text
[id, iq, iqref, omega_e]
```

## Adding a new controller

Additional controllers can be incorporated by adapting their signals at the controller boundary.

1. Define the controller input signals required by the new method.
2. Map the common PMSM benchmark signals to those controller inputs.
3. Map the controller outputs back to the plant interface.
4. Keep the PMSM plant, disturbance scenarios, logging procedure, and metric extraction unchanged.
5. Run the same operating conditions and sampling frequency when direct performance comparison is intended.

Controllers formulated directly in the dq frame can usually use the common measured states and reference signals with minimal adaptation. Controllers formulated in the stationary alpha-beta frame or the three-phase abc frame require the corresponding Clarke/Park or inverse coordinate transformations before connection to the common plant interface.

For controllers that directly generate switching states, such as finite-control-set predictive controllers, the switching commands can be connected to the inverter switching interface without passing through the continuous voltage-reference and PWM path.

If a controller operates at a sampling period different from the benchmark control loop, handle the timing difference locally using sampled-data, zero-order-hold, or rate-transition interfaces. These controller-specific adaptations should not require changes to the PMSM plant, disturbance scenarios, or performance-evaluation procedure.

## DPC training-data generation

The training dataset is generated from closed-loop simulations of the MPC-controlled PMSM over a predefined operating region.

Five rotor-speed levels are used:

```text
300, 600, 900, 1200, and 1500 min^-1
```

Five load-torque levels are used:

```text
0, 1.25, 2.5, 3.75, and 5 N*m
```

These levels form 25 speed-load operating conditions. At each operating condition, the q-axis current reference is varied using predefined step sequences spanning 5-30 A. The ordering of the reference values is intentionally varied to include both upward and downward current-reference transitions. Representative sequences include:

```text
5, 15, 30, 20, 10 A
10, 25, 5, 30, 15 A
20, 5, 25, 10, 30 A
```

The resulting closed-loop trajectories contain both steady-state and transient operating data. The measured states, reference signals, and operating variables along these trajectories are retained as representative training inputs. The MPC control outputs are not used as supervised target labels; the DPC policy is trained through its differentiable predictive-control objective.

To reduce redundancy, steady-state portions are downsampled, while samples around current-reference and load transitions are retained more densely. Approximately equal numbers of samples are retained from the 25 operating conditions, resulting in a dataset of 10,000 samples for network training and validation.

## Offline computational effort

The dataset generation and network training are offline steps and do not contribute to the per-cycle execution time during deployment. In the reported implementation, the computations were performed on an Intel Core Ultra 7 155U CPU with 32 GB RAM and no GPU acceleration:

| Offline step | Approximate effort |
| --- | ---: |
| 10,000-sample dataset generation from closed-loop MPC simulations | 22 min |
| Neural-network training for 2000 epochs | 2.4 h |

During online deployment, the trained DPC controller only requires a forward evaluation of the neural network.

## Radar-chart metrics

The radar chart maps each indicator to the range `[0, 1]`, where a larger value indicates better performance. Fixed reference ranges are used for transient and waveform-quality indicators so that normalized scores do not depend on the set of controllers included in the comparison.

### Settling speed

Settling time is normalized over a 2-10 ms benchmark range, corresponding to approximately 20-100 control cycles at 10 kHz. A settling time of 2 ms or lower receives 1. A settling time of 10 ms or higher receives 0.

```text
SST = clip((10 - ts) / (10 - 2), 0, 1)
```

where `ts` is expressed in milliseconds.

### Overshoot reduction

Overshoot is normalized over 5-15%. An overshoot of 5% or lower receives 1. An overshoot of 15% or higher receives 0.

```text
SOS = clip((15 - OS) / (15 - 5), 0, 1)
```

### Waveform quality

The phase-current THD is normalized over 2-10%. A THD of 2% or lower receives 1. A THD of 10% or higher receives 0.

```text
STHD = clip((10 - THD) / (10 - 2), 0, 1)
```

### Robustness

Robustness is quantified from the fraction of the three test levels for which stable operation is maintained:

```text
Srob = Npassed / 3
```

The three levels are nominal operation, Case I, and Case II. In the reported comparison, PI passes all three levels and receives 1.00. MPC and DPC pass the nominal condition and Case I but lose bounded tracking in Case II, giving `2/3`, approximately 0.67.

### Computation speed

At 10 kHz, the control period is 100 us. A conservative controller-execution budget equal to half of the control period is adopted:

```text
Tbudget = 50 us
```

The computation-speed score is:

```text
Scomp = clip((Tbudget - texec) / (Tbudget - tPI), 0, 1)
```

Using `tPI = 4 us` and `tDPC = 17 us`, the resulting computation scores are 1.00 for PI and approximately 0.72 for DPC. The five-step MPC produces a computational overrun and receives a computation score of 0.

## Metric scripts

Use `calc_metrics_one_run.m` to compute the raw overshoot, settling-time, and THD quantities for one simulation run. The script writes variables such as `OS_PI`, `ST_PI`, and `THD_PI` to the MATLAB base workspace and stores structured results in `Results`.

Use `draw_radar_from_workspace.m` after the raw metrics are available. The script reads the workspace metrics, applies the normalization equations above, and plots the five radar-chart dimensions:

- settling speed;
- overshoot reduction;
- waveform quality;
- robustness;
- computation speed.

For convenience, `plot_radar_wrapper.m` calls the metric extraction and radar-chart drawing functions for the current workspace simulation output.
