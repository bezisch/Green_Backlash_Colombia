# COLOMBIA EXTRACTIONIST TASK

setwd("C:/Users/charlott/Dropbox (Personal)/MA Masterarbeit/H Oil and Gas Fields")
#setwd("C:/Users/Anna/Desktop/MCC/General work folder/Work for Charlotte/Columbia Extractivism Task/script")

library(haven)
library(tidyverse)

df <- read.csv("C:/Users/charlott/Dropbox (Personal)/MA Masterarbeit/H Oil and Gas Fields/datos_completos_prod_regalias_2010_2021.csv") 
#df <- read.csv("C:/Users/Anna/Desktop/MCC/General work folder/Work for Charlotte/Columbia Extractivism Task/script/datos_completos_prod_regalias_2010_2021.csv") 

#Looking at data frame

View(df)
unique(df$Anio)
unique(df$Municipio)

# Extracting the necessary variables and renaming

prod_df <- df %>% 
  select(ITEM = ITEM,
         Municipality = Municipio,
         Year = Anio,
         Month = Mes,
         Field = Campo,
         Price_of_Hydrocarbons_USD = PrecioHidrocarburoUSD,
         Production = ProdGravableBlsKpc,
         Volume_of_Royalties = VolumenRegaliaBlsKpc,
         Royalty_COP = RegaliasCOP) %>% 
  rename(Taxable_Production = Production)

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
  select(Municipality) %>%
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


#. A) Calculate and separate total production by year and municipality

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
