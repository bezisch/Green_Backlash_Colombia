# Creating the List of Oil and Gas fields that were closed down <- Use for Desk research

rm(list = ls())

setwd("/Users/giacomoraederscheidt/Dropbox/MA Masterarbeit/H Oil and Gas Fields/AW__Lotti_and_Anna")
 
library(haven)
library(tidyverse)


df_complete <- read.csv("Merged_file(2010-2019).csv") 
df_complete <- read.csv("Merged_file") 

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

# Only keep unique observations, based on all relevant identifiers
prod_df <- prod_df %>%
  distinct(Department, Municipality, Year, Month, Field, Product_Type, Price_of_Hydrocarbons_USD, Taxable_Production, .keep_all = TRUE)


# Now merge with merged_file to get the info on opening and closing of coal mine
df_opening_closing <- df_complete %>% 
  select(X,
         Year,
         Department,
         Municipality,
         Taxable_Production = Total_production_of_the_field_in_barrels_or_kilo_cubic_feet_by_municipality,
         Opening,
         Closing) 


variation_counts <- df_opening_closing %>%
  group_by(Opening, Closing) %>%
  summarise(municipalities = n_distinct(Municipalities))
print(variation_counts)

check_closing <- df_opening_closing %>% 
  filter(!is.na(Closing))
check_closing <- check_closing %>% 
  group_by(Department, Municipality) %>%
  mutate(Peak_Taxable_Production_barrels = max(Taxable_Production, na.rm = TRUE)) %>%
  mutate(Peak_Production_Year = Year[which.max(Taxable_Production)]) %>%
  ungroup()

# Excel without field name!
library(openxlsx)
wb <- createWorkbook()
#first sheet
addWorksheet(wb, "List_closed_without_names")
writeData(wb, sheet = "List_closed_without_names", x = "Description: list of oil and gas fields (without names) that closed down, input file for Brigitte's desk research	", startCol = 1, startRow = 1)
writeData(wb, sheet = "List_closed_without_names", x = check_closing, startCol = 1, startRow = 2)
saveWorkbook(wb, "List_closed_without_names.xlsx", overwrite = TRUE)



merged_df <- prod_df %>%
  left_join(df_opening_closing, by = c("Department", "Municipality", "Year", "Taxable_Production"))

## Create the two variables for info on peak production and respective year 
merged_df <- merged_df %>%
  group_by(Department, Municipality, Field, Product_Type) %>%
  mutate(Peak_Taxable_Production_barrels = max(Taxable_Production, na.rm = TRUE)) %>%
  mutate(Peak_Production_Year = Year[which.max(Taxable_Production)]) %>%
  ungroup()

## 
merged_df_notemp <- merged_df %>% 
distinct(Department, Municipality, Field, Product_Type, Peak_Taxable_Production_barrels, Peak_Production_Year, Opening, Closing, .keep_all = T)# %>% 
  #select(-c(Year,Month, Price_of_Hydrocarbons_USD, Taxable_Production)) # Don't need these 
  
merged_df_closed <- merged_df_notemp %>% 
  filter(!is.na(Closing))
  
# Excel with two sheets. One with temporal observations and one just with the 
library(openxlsx)
wb <- createWorkbook()
#first sheet
addWorksheet(wb, "List_closed_fields")
writeData(wb, sheet = "List_closed_fields", x = "Description: list of oil and gas fields that closed down, input file for Brigitte's desk research	", startCol = 1, startRow = 1)
writeData(wb, sheet = "List_closed_fields", x = merged_df_closed, startCol = 1, startRow = 2)

# second sheet
addWorksheet(wb, "List_all_fields_notime")
writeData(wb, sheet = "List_all_fields_notime", x = "Description: all oil and gas fields without time dimension", startCol = 1, startRow = 1)
writeData(wb, sheet = "List_all_fields_notime", x = merged_df_notemp, startCol = 1, startRow = 2)

addWorksheet(wb, "List_all_fields_allyears")
writeData(wb, sheet = "List_all_fields_allyears", x = "Description: all oil and gas fields with time dimension", startCol = 1, startRow = 1)
writeData(wb, sheet = "List_all_fields_allyears", x = merged_df, startCol = 1, startRow = 2)
saveWorkbook(wb, "List_desk_research_2.xlsx", overwrite = TRUE)