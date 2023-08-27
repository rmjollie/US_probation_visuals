# US_probation_visuals

This project creates visuals to explore probation rates in the United States and differences across US states from 2010 to 2018. Data on other years going back as far 1994 are publically available through [ICPRS website](https://www.icpsr.umich.edu/web/pages/ICPSR/index.html), though the survey methodology has changed over time and the Annual Probation Survey as used in this project started in 1999.

## probation_rates_tabset.Rmd
This R markdown file contains the full project and produces an HTML flexdashboard containing visuals and text

## probation_rates_code-figures.R
This R script file contains just the code needed to clean and modify the data files and then produce the visuals in R Studio

## probation_rates_tabset.html
This is the HTML file produced by the probation_rates_tabset.Rmd. A better look at the final flexdashboard is on my [RPubs profile](https://rpubs.com/rmjollie/984808)

## Data Sources

1) U.S. Census Bureau, Population Division, Table 1. Annual Estimates of the Resident Population for the United States, Regions, States, and Puerto Rico: April 1, 2010 to July 1, 2019 (NST-EST2019-01), released December 2019

2) United States Department of Justice. Office of Justice Programs. Bureau of Justice Statistics. Annual Probation Survey, 2010 - 2018.

3) United States Department of Justice. Office of Justice Programs. Bureau of Justice Statistics. Annual Survey of Jails, 2010 - 2018.

4) United States Department of Justice. Office of Justice Programs. Bureau of Justice Statistics.Corrections Statistical Analysis Tool (CSAT) - Prisoners, 2010 - 2018.

5) National Conference of State Legislatures. Legislative Partisan Composition Tables, 2010 - 2018
