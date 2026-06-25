# PILA Data Download (only works in Colombia! only works with MS R Client!)

rm(list=ls())
gc()

setwd("C:/Users/Lennard/Dropbox/Studium/MA Masterarbeit/D Pila Data Download/D4 Third Download/")

library(tidyverse)
library(olapR)
library(stringi)

# Define connection
ocs <- OlapConnection("Data Source=cubosbi.sispro.gov.co;Provider=MSOLAP;User Id=sispro\\L_Naumann;Password=G%m73Hj88")
#explore(ocs, cube = "CU_AportesCotizantes", dimension = "Aportantes", hierarchy = "Actividad Economica", level = "Divíson")

# Function for data download
get_pila <- function(year, measure, incl.year.measure = T, 
                     sector = "All sectors",
                     connection = ocs){
  
  # Define server connection
  
  
  # MDX command
  mdx_command <- paste0(
    "SELECT {[Measures].[Measures].[",measure,"]} ON COLUMNS, 

    {[Ubicación Laboral].[País - Departamento - Municipio].[Municipio]} ON ROWS

    FROM [CU_AportesCotizantes] 

    WHERE ([Periodo de Cotizacion].[Anno].[Anno].&[",year,"]",
    ifelse(sector == "All sectors", "", paste0(", [Aportantes].[Actividad economica].[Seccion].&[",sector,"]")),
    ")"
  )
  
  # Load data
  dt <- execute2D(connection, mdx_command)
  
  # Specifiy varnames
  names(dt) <- c("Country", "Departamento", "Municipio", "value")
  
  # Attach year and measure and sector
  if (incl.year.measure)
    dt <- mutate(
      dt,
      year = year,
      variable = measure %>% stri_trans_general("Latin-ASCII") %>% str_remove_all(" "),
      sector = sector
    )
  
}



# Data Download
starty <- 2011
endy <- 2022
vars <- c("Numero Total Empleados",
          "Numero de Dias Cotizados",
          "Valor Aporte",
          "Valor IBC")
sectors <- c("All sectors", "A - AGRICULTURA, GANADERÍA, CAZA, SILVICULTURA Y PESCA",
             "B - EXPLOTACIÓN DE MINAS Y CANTERAS",
             "C - INDUSTRIAS MANUFACTURERAS",
             "D - SUMINISTRO DE ELECTRICIDAD, GAS, VAPOR Y AIRE ACONDICIONADO",
             "E - DISTRIBUCIÓN DE AGUA; EVACUACIÓN Y TRATAMIENTO DE AGUAS RESIDUALES, GESTIÓN DE DESECHOS Y ACTIVIDADES DE SANEAMIENTO AMBIENTAL",
             "F - CONSTRUCCIÓN",
             "G - COMERCIO AL POR MAYOR Y AL POR MENOR; REPARACIÓN DE VEHÍCULOS AUTOMOTORES Y MOTOCICLETAS",
             "H - TRANSPORTE Y ALMACENAMIENTO",
             "I - ALOJAMIENTO Y SERVICIOS DE COMIDA",
             "J - INFORMACIÓN Y COMUNICACIONES",
             "K - ACTIVIDADES FINANCIERAS Y DE SEGUROS",
             "L - ACTIVIDADES INMOBILIARIAS",
             "M - ACTIVIDADES PROFESIONALES, CIENTÍFICAS Y TÉCNICAS",
             "N - ACTIVIDADES DE SERVICIOS ADMINISTRATIVOS Y DE APOYO")

data <- data.frame()
pb <- txtProgressBar(max = (endy-starty+1)*length(vars)*length(sectors), style = 3)
i <- 0
for(y in starty:endy){for(v in vars){for(s in sectors){
  data <- rbind(data, get_pila(year = y, measure = v, sector = s))
  i <- i+1
  setTxtProgressBar(pb, i)
}}}
close(pb)

write.csv(data, paste("pila", Sys.Date(), starty, endy, length(vars), "vars.csv", sep = "_"), row.names = F)














