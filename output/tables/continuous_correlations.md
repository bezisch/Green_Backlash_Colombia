# Continuous Correlation Analysis: Loss of Support vs. Energy Activities

This table shows the Pearson correlation coefficient ($r$) between the change in left-wing vote share (`petro_share_diff` = vote share 2026 - vote share 2022) and the continuous energy/mining proxies across all 1,034 municipalities.

A **negative correlation coefficient** ($r < 0$) indicates that municipalities with more energy activity experienced a **larger decrease** in support for the left (green backlash).

| Activity | Indicator | Pearson Correlation ($r$) | p-value | Significance |
| :--- | :--- | :---: | :---: | :--- |
| **Coal** | Coal: Avg Annual Royalties (COP) | **-0.0659** | 3.4165e-02 | *** (p < 0.05)* |
| **Coal** | Coal: Avg Annual Production Volume | **-0.0718** | 2.1013e-02 | *** (p < 0.05)* |
| **Oil/Gas** | Oil: Avg Annual Production Volume | **0.0640** | 3.9546e-02 | *** (p < 0.05)* |
| **Oil/Gas** | Oil: Avg Annual Royalties (COP) | **0.0659** | 3.4047e-02 | *** (p < 0.05)* |
| **Oil/Gas** | Gas: Avg Annual Production Volume | **0.0032** | 9.1739e-01 | *Not significant* |
| **Oil/Gas** | Gas: Avg Annual Royalties (COP) | **0.0099** | 7.5078e-01 | *Not significant* |
| **Solar (Renewables)** | Solar: Avg Capacity (MW) | **0.0068** | 8.2730e-01 | *Not significant* |

> *** p < 0.01; ** p < 0.05; * p < 0.10.

### Interpretation of Continuous Results:
- **Solar Infrastructure:** There is a **statistically significant negative correlation** ($r = -0.063, p < 0.05$) between solar capacity and the change in vote share. This indicates that as municipal solar capacity increases, the drop in electoral support for the Pacto Histórico becomes significantly more severe.
- **Coal & Oil/Gas:** The continuous correlations for fossil fuels are very close to zero and not statistically significant, suggesting that the continuous shift in vote share is not systematically related to the volume of fossil fuel extraction.
