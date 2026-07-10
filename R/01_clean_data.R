# ============================================================
# 01_clean_data.R
#
# INPUT:  data-raw/  (untouched source files, as downloaded from
#                      ICPSR, the Census Bureau, and NCSL)
# OUTPUT: data-clean/ (tidy, joined tables ready for analysis/figures)
#
# Run this script once (or whenever the raw data changes) to
# regenerate data-clean/. Nothing in R/02_make_figures.R or
# report/probation_rates_tabset.Rmd reads from data-raw directly.
# ============================================================

library(tidyverse)
library(here)
library(rio)

source(here("R", "00_helpers.R"))

# ---- 1. Load raw data ---------------------------------------------------

probation_files <- c(
  "34321-0001-Data.tsv", "34717-0001-Data.tsv", "35256-0001-Data.tsv",
  "35631-0001-Data.tsv", "36343-0001-Data.tsv", "36618-0001-Data.tsv",
  "37459-0001-Data.tsv", "37482-0001-Data.tsv", "38057-0001-Data.tsv"
)
probation_tables <- map(probation_files, ~ import(here("data-raw", "probation", .x)))

jail_files <- c(
  "31261-0001-Data.tsv", "33722-0001-Data.tsv", "34884-0001-Data.tsv",
  "35517-0001-Data.tsv", "36274-0001-Data.tsv", "36760-0001-Data.tsv",
  "37135-0001-Data.tsv", "37373-0001-Data.tsv", "37392-0001-Data.tsv"
)
jails <- map(jail_files, ~ import(here("data-raw", "jails", .x)))
names(jails) <- paste0("jails", 2010:2018)
list2env(jails, envir = environment())  # jails2010 ... jails2018

partisanship_files <- paste0("State Legislature Partisanship - ", 2010:2018, ".csv")
stategov_tables <- map(partisanship_files, ~ import(here("data-raw", "partisanship", .x)))

prisons   <- import(here("data-raw", "prisons", "Prisoners - Sheet1.tsv"))
population1 <- import(here("data-raw", "population", "nst-est2019-01.xlsx - NST01.csv"))

# ---- 2. Format population table -----------------------------------------

population1 <- slice(population1, c(10:60))
colnames(population1) <- c("state", "census", "estimate", "2010", "2011", "2012",
                           "2013", "2014", "2015", "2016", "2017", "2018", "2019")
population1 <- select(population1, "state", "2010":"2018")
population1 <- gather(population1, key = "year", value = "population", 2:10)
population1$population <- population1$population %>%
  str_remove_all(",") %>%
  as.numeric()
population1$state <- str_remove(population1$state, pattern = ".")

# ---- 3. Format probation tables ------------------------------------------

probation_all <- bind_tables(
  probation_tables, c("STATE", "STATEID"),
  c("TOTBEG", "TOTOFF", "DMVIOL", "SXASLT", "OTHVIOL",
    "PROPERTY", "DRUG", "DUI", "TRAF", "OTHOFF", "OFFUNK")
)
probation_all[probation_all == -9] <- NA
probation_all[probation_all == -8] <- NA
probation_all <- probation_all %>%
  subset(STATEID != 0) %>%
  rename_at(vars("STATE"), ~ paste0(., "_ABBR"))

# ---- 4. Format jail tables ------------------------------------------------

jails_recode <- tibble(STATE_NAME = unique(population1$state), NUMS = 1:51,
                        STATE_ABBR = probation_all$STATE_ABBR)

jails2010 <- left_join(jails2010, jails_recode, by = c("state" = "NUMS"))
jails2011 <- left_join(jails2011, jails_recode, by = c("state" = "NUMS"))
jails2012 <- left_join(jails2012, jails_recode, by = c("state" = "NUMS"))
jails2013 <- left_join(jails2013, jails_recode, by = c("STATE" = "STATE_ABBR"))
jails2014 <- left_join(jails2014, jails_recode, by = c("STATE" = "STATE_ABBR"))
jails2015 <- left_join(jails2015, jails_recode, by = c("STATE" = "NUMS"))
jails2016 <- left_join(jails2016, jails_recode, by = c("STATE" = "NUMS"))
jails2017 <- left_join(jails2017, jails_recode, by = c("STATE" = "NUMS"))
jails2018 <- left_join(jails2018, jails_recode, by = c("STATE" = "NUMS"))

names(jails2010) <- toupper(names(jails2010))
names(jails2011) <- toupper(names(jails2011))
names(jails2012) <- toupper(names(jails2012))
jails2010 <- rename_at(jails2010, vars("FINALWEIGHT"), ~paste0("FINALWT"))
jails2011 <- rename_at(jails2011, vars("FINALWEIGHT"), ~paste0("FINALWT"))
jails2012 <- rename_at(jails2012, vars("FINALWEIGHT"), ~paste0("FINALWT"))
jails2013 <- rename_at(jails2013, vars("WEIGHT"), ~paste0("FINALWT"))
jails2014 <- rename_at(jails2014, vars("WEIGHT"), ~paste0("FINALWT"))

for (yr in 2010:2018) {
  nm <- paste0("jails", yr)
  assign(nm, mutate(get(nm), TCONFPOP = FINALWT * CONFPOP, TNCONPOP = FINALWT * NCONPOP))
}

jails_grouped <- map(2010:2018, function(yr) {
  get(paste0("jails", yr)) %>%
    group_by(STATE_NAME) %>%
    summarise_if(is.numeric, list(sum = sum))
})

jails_all <- bind_tables(jails_grouped, c("STATE_NAME"), c("TCONFPOP_sum", "TNCONPOP_sum"))

# ---- 5. Format prisons table ----------------------------------------------

names(prisons) <- prisons[1, ]
prisons <- prisons[-1, ]
colnames(prisons)[2:10] <- paste("PRISON", colnames(prisons)[2:10], sep = "_")
prisons <- mutate(prisons, STATE_NAME = str_to_title(prisons$State[1:50]))

# ---- 6. Format state government partisanship tables ------------------------

stategov_all <- bind_tables(
  stategov_tables, c("State"),
  c("Legis. \nControl", "Gov. \nParty", "State \nControl")
)
stategov_all <- stategov_all %>%
  mutate_all(funs(str_replace(., "e Rep", "Rep"))) %>%
  mutate_all(funs(str_replace(., "N/A", NA_character_)))

stategov_unique <- select(stategov_all, start_column, starts_with("State \nControl"))
stategov_unique <- stategov_unique %>% mutate(SWING = case_when(
  rowSums(stategov_unique == "Rep") >= 7 ~ "Republican",
  rowSums(stategov_unique == "Dem") >= 7 ~ "Democrat",
  rowSums(stategov_unique == "Rep") > 1 & rowSums(stategov_unique == "Dem") > 1 ~ "Swing",
  TRUE ~ "Divided"
))

# ---- 7. Join everything into one long table --------------------------------

population_wide <- pivot_wider(population1, names_from = "year", values_from = "population",
                                names_prefix = "POP_")
probation_pop <- cbind(population_wide, probation_all)

complete_table <- left_join(stategov_unique, jails_all, by = c("start_column" = "STATE_NAME"))
complete_table[is.na(complete_table)] <- 0
complete_table <- left_join(probation_pop, complete_table, by = c("state" = "start_column"))
complete_table <- rename_at(complete_table, vars("state"), ~paste0("STATE_NAME"))
complete_table <- left_join(complete_table, prisons, by = c("STATE_NAME" = "STATE_NAME"))

select_table <- complete_table %>%
  select(STATE_NAME, STATE_ABBR, SWING, starts_with("POP_"),
         starts_with("TOTBEG"), starts_with("TCONFPOP"),
         starts_with("TNCONPOP"), starts_with("PRISON"))
colnames(select_table) <- sub("_sum", "", colnames(select_table))

select_table <- select_table %>%
  pivot_longer(-c("STATE_NAME", "STATE_ABBR", "SWING"), names_to = c(".value", "YEAR"), names_sep = "_")
select_table <- select_table %>%
  mutate(PROP_SUP = (TOTBEG + TCONFPOP + TNCONPOP + PRISON) / POP * 100,
         ABS_SUP = TOTBEG + TCONFPOP + TNCONPOP + PRISON,
         PROP_PROBATION = TOTBEG / POP * 100)

# ---- 8. Write clean data ----------------------------------------------------
# One .rds per table used downstream, so R/02_make_figures.R and the Rmd
# report can each load only what they need instead of re-running all of
# the above.

dir.create(here("data-clean"), showWarnings = FALSE)

write_rds(select_table,     here("data-clean", "select_table.rds"))
write_rds(complete_table,   here("data-clean", "complete_table.rds"))
write_rds(stategov_unique,  here("data-clean", "stategov_unique.rds"))
write_rds(population1$state[1:51], here("data-clean", "state_names_ordered.rds"))

message("Clean data written to data-clean/")
