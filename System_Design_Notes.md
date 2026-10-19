# System_Design 

> The numbers below are worked examples from the design formulas using this model's ratings. Replace the values marked [ ] with the ones actually used in your Simulink blocks.

## 1. Specifications

| Item | Value |
|---|---|
| PV rating | 10.8 kW, Vmp = 270 V, Imp = 40 A, Voc = 300 V |
| DC bus | 400 V |
| Battery | 150 V Li-ion |
| Switching frequency fs | 10 kHz |
| Solver step | 2e-6 s (50 samples per switching period at 10 kHz needs ≤ 2e-6 s) |

## 2. Stage 1: PV Boost Converter

**Duty cycle:** D_boost = 1 − Vin/Vout = 1 − 270/400 = **0.325**

**Inductor:** L_boost = (Vin × D) / (ΔIL × fs)
With ΔIL = 20 % of 40 A = 8 A: L = (270 × 0.325) / (8 × 10 000) ≈ **1.1 mH**   (used: [ ])

**PV input capacitor:** C_in = (Iout × D) / (ΔVin × fs)
Iout = 10.8 kW / 400 V = 27 A, ΔVin = 1 % of 270 V = 2.7 V:
C_in = (27 × 0.325) / (2.7 × 10 000) ≈ **325 µF**   (used: [ ])

**Duty limits:** Vpv = Vbus (1 − D) and Vpv cannot exceed Voc = 300 V, so
D_min = 1 − 300/400 = 0.25. D_max is set to 0.60.

## 3. DC Link

**Load resistance:** R_load = Vdc² / P_load = 400² / 4000 = **40 Ω** (4 kW load)   (used: [ ])

**DC-link capacitor:** C_dc = (I_load × D_max) / (ΔVout × fs)
I_load = 10 A, D_max = 0.6, ΔVout = 4 V (1 %):
C_dc = (10 × 0.6) / (4 × 10 000) = **150 µF** minimum. A larger value (1–4 mF) is recommended to hold the bus steady against PV and battery transients.   (used: [ ])

## 4. Stage 2: Bidirectional Half-Bridge

**Charging duty:** D_hb = Vbatt / Vbus = 150 / 400 = **0.375**

**Battery inductor:** L_batt = ((Vbus − Vbatt) × D_hb) / (ΔIbatt × fs)
With ΔIbatt = 6 A: L = (250 × 0.375) / (6 × 10 000) ≈ **1.6 mH**   (used: [ ])

The two IGBTs are driven complementarily (P and NOT P), so the same stage buck-charges the battery and boost-discharges it.

## 5. PI Controller (bus voltage)

G_c(s) = Kp + Ki/s, error = Vbus_ref − Vbus (400 V reference)

| Parameter | Value |
|---|---|
| Kp | [0.0005 – 0.002] |
| Ki | [0.05 – 0.5] |
| Output saturation | 0.05 – 0.95 (duty ratio) |

The error is in volts and the output is a duty ratio, so the gains must be small. Reduce Ki if the bus oscillates, increase it if the bus is slow.

## 6. MPPT (Perturb & Observe)

| Parameter | Value |
|---|---|
| Update period | 5 ms (N = 5 ms / Ts calls, averaging window) |
| Step ΔD | 0.002 |
| Duty limits | 0.25 – 0.60 |
| Initial / night duty | 0.325 |
| Change threshold | 0.05 % of present power |

Rules for a boost converter (raising D lowers Vpv):

| dP | dV | Action |
|---|---|---|
| > 0 | > 0 | D decreases |
| > 0 | < 0 | D increases |
| < 0 | > 0 | D increases |
| < 0 | < 0 | D decreases |

**Timing rule:** the MPPT period must be much longer than the PV-side settling time, and `Ts` in the code must equal the powergui sample time.

## 7. Time Scaling

- 1 s of simulation = 1 hour of the day (24 s total).
- Battery capacity scaled 50 Ah → 0.0139 Ah (÷ 3600) and response time set to 0.1 s so SOC changes visibly in 24 s. This is a visualization aid, not a physical battery design.

## 8. Observed Behavior and Known Issues

- Dmppt follows irradiance and the battery charges in daylight (SOC ≈ 51.6 % → 53.6 %, charge current up to about 9 A).
- The bus is not regulated at 400 V (about 140 V at night, about 600 V at peak). Planned fixes: retune PI gains and saturation, increase the bus capacitor, size the load and battery current to absorb the PV surplus, and add a bus overvoltage limit to the MPPT.
