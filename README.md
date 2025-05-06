# Multiple Cause of Death/Death Ratio Dataset

## Overview:

This dataset contains monthly mortality statistics across U.S. states, stratified by demographic characteristics such as 5-year age group, sex, and race. The data spans from 1973 to 2022 and includes key metrics such as the number of deaths, monthly population estimates, and calculated mortality ratios.

The primary purpose of this dataset is to support public health research, particularly the analysis of mortality patterns over time and across subpopulations. Each row in the dataset represents a unique combination of year, month, state, age group, sex, and race, with corresponding counts of deaths and population, along with a precomputed mortality ratio. 

## Data Source:

### (1) Mortality Data
Multiple cause of death data-related variables are based on U.S. death records provided by the National Center for Health Statistics (NCHS), covering the period from 1973 to 2022.

• 1973–2004: [NBER Vital Statistics - Multiple Cause of Death Data](https://www.nber.org/research/data/mortality-data-vital-statistics-nchs-multiple-cause-death-data)

• 2005–2022: Restricted-use mortality data obtained from internal sources.

### (2) Population Data
Annual population estimates were sourced from multiple datasets covering different time periods, monthly population values for each demographic group were interpolated using linear interpolation:

• 1973–1979: [U.S. Census County Population Estimates](https://www.census.gov/data/tables/time-series/demo/popest/pre-1980-county.html)

• 1980–1989: [U.S. Census 1980s County Population Estimates](https://www.census.gov/data/tables/time-series/demo/popest/1980s-county.html)

• 1990–2020: [CDC Bridged-Race Population Estimates](https://wonder.cdc.gov/bridged-race-population.html)

• 2021–2022: [CDC Single-Race Population Estimates](https://wonder.cdc.gov/single-race-population.html)

## Data Structure:

| Variable Name | Type     | Description                                          | Example     |
|---------------|----------|------------------------------------------------------|-------------|
| year          | Numeric  | Year of death occurrence                             | 1973        |
| month         | Integer  | Month of death occurrence                            | 1           |
| state         | Character| U.S. state abbreviation where deaths occurred        | "NY"        |
| age           | Ordered Factor | Five-year age group of the deceased             | "75–79"     |
| sex           | Character| Biological sex of the deceased                       | "Female"    |
| race          | Factor   | Race category of the deceased, standardized by CDC   | "White"     |
| cause         | Integer  | Underlying causes of death, ICD-7/8/9                | 4123        |
| deaths        | Numeric  | Number of deaths recorded in the subgroup and month | 170         |
| population    | Numeric  | Estimated population of the given subgroup and time | 71,893      |
| ratio         | Numeric  | Mortality rate per 100,000 population                | 236.4625207 |
