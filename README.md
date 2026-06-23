# Kinetostatic Modeling of Soft Robots: Energy-Minimization Approach and 99-Line MATLAB Implementation

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A 99-line MATLAB implementation of an energy-minimization framework for kinetostatic modeling of soft robots. The approach formulates soft robot deformation as a total potential energy minimization problem and solves it via an improved L-BFGS algorithm with a fixed Hessian matrix.

## Features

- **99-line core implementation** — compact and easy to understand
- **Energy-minimization approach** — more robust than traditional FEM, especially for buckling problems
- **Dual actuation support** — pneumatic-driven and cable-driven soft robots
- **Fixed Hessian matrix** — precomputed initial Hessian significantly accelerates L-BFGS convergence
- **ABAQUS .inp converter** — convert existing ABAQUS models to the required input format
- **Exact Hessian implementation** — included for benchmarking and comparison

## Files

| File | Description |
|------|-------------|
| `main.m` | 99-line core solver (energy function, gradient, Hessian assembly, visualization) |
| `L_BFGS.m` | Standard L-BFGS algorithm with user-defined initial Hessian matrix |
| `AbaqusInput.m` | Convert ABAQUS `.inp` files to MATLAB input data |
| `strainenergyhessian.m` | Exact strain energy Hessian matrix (for convergence benchmarking) |
| `sample/` | Pre-generated input data for seven example soft robots |

## Quick Start

1. Open MATLAB and navigate to the project directory.

2. Run the cable-driven finger example:
```matlab
main
```

3. To use other examples, change the `load` statement in `main.m`:
```matlab
load('sample/cable_finger.mat');      % cable-driven finger
load('sample/pneumatic_finger.mat');   % pneumatic-driven finger
load('sample/cable_grasper.mat');      % cable-driven gripper
load('sample/pneumatic_grasper.mat');  % pneumatic-driven gripper
load('sample/pneumatic_platform.mat'); % multi-material pneumatic robot
load('sample/cable_trunk.mat');        % cable-driven trunk
load('sample/cable_buckling.mat');     % cable-driven buckling arm
```

## Examples

Seven soft robots are provided as validation cases:

| Case | Type | Description |
|------|------|-------------|
| A | Pneumatic | Bending-twisting finger |
| B | Cable | Cable-driven finger |
| C | Pneumatic | Three-finger gripper |
| D | Cable | Three-finger cable gripper |
| E | Pneumatic | Multi-material accordion-arm robot |
| F | Cable | Eight-cable trunk |
| G | Cable | Buckling arm (FEM fails here without imperfection) |

## Input Data Format

The discretized model is stored as a `.mat` file with the following variables:

| Variable | Dimension | Description |
|----------|-----------|-------------|
| `nodes` | 3*n × 1 | Nodal coordinates (flattened column vector) |
| `elements` | 4 × m | Element connectivity (DOF-based indices) |
| `materials` | 2 × m | Material parameters: [C10; D] for each element (Neo-Hookean) |
| `fix` | 1 × k | Fixed node DOF indices |
| `act_con` | 2 × p or 3 × p | Actuation connectivity (cable: 2 nodes; pneumatic: 3 nodes per triangle) |
| `act_value` | 1 × p | Actuation magnitude (force for cable, pressure for pneumatic) |

Use `AbaqusInput.m` to generate `.mat` files from ABAQUS `.inp` files.

## Material Model

The implementation uses the Neo-Hookean material model:

$$\Psi = C_{10}(\bar{I}_1 - 3) + \frac{1}{D}(J - 1)^2$$

where $\bar{I}_1 = J^{-2/3}I_1$, $J = \det(F)$.

## How It Works

1. **Discretization** — The soft robot is discretized into 4-node tetrahedral elements
2. **Energy formulation** — Total potential energy = strain energy + actuation work + gravity work
3. **Fixed Hessian** — A constant approximation of the strain energy Hessian is precomputed at the undeformed configuration
4. **L-BFGS optimization** — The energy is minimized using L-BFGS with the fixed Hessian as the initial guess
5. **Visualization** — Deformed and undeformed configurations are plotted

## Requirements

- MATLAB (R2016b or later recommended)
- No additional toolboxes required

## Citation

If you use this code in your research, please cite:

```bibtex
@article{pei2023kinetostatic,
  title   = {Kinetostatic Modeling of Soft Robots: Energy-Minimization Approach and 99-Line MATLAB Implementation},
  author  = {Pei, Xiaohui and Chen, Guimin},
  journal = {Soft Robotics},
  year    = {2023},
  doi     = {10.1089/soro.2022.0070}
}
```

## License

This project is released under the [MIT License](https://opensource.org/licenses/MIT). See the [LICENSE](LICENSE) file for details.

## Authors

- **Xiaohui Pei** — School of Electro-Mechanical Engineering, Xidian University
- **Guimin Chen** — State Key Laboratory for Manufacturing Systems Engineering, Xi'an Jiaotong University
