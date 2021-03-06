setClass("ageClassTransition",
         slots=c(transition = "array", stages="character", dates="Date"),
         #prototype(transition = plot(raster(matrix(c(0.1,0.9,0,0,0,0,0,0.2,0.8,0,0,0,0,0,.5,.5,0,0,0,0,0,0.8,0.2,0,0,0,0,0,.9,.1,0,0,0,0,0,.1),nrow=6,ncol=6,byrow=TRUE)))),
         validity = function(object){
           # transtion = array dim(number of X, number of Y, number of dates, number of age classes, number of age classes)
           if (dim(object@transition)[3]!=length(object@dates)) stop("third dimension of values array is not equal to number of dates")
           if (dimnames(object@transition)[[3]]!=as.character(object@dates)) stop("slot transition array third dimension colnames is not equal to slot dates")
           #if ((dim(transition)[4]!=length(stages))|(dim(transition)[5]!=length(stages))) stop("fourth and/or fifth dimension of transiton array does not have the same length as stages vector")
         }
)

setMethod(f="getDates",
          signature = "ageClassTransition",
          definition = function(object){
            # arguments : ageClassTransition and the dates that have to be extracted from the array
            # value: slot dates value
            return(object@dates)
          })

setMethod(f="getValues",
          signature = "ageClassTransition",
          definition = function(object,dates=NULL){
            # arguments : ageClassTransition and the dates that have to be extracted from the array
            # value: ageClassTransition array with all the dates if argument dates is NULL (default) or selected dates 
            if (is.null(dates)) return(object@transition) else if (class(dates)=="Date") return(object@transition[,,as.character(dates),,]) else stop("wrong class for dates argument. It should be 'Date'")
          })

setMethod(f="mySubset",
          signature = "ageClassTransition",
          definition = function(object,Subset){
            if (class(Subset) == "Date") {
              if (Subset%in%getDates(object)) {object@transition <- getValues(object)[,,as.character(Subset),,]
                                               object@dates <- Subset
                                               } else stop("Subset is not along the dates present in ageClassTansition object") } else {
                warning("Subset is not class Date, whole ageClassTransition object is returned")
              }
            return(object)
          }
          )

#setMethod(f="transition",
#          signature = "ageClassTransition",
#          definition = function(object,dates=NULL){
#            if (is.null(dates)) return(object@transition) else return(object@transition[,,dates,,])
#          })


ageClassTransition_numeric <- function(devEnvVar,developmentRateFunction,species,stages,number_of_age_class_per_stage)
{
  mat <- matrix(NA,nrow=length(stages),ncol=2)
  if (!is.na(devEnvVar)) {    
    for (C1 in 1:(length(stages))){ # C1 <- 1
    number_of_age_class <- number_of_age_class_per_stage[stages[C1]]
    cumT <- 0 # cumT is the cumulated development rate 
    C2 <- C1
    while ((cumT<1)&(C2<=length(stages)))
      {
      devRate_v <-  vapply(X = devEnvVar,
                           FUN = developmentRateFunction,
                           species = species,
                           life_stage = stages[C2],
                           FUN.VALUE = c(1))
      T <- 1/(devRate_v*number_of_age_class)
      cumT = cumT + T
      C2 <- C2+1
      }
    mat[C1,]<-c(C2-1,(cumT-1)/T) # numéro et probabilité de la classe "inférieure"
    }
  }
mat[mat[,2]<0,2] <- 0
mat
}

#envtimeserie=Tmean; developmentRateFunction=developmentRateLogan; dates=getDates(Tmean)[1:2]; Transition=NULL;species="Busseola_fusca"

ageClassTransition <- function(envtimeserie=NULL, developmentRateFunction=NULL, stages=NULL, species = "Busseola_fusca", dates=NULL, Transition=NULL)
  # Arguments :
  # (envtimeserie, developmentRateFunction, stages, dates), or 
  # (transition, stages, dates)
{
  # Constructor of age class transition array
  # slots : 
  # Transition = array of transition : dimensions X, Y, Date, Classe d'age, Classe d'age supérieure du jour suivant, probabilité associée
  # stages
  # dates = class date
#   developmentRateLogan(getValues(Tmean),"Bf","Egg")
#   envtimeserie = Tmean; developmentRateFunction = developmentRateLogan; stages = stages; dates = dates; species = "Bf"
  if (is.null(Transition)) 
  {
    if (!any(unlist(lapply(list(envtimeserie,developmentRateFunction,stages,dates),"is.null"))))
      # if none of the other arguments is null
    {
      ### Formatting dates
      if (class(dates)=="character") dates <- as.Date(dates)
      if (class(dates)=="Date") datesnumbers <- which(getDates(envtimeserie)%in%dates) # datesnumbers is the layer numbers of the dates in the envtimeserie
      ### Initialize 
      ageclassTransition <- array(0, dim = c(dim(getValues(envtimeserie)),length(stages),2))
      # to put in a method of EcoDay
      
      vec <- 1:length(levels(as.factor(stages)))
      number_of_age_class_per_stage <- vec
      for (Stage in vec) {
        number_of_age_class_per_stage[Stage] <- sum( stages == levels(as.factor(stages))[Stage]) 
      }
      names(number_of_age_class_per_stage) <- levels(as.factor(stages))
      
      ### Fill the array for transition between substages of eggs/larvae/adult
      devEnVar <- array(as.array(getValues(envtimeserie))[,,datesnumbers],
                        dim=c(dim(getValues(envtimeserie))[1:2],length(dates)))
      Transition <- array(0,dim=c(dim(getValues(envtimeserie))[1],
                                  dim(getValues(envtimeserie))[2],
                                  length(dates),length(stages),2),
                          dimnames=list(1:24,1:24,
                                        as.character(dates),stages,c("NextDayUpperStage","AssociatedProb"))
      )
      negatif <- data.frame(X=NA,Y=NA,i_date=NA);count=1
      for (X in 1:dim(getValues(envtimeserie))[1]){ # X <- 1 
        for (Y in 1:dim(getValues(envtimeserie))[2]){ # Y <- 1
          for (i_date in 1:length(dates)){ # i_date <- 1
            Transition[X,Y,i_date,,] <- ageClassTransition_numeric(devEnVar[X,Y,i_date],developmentRateFunction,species=species,stages=stages,number_of_age_class_per_stage)
            if (any(na.omit(Transition[X,Y,i_date,,])<0)) {negatif[count,] <- c(X,Y,i_date);count=count+1}
          }
        }
      }
    } else stop("missing arguments")
  }
new("ageClassTransition",transition=Transition,stages=stages,dates=dates) #,extent(getValues(envtimeserie)),res
}

# note : we can maybe use exponential distribution to evaluate the probability distribution of age class transition for each day an deme
