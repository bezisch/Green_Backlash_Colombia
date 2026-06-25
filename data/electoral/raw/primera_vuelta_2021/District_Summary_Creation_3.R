# this file prepares the district summaries for Colombian municipalities.

Sys.setenv(LANG = "en")

library(haven)
library(dplyr)
library(foreign)

setwd("C:/Users/charlott/Dropbox (Personal)/MA Masterarbeit/E Elections-CMP Preparation")

clea.m  <- read_dta("Data_Preparation_All_Elections_Covered_CMP.dta")

#input here: pvs1, the 4 scores (for each lowe and median)
# Note that the new version of Data_Preparation_All_Elections_Covered_CMP.dta has two pvs1: the unweighted, and the weighted version (simply called pvs1)
# it is weighted (normalized) by the population in voting age (>17 yo)

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


resc.var <- c("environment", "environment_raw", "leftright", "econleftright", "nationalist")

for (i in 1:length(resc.var)) {
  temp <- clea.m[, paste0("lowe_", resc.var[i])]
  temp <- as.vector(t(temp))
  
  clea.m$pvs1t <- clea.m$pvs1
  clea.m$pvs1t[is.na(clea.m$pvs1) & !is.na(temp)] <- 0
  
  # Median for each distyear
  median <- tapply(seq(along = temp), clea.m$distyear, 
                   function(i, x = temp, w = clea.m$pvs1t) weighted.median(x[i], w[i], na.rm = TRUE))
  
  # Mean for each distyear
  mean <- tapply(seq(along = temp), clea.m$distyear, 
                 function(i, x = temp, w = clea.m$pvs1t) weighted.mean(x[i], w[i], na.rm = TRUE))
  
  # raw mean 
  
  mean_raw <- tapply(seq(along=clea.m$lowe_environment_raw), clea.m$distyear, 
                     function(i, x=clea.m$lowe_environment_raw, w=clea.m$pvs1t) weighted.mean(x[i], w[i], na.rm=TRUE))
  
  
  mv <- data.frame(names(median), median, mean, mean_raw) # we do not consider maxvote here, not needed at the moment.
  
  names(mv) <- c("distyear", paste0(c("MV", "MEAN", "MEAN_raw"), resc.var[i]))
  
  #clea.m <- merge(clea.m, mv, by.x="distyear", by.y=1, all.x=TRUE)
  
  if(i==1){summaries.mv.district <- mv}else{
    summaries.mv.district <- merge(summaries.mv.district, mv, by="distyear", all.x=TRUE, all.y=TRUE)}
}

save(summaries.mv.district, file="summaries.mv.district")

sum.voteshares <- function(x, w){
  
  
  sum(x[w==TRUE], na.rm=TRUE)  
  
}


#########################################################  TEST ###############################################


# Split 'distyear' to extract the year and create a new variable 'year'

library(stringr)

test_data <- summaries.mv.district %>%
  mutate(year = str_extract(distyear, "_([0-9]+)$") %>% str_remove("_"))

means_by_year <- test_data %>%
  group_by(year) %>%
  summarise(mean_environment = mean(MEANenvironment, na.rm = TRUE),
            mean_environment_raw = mean(MEANenvironment_raw, na.rm = TRUE),
            mean_leftright = mean(MEANleftright, na.rm = TRUE),
            mean_econleftright = mean(MEANeconleftright, na.rm = TRUE),
            mean_nationalist = mean(MEANnationalist, na.rm = TRUE))

# Print the means by year
print(means_by_year)


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

# note that i have dropped Share, Prop and the raw mean for now, as we do not need them and they created trouble. 


