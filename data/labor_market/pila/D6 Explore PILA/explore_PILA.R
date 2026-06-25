# PILA Detailed Codebook (only works in Colombia! only works with MS R Client!)

rm(list=ls())
gc()

setwd("C:/Users/Lennard/Dropbox/Studium/MA Masterarbeit/D Pila Data Download/D6 Explore PILA/")

library(tidyverse)
library(olapR)
library(stringi)
library(xlsx)
library(reshape2)

# Define connection
ocs <- OlapConnection("Data Source=cubosbi.sispro.gov.co;Provider=MSOLAP;User Id=sispro\\L_Naumann;Password=G%m73Hj88")

get_pila_multidim <- function(axes, filters = NULL, connection = ocs, drop.na = T){
  
  # MDX command
  to_select <- paste0("NONEMPTY ({", axes, "}) ON ", 0:(length(axes)-1), collapse = ", ")
  to_filter <- ifelse(is.null(filters), "", paste0(" WHERE (",filters,")"))
  mdx_command <- paste0("SELECT ", to_select, " FROM [CU_AportesCotizantes]", to_filter)
  
  # Load data
  dt <- executeMD(connection, mdx_command) %>% melt
  
  # Specifiy varnames as penultimate entry of axis name
  names(dt) <- c(str_split(axes, "\\]\\.\\[", simplify = T)[,2], "value")
  
  if(drop.na) dt <- filter(dt, !is.na(value))
  
  return(dt)
}


# Check advanced filters and compare to ILO, Kugler, WB
load("downloaded_results.RData") # loads the ones below to save time

# World Bank says workforce in 2019 was ~26.3 million, check with following code (takes forever:)
wb_workforce <- get_pila_multidim(axes    = "[Measures].[Measures].[Número de Cotizantes]",
                  filters = "[Periodo de Cotizacion].[Anno].&[2019]")

# World Bank PDF report says 182k in mining employment in 2019
wb_mining <- get_pila_multidim(axes    = c("[Measures].[Measures].[Número de Cotizantes]", "[Aportantes].[Actividad economica].[Seccion]"),
                             filters = "[Periodo de Cotizacion].[Anno].&[2019]")


# Comparison with Tables 1 from Kugler's robots paper:
kugler1.2 <- get_pila_multidim(axes    = c("[Measures].[Measures].[Número de Cotizantes]", "[Cotizante].[Sexo].[Sexo]"),
                  filters = "[Periodo de Cotizacion].[Anno].&[2016]")
kugler1.3 <- get_pila_multidim(axes    = c("[Measures].[Measures].[Número de Cotizantes]", "[Cotizante].[Edad].[Edad]"),
                  filters = "[Periodo de Cotizacion].[Anno].&[2016]")
kugler1.4 <- get_pila_multidim(axes    = c("[Rango Numero Empleados].[Rango Numero Empleados].[Rango Numero Empleados]"),
                  filters = "[Periodo de Cotizacion].[Anno].&[2016]")

# Comparison with Tables 1 from Kugler's robots paper:
kugler2 <- get_pila_multidim(axes    = c("[Measures].[Measures].[Número de Cotizantes]", "[Aportantes].[Actividad economica].[Seccion]"),
                  filters = "[Periodo de Cotizacion].[Anno].&[2016]")

# ILO says for 2019: 41% of women in the workforce
ilo1 <- get_pila_multidim(axes    = c("[Measures].[Measures].[Número de Cotizantes]", "[Cotizante].[Sexo].[Sexo]"),
                          filters = "[Periodo de Cotizacion].[Anno].&[2019]")
# and 13 % women in the mining sector
ilo2 <- get_pila_multidim(axes    = c("[Measures].[Measures].[Número de Cotizantes]", "[Cotizante].[Sexo].[Sexo]"),
                          filters = "[Periodo de Cotizacion].[Anno].&[2019], [Aportantes].[Actividad economica].[Seccion].&[B - EXPLOTACIÓN DE MINAS Y CANTERAS]")
# while mining sector makes up .9% of overall employment
ilo3 <- wb_mining

# Plain Data Download for Zipaquirá:
if(F){
  ts0 <- Sys.time()
  get_pila_multidim(
    axes = c(
      paste0(
        "[Measures].[Measures].[",
        c("Numero de Dias Cotizados"),
        "]",
        collapse = ", "
      ),
      "[Cotizante].[Edad].[Edad]",
      "[Cotizante].[Sexo].[Sexo]",
      "[Fecha Pago].[Hierarchy].[Fecha ID]",
      "[Cotizante].[Etnia].[Etnia]",
      "[Cotizante].[Geografiia Cotizante].[Municipio]"
    ),
    filter = "[Periodo de Cotizacion].[Anno].&[2019], 
              [Aportantes].[Actividad economica].[Seccion].&[B - EXPLOTACIÓN DE MINAS Y CANTERAS],
                [Ubicación Laboral].[País - Departamento - Municipio].[Municipio].&[25899 - Zipaquirá]"
  ) %>% write.csv("dt.ndcb.csv")
  gc()
  ts1 <- Sys.time()
  cat("ndc B done in ")
  print(ts1-ts0)
  
  get_pila_multidim(
    axes = c(
      paste0(
        "[Measures].[Measures].[",
        c("Valor IBC"),
        "]",
        collapse = ", "
      ),
      "[Cotizante].[Edad].[Edad]",
      "[Cotizante].[Sexo].[Sexo]",
      "[Fecha Pago].[Hierarchy].[Fecha ID]",
      "[Cotizante].[Etnia].[Etnia]",
      "[Cotizante].[Geografiia Cotizante].[Municipio]"
    ),
    filter = "[Periodo de Cotizacion].[Anno].&[2019], 
              [Aportantes].[Actividad economica].[Seccion].&[B - EXPLOTACIÓN DE MINAS Y CANTERAS],
                [Ubicación Laboral].[País - Departamento - Municipio].[Municipio].&[25899 - Zipaquirá]"
  ) %>% write.csv("dt.ibcb.csv")
  gc()
  ts2 <- Sys.time()
  cat("ibc B done in ")
  print(ts2-ts1)
  
  
  
  
  
  
  get_pila_multidim(
    axes = c(
      paste0(
        "[Measures].[Measures].[",
        c("Numero Total Empleados"),
        "]",
        collapse = ", "
      ),
      "[Cotizante].[Edad].[Edad]",
      "[Cotizante].[Sexo].[Sexo]",
      "[Fecha Pago].[Hierarchy].[Fecha ID]",
      "[Cotizante].[Etnia].[Etnia]",
      "[Cotizante].[Geografiia Cotizante].[Municipio]"
    ),
    filter = "[Periodo de Cotizacion].[Anno].&[2019], 
                [Ubicación Laboral].[País - Departamento - Municipio].[Municipio].&[25899 - Zipaquirá]"
  ) %>% write.csv("dt.ntea.csv")
  gc()
  ts3 <- Sys.time()
  cat("ntea done in ")
  print(ts3-ts2)
  
  
  
  get_pila_multidim(
    axes = c(
      paste0(
        "[Measures].[Measures].[",
        c("Numero de Dias Cotizados"),
        "]",
        collapse = ", "
      ),
      "[Cotizante].[Edad].[Edad]",
      "[Cotizante].[Sexo].[Sexo]",
      "[Fecha Pago].[Hierarchy].[Fecha ID]",
      "[Cotizante].[Etnia].[Etnia]",
      "[Cotizante].[Geografiia Cotizante].[Municipio]"
    ),
    filter = "[Periodo de Cotizacion].[Anno].&[2019], 
                [Ubicación Laboral].[País - Departamento - Municipio].[Municipio].&[25899 - Zipaquirá]"
  ) %>% write.csv("dt.ndca.csv")
  gc()
  ts4 <- Sys.time()
  cat("ndc A done in ")
  print(ts4-ts3)
  
  
  get_pila_multidim(
    axes = c(
      paste0(
        "[Measures].[Measures].[",
        c("Valor IBC"),
        "]",
        collapse = ", "
      ),
      "[Cotizante].[Edad].[Edad]",
      "[Cotizante].[Sexo].[Sexo]",
      "[Fecha Pago].[Hierarchy].[Fecha ID]",
      "[Cotizante].[Etnia].[Etnia]",
      "[Cotizante].[Geografiia Cotizante].[Municipio]"
    ),
    filter = "[Periodo de Cotizacion].[Anno].&[2019], 
                [Ubicación Laboral].[País - Departamento - Municipio].[Municipio].&[25899 - Zipaquirá]"
  ) %>% write.csv("dt.ibca.csv")
  gc()
  ts5 <- Sys.time()
  cat("ibc A done in ")
  print(ts5-ts4)
}
