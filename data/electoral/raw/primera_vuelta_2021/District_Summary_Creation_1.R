# this file prepares the district summaries for Colombian municipalities.

Sys.setenv(LANG = "en")

library(haven)
library(dplyr)
library(foreign)

setwd("C:/Users/charlott/Dropbox (Personal)/MA Masterarbeit/E Elections-CMP Preparation")

clea.m  <- read_dta("Data_Preparation_All_Elections_Covered_CMP.dta")

#input here: pvs1, the 4 scores (for each lowe and median), and the green dummy

################################################## HERE define the weighted median function ##################################################


weighted.median <- function(x, w, na.rm=TRUE, ties=NULL) {
  if (missing(w))
    w <- rep(1, length(x));
  
  # Remove values that are NA's
  if (na.rm == TRUE) {
    keep <- !(is.na(x) | is.na(w));
    x <- x[keep];
    w <- w[keep];
  } else if (any(is.na(x)))
    return(NA);
  
  # Assert that the weights are all non-negative.
  if (any(w < 0))
    stop("Some of the weights are negative; one can only have positive
weights.");
  
  # Remove values with weight zero. This will:
  #  1) take care of the case when all weights are zero,
  #  2) make sure that possible tied values are next to each others, and
  #  3) it will most likely speed up the sorting.
  n <- length(w);
  keep <- (w > 0);
  nkeep <- sum(keep);
  if (nkeep < n) {
    x <- x[keep];
    w <- w[keep];
    n <- nkeep;
  }
  
  # Are any weights Inf? Then treat them with equal weight and all others
  # with weight zero.
  wInfs <- is.infinite(w);
  if (any(wInfs)) {
    x <- x[wInfs];
    n <- length(x);
    w <- rep(1, n);
  }
  
  # Are there any values left to calculate the weighted median of?
  if (n == 0)
    return(NA);
  
  # Order the values and order the weights accordingly
  ord <- order(x);
  x <- x[ord];
  w <- w[ord];
  
  wcum <- cumsum(w);
  wsum <- wcum[n];
  wmid <- wsum / 2;
  
  # Find the position where the sum of the weights of the elements such that
  # x[i] < x[k] is less or equal than half the sum of all weights.
  # (these two lines could probably be optimized for speed).
  lows <- (wcum <= wmid);
  k  <- sum(lows);
  
  # Two special cases where all the weight are at the first or the
  # last value:
  if (k == 0) return(x[1]);
  if (k == n) return(x[n]);
  
  # At this point we know that:
  #  1) at most half the total weight is in the set x[1:k],
  #  2) that the set x[(k+2):n] contains less than half the total weight
  # The question is whether x[(k+1):n] contains *more* than
  # half the total weight (try x=c(1,2,3), w=c(1,1,1)). If it is then
  # we can be sure that x[k+1] is the weighted median we are looking
  # for, otherwise it is any function of x[k:(k+1)].
  
  wlow  <- wcum[k];    # the weight of x[1:k]
  whigh <- wsum - wlow;  # the weight of x[(k+1):n]
  if (whigh > wmid)
    return(x[k+1]);
  
  if (is.null(ties) || ties == "weighted") {  # Default!
    (wlow*x[k] + whigh*x[k+1]) / wsum;
  } else if (ties == "max") {
    x[k+1];
  } else if (ties == "min") {
    x[k];
  } else if (ties == "mean") {
    (x[k]+x[k+1])/2;
  } else if (ties == "both") {
    c(x[k], x[k+1]);
  }
}



############################################ HERE (ONCE ALL DIAGNOSTICS ARE RUN) CALCULATE THE ACTUAL SCORES

########################  MAKE SURE THERE ARE NO NUMERIC CODES FOR MISSING VALUES in pvs1
check.pvs1 <- summary(clea.m$pvs1)

if (check.pvs1[[1]] < 0) {
  cat(
    "Caution: There are negative vote shares, missing values that incorrectly creeped through"
  )
}

na.exclude(clea.m$pvs1)

######################## important is to avoid placing 0 in contexts with missing values only

######################### HERE LOOP TO CREATE ALL THOSE FOR RESCALED VARS

######################### name the four times two variables we have (normal and rescaled)
# drop here the _RESC variable, we do not use them for now (rescale them by country or country-year does not make sense in our case.)

resc.var<- c("environment", 
             
             "environment_raw",
             
             "leftright",   
             
             "econleftright", 
             
             "nationalist")     

#View(resc.var)


#########################################################  STEP 1  ###############################################

for ( i in 1:length(resc.var)){
  
  temp <- clea.m[, paste0("lowe_", resc.var[i]) ]
  
  #unlist(test)
  temp <- as.vector(t(temp))
  
  clea.m$pvs1t <- clea.m$pvs1
  
  clea.m$pvs1t[is.na(clea.m$pvs1)&!is.na(temp)]<- 0
  
  #median for each distyear   
  mv1 <- tapply(seq(along=temp), clea.m$distyear, 
                function(i, x=temp, w=clea.m$pvs1t) weighted.median(x[i], w[i], na.rm=TRUE))
  
  #mean for each distyear --> not corrected, do it later (also with respect to version _3)
  
  mv2a <- tapply(seq(along=clea.m$lowe_environment), clea.m$distyear, 
                 function(i, x=clea.m$lowe_environment, w=clea.m$pvs1t) weighted.mean(x[i], w[i], na.rm=TRUE))
  
  clea.m$party <- clea.m$lowe_environment>0
  
  
  
  mv2c <- tapply(seq(along=clea.m$lowe_environment_raw), clea.m$distyear, 
                 function(i, x=clea.m$lowe_environment_raw, w=clea.m$pvs1t) weighted.mean(x[i], w[i], na.rm=TRUE))
  
  #propensity to vote given party for each distyear 
  mv3 <- tapply(seq(along=clea.m$lowe_environment), clea.m$distyear, 
                function(i, x=clea.m$party, w=clea.m$pvs1t) weighted.mean(x[i], w[i], na.rm=TRUE))
  
  #mv <- data.frame(names(mv), mv)
  
  
  maxvote <- tapply(temp[clea.m$pvs1>0&!is.na(clea.m$pvs1)]
                    
                    , clea.m$distyear[clea.m$pvs1>0&!is.na(clea.m$pvs1)], max, na.rm=TRUE)
  
  maxvote <- data.frame(names(maxvote), maxvote)
  
  names(maxvote) <- c("distyear", paste0("max", resc.var[i]))
  
  clea.m <- merge(clea.m, maxvote, by.x="distyear", by.y=1, all.x=TRUE)
  
  clea.m$green <-temp==clea.m[,paste0("max", resc.var[i])]
  
  clea.m$green[is.na(clea.m$green)] <- FALSE
  
  #vote share of green party for each distyear 
  mv5 <- tapply(seq(along=temp), clea.m$distyear, 
                function(i, x=clea.m$pvs1t, w=clea.m$green) weighted.mean(x[i], w[i], na.rm=TRUE))
  
  
  #divided into left and right for green parties 
  
  ###### now a little trick to avoid assigning 0 (rather than NA) to districts in which no party has a score
  
  mv5.check <- tapply(seq(along=temp), clea.m$distyear, 
                      function(i, x=clea.m$green) sum(x[i], na.rm=TRUE))
  
  
  if(is.na(mean(mv5.check))){cat("problem here!")}
  
  mv <- data.frame(names(mv1), mv1, mv2a, mv2c, mv3, mv5)
  
  names(mv) <- c("distyear", paste0(c("MV", "MEAN", "MEAN_raw", "PROP", "SHAREmost"), resc.var[i]))
  
  #clea.m <- merge(clea.m, mv, by.x="distyear", by.y=1, all.x=TRUE)
  
  if(i==1){summaries.mv.district <- mv}else{
    summaries.mv.district <- merge(summaries.mv.district, mv, by="distyear", all.x=TRUE, all.y=TRUE)}
}

save(summaries.mv.district, file="summaries.mv.district")

sum.voteshares <- function(x, w){
  
  
  sum(x[w==TRUE], na.rm=TRUE)  
  
}

#########################################################  STEP 2  : create combined vote shares for party categories ###############################################


#those three variables correspond to the party category vote share and have been created in STATA before
#plus the dummy variables right, econright, and nationalist

vars <- c( "mainstream"     ,    "green"   ,   "green_agragian" ,   "green_right"   ,   "green_econright"   ,   "green_nationalist")


for ( i in 1:length(vars)){
  
  #temp <- clea.m[, paste0("lowe_", resc.var[i]) ]
  
  #temp <- as.numeric(clea.m[, vars[i]])
  
  temp[is.na(temp)] <- 0 
  
  
  propvote <- tapply(seq(along=temp), clea.m$distyear, 
                     
                     function(i, x=clea.m$pvs1, w=temp) sum.voteshares(x[i], w[i]))
  
  
  propvote <- data.frame(names(propvote), propvote)
  
  names(propvote) <- c("distyear", paste0(vars[i],"_share"))
  
  summaries.mv.district <- merge(summaries.mv.district, propvote, by="distyear", all.x=TRUE, all.y=TRUE)
  
}


#########################################################################################################################################################################

save(summaries.mv.district, file="summaries.mv.district.after.inc")

get.nuts <- function(x){
  
  
  out <- substr(x, 1,5)  
  
  out <- sub("_", "", out, fixed=TRUE)
  return(out)
}



get.yr <- function(x){
  
  x <- as.character(x)
  
  len <- nchar(x)
  
  out <- substr(x, len-4, len)
  
  out <-as.numeric(out)
  
  return(out)
}

summaries.mv.district$municipio <- sapply(summaries.mv.district$distyear, get.nuts)

summaries.mv.district$year <- sapply(summaries.mv.district$distyear, get.yr)

write.dta(summaries.mv.district, file="Scores_Elections.dta") 


library(haven)

write_dta(summaries.mv.district, 'Scores_Elections.dta') # in C:\Users\charlott\Dropbox (Personal)\MA Masterarbeit\E Elections-CMP Preparation

######################################################   FINE    ######################################################



