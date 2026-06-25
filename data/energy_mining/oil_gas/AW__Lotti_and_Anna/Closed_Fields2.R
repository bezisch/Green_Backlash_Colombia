# Creating the List of Oil and Gas fields that were closed down <- Use for Desk research

rm(list = ls())

setwd("/Users/giacomoraederscheidt/Dropbox/MA Masterarbeit/H Oil and Gas Fields/AW__Lotti_and_Anna")

library(haven)
library(tidyverse)


df <- read.csv("/Users/giacomoraederscheidt/Dropbox/MA Masterarbeit/H Oil and Gas Fields/datos_completos_prod_regalias_2010_2021.csv") 

prod_df <- df %>% 
  select(ITEM = ITEM,
         Department = Departamento,
         Municipality = Municipio,
         Year = Anio,
         Month = Mes,
         Field = Campo,
         Product_Type=TipoProd, # I think it's important, check again
         Price_of_Hydrocarbons_USD = PrecioHidrocarburoUSD,
         Production = ProdGravableBlsKpc) %>% 
  #Volume_of_Royalties = VolumenRegaliaBlsKpc,
  #Royalty_COP = RegaliasCOP) %>% 
  rename(Taxable_Production = Production)

# calculating first and last years of reporting per Municipality/Field pair

 first_years <- prod_df %>%
     group_by(Municipality, Field) %>%
   summarise(First_Year = min(Year))

df_opening <- left_join(prod_df, first_years, by = c("Municipality", "Field"))

closing_years <- prod_df %>%
  group_by(Municipality, Field) %>%
  summarise(Closing_Year = max(Year))

df_opening_closing<- left_join(df_opening, closing_years, by = c("Municipality", "Field"))


# As Anna did, only consider period 2010-2019
filtered_df <- df_opening_closing %>%
  filter(Year >= 2010 & Year <= 2019) %>% 
  mutate(First_Year = ifelse(First_Year == 2010, NA, First_Year),
         Closing_Year = ifelse(Closing_Year >= 2019, NA, Closing_Year))
# filtered_df <- filtered_df %>%
#   group_by(Municipality, Field) %>%
#   arrange(Year) %>%
#   mutate(Prev_Year = lag(Year),
#          Years_between_missing = ifelse(any(diff(Year) > 1), TRUE, FALSE)) %>%
#   ungroup() %>%
#   select(-Prev_Year)

## To identify gaps in reporting  
filtered_df <- filtered_df %>%
  group_by(Municipality, Field) %>%
  arrange(Year) %>%
  mutate(Prev_Year = lag(Year),
         Years_between_missing = ifelse(any(diff(Year) > 1), TRUE, FALSE),
         Missing_Years = list(setdiff(min(Year):max(Year), Year))) %>%
  ungroup() %>%
  select(-Prev_Year)

# modified_df <- filtered_df %>%
#   group_by(Municipality, Field) %>%
#   mutate(pause = ifelse(Year - lag(Year, default = Year[1]) > 1, 1, 0)) %>%
#   ungroup()

# Calculating peak taxable production and the year of peak taxable production (howver right now, peak production refers to month, could change to cummulative year amount) 
output_df <- filtered_df %>% 
  filter(!is.na(Closing_Year))
output_df <- output_df %>% 
  group_by(Department, Municipality, Field) %>%
  mutate(Peak_Taxable_Production_barrels = max(Taxable_Production, na.rm = TRUE)) %>%
  mutate(Peak_Production_Year = Year[which.max(Taxable_Production)]) %>%
  ungroup()

# Only keep unique observations, based on all relevant identifiers
output_df <- output_df %>%
  distinct(Department, Municipality, Field, Closing_Year, .keep_all = TRUE)
# Keep relevant vars
output_df <- output_df %>% 
  select(Department, Municipality, Field, First_Year, Closing_Year, Peak_Taxable_Production_barrels, Peak_Production_Year, Missing_Years)

# I throw out all observations with zero peak taxable production (is it a reporting error, or do they still produce and it's just not taxed?). 
# However, there are still observations that for at least one of the reported years exhibit > 0 taxable production
output_df <- output_df %>% 
  filter(Peak_Taxable_Production_barrels > 0)

# Could throw out observations were opening year = closing year?



###
variation_counts <- output_df %>%
  group_by(Closing_Year) %>%
  summarise(municipalities = n_distinct(Municipality))

###################
# same but with zero taxable production considered as closed-field
# Filter out years with zero taxable production
prod_df2 <- prod_df %>%
  filter(Taxable_Production > 0)

first_years <- prod_df2 %>%
  group_by(Municipality, Field) %>%
  summarise(First_Year = min(Year))

df_opening <- left_join(prod_df2, first_years, by = c("Municipality", "Field"))

closing_years <- prod_df2 %>%
  group_by(Municipality, Field) %>%
  summarise(Closing_Year = max(Year))

df_opening_closing<- left_join(df_opening, closing_years, by = c("Municipality", "Field"))





filtered_df2 <- df_opening_closing %>%
  filter(Year >= 2010 & Year <= 2019) %>% 
  mutate(First_Year = ifelse(First_Year == 2010, NA, First_Year),
         Closing_Year = ifelse(Closing_Year >= 2019, NA, Closing_Year))



filtered_df2 <- filtered_df2 %>%
  group_by(Municipality, Field) %>%
  arrange(Year) %>%
  mutate(Prev_Year = lag(Year),
         Years_between_missing = ifelse(any(diff(Year) > 1), TRUE, FALSE),
         Missing_Years = list(setdiff(seq(min(Year), max(Year)), Year))) %>%
  ungroup() %>%
  select(-Prev_Year)

output_df2 <- filtered_df2 %>% 
  filter(!is.na(Closing_Year))

output_df2 <- output_df2 %>% 
  group_by(Department, Municipality, Field) %>%
  mutate(Peak_Taxable_Production_barrels = max(Taxable_Production, na.rm = TRUE)) %>%
  mutate(Peak_Production_Year = Year[which.max(Taxable_Production)]) %>%
  ungroup()

output_df2 <- output_df2 %>%
  distinct(Department, Municipality, Field, Closing_Year, .keep_all = TRUE)

output_df2 <- output_df2 %>% 
  select(Department, Municipality, Field, First_Year, Closing_Year, Peak_Taxable_Production_barrels, Peak_Production_Year, Missing_Years)

output_df2 <- output_df2 %>% 
  filter(Peak_Taxable_Production_barrels > 0)


# Excel without field name!
library(openxlsx)
wb <- createWorkbook()
#first sheet
addWorksheet(wb, "List_closed_fields")
writeData(wb, sheet = "List_closed_fields", x = "Description: list of oil and gas fields that closed down, input file for Brigitte's desk research. In this list 
          I did not consider fields that never reported non-zero taxable production, but kept fields with at least one year of non-zero reporting.
          I also checked for fields that exhibit a reporting gap. The column Missing_Years shows these years (e.g. 2012:2014 means that between 2012 and 2014, there was
          a reporting gap or the field temporarily closed(?) ", startCol = 1, startRow = 1)
writeData(wb, sheet = "List_closed_fields", x = output_df, startCol = 1, startRow = 2)

# second sheet
addWorksheet(wb, "List_closed_fields_zero_prod")
writeData(wb, sheet = "List_closed_fields_zero_prod", x = "Description: Difference to first sheet is that here I considered zero taxable production as closed-field", startCol = 1, startRow = 1)
writeData(wb, sheet = "List_closed_fields_zero_prod", x = output_df2, startCol = 1, startRow = 2)



saveWorkbook(wb, "List_closed_fields.xlsx", overwrite = TRUE)



