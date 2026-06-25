# PILA Detailed Codebook (only works in Colombia! only works with MS R Client!)

rm(list=ls())
gc()

setwd("C:/Users/Lennard/Dropbox/Studium/MA Masterarbeit/D Pila Data Download/D5 Detailed Codebook/")

library(tidyverse)
library(olapR)
library(stringi)
library(xlsx)

# Define connection
ocs <- OlapConnection("Data Source=cubosbi.sispro.gov.co;Provider=MSOLAP;User Id=sispro\\L_Naumann;Password=G%m73Hj88")

dimensions <- character()
while(is_empty(dimensions)){
  try(dimensions <- capture.output(explore(ocs, cube = "CU_AportesCotizantes")))
}



results <- data.frame()
for(dimensionx in dimensions){
  cat(paste0("__ dimension _ ", dimensionx, "\n"))
  
  hierarchies_ <- character()
  while(is_empty(hierarchies_)){
    try(hierarchies_ <- capture.output(explore(ocs, cube = "CU_AportesCotizantes", dimension = dimensionx)))
  }
  
  
  for(hierarchyx in hierarchies_){
    cat(paste0("____ hierarchy _ ", hierarchyx, "\n"))
    
    levels_ <- character()
    while(is_empty(levels_)){
      try(levels_ <- capture.output(explore(ocs, cube = "CU_AportesCotizantes", dimension = dimensionx, hierarchy = hierarchyx)))
    }
    
    
    for(levelx in levels_){
      cat(paste0("______ level _ ", levelx, "\n"))
      
      values_ <- character()
      while(is_empty(values_)){
        try(values_ <- capture.output(explore(ocs, cube = "CU_AportesCotizantes", dimension = dimensionx, hierarchy = hierarchyx, level = levelx)))
      }
     
      for(value in values_){
        cat(paste0("__________", value, "\n"))
      }
      
      results <- rbind(results, data.frame(dimension = dimensionx, hierarchy = hierarchyx, level = levelx, values = paste(unique(values_), collapse = "; ")))
      
      
    }
  }
}


write.xlsx(results, paste0("results_", Sys.Date(), ".xlsx"), row.names = F)
