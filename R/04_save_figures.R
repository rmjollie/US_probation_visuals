# ============================================================
# 04_save_figures.R
#
# INPUT:  data-clean/  (produced by R/01_clean_data.R)
# OUTPUT: figs/         (static .png copies of every figure)
#
# Run this after 01_clean_data.R to (re)generate all figures as
# standalone image files -- handy for embedding in a portfolio
# README, slide deck, or anywhere outside the flexdashboard.
# The report itself (report/probation_rates_tabset.Rmd) calls the
# same make_*() functions directly and does not depend on this
# script having been run first.
# ============================================================

library(tidyverse)
library(here)

source(here("R", "00_helpers.R"))
source(here("R", "02_figures_national.R"))
source(here("R", "03_figures_case_study.R"))

select_table    <- read_rds(here("data-clean", "select_table.rds"))
complete_table  <- read_rds(here("data-clean", "complete_table.rds"))
stategov_unique <- read_rds(here("data-clean", "stategov_unique.rds"))
state_names     <- read_rds(here("data-clean", "state_names_ordered.rds"))

dir.create(here("figs"), showWarnings = FALSE)
geo_path <- here("data-raw", "geo", "us_states_hexgrid.geojson")

save_fig <- function(plot, filename, width = 9, height = 6) {
  ggsave(here("figs", filename), plot = plot, width = width, height = height, dpi = 150)
}

# National figures
save_fig(make_hexbin_map(select_table, geo_path), "national_hexbin_probation_2018.png")
save_fig(make_probation_linegraph(select_table),  "national_probation_rate_2010_2018.png")
save_fig(make_incarceration_bargraph(select_table), "national_supervision_bargraph_2018.png")
save_fig(make_partisanship_linegraph(select_table), "national_partisanship_linegraph.png")
save_fig(make_partisanship_boxplot(select_table),   "national_partisanship_boxplot_2018.png")
save_fig(make_change_map(select_table, state_names), "national_change_map_2010_2018.png")

# Case-study figures
save_fig(make_state_area_chart(select_table, "Idaho", line_color = "white", label_y = 1.4), "idaho_supervision_area.png")
save_fig(make_state_area_chart(select_table, "Georgia", line_color = "white", label_y = 1.5), "georgia_supervision_area.png")
save_fig(make_state_area_chart(select_table, "Arkansas", line_color = "black", label_y = 1.7), "arkansas_supervision_area.png")

message("Figures written to figs/")
message("Note: the offense donut charts (webr::PieDonut) and DT datatables are")
message("interactive/base-graphics widgets rather than ggplot objects, so they")
message("are rendered live in the Rmd report rather than saved here.")
