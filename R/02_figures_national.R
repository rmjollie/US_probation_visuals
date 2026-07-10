# ============================================================
# 02_figures_national.R
#
# National-level figures. Each function takes a clean table
# (loaded from data-clean/) and returns a ggplot object.
# Source this file, then call the functions from the Rmd report
# or from R/04_save_figures.R to write them to figs/.
# ============================================================

library(tidyverse)
library(gghighlight)
library(viridis)
library(sf)

#' US average supervision rate by year, used as a reference line
#' on several of the figures below
us_avg_supervision <- function(select_table) {
  df <- select_table
  df$TOTBEG <- as.numeric(df$TOTBEG)
  # Georgia and Michigan didn't report in 2016; interpolate from adjacent years
  df[df$STATE_ABBR == "GA" & df$YEAR == 2016, "TOTBEG"] <-
    (df[df$STATE_ABBR == "GA" & df$YEAR == 2015, "TOTBEG"] + df[df$STATE_ABBR == "GA" & df$YEAR == 2017, "TOTBEG"]) / 2
  df[df$STATE_ABBR == "MI" & df$YEAR == 2016, "TOTBEG"] <-
    (df[df$STATE_ABBR == "MI" & df$YEAR == 2015, "TOTBEG"] + df[df$STATE_ABBR == "MI" & df$YEAR == 2017, "TOTBEG"]) / 2
  
  df %>%
    group_by(YEAR) %>%
    summarize(POP_SUM = sum(POP), TOTBEG_SUM = sum(TOTBEG, na.rm = TRUE),
              TCONFPOP_SUM = sum(TCONFPOP, na.rm = TRUE), TNCONPOP_SUM = sum(TNCONPOP, na.rm = TRUE),
              PRISON_SUM = sum(PRISON, na.rm = TRUE)) %>%
    mutate(US_AVG_SUP = (TOTBEG_SUM + TCONFPOP_SUM + TNCONPOP_SUM + PRISON_SUM) / POP_SUM * 100,
           GROUP = "United States")
}

#' Hexbin map: % of state population on probation in 2018
make_hexbin_map <- function(select_table, geo_path) {
  geo <- sf::st_read(geo_path, quiet = TRUE)
  
  centers <- sf::st_centroid(geo)
  centers <- cbind(sf::st_coordinates(centers), id = geo$iso3166_2) %>%
    as.data.frame()
  centers$X <- as.numeric(centers$X)
  centers$Y <- as.numeric(centers$Y)
  
  my_palette <- rev(mako(6))[c(-1, -8)]
  
  df_2018 <- select_table %>% filter(YEAR == 2018)
  df_2018$bin <- cut(df_2018$PROP_PROBATION, breaks = c(0, 0.5, 1, 2, 4),
                     labels = c("under 0.5%", "0.5 - 0.99%", "1 - 1.99%", "2% or more"),
                     include.lowest = TRUE)
  
  geo_joined <- dplyr::left_join(geo, df_2018, by = c("iso3166_2" = "STATE_ABBR"))
  
  ggplot() +
    geom_sf(data = geo_joined, aes(fill = bin)) +
    geom_text(data = centers, aes(x = X, y = Y, label = id), color = "white", size = 4) +
    theme_void() +
    scale_fill_manual(values = my_palette, name = "% of population on probation",
                      guide = guide_legend(keyheight = unit(3, "mm"), keywidth = unit(18, "mm"),
                                           label.position = "bottom", title.position = "top", nrow = 1)) +
    ggtitle("Percent of State Population on Probation in 2018") +
    theme(legend.position = c(0.5, 0.85),
          plot.background = element_rect(fill = "white", color = NA),
          panel.background = element_rect(fill = "white", color = NA),
          legend.background = element_rect(fill = "white", color = NA),
          legend.key = element_rect(fill = "white", color = NA),
          plot.title = element_text(size = 15, hjust = 0.5, color = "black",
                                    margin = margin(b = -0.1, t = 0.4, l = 2, unit = "cm")))
}

#' Line graph: % of state population on probation, 2010-2018, with high-probation
#' states highlighted and a dashed US average line
make_probation_linegraph <- function(select_table) {
  us_avg <- us_avg_supervision(select_table) %>% rename(US_AVG = US_AVG_SUP)
  
  high_probation <- select_table %>%
    filter(PROP_PROBATION >= 2) %>%
    arrange(desc(PROP_PROBATION)) %>%
    pull(STATE_ABBR) %>%
    unique()
  
  ggplot() +
    geom_line(data = select_table, aes(x = YEAR, y = PROP_PROBATION, group = STATE_NAME, col = STATE_NAME), size = 0.6) +
    gghighlight(STATE_ABBR %in% high_probation) +
    scale_y_continuous(labels = function(x) paste0(x, "%")) +
    geom_line(data = us_avg, aes(x = YEAR, y = US_AVG, group = GROUP), linewidth = 1, linetype = "dashed") +
    annotate(geom = "text", x = 4, y = 1.4, label = "US Average", hjust = "left") +
    geom_label(label = "Georgia did not report \n probation data in 2016", x = 8, y = 5, color = "coral") +
    annotate(geom = "curve", color = "coral", x = 8, y = 4.8, xend = 7, yend = 4.4,
             curvature = .3, arrow = arrow(length = unit(2, "mm"))) +
    labs(y = "", x = "", title = "Percent of State Population on Probation 2010 - 2018") +
    theme_classic() +
    theme(plot.title = element_text(size = 15, hjust = 0.5, color = "black",
                                    margin = margin(b = 0.3, t = 0.4, l = 1.5, unit = "cm")),
          legend.position = "none")
}

#' Bar graph: % of population on probation/jail/prison in 2018, by state
make_incarceration_bargraph <- function(select_table) {
  df <- select_table %>% filter(YEAR == 2018)
  df$STATE_ABBR <- factor(df$STATE_ABBR, levels = df$STATE_ABBR[order(df$POP)])
  
  df <- df %>%
    select(1:9) %>%
    gather(key = "TYPE", value = "SUPERVISED", 6:9) %>%
    mutate(PERC_SUP_TYPE = SUPERVISED / POP * 100)
  
  my_palette <- rev(mako(6))[c(-1, -8)]
  
  ggplot(df, aes(x = STATE_ABBR, y = PERC_SUP_TYPE, fill = TYPE)) +
    geom_bar(stat = "identity") +
    annotate(geom = "curve", x = 16.5, y = 1.9, xend = 15, yend = 1.45,
             curvature = .3, arrow = arrow(length = unit(2, "mm"))) +
    annotate(geom = "text", x = 16, y = 2, label = "Highest Percentage Quartile \n on Probation", hjust = "left") +
    coord_flip() +
    geom_hline(yintercept = 1.4, linetype = "dashed", size = .8) +
    scale_y_continuous(labels = function(x) paste0(x, "%")) +
    scale_fill_manual(values = my_palette,
                      labels = c("Prison", "Confined to Jail", "Jail Supervision", "Probation"),
                      name = "Supervision Type") +
    labs(x = "", y = "", title = "Percent of State Population on Probation and in Jail in 2018",
         subtitle = "Ordered by State Population Size") +
    theme_classic() +
    theme(plot.title = element_text(size = 15, hjust = 0.5, color = "black", margin = margin(b = 0.3, t = 1, l = 2, unit = "cm")),
          plot.subtitle = element_text(size = 12, hjust = 0.5, color = "black"),
          legend.position = c(.8, .6))
}

#' Line graph: average supervision rate by state government partisanship
make_partisanship_linegraph <- function(select_table) {
  swing_sup <- select_table %>%
    filter(STATE_NAME != "Georgia" & STATE_NAME != "Michigan") %>%
    group_by(SWING, YEAR) %>%
    summarize(SUM_CONFPOP = sum(TCONFPOP, na.rm = TRUE), SUM_TOTBEG = sum(TOTBEG, na.rm = TRUE),
              SUM_NCONPOP = sum(TNCONPOP, na.rm = TRUE), SUM_PRISON = sum(PRISON, na.rm = TRUE),
              SUM_POP = sum(POP, na.rm = TRUE)) %>%
    mutate(AVG_PERC_SUP = (SUM_CONFPOP + SUM_TOTBEG + SUM_NCONPOP + SUM_PRISON) / SUM_POP * 100) %>%
    ungroup() %>%
    drop_na()
  
  ggplot(swing_sup, aes(x = YEAR, y = AVG_PERC_SUP, group = SWING, color = SWING)) +
    geom_line(size = 1.2) +
    geom_label(color = "purple", fill = "#FAD6FF", x = 3.5, y = .8,
               label = "Only one state (Arkansas) \n changed partisan control \n between 2010 and 2018 \n from Democratic 2010 - 2012 \n Divided 2013 - 2014 \n and Republican 2015 - 2018") +
    annotate(geom = "curve", color = "purple", x = 1, y = 1.05, xend = 1, yend = 1.52,
             curvature = -.3, arrow = arrow(length = unit(2, "mm"))) +
    scale_color_manual(values = c("blue", "Orange", "Red", "Purple")) +
    guides(color = guide_legend(title = "State Gov Partisanship")) +
    theme_classic() +
    labs(y = "", x = "", title = "Percent of US Population on Probation or Incarcerated \n Based on State Government Pastisanship") +
    scale_y_continuous(labels = function(x) paste0(x, "%"), limits = c(0, 2)) +
    theme(plot.title = element_text(size = 15, hjust = 0.5, color = "black", margin = margin(b = -0.1, t = 0.5, l = 2, unit = "cm")))
}

#' Boxplot: distribution of 2018 supervision rate by partisanship group
make_partisanship_boxplot <- function(select_table) {
  select_table %>%
    filter(YEAR == 2018) %>%
    drop_na() %>%
    ggplot(aes(x = SWING, y = PROP_SUP, fill = SWING)) +
    geom_boxplot() +
    geom_label(label = "GA", x = 3.15, y = 4.55, fill = "white") +
    scale_y_continuous(labels = function(x) paste0(x, "%")) +
    scale_fill_manual(values = c("blue", "Orange", "Red", "Purple")) +
    labs(x = "", y = "", title = "Distribution of State Population on Probation or in Jail \n Based on State Government Control") +
    theme_classic() +
    theme(plot.title = element_text(size = 15, hjust = 0.5, color = "black", margin = margin(b = 0.3, t = 1, l = 2, unit = "cm")),
          plot.subtitle = element_text(size = 12, hjust = 0.5, color = "black"),
          legend.position = "none")
}

#' Choropleth: % change in state probation population, 2010 to 2018
make_change_map <- function(select_table, state_names_ordered) {
  select_table_change <- select_table %>%
    select(1:6) %>%
    filter(YEAR == 2010 | YEAR == 2018) %>%
    pivot_wider(names_from = YEAR, values_from = c(POP, TOTBEG)) %>%
    mutate(CHANGE = (TOTBEG_2018 - TOTBEG_2010) / TOTBEG_2010 * 100) %>%
    mutate(DIRECTION = ifelse(CHANGE < 0, "decrease", "increase"),
           STATE_NAME = str_to_lower(state_names_ordered))
  
  state_map <- map_data("state")
  state_map <- left_join(state_map, select_table_change, by = c("region" = "STATE_NAME"))
  
  ggplot(state_map, aes(x = long, y = lat, group = group, fill = CHANGE)) +
    geom_polygon(color = "black") +
    scale_fill_gradient2(low = "#123EF0", mid = "white", high = "#EB7D00", name = "% change") +
    coord_map() +
    labs(title = "Change in State Probation Populations from 2010-2018",
         subtitle = "as a percent of each state's probation population in 2010") +
    theme_void() +
    theme(text = element_text(color = "black"),
          legend.position = c(0.9, 0.3),
          plot.background = element_rect(fill = "white", color = NA),
          panel.background = element_rect(fill = "white", color = NA),
          legend.background = element_rect(fill = "white", color = NA),
          legend.key = element_rect(fill = "white", color = NA),
          plot.title = element_text(hjust = 0.1),
          plot.subtitle = element_text(hjust = 0.1),
          plot.caption = element_text(hjust = 0.9))
}