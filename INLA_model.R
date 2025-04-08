library(dplyr)
library(here)
library(haven)
library(stringr)
library(readr)
library(purrr)
library(readxl)
library(tidyr)
library(posterior)
library(ggplot2)
library(coda)
library(spdep)
library(INLA)

project_root <- here::here()
setwd(project_root)

all_causes_summary <- read_rds("output_seasonal/all_causes_summary.rds")
age_levels <- c("<1", "1-4", "5-9", "10-14", "15-19", "20-24", "25-29", "30-34",
                "35-39", "40-44", "45-49", "50-54", "55-59", "60-64",
                "65-69", "70-74", "75-79", "80-84", "85+")
race_levels <- c("White", "Black or African American", "Asian or Pacific Islander",
                 "American Indian or Alaska Native", "All other races")

subset_test_f <- all_causes_summary %>%
  filter(!is.na(month)) %>%
  filter(!is.na(ratio)) %>%
  filter(sex == 'Female') %>%
  slice_sample(n = 70000) %>%
  arrange(year, month) %>%
  mutate(
    x = year - 1972,
    xm = (year - 1973) * 12 + month,
    age = factor(age, levels = age_levels, ordered = TRUE),
    race = factor(race, levels = race_levels)
  ) %>%
  mutate(
    id_agemo = as.integer(interaction(age, month, drop = TRUE)),
    id_racemo = as.integer(interaction(race, month, drop = TRUE)),
    month2 = subset_test_f$month,
    age2 = subset_test_f$age,
    race2 = subset_test_f$race,
    id_agemo2 = subset_test_f$id_agemo,
    id_racemo2 = subset_test_f$id_racemo
  )

subset_test_m <- all_causes_summary %>%
  filter(!is.na(month)) %>%
  filter(!is.na(ratio)) %>%
  filter(sex == 'Male') %>%
  slice_sample(n = 20000) %>%
  arrange(year, month) %>%
  mutate(
    x = year - 1972,
    xm = (year - 1973) * 12 + month,
    age = factor(age, levels = age_levels, ordered = TRUE),
    race = factor(race, levels = race_levels)
  ) %>%
  mutate(
    id_agemo = as.integer(interaction(age, month, drop = TRUE)),
    id_racemo = as.integer(interaction(race, month, drop = TRUE)),
    month2 = subset_test_f$month,
    age2 = subset_test_f$age,
    race2 = subset_test_f$race,
    id_agemo2 = subset_test_f$id_agemo,
    id_racemo2 = subset_test_f$id_racemo
  )

## INLA Code for national seasonal model
# INLA requires unique names for the first of each in f(). So for example you set:
# dat$age2 = dat$age
# etc. because f(AGE,...) and f(AGE2,...) need to be different
# The second term in each f() (e.g., f(age2, YEAR2,...)) can be repeated as the second term
# To test, you can try all 'rw1' as 'iid' first
# Please try most basic model to check that INLA runs first,
# i.e., fml <- deaths ~ 1 + year.month
## dat - data frame in long form
## year.month, year.month2, ... - month and year over time, values 1-N_yearmonth
## month1, month2, ... - indices for month, values 1-12
## e - column of 1...N_rows_dataframe
# hyperparameter value and hyperprior
loggamma_prior = function(gamma.shape = 0.001, gamma.rate = 0.001) {
  as.character(glue::glue(
    'list(prec = list(prior = "loggamma", param = ',
    'c({gamma.shape}, {gamma.rate})))'
  ))
}
hyperprior = loggamma_prior()

#INLA formula
fml <- deaths ~ 1 + # global intercept
  xm + # global slope
  # month specific terms (cyclical random walk)
  f(month, model='iid', hyper = hyperprior, constr = TRUE) + # month specific intercept
  f(month2, xm, model='iid', hyper = hyperprior, constr = TRUE) + # month specific slope
  # age group specific terms (random walk)
  f(age, model='iid', hyper = hyperprior, constr = TRUE) + # age group specific intercept
  f(age2, xm, model='iid', hyper = hyperprior, constr = TRUE) + # age group specific slope
  # race specific terms (iid)
  f(race, model='iid', hyper = hyperprior, constr = TRUE) + # race specific intercept
  f(race2, xm, model='iid', hyper = hyperprior, constr = TRUE) + # race specific slope
  # age-month interaction
  f(id_agemo, model='iid', hyper = hyperprior, constr = TRUE) + # age-month specific intercept
  f(id_agemo2, xm, model='iid', hyper = hyperprior, constr = TRUE) + # age-month specific slope
  # race-month interaction
  f(id_racemo, model='iid', hyper = hyperprior, constr = TRUE) + # race-month specific intercept
  f(id_racemo2, xm, model='iid', hyper = hyperprior, constr = TRUE) + # race-month specific slope

  # # month-age specific terms (cyclical random walk x random walk)
  # f(month3, model="rw1", cyclic = TRUE, group=age3, control.group=list(model='rw1', hyper = hyperprior), hyper = hyperprior, fixed=FALSE)),scale = TRUE, constr = TRUE) + # month-age specific intercept
  # f(month4, year.month2, model="rw1", cyclic = TRUE, group=age3, control.group=list(model='rw1', hyper = hyperprior), hyper = hyperprior, fixed=FALSE)),scale = TRUE, constr = TRUE) + # month-age specific slope
  # # month-race specific terms (cyclical random walk x iid)
  # f(month5, model="rw1", cyclic = TRUE, group=race3, control.group=list(model='iid', hyper = hyperprior), hyper = hyperprior, fixed=FALSE)),scale = TRUE, constr = TRUE) + # month-race specific intercept
  # f(month6, year.month2, model="rw1", cyclic = TRUE, group=race3, control.group=list(model='iid', hyper = hyperprior), hyper = hyperprior, fixed=FALSE)),scale = TRUE, constr = TRUE) + # month-race specific slope
  # # age-race specific terms (random walk x iid)
  # f(age4, model="rw1", group=race3, control.group=list(model='iid', hyper = hyperprior), hyper = hyperprior, fixed=FALSE)),scale = TRUE, constr = TRUE) + # age-race specific intercept
  # f(age5, year.month2, model="rw1", group=race3, control.group=list(model='iid', hyper = hyperprior), hyper = hyperprior, fixed=FALSE)),scale = TRUE, constr = TRUE) + # age-race specific slope
  # # random walk across time
  #
  # f(year.month3, model="rw1", hyper = hyperprior, scale = TRUE, constr = TRUE) + # rw1 over time
  #
  # overdispersion term
  # f(e, model = "iid", hyper = hyperprior, constr = TRUE) # overdispersion term

# INLA model rough
mod.rough =
  inla(formula = fml,
       family = "poisson",
       data = subset_test_f,
       E = population,
       control.compute = list(dic=TRUE, openmp.strategy="huge"), # openmp.strategy="pardiso.parallel" ?
       control.predictor = list(link = 1),
       control.inla = list(diagonal=10000, int.strategy='eb',strategy='gaussian'),
       #num.threads = 40,
       # verbose=TRUE
  )

# INLA model proper
mod =
  inla(formula = fml,
       family = "poisson",
       data = subset_test_f,
       E = population,
       control.compute = list(config=TRUE, dic=TRUE, openmp.strategy="huge"), # openmp.strategy="pardiso.parallel" ?
       control.predictor = list(link = 1),
       control.inla=list(diagonal=0),
       control.mode = list(result = mod.rough, restart = TRUE),
       #num.threads = 40,
       #verbose=TRUE
  )

plot(mod)

summary(mod)








