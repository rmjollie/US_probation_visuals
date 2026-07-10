# Probation Rates in the United States

An exploration of probation and incarceration rates across US states from
2010 to 2018, and how they relate to state population size and state
government partisan control. Full interactive report:
[RPubs](https://rpubs.com/rmjollie/984808).

## Key questions

1. How have probation rates in the US changed from 2010 to 2018?
2. Do state population size and partisan control influence probation rates?
3. Which states are worth a closer look as policy case studies?

See `report/probation_rates_tabset.Rmd` (rendered: `report/probation_rates_tabset.html`)
for the full write-up and answers.

## Project structure

```
data-raw/          Original, untouched source files (see Data Sources below)
  probation/          ICPSR Annual Probation Survey, 2010-2018 (9 files)
  jails/              ICPSR Annual Survey of Jails, 2010-2018 (9 files)
  prisons/            BJS Corrections Statistical Analysis Tool prisoner counts
  population/         Census Bureau state population estimates
  partisanship/       NCSL state legislature/governor partisanship, 2010-2018
  geo/                US hex-cartogram geometry for the state map

data-clean/         Tidy, joined tables produced by R/01_clean_data.R.
                    Not tracked in version control -- regenerate by running
                    the R/ scripts in order (see Reproducing below).

R/                  Pipeline scripts, run in numeric order
  00_helpers.R          Shared helper functions (bind_tables, pretty_count)
  01_clean_data.R       data-raw/  ->  data-clean/
  02_figures_national.R  National-level figure functions (map, linegraphs, etc.)
  03_figures_case_study.R  Per-state case-study figure functions (Idaho/Georgia/Arkansas)
  04_save_figures.R     data-clean/  ->  figs/ (static .png copies of every figure)

figs/               Static image copies of each figure, for use outside the
                    dashboard (e.g. embedding elsewhere).

report/             The flexdashboard report itself
  probation_rates_tabset.Rmd   Loads data-clean/, calls the figure functions
  probation_rates_tabset.html  Rendered output
```

## Reproducing this project

1. Add the raw data files to each `data-raw/<source>/` folder (see the
   `PLACE_FILES_HERE.txt` note in each folder, and Data Sources below).
2. Run `R/01_clean_data.R` to build `data-clean/`.
3. Either:
   - Run `R/04_save_figures.R` to write every figure to `figs/` as a `.png`, or
   - Knit `report/probation_rates_tabset.Rmd` to regenerate the full dashboard.

Both `04_save_figures.R` and the Rmd report read only from `data-clean/` and
`R/02_figures_national.R` / `R/03_figures_case_study.R` -- neither touches
`data-raw/` directly, so the cleaning step only needs to run once (or
whenever the raw data changes).

## Data Sources

1. U.S. Census Bureau, Population Division, Table 1. Annual Estimates of the
   Resident Population for the United States, Regions, States, and Puerto
   Rico: April 1, 2010 to July 1, 2019 (NST-EST2019-01), released December 2019.
2. United States Department of Justice. Office of Justice Programs. Bureau of
   Justice Statistics. Annual Probation Survey, 2010-2018.
3. United States Department of Justice. Office of Justice Programs. Bureau of
   Justice Statistics. Annual Survey of Jails, 2010-2018.
4. United States Department of Justice. Office of Justice Programs. Bureau of
   Justice Statistics. Corrections Statistical Analysis Tool (CSAT) --
   Prisoners, 2010-2018.
5. National Conference of State Legislatures. Legislative Partisan
   Composition Tables, 2010-2018.

All of these (and data for other years back to 1994, under a slightly
different survey methodology) are publicly available through
[ICPSR](https://www.icpsr.umich.edu/web/pages/ICPSR/index.html).

## What changed in this refactor

This project originally lived as two files -- a `.R` script and an `.Rmd`
report -- each containing a full copy of the same ~150 lines of data-cleaning
code, plus figure code that was itself copy-pasted three times (once per
state case study) with only the state name changed. The structure above
splits that into a single cleaning step, reusable figure functions, and a
thin report that just calls them -- so a reviewer can see the cleaning logic,
the figure logic, and the narrative each in one place, and so re-running the
cleaning step no longer means re-running it twice.
