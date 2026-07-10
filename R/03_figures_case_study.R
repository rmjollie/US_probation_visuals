# ============================================================
# 03_figures_case_study.R
#
# The original project built near-identical charts for Idaho,
# Georgia, and Arkansas by copy-pasting the same code three times
# and swapping the state name. Here each chart type is a single
# parameterized function instead, called once per state.
# ============================================================

library(tidyverse)
library(viridis)
library(webr)
library(DT)

source(here::here("R", "02_figures_national.R"))  # for us_avg_supervision()

#' Area chart: supervision-type composition over time for one state,
#' with the US average overlaid as a dashed line
make_state_area_chart <- function(select_table, state_name, line_color = "black", label_y = 1.7) {
  state_df <- select_table %>%
    filter(STATE_NAME == state_name) %>%
    mutate(PROP_PRISON = PRISON / POP * 100,
           PROP_CONFPOP = TCONFPOP / POP * 100,
           PROP_NCONPOP = TNCONPOP / POP * 100) %>%
    gather(key = "TYPE", value = "PROP_SUPERVISION", 12:15)

  us_avg_sup <- us_avg_supervision(select_table)
  my_palette <- rev(mako(5))[c(-1, -8)]

  ggplot() +
    geom_area(data = state_df, aes(x = YEAR, y = PROP_SUPERVISION, group = TYPE, fill = TYPE)) +
    geom_line(data = us_avg_sup, aes(x = YEAR, y = US_AVG_SUP, group = GROUP), size = 1,
              linetype = "dashed", color = line_color) +
    annotate(geom = "text", x = 4, y = label_y, label = "US Average (Probation + Incarceration)",
             hjust = "left", color = line_color) +
    scale_y_continuous(labels = function(x) paste0(x, "%")) +
    scale_fill_manual(values = my_palette,
                       labels = c("Prison", "Confined to Jail", "Jail Supervision", "Probation"),
                       name = "Supervision Type") +
    labs(x = "", y = "", title = paste0("Change in Probation and Jail Rate in ", state_name, " from 2010 - 2018")) +
    theme_classic() +
    theme(plot.title = element_text(size = 15, hjust = 0.5, color = "black", margin = margin(b = 0.3, t = 1, l = 2, unit = "cm")),
          plot.subtitle = element_text(size = 12, hjust = 0.5, color = "black"))
}

#' Donut chart: breakdown of probationers' most serious offense type,
#' for one state and one year
make_state_offense_donut <- function(complete_table, state_name, year,
                                      exclude_subtypes = c("DUI"), title_prefix = "Probationers Most Serious Offense in") {
  state_df <- complete_table %>%
    filter(STATE_NAME == state_name) %>%
    select(STATE_NAME, starts_with("TOTBEG"), starts_with("TOTOFF"), starts_with("DMVIOL"),
           starts_with("SXASLT"), starts_with("OTHVIOL"), starts_with("PROPERTY"),
           starts_with("DRUG"), starts_with("DUI"), starts_with("TRAF"),
           starts_with("OTHOFF"), starts_with("OFFUNK")) %>%
    pivot_longer(-c("STATE_NAME"), names_to = c(".value", "YEAR"), names_sep = "_")

  colnames(state_df) <- c("State_name", "Year", "TotalProb", "TotalOff",
                           "DV", "Sexual Assualt", "Other Violent",
                           "Property Crime", "Drug Crime", "DUI", "Traffic", "Other Crime", "Unknown")

  donut_df <- state_df %>%
    filter(Year == as.character(year)) %>%
    gather(key = "Subtype", value = "Crime", 5:13) %>%
    cbind(Offenses = c(rep("Violent", 3), rep("Nonviolent", 4), "Other", "Unknown")) %>%
    filter(!Subtype %in% exclude_subtypes, Offenses != "Unknown")

  donut_df$Offenses <- factor(donut_df$Offenses)
  donut_df$Subtype <- factor(donut_df$Subtype)

  PieDonut(donut_df, aes(Offenses, Subtype, count = Crime),
           ratioByGroup = FALSE, r0 = .3, r1 = .8,
           title = paste(title_prefix, year), labelpositionThreshold = 0.05)
}

#' Small summary datatable for a state: gov't control + current supervision counts
make_state_datatable <- function(stategov_unique, select_table, state_name) {
  gov_control <- stategov_unique %>%
    filter(start_column == state_name) %>%
    select(starts_with("state")) %>%
    t()

  counts <- select_table %>%
    filter(STATE_NAME == state_name) %>%
    select(POP, TOTBEG, TCONFPOP, TNCONPOP, PRISON) %>%
    mutate(across(everything(), pretty_count))

  out <- t(cbind(gov_control, counts))
  colnames(out) <- gsub("State..Control_", "", colnames(out))
  rownames(out) <- c("State Gov't Control", "State Population", "Probationers", "In Jail", "Jail Supervision", "State Prison")

  datatable(out, options = list(columnDefs = list(list(className = "dt-right", targets = 1:9))))
}
