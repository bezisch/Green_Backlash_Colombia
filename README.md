# Green_Backlash_Colombia
repo to analyse green voting backlash in Colombia, 2022-2026

## Data sources

| Dataset | Source | Contact |
|---|---|---|
| 2026 primera vuelta results | Registraduría Nacional | Brigitte |
| 2022 election results | Registraduría Nacional | Lotti |
| Coal/minerals production (monthly, municipio) | Agencia Nacional de Minería | Brigitte | until 2026
| Oil & gas fields | ANH | Brigitte | until 2026
| Solar energy | UPME | Brigitte |
| Party manifestos 2022/2026 | — | Brigitte/Lotti |
| PILA (labor market) | MinTrabajo | TBC – VPN required |
| Armed groups presence | — | TBC |

## Climate salience in manifestos

We apply the [policlim model](https://github.com/marysanford/policlim) (Sanford et al., 2025) to the 2022 and 2026 Colombian party manifestos, which identified 355 relevant sentences (relevancy >=0.8%). We used Sonnet 5 to identify 30 false negatives and then use the same model to further classify these 355 statements into just_transition, pro_ff, anti_ff and nationalism. We validate the entire dataset manually.

policlim identifies 386 sentences as relevant with a relevancy filter of 0.8 or above (out of 5,062 sentences between 2022 and 2025). After identifying 30 false positives, our final sample is:

N=356 relevant (general policlim score). Hence: Pooling together manifesto data from 2022 und 2026, we find that 7% of all manifestos discuss climate as per policlim. (356/5062)
110 pro_just_transition. Hence: Out of this, 2.2% discuss the just transition.
96 anti_ff
42 pro_ff
56 energy_security

We then merge the election data with the manifesto scores via the ID name_candidate_year.

data/manifestos/apply_policlim_to_manifestos_2022_2026.ipynb
Extracts manifesto PDFs (2022, 2026), classifies sentences with the policlim model, and compares those scores against an LLM re-classification of the high-score subset.

Output: data/manifestos/output/policlim_comparison/policlim_manifesto_summary_all_years.csv (manifesto-level policlim scores)

Output: data/manifestos/output/policlim_comparison/policlim_vs_llm_manifesto_scores.csv (policlim vs. LLM scores, weighted by 2026 vote share)

data/manifestos/compare_llm_policlim.py
Standalone script version of the policlim-vs-LLM comparison above (same output), runnable without the notebook's PDF pipeline.

data/electoral/build_municipio_manifesto_vote_shares.py
Matches 2022 and 2026 municipios (different coding schemes) and merges each candidate's municipio-level vote share with their manifesto's climate/LLM scores.

Output: data/electoral/processed/municipio_switching/municipio_manifesto_vote_shares.csv
Output: data/electoral/processed/municipio_switching/municipio_manifesto_summary_table.tex and ..._llm.tex (LaTeX summary tables)

code/cleaning/analyse_switching.py
Matches 2022 and 2026 municipios and tracks municipality-level switching between Petro (2022) and Cepeda (2026).

Brigitte to test the PILA access.
