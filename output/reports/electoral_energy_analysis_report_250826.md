# Report: Electoral Backlash and Energy Infrastructure in Colombia (2022 vs 2026)

This report analyzes the electoral performance of the government coalition (*Pacto Histórico*) in the May 31, 2026 first-round presidential election compared to the 2022 first-round results (Gustavo Petro's victory). It identifies municipalities characterized by a "Green Backlash" (where support for the left decreased) and correlates this political shift with the local presence of coal mining, oil and gas extraction, and solar energy infrastructure.

---

## Section 1: Identifying the "Green Backlash" Municipalities (Electoral Switchers)

*   **Data & Scope:** We compared first-round results from **2022** (Gustavo Petro) with **2026** (Iván Cepeda Castro representing the *Pacto Histórico*).
*   **Geographic Harmonization:** DANE municipality codes (from 2022) were matched with Registraduría DIVIPOL codes (from 2026) using an automated exact and fuzzy string-matching algorithm. A total of **1,034 municipalities** were successfully matched across both datasets.
*   **Electoral Switching Results (Approach A - Plurality Switch):**
    *   **Voted Petro in 2022 (Plurality Winner):** 376 municipalities.
    *   **Loyal to Pacto Histórico in 2026 (Cepeda Winner):** 340 municipalities (*No Switch*).
    *   **"Green Backlash" Switchers:** **36 municipalities** where Petro won in 2022, but Cepeda lost in 2026. In most of these 36 municipalities, the conservative candidate **Abelardo de la Espriella** won the plurality in 2026.
    *   **Did not vote Petro in 2022:** 658 municipalities.

*Key switcher municipalities include:* Manizales (Caldas), Sogamoso (Boyacá), Necoclí (Antioquia), Arboletes (Antioquia), Palestina (Caldas), and Astrea (Cesar).

---

## Section 2: Mapping Energy Activities (Approach A - Binary Comparison)

We processed three energy/mining datasets to create municipal-level presence and intensity indicators:
1.  **Coal Mining:** Average annual royalties and volumes (2018–2025) from the National Mining Agency (ANM).
2.  **Oil & Gas:** Average annual production (2018–2021) from the Ministry of Mines and Energy (`datos_completos`).
3.  **Solar Renewables:** Active/testing solar projects and total capacity in MW from XM (grid operator).

The table below compares the averages in the **36 Backlash Municipalities** against the **National Average** of all 1,034 municipalities.

### Table 1: Backlash vs. National Averages

| Activity | Indicator | Backlash Avg (N=36) | National Avg (N=1034) | Ratio (Backlash / Nat) | Statistical Significance (t-test) |
| :--- | :--- | :---: | :---: | :---: | :--- |
| **Coal Mining** | % Municipalities with Mining | 2.78% | 13.83% | **0.20x** | $p < 0.01$ (Very Significant) |
| | Avg Annual Royalties (COP) | $76,407,780.14 | $3,912,270,997.37 | **0.02x** | $p < 0.05$ (Significant) |
| **Oil & Gas** | % Producing Municipalities | 13.89% | 10.15% | **1.37x** | Not significant |
| | Avg Annual Royalties (COP) | $3,679,217,938.57 | $4,662,047,886.25 | **0.79x** | Not significant |
| **Solar (Renewables)** | % Municipalities with Projects | 19.44% | 11.41% | **1.70x** | Not significant |
| | Avg Capacity (MW) | 8.03 MW | 3.07 MW | **2.62x** | Not significant |

**Brief Interpretation:**  
Municipalities that shifted away from the government are **1.37 times more likely** to produce oil and gas and **1.70 times more likely** to host active solar projects, representing **2.62 times** the average national solar capacity. Conversely, they are significantly less likely to host coal mining.

![Presence of Energy Activities](file:///Users/brigittecastaneda/Documents/GitHub/Green_Backlash_Colombia/output/graphs/plot_presence_shares.png)

---

## Section 3: Continuous Correlation Analysis (Approach B - Loss of Support)

Rather than using a binary switch, **Approach B** correlates the continuous change in vote share (`petro_share_diff` = vote share 2026 - vote share 2022) with the continuous energy/mining proxies across all **1,034 municipalities** using Pearson correlation coefficients ($r$). 

A **negative correlation** ($r < 0$) indicates that municipalities with higher energy activity experienced a **larger decrease** in support for the left.

### Table 2: Continuous Pearson Correlation Results

| Activity | Indicator | Pearson Correlation ($r$) | p-value | Significance |
| :--- | :--- | :---: | :---: | :--- |
| **Coal** | Coal: Avg Annual Production Volume | **-0.0718** | $2.10 \times 10^{-2}$ | *** (p < 0.05)** |
| **Coal** | Coal: Avg Annual Royalties (COP) | **-0.0659** | $3.41 \times 10^{-2}$ | *** (p < 0.05)** |
| **Oil/Gas** | Oil: Avg Annual Production Volume | **+0.0609** | $5.02 \times 10^{-2}$ | **\* (p < 0.10)** |
| **Oil/Gas** | Oil: Avg Annual Royalties (COP) | **+0.0606** | $5.15 \times 10^{-2}$ | **\* (p < 0.10)** |
| **Oil/Gas** | Gas: Avg Annual Production Volume | **+0.0057** | $8.54 \times 10^{-1}$ | **Not significant** |
| **Oil/Gas** | Gas: Avg Annual Royalties (COP) | **+0.0140** | $6.53 \times 10^{-1}$ | **Not significant** |
| **Solar (Renewables)** | Solar: Avg Capacity (MW) | **+0.0068** | $8.27 \times 10^{-1}$ | **Not significant** |

**Brief Interpretation:**  
At a national scale, coal mining shows a significant negative correlation with the change in vote share, confirming a drop in support in coal-producing regions. Oil production shows a marginally positive relationship. Solar capacity shows no linear correlation, indicating that the solar backlash is a localized presence-based friction rather than a linear function of project size.

---

## Section 4: Project Deliverables and Code Location

All deliverables are organized in the project repository under the following structure:

*   **Reports (`output/reports/`):**
    *   Report (this document, June format name): [`electoral_energy_analysis_report_250626.md`](file:///Users/brigittecastaneda/Documents/GitHub/Green_Backlash_Colombia/output/reports/electoral_energy_analysis_report_250626.md)
    *   Report (current date format name): [`electoral_energy_analysis_report_250826.md`](file:///Users/brigittecastaneda/Documents/GitHub/Green_Backlash_Colombia/output/reports/electoral_energy_analysis_report_250826.md)
*   **Tables (`output/tables/`):**
    *   Electoral switchers dataset: [`petro_switching.csv`](file:///Users/brigittecastaneda/Documents/GitHub/Green_Backlash_Colombia/output/tables/petro_switching.csv) & [`.dta`](file:///Users/brigittecastaneda/Documents/GitHub/Green_Backlash_Colombia/output/tables/petro_switching.dta)
    *   Binary comparison table & interpretations: [`energy_backlash_comparison.md`](file:///Users/brigittecastaneda/Documents/GitHub/Green_Backlash_Colombia/output/tables/energy_backlash_comparison.md) & [`.csv`](file:///Users/brigittecastaneda/Documents/GitHub/Green_Backlash_Colombia/output/tables/energy_backlash_comparison.csv)
    *   Continuous correlation table & interpretations: [`continuous_correlations.md`](file:///Users/brigittecastaneda/Documents/GitHub/Green_Backlash_Colombia/output/tables/continuous_correlations.md) & [`.csv`](file:///Users/brigittecastaneda/Documents/GitHub/Green_Backlash_Colombia/output/tables/continuous_correlations.csv)
*   **Graphs (`output/graphs/`):**
    *   Map - Plurality Winner Switch: [`map_switched_plurality.png`](file:///Users/brigittecastaneda/Documents/GitHub/Green_Backlash_Colombia/output/graphs/map_switched_plurality.png)
    *   Map - Continuous Share Difference: [`map_petro_share_diff.png`](file:///Users/brigittecastaneda/Documents/GitHub/Green_Backlash_Colombia/output/graphs/map_petro_share_diff.png)
    *   Map - Categorical Switch Classification: [`map_petro_supporter_switched.png`](file:///Users/brigittecastaneda/Documents/GitHub/Green_Backlash_Colombia/output/graphs/map_petro_supporter_switched.png)
    *   Bar Chart - Presence shares of energy activities: [`plot_presence_shares.png`](file:///Users/brigittecastaneda/Documents/GitHub/Green_Backlash_Colombia/output/graphs/plot_presence_shares.png)
*   **Scripts (`code/cleaning/`):**
    *   Electoral switching analysis: [`analyse_switching.py`](file:///Users/brigittecastaneda/Documents/GitHub/Green_Backlash_Colombia/code/cleaning/analyse_switching.py) & [`.R`](file:///Users/brigittecastaneda/Documents/GitHub/Green_Backlash_Colombia/code/cleaning/analyse_switching.R)
    *   Energy correlation analysis: [`analyse_correlations.py`](file:///Users/brigittecastaneda/Documents/GitHub/Green_Backlash_Colombia/code/cleaning/analyse_correlations.py) & [`.R`](file:///Users/brigittecastaneda/Documents/GitHub/Green_Backlash_Colombia/code/cleaning/analyse_correlations.R)
