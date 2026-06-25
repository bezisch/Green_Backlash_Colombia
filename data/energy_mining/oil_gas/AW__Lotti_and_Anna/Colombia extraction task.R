# COLOMBIA EXTRACTIONIST TASK

rm(list = ls())

setwd("C:/Users/charlott/Dropbox (Personal)/MA Masterarbeit/H Oil and Gas Fields")
#setwd("C:/Users/Anna/Desktop/MCC/General work folder/Work for Charlotte/Colombia Extractivism Task/script")

library(haven)
library(tidyverse)

df <- read.csv("C:/Users/charlott/Dropbox (Personal)/MA Masterarbeit/H Oil and Gas Fields/datos_completos_prod_regalias_2010_2021.csv") 
#df <- read.csv("C:/Users/Anna/Desktop/MCC/General work folder/Work for Charlotte/Colombia Extractivism Task/script/datos_completos_prod_regalias_2010_2021.csv") 

View(df)
#Looking at data frame

View(df)
unique(df$Anio)
unique(df$Municipio)

# Extracting the necessary variables and renaming

prod_df <- df %>% 
  dplyr::select(ITEM = ITEM,
         Department = Departamento,
         Municipality = Municipio,
         Year = Anio,
         Month = Mes,
         Field = Campo,
         Price_of_Hydrocarbons_USD = PrecioHidrocarburoUSD,
         Production = ProdGravableBlsKpc,
         Volume_of_Royalties = VolumenRegaliaBlsKpc,
         Royalty_COP = RegaliasCOP) %>% 
  rename(Taxable_Production = Production)

names(prod_df)

View(prod_df)

### A. Average field production and which fields produce more than average


average_production_by_field <- prod_df %>% 
  dplyr::select(Year, Municipality, Taxable_Production, Field) %>% 
  group_by(Municipality, Field) %>%
  summarise(mean_production = mean(Taxable_Production, na.rm = TRUE))

above_average_production <- average_production_by_field %>%
  filter(mean_production > mean(mean_production, na.rm = TRUE)) %>%
  arrange(desc(mean_production))

print(above_average_production)

View(above_average_production)



### 1. PLOTTING MEAN PRICE, PRODUCTION, ROYALTIES VOLUME, AND ROYALTIES AMOUNT

# 1.1. Mean Price by Year

# A.) Calculation

mean_price_by_year <- prod_df %>%
  group_by(Year) %>%
  summarize(mean_price_hydrocarbons = mean(Price_of_Hydrocarbons_USD, na.rm = TRUE)) 

df_main <- data.frame(
  Year = c(2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018, 2019),
  Mean_Price = c(51.80668, 68.28489, 70.74825, 65.01000, 52.24406, 22.64876, 18.67192, 23.46762, 34.37029, 33.38670),
  Total_Production = c(679261358, 758907467, 786672230, 839173156, 839856841, 826895582, 761563641, 747341948, 783353016, 615571720),
  Total_Volume_Royalties = c(114407034, 123104916, 126081430, 129706244, 126690500, 122731659, 105555484, 95661544, 96082295, 74801617),
  Total_Amount_Royalties = c(5.41e12, 8.15e12, 8.55e12, 8.10e12, 7.43e12, 4.71e12, 3.93e12, 4.97e12, 6.52e12, 3.54e12))


# B.) Plotting Mean Price

df_main$Year <- factor(df_main$Year)

plot_mean_price <-  
    ggplot(data = df_main,aes(x = Year, y = Mean_Price, group = 1)) + 
    geom_point() + 
    geom_line() +
    theme_bw() +
    labs(x = "Year", 
         y = "Average Price of Hydrocarbons (USD)",
         title = "Average Price of Hydrocarbons Over Time (2010-2019)")

plot_mean_price


ggsave(filename = "Average_price_of_hydrocarbons_plot.png", plot = plot_mean_price, width = 8, height = 6, units = "in", dpi = 300) # save dens. plot

# C.) Density plot for the price of hydrocarbons by year

density_plot_price <- prod_df %>%
  group_by(Year) %>% 
  ggplot(aes(x = Price_of_Hydrocarbons_USD, color = factor(Year))) +
  geom_density(alpha = 0.5) +
  theme_bw() +
  labs(x = "Price of Hydrocarbons (USD)", 
       y = "Density",
       title = "Density Plot of Price of Hydrocarbons by Year")

density_plot_price

ggsave(filename = "Density_plot_price.png", plot = density_plot_price, width = 8, height = 6, units = "in", dpi = 300) #save dens. plot



# 1.2. Total Production by Year

# A.) Calculation

total_production_year <- prod_df %>%
  group_by(Year) %>%
  summarize(total_taxable_production = sum(Taxable_Production, na.rm = TRUE)) 

# B.) Plot Production by Year

df_main$Year <- factor(df_main$Year)

plot_total_production <-  
  ggplot(data = df_main,aes(x = Year, y = Total_Production, group = 1)) + 
  geom_point() + 
  geom_line() +
  theme_bw() +
  labs(x = "Year", 
       y = "Total Taxable Production (USD)",
       title = "Total Taxable Production Over Time (2010-2019)")
plot_total_production

ggsave(filename = "Total_taxable_production_plot.png", plot = plot_total_production, width = 8, height = 6, units = "in", dpi = 300) # save the plot


# C.) Density plot of Production

density_plot_production <- prod_df %>%
  group_by(Year) %>% 
  ggplot(aes(x = Taxable_Production, color = factor(Year))) +
  geom_density() +
  theme_bw() +
  scale_x_log10() +
  labs(x = "Taxable Production", 
       y = "Density",
       title = "Density Plot of Taxable Production")

density_plot_production

ggsave(filename = "Density_plot_production.png", plot = density_plot_production, width = 8, height = 6, units = "in", dpi = 300) #save dens. plot

unique(prod_df$Taxable_Production)



# 1.3.) Total Volume of Royalties 

# A.) Calculation
total_volume_year <- prod_df %>%
  group_by(Year) %>%
  summarize(total_volume_of_royalties = sum(Volume_of_Royalties, na.rm = TRUE)) 

total_volume_year

# B.) Plot Total Volume of Royalties Over Time

df_main$Year <- factor(df_main$Year)

plot_total_volume_royalties <-  
  ggplot(data = df_main,aes(x = Year, y = Total_Volume_Royalties, group = 1)) + 
  geom_point() + 
  geom_line() +
  theme_bw() +
  labs(x = "Year", 
       y = "Total Volume of Royalties",
       title = "Total Volume of Royalties Over Time (2010-2019)")
plot_total_volume_royalties

ggsave(filename = "Total_volume_royalties_plot.png", plot = plot_total_volume_royalties
, width = 8, height = 6, units = "in", dpi = 300) # save plot


# C.) Density plot volume of royalties

df_main$Year <- factor(df_main$Year)

density_plot_volume_royalties <- prod_df %>%
  group_by(Year) %>% 
  ggplot(aes(x = Volume_of_Royalties, color = factor(Year))) +
  geom_density() +
  theme_bw() +
  scale_x_log10() + 
  labs(x = "Volume of Royalties", 
       y = "Density",
       title = "Density Plot of Volume of Royalties")
density_plot_volume_royalties

ggsave(filename = "Total_volume_royalties__density_plot.png", plot = density_plot_volume_royalties
       , width = 8, height = 6, units = "in", dpi = 300)



# 1.4.) Amount of Royalties by Year

# A.) Calculation

total_amount_royalties <- prod_df %>%
  group_by(Year) %>%
  summarize(total_amount_royalties = sum(Royalty_COP, na.rm = TRUE)) 

total_amount_royalties

# B) Plot Total Amount of Royalties by Year

df_main$Year <- factor(df_main$Year)

plot_amount_royalties <-  
  ggplot(data = df_main,aes(x = Year, y = Total_Amount_Royalties, group = 1)) + 
  geom_point() + 
  geom_line() +
  theme_bw() +
  labs(x = "Year", 
       y = "Total Amount Royalties (COP)",
       title = "Total Amount Royalties Over Time (2010-2019)")
plot_amount_royalties

ggsave(filename = "Total_amount_royalties_plot.png", plot = plot_amount_royalties
       , width = 8, height = 6, units = "in", dpi = 300) #save plot

# C) Density plot for amount of royalties

df_main$Year <- factor(df_main$Year)

density_plot_amount_royalties <- prod_df %>%
  filter(!is.na(Royalty_COP)) %>%
  group_by(Year) %>% 
  ggplot(aes(x = Royalty_COP, color = factor(Year))) +
  geom_density() +
  theme_bw() +
  scale_x_log10() +
  labs(x = "Amount of Royalties", 
       y = "Density",
       title = "Density Plot of Amount of Royalties")

density_plot_amount_royalties

ggsave(filename = "Total_amount_royalties_density_plot.png", plot = density_plot_amount_royalties
       , width = 8, height = 6, units = "in", dpi = 300) #save dens. plot



# 2. HOW MANY MUNICIPALITIES ARE PRODUCING? 

names(prod_df)

num_municipalities <- prod_df %>% 
  filter(!is.na(Taxable_Production)) %>%
  dplyr::select(Municipality) %>%
  n_distinct()

print(num_municipalities)


#3. FIELD BY MUNICIPALITY

unique_fields_by_municipality <- prod_df %>%
  filter(!is.na(Field)) %>%  
  group_by(Municipality) %>%
  summarize(unique_fields = n_distinct(Field))

print(unique_fields_by_municipality)

View(unique_fields_by_municipality)

library(foreign)

write.csv(unique_fields_by_municipality, "Unique_Fields_by_Municipality.csv", row.names = FALSE) # Save csv



### 4. TOP MUNICIPALITIES 

top_municipalities <- prod_df %>%
  group_by(Municipality) %>%
  summarize(total_production = sum(Taxable_Production, na.rm = TRUE)) %>%
  arrange(desc(total_production)) %>%  # Arr. descending order of production
  top_n(10)

print(top_municipalities)

write.csv(top_municipalities, "Top_municipalities_by_production.csv", row.names = FALSE) #save table



# 5. PLOT PRODUCTION BY TOP MUNICIPALITIES OVER YEARSPlot production of municipalites over the years

selected_municipalities <- c("PUERTO GAITAN", "MANAURE", "AGUAZUL", "YOPAL", "TAURAMENA",
                             "URIBIA", "ACACIAS", "RIOHACHA", "CASTILLA NUEVA", "BARRANCABERMEJA")

filtered_df <- prod_df %>%
  filter(Municipality %in% selected_municipalities)

plot_production_top_municipalites <- ggplot(filtered_df, aes(x = Year, y = Taxable_Production, color = Municipality)) +
  geom_point() +
  geom_line() +
  theme_bw() +
  labs(x = "Year", y = "Taxable Production", title = "Production of Top Municipalities Over the Years")

print(plot_production_top_municipalites) # not good plot, not useful for us, do not use


# A.) Calculate and separate total production by year and municipality

total_production <- prod_df %>%
  group_by(Year, Municipality) %>%
  summarize(total_production = sum(Taxable_Production, na.rm = TRUE))

View(total_production)

unique(top_municipalities$Municipality)


# B.) PLOT FOR TOP TEN MUNICIPALITIES

#1 PLOT FOR Acacias MUNICIPALITY

total_production$Year <- factor(total_production$Year)

plot_Acacias <-  total_production %>% 
  filter(Municipality == "ACACIAS") %>% 
  ggplot(aes(x = Year, y = total_production, group = 1)) + 
  geom_point() + 
  geom_line() +
  theme_bw() +
  labs(x = "Year", 
       y = "Total Production in Acacias (USD)",
       title = "Total Production in Acacias Over Time (2010-2019)")
  
plot_Acacias

ggsave(filename = "Total_production_Acacias.png", plot = plot_Acacias
       , width = 8, height = 6, units = "in", dpi = 300) #SAVE


#2. PLOT FOR PUERTO GAITAN MUNICIPALITY


total_production$Year <- factor(total_production$Year)

plot_PUERTO_GAITAN <-  total_production %>% 
  filter(Municipality == "PUERTO GAITAN") %>% 
  ggplot(aes(x = Year, y = total_production, group = 1)) + 
  geom_point() + 
  geom_line() +
  theme_bw() +
  labs(x = "Year", 
       y = "Total Production in PUERTO GAITAN (USD)",
       title = "Total Production in PUERTO GAITAN Over Time (2010-2019)")

plot_PUERTO_GAITAN

ggsave(filename = "Total_production_PUERTO GAITAN.png", plot = plot_PUERTO_GAITAN
       , width = 8, height = 6, units = "in", dpi = 300) #SAVE


# 3. PLOT FOR MANAURE MUNICIPALITY

total_production$Year <- factor(total_production$Year)

plot_MANAURE <-  total_production %>% 
  filter(Municipality == "MANAURE") %>% 
  ggplot(aes(x = Year, y = total_production, group = 1)) + 
  geom_point() + 
  geom_line() +
  theme_bw() +
  labs(x = "Year", 
       y = "Total Production in MANAURE (USD)",
       title = "Total Production in MANAURE Over Time (2010-2019)")

plot_MANAURE

ggsave(filename = "Total_production_MANAURE.png", plot = plot_MANAURE
       , width = 8, height = 6, units = "in", dpi = 300) #save

# 4. PLOT FOR AGUAZUL MUNICIPALITY
total_production$Year <- factor(total_production$Year)

plot_AGUAZUL <-  total_production %>% 
  filter(Municipality == "AGUAZUL") %>% 
  ggplot(aes(x = Year, y = total_production, group = 1)) + 
  geom_point() + 
  geom_line() +
  theme_bw() +
  labs(x = "Year", 
       y = "Total Production in AGUAZUL (USD)",
       title = "Total Production in AGUAZUL Over Time (2010-2019)")

plot_AGUAZUL

ggsave(filename = "Total_production_AGUAZUL.png", plot = plot_AGUAZUL
       , width = 8, height = 6, units = "in", dpi = 300) #save

# 5. PLOT FOR YOPAL MUNICIPALITY

total_production$Year <- factor(total_production$Year)

plot_YOPAL <-  total_production %>% 
  filter(Municipality == "YOPAL") %>% 
  ggplot(aes(x = Year, y = total_production, group = 1)) + 
  geom_point() + 
  geom_line() +
  theme_bw() +
  labs(x = "Year", 
       y = "Total Production in YOPAL (USD)",
       title = "Total Production in YOPAL Over Time (2010-2019)")

plot_YOPAL

ggsave(filename = "Total_production_YOPAL.png", plot = plot_YOPAL
       , width = 8, height = 6, units = "in", dpi = 300) #save

# 6. PLOT FOR TAURAMENA MUNICIPALITY

total_production$Year <- factor(total_production$Year)

plot_TAURAMENA <-  total_production %>% 
  filter(Municipality == "TAURAMENA") %>% 
  ggplot(aes(x = Year, y = total_production, group = 1)) + 
  geom_point() + 
  geom_line() +
  theme_bw() +
  labs(x = "Year", 
       y = "Total Production in TAURAMENA (USD)",
       title = "Total Production in TAURAMENA Over Time (2010-2019)")

plot_TAURAMENA

ggsave(filename = "Total_production_TAURAMENA.png", plot = plot_TAURAMENA
       , width = 8, height = 6, units = "in", dpi = 300) #save

# 7. PLOT FOR URIBIA MUNICIPALITY

total_production$Year <- factor(total_production$Year)

plot_URIBIA <-  total_production %>% 
  filter(Municipality == "URIBIA") %>% 
  ggplot(aes(x = Year, y = total_production, group = 1)) + 
  geom_point() + 
  geom_line() +
  theme_bw() +
  labs(x = "Year", 
       y = "Total Production in URIBIA (USD)",
       title = "Total Production in URIBIA Over Time (2010-2019)")

plot_URIBIA

ggsave(filename = "Total_production_URIBIA.png", plot = plot_URIBIA
       , width = 8, height = 6, units = "in", dpi = 300) #save

# 8. PLOT FOR RIOHACHA MUNICIPALITY
total_production$Year <- factor(total_production$Year)

plot_RIOHACHA <-  total_production %>% 
  filter(Municipality == "RIOHACHA") %>% 
  ggplot(aes(x = Year, y = total_production, group = 1)) + 
  geom_point() + 
  geom_line() +
  theme_bw() +
  labs(x = "Year", 
       y = "Total Production in RIOHACHA (USD)",
       title = "Total Production in RIOHACHA Over Time (2010-2019)")

plot_RIOHACHA

ggsave(filename = "Total_production_RIOHACHA.png", plot = plot_RIOHACHA
       , width = 8, height = 6, units = "in", dpi = 300) #save

# 9. PLOT FOR CASTILLA NUEVA MUNICIPALITY

total_production$Year <- factor(total_production$Year)

plot_CASTILLA_NUEVA <-  total_production %>% 
  filter(Municipality == "CASTILLA NUEVA") %>% 
  ggplot(aes(x = Year, y = total_production, group = 1)) + 
  geom_point() + 
  geom_line() +
  theme_bw() +
  labs(x = "Year", 
       y = "Total Production in CASTILLA NUEVA (USD)",
       title = "Total Production in CASTILLA NUEVA Over Time (2010-2019)")

plot_CASTILLA_NUEVA

ggsave(filename = "Total_production_CASTILLA_NUEVA.png", plot = plot_CASTILLA_NUEVA
       , width = 8, height = 6, units = "in", dpi = 300) #save

# 10. PLOT FOR BARRANCABERMEJA MINICIPALITY

total_production$Year <- factor(total_production$Year)

plot_BARRANCABERMEJA <-  total_production %>% 
  filter(Municipality == "BARRANCABERMEJA") %>% 
  ggplot(aes(x = Year, y = total_production, group = 1)) + 
  geom_point() + 
  geom_line() +
  theme_bw() +
  labs(x = "Year", 
       y = "Total Production in BARRANCABERMEJA (USD)",
       title = "Total Production in BARRANCABERMEJA Over Time (2010-2019)")

plot_BARRANCABERMEJA

ggsave(filename = "Total_production_BARRANCABERMEJA.png", plot = plot_BARRANCABERMEJA
       , width = 8, height = 6, units = "in", dpi = 300) #save


str(prod_df)

# 7. IDENTIFY WHERE PRODUCTION STOPPED 

# production has been down/stopped in 2 and more consequitive years

unique(prod_df$Municipality)

plot_total_production_all_municipalities <- prod_df %>%
  group_by(Year, Municipality) %>%
  summarize(total_production_munic = sum(Taxable_Production, na.rm = TRUE)) %>% 
  ggplot(aes(x = Year,
             y = total_production_munic)) + 
  geom_line(stat = "identity") + 
  facet_wrap(~Municipality)

plot_total_production_all_municipalities


#NEED to check for Various municipalities directly to figure out precisely

unique(prod_df$Municipality)

total_production$Year <- factor(total_production$Year)

total_production %>% 
  filter(Municipality == "MUNICIPIO NN PUTUMAYO ")%>% 
  ggplot(aes(x = Year, y = total_production, group = 1)) + 
  geom_point() + 
  geom_line() +
  theme_bw() 




# Create a total_df_original

#Group by year and municipality (Mean Price, Production, Total Volume of Royalties, Royalty_COP )

df_mean_by_year_municipality <- prod_df %>%
  group_by(Year, Municipality) %>%
  summarize(mean_price_hydrocarbons = mean(Price_of_Hydrocarbons_USD, na.rm = TRUE))

df_mean_by_year_municipality

df_prod_sum_by_year_municipality <- prod_df %>%
  group_by(Year, Municipality) %>%
  summarize(total_production_by_municipality = sum(Taxable_Production, na.rm = TRUE))

df_royalties_vol_sum_by_year_municipality <- prod_df %>%
  group_by(Year, Municipality) %>%
  summarize(total_of_royalties_by_municipality = sum(Volume_of_Royalties, na.rm = TRUE))  

df_royalty_COP_sum_by_year_municipality <- prod_df %>%
  group_by(Year, Municipality) %>%
  summarize(total_royalty_COP_by_municipality = sum(Royalty_COP, na.rm = TRUE))

#Join into one dataframe

df_mean_by_year_municipality <- df_mean_by_year_municipality %>%
  left_join(
    df_prod_sum_by_year_municipality,
    by = c("Municipality", "Year")
  )

df_mean_by_year_municipality <- df_mean_by_year_municipality %>%
  left_join(
    df_royalties_vol_sum_by_year_municipality,
    by = c("Municipality", "Year")
  )

df_mean_by_year_municipality <- df_mean_by_year_municipality %>%
  left_join(
    df_royalty_COP_sum_by_year_municipality,
    by = c("Municipality", "Year")
  )

total_df_original <- df_mean_by_year_municipality

df_2010_2019 <- total_df_original %>%
  group_by(Municipality) %>%
  mutate(Production_Years = n_distinct(Year[!is.na(total_production_by_municipality) & Year >= 2010 & Year <= 2019]))

df_2010_2019$Production_2010_2019 <- ifelse(df_2010_2019$Production_Years == 10, 1, 0)


# Years opening other than 2010
first_years <- df_2010_2019 %>%
  group_by(Municipality) %>%
  summarise(First_Year = min(Year))

df_2010_2019 <- left_join(df_2010_2019, first_years, by = "Municipality")
df_2010_2019 <- df_2010_2019 %>% 
  rename(Opening = First_Year)


# Years closing other than 2019

closing_years <- df_2010_2019 %>%
  group_by(Municipality) %>%
  summarise(closing_Year = max(Year))

df_2010_2019 <- left_join(df_2010_2019, closing_years, by = "Municipality")

df_2010_2019 <- df_2010_2019 %>% 
  rename(Closing = closing_Year)


### c. Find out which rows have one observation and get rid of that observatio

df_filtered <- df_2010_2019 %>%
  filter(Production_Years == 1)

df_filtered

# MUNICIPIO NN PUTUMAYO, SAN JOSE DE FRAGUA, RIO NEGRO, HATO COROZAL, FUENTE de ORO

df_2010_2019 <- df_2010_2019 %>%
  filter(Municipality != "FUENTE DE ORO") %>% 
  filter(Municipality != "HATO COROZAL")

production_summary <- df_2010_2019 %>%
  summarise(mean_production = mean(total_production_by_municipality, na.rm = TRUE),
            median_production = median(total_production_by_municipality, na.rm = TRUE))



### Include other variables

unique(total_df_original)
names(total_df_original)
total_df_original <- total_df_original %>% 
  dplyr:: mutate(Production = case_match(Municipality,
                                       'PUERTO NARE' ~ '1',
                                       'YONDO'~ '1',
                                       'PUERTO TRIUNFO' ~ '1',
                                       'ARAUCA' ~ '1',
                                       'ARAUQUITA' ~ '1',
                                       'SARAVENA' ~ '1',
                                       'MOMPOS' ~ '1',
                                       'TAME' ~ '1',
                                       'CANTAGALLO' ~ '1',
                                       'TALAIGUA NUEVO' ~ '1',
                                       'CICUCO' ~ '1',
                                       'CORRALES' ~ '1',
                                       'PUERTO BOYACA' ~ '1',
                                       'PIAMONTE' ~ '1',
                                       'SAN LUIS DE GACENO' ~ '1',
                                       'TOPAGA' ~ '1',
                                       'AGUAZUL' ~ '1',
                                       'YAGUARA' ~ '1',
                                       'MANI' ~ '1',
                                       'TAURAMENA' ~ '1',
                                       'MONTERREY' ~ '1',                  
                                       'NUNCHIA' ~ '1',
                                       'OROCUE' ~ '1',
                                       'PAZ DE ARIPORO' ~ '1',
                                       'PORE' ~ '1',
                                       'SAN LUIS DE PALENQUE' ~ '1',
                                       'YOPAL' ~ '1',
                                       'TRINIDAD' ~ '1',
                                       'VILLA NUEVA' ~ '1',                
                                       'PULI' ~ '1',
                                       'AGUACHICA' ~ '1',
                                       'CHIRIGUANA' ~ '1', 
                                       'LA JAGUA IBIRICO' ~ '1',
                                       'RIO DE ORO' ~ '1',
                                       'SAN ALBERTO' ~ '1',
                                       'SAN MART�\u008dN' ~ '1',       
                                       'SAHAGUN' ~ '1',                    
                                       'GUADUAS' ~ '1',
                                       'PUERTO SALGAR' ~ '0',              
                                       'MUNICIPIO NN' ~ '1',
                                       'DIBULLA' ~ '1',                    
                                       'MANAURE' ~ '1',
                                       'RIOHACHA'~ '1',
                                       'URIBIA' ~ '1',
                                       'AIPE' ~ '1',                       
                                       'ACACIAS' ~ '1',
                                       'VILLAVICENCIO' ~ '1',              
                                       'BARAYA' ~ '1',
                                       'GARZON' ~ '1',                     
                                       'GIGANTE' ~ '1',
                                       'NEIVA' ~ '1',
                                       'PAICOL' ~ '1',
                                       'PALERMO' ~ '1',
                                       'TESALIA' ~ '1',
                                       'VILLAVIEJA' ~ '1',
                                       'BARRANCA DE UPIA' ~ '1',
                                       'CABUYARO' ~ '1',
                                       'CASTILLA NUEVA' ~ '1',
                                       'ORITO' ~ '1',
                                       'GUAMAL' ~ '1',
                                       'PUERTO GAITAN' ~ '1',              
                                       'PUERTO LOPEZ' ~ '1',
                                       'VISTA HERMOSA' ~ '0',              
                                       'IPIALES' ~ '1',
                                       'CUCUTA' ~ '1',                     
                                       'LA ESPERANZA' ~ '1',
                                       'CIMITARRA' ~ '1',
                                       'SARDINATA' ~ '1',
                                       'TIBU' ~ '1',
                                       'MOCOA' ~ '1',
                                       'PUERTO ASIS' ~ '1',
                                       'PUERTO CAICEDO' ~ '1',
                                       'PUERTO GUZMÁN' ~ '0',
                                       'SAN MIGUEL' ~ '1',
                                       'VALLE DEL GUAMUEZ' ~ '1',
                                       'VILLAGARZON' ~ '1',
                                       'BARRANCABERMEJA' ~ '1',
                                       'BOLIVAR' ~ '1',
                                       'EL CARMEN DE CHUCURI' ~ '1',
                                       'PUERTO WILCHES' ~ '1',
                                       'RIONEGRO' ~ '1',
                                       'ORTEGA' ~ '1',
                                       'SABANA DE TORRES' ~ '1',
                                       'SAN VICENTE DE CHUCURI' ~ '1',
                                       'CHAPARRAL' ~ '1',
                                       'SIMACOTA' ~ '1',
                                       'LOS PALMITOS' ~ '1',
                                       'SAN PEDRO' ~ '1',
                                       'ALVARADO' ~ '1',
                                       'COELLO' ~ '0',
                                       'ESPINAL' ~ '1',
                                       'FLANDES' ~ '1',
                                       'ICONONZO' ~ '1',
                                       'MELGAR' ~ '1',
                                       'PIEDRAS' ~ '1',
                                       'PRADO' ~ '1',
                                       'PURIFICACIÓN' ~ '1',
                                       'SAN LUIS' ~ '1',
                                       'SANTA ROSALIA' ~ '0',
                                       'SAN VICENTE DEL CAGUAN' ~ '1',
                                       'MUNICIPIO NN CASANARE' ~ '1',
                                       'BECERRIL' ~ '0',
                                       'EL PASO' ~ '1',
                                       'PUEBLO NUEVO' ~ '1',
                                       'YACOPI' ~ '0',
                                       'ARIGUANI' ~ '1',
                                       'PIJINO DEL CARMEN' ~ '0',
                                       'SANTA ANA' ~ '1',
                                       'MUNICIPIO NN PUTUMAYO' ~ '0',
                                       'MUNICIPIO NN SANTANDER' ~ '1',
                                       'GUAMO' ~ '1',
                                       'SAN JOSE DE FRAGUA' ~ '0',
                                       'TELLO' ~ '0',
                                       'MUNICIPIO NN META' ~ '1',
                                       'PUERTO LLERAS' ~ '0',
                                       'OVEJAS' ~ '1',
                                       'HATO COROZAL' ~ '0',
                                       'SAN CAARLOS GUAROA' ~ '1',
                                       'FONSECA' ~ '0',
                                       'FUENTE DE ORO' ~ '0',
                                       'SABANALARGA' ~ '1',
                                       'PENDIENTE CERTIFICADO IGAC' ~ '1',
                                       'GAMARRA' ~ '1',
                                       'LA UNION' ~ '1',
                                       'SAN MARCOS' ~ '1',
                                       'ASTREA' ~ '1',
                                       'VILLANUEVA' ~ '1',
                                       'SINCE' ~ '1',
                                       'RIO NEGRO' ~ '0')) %>% 
  dplyr:: mutate(Continuous_Production = case_match(Municipality,
                                         'PUERTO NARE' ~ '1',
                                         'YONDO'~ '1',
                                         'PUERTO TRIUNFO' ~ '1',
                                         'ARAUCA' ~ '1',
                                         'ARAUQUITA' ~ '1',
                                         'SARAVENA' ~ '0',
                                         'MOMPOS' ~ '1',
                                         'TAME' ~ '0',
                                         'CANTAGALLO' ~ '1',
                                         'TALAIGUA NUEVO' ~ '1',
                                         'CICUCO' ~ '1',
                                         'CORRALES' ~ '1',
                                         'PUERTO BOYACA' ~ '1',
                                         'PIAMONTE' ~ '1',
                                         'SAN LUIS DE GACENO' ~ '0',
                                         'TOPAGA' ~ '1',
                                         'AGUAZUL' ~ '1',
                                         'YAGUARA' ~ '1',
                                         'MANI' ~ '1',
                                         'TAURAMENA' ~ '1',
                                         'MONTERREY' ~ '1',                  
                                         'NUNCHIA' ~ '1',
                                         'OROCUE' ~ '1',
                                         'PAZ DE ARIPORO' ~ '1',
                                         'PORE' ~ '1',
                                         'SAN LUIS DE PALENQUE' ~ '1',
                                         'YOPAL' ~ '1',
                                         'TRINIDAD' ~ '1',
                                         'VILLA NUEVA' ~ '1',                
                                         'PULI' ~ '1',
                                         'AGUACHICA' ~ '1',
                                         'CHIRIGUANA' ~ '0', 
                                         'LA JAGUA IBIRICO' ~ '0',
                                         'RIO DE ORO' ~ '1',
                                         'SAN ALBERTO' ~ '1',
                                         'SAN MART�\u008dN' ~ '1',       
                                         'SAHAGUN' ~ '1',                    
                                         'GUADUAS' ~ '1',
                                         'PUERTO SALGAR' ~ '0',              
                                         'MUNICIPIO NN' ~ '1',
                                         'DIBULLA' ~ '1',                    
                                         'MANAURE' ~ '1',
                                         'RIOHACHA'~ '1',
                                         'URIBIA' ~ '1',
                                         'AIPE' ~ '1',                       
                                         'ACACIAS' ~ '1',
                                         'VILLAVICENCIO' ~ '1',              
                                         'BARAYA' ~ '1',
                                         'GARZON' ~ '1',                     
                                         'GIGANTE' ~ '1',
                                         'NEIVA' ~ '1',
                                         'PAICOL' ~ '1',
                                         'PALERMO' ~ '1',
                                         'TESALIA' ~ '1',
                                         'VILLAVIEJA' ~ '1',
                                         'BARRANCA DE UPIA' ~ '1',
                                         'CABUYARO' ~ '1',
                                         'CASTILLA NUEVA' ~ '1',
                                         'ORITO' ~ '1',
                                         'GUAMAL' ~ '1',
                                         'PUERTO GAITAN' ~ '1',              
                                         'PUERTO LOPEZ' ~ '1',
                                         'VISTA HERMOSA' ~ '0',              
                                         'IPIALES' ~ '1',
                                         'CUCUTA' ~ '1',                     
                                         'LA ESPERANZA' ~ '1',
                                         'CIMITARRA' ~ '1',
                                         'SARDINATA' ~ '1',
                                         'TIBU' ~ '1',
                                         'MOCOA' ~ '1',
                                         'PUERTO ASIS' ~ '1',
                                         'PUERTO CAICEDO' ~ '1',
                                         'PUERTO GUZMÁN' ~ '0',
                                         'SAN MIGUEL' ~ '1',
                                         'VALLE DEL GUAMUEZ' ~ '1',
                                         'VILLAGARZON' ~ '1',
                                         'BARRANCABERMEJA' ~ '1',
                                         'BOLIVAR' ~ '0',
                                         'EL CARMEN DE CHUCURI' ~ '1',
                                         'PUERTO WILCHES' ~ '1',
                                         'RIONEGRO' ~ '1',
                                         'ORTEGA' ~ '0',
                                         'SABANA DE TORRES' ~ '1',
                                         'SAN VICENTE DE CHUCURI' ~ '1',
                                         'CHAPARRAL' ~ '1',
                                         'SIMACOTA' ~ '1',
                                         'LOS PALMITOS' ~ '1',
                                         'SAN PEDRO' ~ '1',
                                         'ALVARADO' ~ '1',
                                         'COELLO' ~ '1',
                                         'ESPINAL' ~ '1',
                                         'FLANDES' ~ '1',
                                         'ICONONZO' ~ '1',
                                         'MELGAR' ~ '1',
                                         'PIEDRAS' ~ '1',
                                         'PRADO' ~ '1',
                                         'PURIFICACIÓN' ~ '1',
                                         'SAN LUIS' ~ '0',
                                         'SANTA ROSALIA' ~ '0',
                                         'SAN VICENTE DEL CAGUAN' ~ '0',
                                         'MUNICIPIO NN CASANARE' ~ '1',
                                         'BECERRIL' ~ '0',
                                         'EL PASO' ~ '1',
                                         'PUEBLO NUEVO' ~ '1',
                                         'YACOPI' ~ '0',
                                         'ARIGUANI' ~ '1',
                                         'PIJINO DEL CARMEN' ~ '1',
                                         'SANTA ANA' ~ '0',
                                         'MUNICIPIO NN PUTUMAYO' ~ '0',
                                         'MUNICIPIO NN SANTANDER' ~ '1',
                                         'GUAMO' ~ '1',
                                         'SAN JOSE DE FRAGUA' ~ '0',
                                         'TELLO' ~ '0',
                                         'MUNICIPIO NN META' ~ '0',
                                         'PUERTO LLERAS' ~ '0',
                                         'OVEJAS' ~ '0',
                                         'HATO COROZAL' ~ '0',
                                         'SAN CAARLOS GUAROA' ~ '0',
                                         'FONSECA' ~ '0',
                                         'FUENTE DE ORO' ~ '0',
                                         'SABANALARGA' ~ '1',
                                         'PENDIENTE CERTIFICADO IGAC' ~ '1',
                                         'GAMARRA' ~ '1',
                                         'LA UNION' ~ '1',
                                         'SAN MARCOS' ~ '1',
                                         'ASTREA' ~ '1',
                                         'VILLANUEVA' ~ '1',
                                         'SINCE' ~ '1',
                                         'RIO NEGRO' ~ '0'))
                                       


# Need to drop


# d. Drop during crisis

df_grouped <- df_2010_2019 %>%
  group_by(Year)

  
df_2010_2019 <- df_2010_2019 %>% 
  dplyr:: mutate(drop_during_crisis = case_match(Municipality,
                                         'PUERTO NARE' ~ '1',
                                         'YONDO'~ '1',
                                         'PUERTO TRIUNFO' ~ '1',
                                         'ARAUCA' ~ '1',
                                         'ARAUQUITA' ~ '1',
                                         'SARAVENA' ~ '0',
                                         'MOMPOS' ~ '0',
                                         'TAME' ~ 'NA',
                                         'CANTAGALLO' ~ '0',
                                         'TALAIGUA NUEVO' ~ '0',
                                         'CICUCO' ~ '0',
                                         'CORRALES' ~ '1',
                                         'PUERTO BOYACA' ~ '0',
                                         'PIAMONTE' ~ '0',
                                         'SAN LUIS DE GACENO' ~ '0',
                                         'TOPAGA' ~ '1',
                                         'AGUAZUL' ~ '0',
                                         'YAGUARA' ~ '1',
                                         'MANI' ~ '1',
                                         'TAURAMENA' ~ '0',
                                         'MONTERREY' ~ '1',                  
                                         'NUNCHIA' ~ '1',
                                         'OROCUE' ~ '1',
                                         'PAZ DE ARIPORO' ~ '1',
                                         'PORE' ~ '1',
                                         'SAN LUIS DE PALENQUE' ~ '1',
                                         'YOPAL' ~ '0',
                                         'TRINIDAD' ~ '1',
                                         'VILLA NUEVA' ~ '0',                
                                         'PULI' ~ '0',
                                         'AGUACHICA' ~ '0',
                                         'CHIRIGUANA' ~ '0', 
                                         'LA JAGUA IBIRICO' ~ '1',
                                         'RIO DE ORO' ~ '1',
                                         'SAN ALBERTO' ~ '1',
                                         'SAN MART�\u008dN' ~ '0',       
                                         'SAHAGUN' ~ '1',                    
                                         'GUADUAS' ~ '1',
                                         'PUERTO SALGAR' ~ '1',              
                                         'MUNICIPIO NN' ~ '1',
                                         'DIBULLA' ~ '1',                    
                                         'MANAURE' ~ '1',
                                         'RIOHACHA'~ '1',
                                         'URIBIA' ~ '1',
                                         'AIPE' ~ '1',                       
                                         'ACACIAS' ~ '0',
                                         'VILLAVICENCIO' ~ '1',              
                                         'BARAYA' ~ '1',
                                         'GARZON' ~ '1',                     
                                         'GIGANTE' ~ '1',
                                         'NEIVA' ~ '1',
                                         'PAICOL' ~ '0',
                                         'PALERMO' ~ '1',
                                         'TESALIA' ~ '1',
                                         'VILLAVIEJA' ~ '1',
                                         'BARRANCA DE UPIA' ~ '1',
                                         'CABUYARO' ~ '1',
                                         'CASTILLA NUEVA' ~ '1',
                                         'ORITO' ~ '0',
                                         'GUAMAL' ~ '0',
                                         'PUERTO GAITAN' ~ '1',              
                                         'PUERTO LOPEZ' ~ '0',
                                         'VISTA HERMOSA' ~ '0',              
                                         'IPIALES' ~ '0',
                                         'CUCUTA' ~ '0',                     
                                         'LA ESPERANZA' ~ '1',
                                         'CIMITARRA' ~ '1',
                                         'SARDINATA' ~ '1',
                                         'TIBU' ~ '0',
                                         'MOCOA' ~ '0',
                                         'PUERTO ASIS' ~ '1',
                                         'PUERTO CAICEDO' ~ '1',
                                         'PUERTO GUZMÁN' ~ 'NA',
                                         'SAN MIGUEL' ~ '1',
                                         'VALLE DEL GUAMUEZ' ~ '0',
                                         'VILLAGARZON' ~ '1',
                                         'BARRANCABERMEJA' ~ '1',
                                         'BOLIVAR' ~ '1',
                                         'EL CARMEN DE CHUCURI' ~ '1',
                                         'PUERTO WILCHES' ~ '1',
                                         'RIONEGRO' ~ '1',
                                         'ORTEGA' ~ '1',
                                         'SABANA DE TORRES' ~ '1',
                                         'SAN VICENTE DE CHUCURI' ~ '1',
                                         'CHAPARRAL' ~ '1',
                                         'SIMACOTA' ~ '1',
                                         'LOS PALMITOS' ~ '1',
                                         'SAN PEDRO' ~ '1',
                                         'ALVARADO' ~ '0',
                                         'COELLO' ~ '1',
                                         'ESPINAL' ~ '1',
                                         'FLANDES' ~ '1',
                                         'ICONONZO' ~ '1',
                                         'MELGAR' ~ '1',
                                         'PIEDRAS' ~ '1',
                                         'PRADO' ~ '1',
                                         'PURIFICACIÓN' ~ '1',
                                         'SAN LUIS' ~ '1',
                                         'SANTA ROSALIA' ~ '1',
                                         'SAN VICENTE DEL CAGUAN' ~ 'NA',
                                         'MUNICIPIO NN CASANARE' ~ '1',
                                         'BECERRIL' ~ '1',
                                         'EL PASO' ~ '1',
                                         'PUEBLO NUEVO' ~ '0',
                                         'YACOPI' ~ '1',
                                         'ARIGUANI' ~ '0',
                                         'PIJINO DEL CARMEN' ~ 'NA',
                                         'SANTA ANA' ~ '0',
                                         'MUNICIPIO NN SANTANDER' ~ '1',
                                         'GUAMO' ~ '1',
                                         'TELLO' ~ 'NA',
                                         'MUNICIPIO NN META' ~ 'NA',
                                         'PUERTO LLERAS' ~ '1',
                                         'OVEJAS' ~ 'NA',
                                         'HATO COROZAL' ~ 'NA',
                                         'SAN CAARLOS GUAROA' ~ '1',
                                         'FONSECA' ~ '1',
                                         'FUENTE DE ORO' ~ 'NA',
                                         'SABANALARGA' ~ 'NA',
                                         'PENDIENTE CERTIFICADO IGAC' ~ 'NA',
                                         'GAMARRA' ~ 'NA',
                                         'LA UNION' ~ 'NA',
                                         'SAN MARCOS' ~ 'NA',
                                         'ASTREA' ~ 'NA',
                                         'VILLANUEVA' ~ 'NA',
                                         'SINCE' ~ 'NA'))

# 5. Redo everything above but intrapolated


# Include all years and NA for intrapolation


unique_municipalities <- unique(df_2010_2019$Municipality)

all_years <- seq(2010, 2019)
all_combinations <- expand.grid(Year = all_years, Municipality = unique_municipalities)

df_complete <- merge(all_combinations, df_2010_2019, by = c("Year", "Municipality"), all.x = TRUE)


# Intrapolated dataframe


interpolate_linear <- function(x) { 
  for (i in 2:(length(x) - 1)) { 
    if (is.na(x[i]) && !(is.na(x[i-1]) || is.na(x[i+1])) ) { x[i] <- mean(c(x[i-1], x[i+1]), na.rm = TRUE) } } 
  return(x) }

df_complete <- df_complete %>%
  group_by(Municipality) %>%
  mutate(total_production_by_municipality = interpolate_linear(total_production_by_municipality)) %>% 
  mutate(mean_price_hydrocarbons = interpolate_linear(mean_price_hydrocarbons)) %>% 
  mutate(total_of_royalties_by_municipality = interpolate_linear(total_of_royalties_by_municipality)) %>% 
  mutate(total_royalty_COP_by_municipality = interpolate_linear(total_royalty_COP_by_municipality)) %>% 
  mutate(Opening = interpolate_linear(Opening)) %>% 
  mutate(Closing = interpolate_linear(Closing))


# Include the variables

# a. Production year

df_complete$Municipality <- factor(df_complete$Municipality)

df_complete <- df_complete %>%
  group_by(Municipality) %>%
  mutate(Production_Years = n_distinct(Year[!is.na(total_production_by_municipality) & Year >= 2010 & Year <= 2019]))

df_complete$Production_2010_2019 <- ifelse(df_complete$Production_Years == 10, 1, 0)

# Make 2010 and 2019 blank in Opening and Closing variable

df_complete$Opening[df_complete$Opening == 2010] <- ""

df_complete$Closing[df_complete$Closing == 2019] <- ""

# MUNICIPIO NN PUTUMAYO, SAN JOSE DE FRAGUA, RIO NEGRO, HATO COROZAL (eliminated earlier), FUENTE de ORO (eliminated earlier)

df_complete <- df_complete %>%
  filter(Municipality != "MUNICIPIO NN PUTUMAYO") %>% 
  filter(Municipality != "SAN JOSE DE FRAGUA") %>% 
  filter(Municipality != "RIO NEGRO") 


# Variable df_during_crisis
df_complete <- df_complete %>% 
  dplyr:: mutate(Municipality = as.character(Municipality),
                 drop_during_crisis = case_match(Municipality,
                                                 'PUERTO NARE' ~ '1',
                                                 'YONDO'~ '1',
                                                 'PUERTO TRIUNFO' ~ '1',
                                                 'ARAUCA' ~ '1',
                                                 'ARAUQUITA' ~ '1',
                                                 'SARAVENA' ~ '0',
                                                 'MOMPOS' ~ '0',
                                                 'TAME' ~ 'NA',
                                                 'CANTAGALLO' ~ '0',
                                                 'TALAIGUA NUEVO' ~ '0',
                                                 'CICUCO' ~ '0',
                                                 'CORRALES' ~ '1',
                                                 'PUERTO BOYACA' ~ '0',
                                                 'PIAMONTE' ~ '0',
                                                 'SAN LUIS DE GACENO' ~ '0',
                                                 'TOPAGA' ~ '1',
                                                 'AGUAZUL' ~ '0',
                                                 'YAGUARA' ~ '1',
                                                 'MANI' ~ '1',
                                                 'TAURAMENA' ~ '0',
                                                 'MONTERREY' ~ '1',                  
                                                 'NUNCHIA' ~ '1',
                                                 'OROCUE' ~ '1',
                                                 'PAZ DE ARIPORO' ~ '1',
                                                 'PORE' ~ '1',
                                                 'SAN LUIS DE PALENQUE' ~ '1',
                                                 'YOPAL' ~ '0',
                                                 'TRINIDAD' ~ '1',
                                                 'VILLA NUEVA' ~ '0',                
                                                 'PULI' ~ '0',
                                                 'AGUACHICA' ~ '0',
                                                 'CHIRIGUANA' ~ '0', 
                                                 'LA JAGUA IBIRICO' ~ '1',
                                                 'RIO DE ORO' ~ '1',
                                                 'SAN ALBERTO' ~ '1',
                                                 'SAN MART�\u008dN' ~ '0',       
                                                 'SAHAGUN' ~ '1',                    
                                                 'GUADUAS' ~ '1',
                                                 'PUERTO SALGAR' ~ '1',              
                                                 'MUNICIPIO NN' ~ '1',
                                                 'DIBULLA' ~ '1',                    
                                                 'MANAURE' ~ '1',
                                                 'RIOHACHA'~ '1',
                                                 'URIBIA' ~ '1',
                                                 'AIPE' ~ '1',                 
                                                 'VILLAVICENCIO' ~ '1',              
                                                 'BARAYA' ~ '1',
                                                 'GARZON' ~ '1',                     
                                                 'GIGANTE' ~ '1',
                                                 'NEIVA' ~ '1',
                                                 'PAICOL' ~ '0',
                                                 'PALERMO' ~ '1',
                                                 'TESALIA' ~ '1',
                                                 'VILLAVIEJA' ~ '1',
                                                 'BARRANCA DE UPIA' ~ '1',
                                                 'CABUYARO' ~ '1',
                                                 'CASTILLA NUEVA' ~ '1',
                                                 'ORITO' ~ '0',
                                                 'GUAMAL' ~ '0',
                                                 'PUERTO GAITAN' ~ '1',              
                                                 'PUERTO LOPEZ' ~ '0',
                                                 'VISTA HERMOSA' ~ '0',              
                                                 'IPIALES' ~ '0',
                                                 'CUCUTA' ~ '0',                     
                                                 'LA ESPERANZA' ~ '1',
                                                 'CIMITARRA' ~ '1',
                                                 'SARDINATA' ~ '1',
                                                 'TIBU' ~ '0',
                                                 'MOCOA' ~ '0',
                                                 'PUERTO ASIS' ~ '1',
                                                 'PUERTO CAICEDO' ~ '1',
                                                 'PUERTO GUZMÁN' ~ 'NA',
                                                 'SAN MIGUEL' ~ '1',
                                                 'VALLE DEL GUAMUEZ' ~ '0',
                                                 'VILLAGARZON' ~ '1',
                                                 'BARRANCABERMEJA' ~ '1',
                                                 'BOLIVAR' ~ '1',
                                                 'EL CARMEN DE CHUCURI' ~ '1',
                                                 'PUERTO WILCHES' ~ '1',
                                                 'RIONEGRO' ~ '1',
                                                 'ORTEGA' ~ '1',
                                                 'SABANA DE TORRES' ~ '1',
                                                 'SAN VICENTE DE CHUCURI' ~ '1',
                                                 'CHAPARRAL' ~ '1',
                                                 'SIMACOTA' ~ '1',
                                                 'LOS PALMITOS' ~ '1',
                                                 'SAN PEDRO' ~ '1',
                                                 'ALVARADO' ~ '0',
                                                 'COELLO' ~ '1',
                                                 'ESPINAL' ~ '1',
                                                 'FLANDES' ~ '1',
                                                 'ICONONZO' ~ '1',
                                                 'MELGAR' ~ '1',
                                                 'PIEDRAS' ~ '1',
                                                 'PRADO' ~ '1',
                                                 'PURIFICACIÓN' ~ '1',
                                                 'SAN LUIS' ~ '1',
                                                 'SANTA ROSALIA' ~ '1',
                                                 'SAN VICENTE DEL CAGUAN' ~ 'NA',
                                                 'MUNICIPIO NN CASANARE' ~ '1',
                                                 'BECERRIL' ~ '1',
                                                 'EL PASO' ~ '1',
                                                 'PUEBLO NUEVO' ~ '0',
                                                 'YACOPI' ~ '1',
                                                 'ARIGUANI' ~ '0',
                                                 'PIJINO DEL CARMEN' ~ 'NA',
                                                 'SANTA ANA' ~ '0',
                                                 'MUNICIPIO NN SANTANDER' ~ '1',
                                                 'GUAMO' ~ '1',
                                                 'TELLO' ~ 'NA',
                                                 'MUNICIPIO NN META' ~ 'NA',
                                                 'PUERTO LLERAS' ~ '1',
                                                 'OVEJAS' ~ 'NA',
                                                 'HATO COROZAL' ~ 'NA',
                                                 'SAN CAARLOS GUAROA' ~ '1',
                                                 'FONSECA' ~ '1',
                                                 'FUENTE DE ORO' ~ 'NA',
                                                 'SABANALARGA' ~ 'NA',
                                                 'PENDIENTE CERTIFICADO IGAC' ~ 'NA',
                                                 'GAMARRA' ~ 'NA',
                                                 'LA UNION' ~ 'NA',
                                                 'SAN MARCOS' ~ 'NA',
                                                 'ASTREA' ~ 'NA',
                                                 'VILLANUEVA' ~ 'NA',
                                                 'SINCE' ~ 'NA',
                                                 'ACACIAS' ~ '0'))

df_complete <- df_complete %>% 
  dplyr:: mutate(production_pause = case_match(Municipality,
                                         'PUERTO NARE' ~ '1',
                                         'YONDO'~ '1',
                                         'PUERTO TRIUNFO' ~ '1',
                                         'ARAUCA' ~ '1',
                                         'ARAUQUITA' ~ '1',
                                         'SARAVENA' ~ '1',
                                         'MOMPOS' ~ '1',
                                         'TAME' ~ '1',
                                         'CANTAGALLO' ~ '1',
                                         'TALAIGUA NUEVO' ~ '1',
                                         'CICUCO' ~ '1',
                                         'CORRALES' ~ '1',
                                         'PUERTO BOYACA' ~ '1',
                                         'PIAMONTE' ~ '1',
                                         'SAN LUIS DE GACENO' ~ '1',
                                         'TOPAGA' ~ '1',
                                         'AGUAZUL' ~ '1',
                                         'YAGUARA' ~ '1',
                                         'MANI' ~ '1',
                                         'TAURAMENA' ~ '1',
                                         'MONTERREY' ~ '1',                  
                                         'NUNCHIA' ~ '1',
                                         'OROCUE' ~ '1',
                                         'PAZ DE ARIPORO' ~ '1',
                                         'PORE' ~ '1',
                                         'SAN LUIS DE PALENQUE' ~ '1',
                                         'YOPAL' ~ '1',
                                         'TRINIDAD' ~ '1',
                                         'VILLA NUEVA' ~ '1',                
                                         'PULI' ~ '1',
                                         'AGUACHICA' ~ '1',
                                         'CHIRIGUANA' ~ '1', 
                                         'LA JAGUA IBIRICO' ~ '1',
                                         'RIO DE ORO' ~ '1',
                                         'SAN ALBERTO' ~ '1',
                                         'SAN MART�\u008dN' ~ '1',       
                                         'SAHAGUN' ~ '1',                    
                                         'GUADUAS' ~ '1',
                                         'PUERTO SALGAR' ~ '0',              
                                         'MUNICIPIO NN' ~ '1',
                                         'DIBULLA' ~ '1',                    
                                         'MANAURE' ~ '1',
                                         'RIOHACHA'~ '1',
                                         'URIBIA' ~ '1',
                                         'AIPE' ~ '1',                       
                                         'ACACIAS' ~ '1',
                                         'VILLAVICENCIO' ~ '1',              
                                         'BARAYA' ~ '1',
                                         'GARZON' ~ '1',                     
                                         'GIGANTE' ~ '1',
                                         'NEIVA' ~ '1',
                                         'PAICOL' ~ '1',
                                         'PALERMO' ~ '1',
                                         'TESALIA' ~ '1',
                                         'VILLAVIEJA' ~ '1',
                                         'BARRANCA DE UPIA' ~ '1',
                                         'CABUYARO' ~ '1',
                                         'CASTILLA NUEVA' ~ '1',
                                         'ORITO' ~ '1',
                                         'GUAMAL' ~ '1',
                                         'PUERTO GAITAN' ~ '1',              
                                         'PUERTO LOPEZ' ~ '1',
                                         'VISTA HERMOSA' ~ '0',              
                                         'IPIALES' ~ '1',
                                         'CUCUTA' ~ '1',                     
                                         'LA ESPERANZA' ~ '1',
                                         'CIMITARRA' ~ '1',
                                         'SARDINATA' ~ '1',
                                         'TIBU' ~ '1',
                                         'MOCOA' ~ '1',
                                         'PUERTO ASIS' ~ '1',
                                         'PUERTO CAICEDO' ~ '1',
                                         'PUERTO GUZMÁN' ~ '0',
                                         'SAN MIGUEL' ~ '1',
                                         'VALLE DEL GUAMUEZ' ~ '1',
                                         'VILLAGARZON' ~ '1',
                                         'BARRANCABERMEJA' ~ '1',
                                         'BOLIVAR' ~ '1',
                                         'EL CARMEN DE CHUCURI' ~ '1',
                                         'PUERTO WILCHES' ~ '1',
                                         'RIONEGRO' ~ '1',
                                         'ORTEGA' ~ '1',
                                         'SABANA DE TORRES' ~ '1',
                                         'SAN VICENTE DE CHUCURI' ~ '1',
                                         'CHAPARRAL' ~ '1',
                                         'SIMACOTA' ~ '1',
                                         'LOS PALMITOS' ~ '1',
                                         'SAN PEDRO' ~ '1',
                                         'ALVARADO' ~ '1',
                                         'COELLO' ~ '0',
                                         'ESPINAL' ~ '1',
                                         'FLANDES' ~ '1',
                                         'ICONONZO' ~ '1',
                                         'MELGAR' ~ '1',
                                         'PIEDRAS' ~ '1',
                                         'PRADO' ~ '1',
                                         'PURIFICACIÓN' ~ '1',
                                         'SAN LUIS' ~ '1',
                                         'SANTA ROSALIA' ~ '0',
                                         'SAN VICENTE DEL CAGUAN' ~ '1',
                                         'MUNICIPIO NN CASANARE' ~ '1',
                                         'BECERRIL' ~ '0',
                                         'EL PASO' ~ '1',
                                         'PUEBLO NUEVO' ~ '1',
                                         'YACOPI' ~ '0',
                                         'ARIGUANI' ~ '1',
                                         'PIJINO DEL CARMEN' ~ '0',
                                         'SANTA ANA' ~ '1',
                                         'MUNICIPIO NN PUTUMAYO' ~ '0',
                                         'MUNICIPIO NN SANTANDER' ~ '1',
                                         'GUAMO' ~ '1',
                                         'SAN JOSE DE FRAGUA' ~ '0',
                                         'TELLO' ~ '0',
                                         'MUNICIPIO NN META' ~ '1',
                                         'PUERTO LLERAS' ~ '0',
                                         'OVEJAS' ~ '1',
                                         'HATO COROZAL' ~ '0',
                                         'SAN CAARLOS GUAROA' ~ '1',
                                         'FONSECA' ~ '0',
                                         'FUENTE DE ORO' ~ '0',
                                         'SABANALARGA' ~ '1',
                                         'PENDIENTE CERTIFICADO IGAC' ~ '1',
                                         'GAMARRA' ~ '1',
                                         'LA UNION' ~ '1',
                                         'SAN MARCOS' ~ '1',
                                         'ASTREA' ~ '1',
                                         'VILLANUEVA' ~ '1',
                                         'SINCE' ~ '1',
                                         'RIO NEGRO' ~ '0'))

df_complete <- df_complete %>% 
  dplyr:: rename(Total_volume_of_royalties_liquidated_in_barrels_or_kilo_cubic_feet_by_municipality = total_of_royalties_by_municipality) 

df_complete <- df_complete %>% 
  dplyr:: rename(Mean_price_of_hydrocarbons_in_USD = mean_price_hydrocarbons) %>% 
  dplyr:: rename(Total_production_of_the_field_in_barrels_or_kilo_cubic_feet_by_municipality = total_production_by_municipality) %>% 
  dplyr:: rename(Total_royalties_liquidated_in_COP_pesos_by_municipality = total_royalty_COP_by_municipality) %>% 
  dplyr:: rename(Production_pause = production_pause)

names(df_complete)

df_complete <- df_complete %>% 
  left_join(
    unique_fields_by_municipality,
    by = c("Municipality"))

df_complete <- df_complete %>% 
  rename(Unique_oil_field_by_municipality = unique_fields)

#6.Merging of two data sets

library(haven)
library(foreign)

df_match <- read_dta("C:/Users/Anna/Desktop/MCC/General work folder/Work for Charlotte/Colombia Extractivism Task/data/data_for_matching.dta") #new dataset into which we will merge

View(df_match)

df_match <- df_match %>% 
  rename(Department = adm1,
         Municipality = adm2,
         Municipality_Code = municipio,
         Year =  year)

df_match <- df_match %>% 
  rename(Municipality_Code = municipio)


is_present <- any(prod_df$Municipality == "SAN MART")

df_match$Year <- as.integer(df_match$Year)
prod_df$Year <- as.integer(prod_df$Year)
df_main$Year <- as.integer(df_main$Year)
View(df_main)


### Combine into a common dataframe


df_match_new_full <- df_match %>% 
  left_join(
    df_complete,
    by = c("Municipality", "Year")) %>% 
  rename( Drop_during_crisis = drop_during_crisis)

View(df_match_new_full)


library(foreign)

write.csv(df_match_new_full, "Merged_file(2010-2019).csv", row.names = TRUE)


View(df_match_new)

### kdensity for all production values to see if its skewed to the right plus summary statistics

install.packages("ggplot2")
install.packages("summarytools")
library(ggplot2)
library(summarytools)

write.csv(df_complete, "Non-merged file.csv", row.names = TRUE)

# Kernel density plot
k_density_plot <- ggplot(df_complete, aes(x = Total_production_of_the_field_in_barrels_or_kilo_cubic_feet_by_municipality)) +
  geom_density(fill = "skyblue", color = "red") +
  labs(title = "Kernel Density Plot of Production Values",
       x = "Production", y = "Density") +
  theme_bw() +
  xlim(0, 10000000) 


k_density_plot #skewed data

# Summary statistics

library(summarytools)

# Generate summary statistics
production_summary <- summary(df_complete$Total_production_of_the_field_in_barrels_or_kilo_cubic_feet_by_municipality)
print(production_summary)

summary_stats <- descr(df_complete$Total_production_of_the_field_in_barrels_or_kilo_cubic_feet_by_municipality)
summary_stats
 
# Summary statistics for continuous production

continuous_production <- df_complete %>%
  filter(Production_2010_2019 == 1)

summary_stats_continuous_production <- descr(continuous_production$Total_production_of_the_field_in_barrels_or_kilo_cubic_feet_by_municipality)
summary_stats_continuous_production

# Number of Distinct Municipalities by Opening and Closing

df_complete$Municipality <- as.factor(df_complete$Municipality)

variation_counts <- df_complete %>%
  group_by(Opening, Closing) %>%
  summarise(municipalities = n_distinct(Municipality))

View(variation_counts)

# Read Me text file

names(df_complete)

variable_explanations <- c(
  "Year",                                                                              
  "Municipality: Municipality name",                                                                      
  "Mean_price_of_hydrocarbons_in_USD: Mean price of hydrocarbons (USD)",                                                 
  "Total_production_of_the_field_in_barrels_or_kilo_cubic_feet_by_municipality: Total production of oil/gas fields bbl/kcf by municipality",       
  "Total_volume_of_royalties_liquidated_in_barrels_or_kilo_cubic_feet_by_municipality: Total volume of liquidated royalties in bbl/kcf by municipality",
  "Total_royalties_liquidated_in_COP_pesos_by_municipality: Total amount of royalties paid in Colombian pesos (COP) by municipality",                           
  "Production_Years: Indicates the number of production years",                                                                  
  "Production_2010_2019: 1, Continuous production 2010-2019; 0, Non-continous production between 2010-2019",                                                              
  "Opening: Start of the production > 2010; NA = 2010",                                                                           
  "Closing: Closing of the production <2019; NA = 2019",                                                                           
  "Drop_during_crisis: 1, Dropped during 2014 or 2015; 0, Did not drop during 2014 or 2015",                                                                
  "Production_pause: 1, production stopped for > 2 years; 0, production did not stop or stopped for =< 2",                                                                  
  "Unique_oil_field_by_municipality: Indicates number of unique fields per municipality")

file_path <- "readme.txt"
writeLines(variable_explanations, file_path)
