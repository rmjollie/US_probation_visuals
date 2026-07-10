# ============================================================
# 00_helpers.R
# Shared helper functions used by the cleaning and figure scripts.
# Source this file at the top of any script that needs it:
#     source(here::here("R", "00_helpers.R"))
# ============================================================

#' Bind a list of yearly tables into one wide table, keyed on state
#'
#' Takes a list of tables (one per year) that all share the same
#' identifier column(s) and value column(s), and glues them together
#' side-by-side, suffixing each value column with its year
#' (e.g. TOTBEG_2010, TOTBEG_2011, ...).
#'
#' @param list list of data frames, one per year, in chronological order
#' @param id_cols character vector of identifier column(s) to keep from the first table
#' @param value_cols character vector of value column(s) to pull from every table
#' @param start_year the year of the first table in `list`
#' @return a single wide data frame
bind_tables <- function(list, id_cols, value_cols, start_year = 2010) {
  start_column <- list[[1]][, id_cols]
  year <- start_year
  for (i in seq_along(list)) {
    new_table <- list[[i]][, value_cols]
    start_column <- cbind(start_column, new_table)
    start_column <- dplyr::rename_at(start_column, dplyr::vars(value_cols), ~ paste0(., "_", year))
    year <- year + 1
  }
  start_column
}

#' Format a supervised-population count column with thousands separators
#'
#' Small convenience wrapper so the state case-study data tables
#' (Georgia / Idaho / Arkansas) don't repeat the same prettyNum() call
#' four times each.
pretty_count <- function(x) {
  prettyNum(ceiling(x), big.mark = ",", scientific = FALSE)
}
