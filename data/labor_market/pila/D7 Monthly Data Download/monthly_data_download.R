# PILA Data Download (only works in Colombia! only works with MS R Client!)

rm(list=ls())
gc()

setwd("C:/Users/Lennard/Dropbox/Studium/MA Masterarbeit/D Pila Data Download/D7 Monthly Data Download/")

library(tidyverse)
library(olapR)

# Define connection
ocs <- OlapConnection("Data Source=cubosbi.sispro.gov.co;Provider=MSOLAP;User Id=sispro\\L_Naumann;Password=G%m73Hj88")
#explore(ocs, cube = "CU_AportesCotizantes", dimension = "Aportantes", hierarchy = "Actividad Economica", level = "Div?son")

# Function for data download
get_pila <- function(year, depart, munip, measure, incl.year.measure = T, 
                     sector = "All sectors",
                     connection = ocs){
  
  
  # MDX command
  mdx_command <- paste0(
    "SELECT {[Measures].[Measures].[",measure,"]} ON COLUMNS, 

    {[Periodo de Cotizacion].[Mes].[Mes]} ON ROWS

    FROM [CU_AportesCotizantes] 

    WHERE ([Periodo de Cotizacion].[Anno].[Anno].&[",year,"],
           [Ubicaci?n Laboral].[Pa?s - Departamento - Municipio].[Municipio].&[",munip,"]",
    ifelse(sector == "All sectors", "", paste0(", [Aportantes].[Actividad economica].[Seccion].&[",sector,"]")),
    ")"
  )
  
  # Load data
  dt <- execute2D(connection, mdx_command)
  
  # Specifiy varnames
  names(dt) <- c("month", "value")
  
  # Attach year and month and measure and sector
  if (incl.year.measure){
    dt$year <- year
    dt$Departamento <- depart
    dt$Municipio <- munip
    dt$variable <- "NumerodeCotizantes"
    dt$sector <- sector
  }
  
  return(dt)
}

# Prepare departments and municipalities
adms <- execute2D(
  ocs,
  "SELECT {[Measures].[Measures].[N?mero de Cotizantes]} ON COLUMNS, 

    {[Ubicaci?n Laboral].[Pa?s - Departamento - Municipio].[Municipio]} ON ROWS

    FROM [CU_AportesCotizantes] 

    WHERE ([Periodo de Cotizacion].[Anno].[Anno].&[2019],
    [Aportantes].[Actividad economica].[Seccion].&[B - EXPLOTACI?N DE MINAS Y CANTERAS])"
)
names(adms) <- c("Country", "Department", "Municipio", "Omit")
adms <- unique(adms[,c("Department", "Municipio")])
 


# Data Download
# FLAG: 2015 missing (crashed twice)
starty <- 2015
endy <- 2022
vars <- c("N?mero de Cotizantes")
sectors <- c(#"A - AGRICULTURA, GANADER?A, CAZA, SILVICULTURA Y PESCA",
             "B - EXPLOTACI?N DE MINAS Y CANTERAS"#,
             #"C - INDUSTRIAS MANUFACTURERAS",
             #"D - SUMINISTRO DE ELECTRICIDAD, GAS, VAPOR Y AIRE ACONDICIONADO",
             #"E - DISTRIBUCI?N DE AGUA; EVACUACI?N Y TRATAMIENTO DE AGUAS RESIDUALES, GESTI?N DE DESECHOS Y ACTIVIDADES DE SANEAMIENTO AMBIENTAL",
             #"F - CONSTRUCCI?N",
             #"G - COMERCIO AL POR MAYOR Y AL POR MENOR; REPARACI?N DE VEH?CULOS AUTOMOTORES Y MOTOCICLETAS",
             #"H - TRANSPORTE Y ALMACENAMIENTO",
             #"I - ALOJAMIENTO Y SERVICIOS DE COMIDA",
             #"J - INFORMACI?N Y COMUNICACIONES",
             #"K - ACTIVIDADES FINANCIERAS Y DE SEGUROS",
             #"L - ACTIVIDADES INMOBILIARIAS",
             #"M - ACTIVIDADES PROFESIONALES, CIENT?FICAS Y T?CNICAS",
             #"N - ACTIVIDADES DE SERVICIOS ADMINISTRATIVOS Y DE APOYO"
  )


for(y in starty:endy){
  
  cat(paste0(" #### Year ", y, " ####\n"))
  data <- data.frame()
  pb <- txtProgressBar(max = length(vars)*length(sectors)*nrow(adms), style = 3)
  i <- 0
  start.time <- Sys.time()
  
    for(j in 1:nrow(adms)){for(v in vars){for(s in sectors){
    try(data <- rbind(data, get_pila(year = y, 
                                 depart = adms[j,1], 
                                 munip = adms[j,2], 
                                 measure = v, 
                                 sector = s)), silent = T)
    i <- i+1
    setTxtProgressBar(pb, i)
    }}}
  
  close(pb)
  
  write.csv(data, paste0(y, "_", Sys.Date(), ".csv"))
  
  cat(paste0(
    "\nFinished in ", 
    round(difftime(Sys.time(), start.time, units = "hours"), 2), 
    " hours.\n\n"
  ))
  
  cat("Sleep for one minute...\n\n")
  Sys.sleep(60)
  
  }

rbind(
  read.csv("2011_2023-08-15.csv"), read.csv("2012_2023-08-16.csv"),
  read.csv("2013_2023-08-16.csv"), read.csv("2014_2023-08-16.csv"),
  read.csv("2015_2023-08-14.csv"), read.csv("2016_2023-08-14.csv"),
  read.csv("2017_2023-08-14.csv"), read.csv("2018_2023-08-14.csv"),
  read.csv("2019_2023-08-14.csv"), read.csv("2020_2023-08-14.csv"),
  read.csv("2021_2023-08-14.csv"), read.csv("2022_2023-08-14.csv")
) %>% 
  write.csv(file = paste0("PILA_monthly_", Sys.Date(), ".csv"))
