expectedInd <- function(parameters){
  # Fonction qui calcule le nombre d'individus attendus
  # Hypothèse : 
  # Temps de développement : réponse linéaire décroissante au Tmin
  # Carrying capacity K : nombre de larves maximales hébergées par une plante en phase foreur réponse quadratique skewed à Tmin, Tmax et rainf
  # taux de croissance r : nombre d'oeufs déposés par adulte qui survivent à la phase phylophage, réponse quadratique skewed à Rainf
  # modèle de migration des adultes : chaque jour une dispersion suivant un modèle fat tail 1 fonction de la distance
  #
  #
  #
  # Variables: 
   parameters = c(fecun=10,
                  PhyloL.surv.Rainf.median = 0.001,
                  slope.K.StembL=12000,
                  r.StembL=0.9,
                  survival=0.9,
                  disp.D.alpha=100,disp.D.beta=2)
   
#                  PhyloL.surv.Rainf.Xmax = 
#                  r.fecun.Rainf.Xmax=0.0003,r.Rainf.Xopt=0.0001,r.Rainf.Yopt=15,
#                  K.Rainf.Xmin=0,K.Rainf.Xmax=0.0003,K.Rainf.Xopt=0.0001,K.Rainf.Yopt=5,
#                  K.Tminf.Xmin=15,K.Tmin.Xmax=20,K.Tmin.Xopt=25,K.Tmin.Yopt=5,
#                  K.Tmax.Xmin=25,K.Tmax.Xmax=35,K.Tmax.Xopt=22,K.Tmax.Yopt=5,
#                  disp.D.alpha=100,disp.D.beta=2)
EnvironPhyloL <- model(varName="Rainf", Fun= precipitation_survival, stages = "PhyloL", submodel=list(median_survival_value=0.00001), supermodel=FALSE,environmental=TRUE)
NonEnvironStembL <- model(varName="StembL", Fun= proportional, stages = "StembL", submodel=list(parameters["r.StembL"]), supermodel=NA,environmental=FALSE)
survival <- model(varName="All", Fun= proportional, stages = c("Eggs","PhyloL","StembL","Pupae","Adult"), submodel=list(parameters["survival"]), supermodel=NA,environmental=FALSE)
KStembL <- model(varName="plantQ", Fun= proportional, stages = "StembL", submodel=list(parameters["slope.K.StembL"]), supermodel=NA, environmental=TRUE)
StembL <- model(varName=NA, Fun=truncate, stages="StembL", submodel=list(NonEnvironStembL,KStembL), supermodel=TRUE, environmental=TRUE) 

# initialisation
  refStack <- getDays(EnvData,1)
  
 # burn-in 
  Current <- EcoDay(list(array(0,dim=c(landDim,5*10)),
                      as.Date("2001-01-01"),getDays(EnvData,1),
                      stages=rep(c("Egg","PhyloL","StembL","Pupae","Adult"),each=10),
                      variables = getVarNames(EnvData)
                      ))  
  Day=1
  m <- migrationRateMatrix(fatTail1(distanceMatrix,alpha=parameters["disp.D.alpha"],beta=parameters["disp.D.beta"]))
  while (Day < etsDim(EnvData)[[1]][3])
  {
    if (Day<burnin_period) { Current <- myOperation(Current,1,'+',41)
                             Current <- myOperation(Current,1,'+',"PhyloL")
                             Current <- myOperation(Current,1,'+',"StembL") }
    # migration
    Current <- mySetValues(Current,
                           getMigratedMatrix(Current,"Adult",m),
                           which(getStage(Current)=="Adult")[1])
    #recruitment
    Current <- recruitment(Current,parameters["fecun"])
    #survival
    #Current <- applyModel(EnvironPhyloLCurrent)
    Current <- applyModel(EnvironPhyloL,Current)
    Current <- applyModel(StembL,Current)
    Day <- Day + 1
  }
}
  # Survival arrays eggs, phyloLarvae, and pupae (do not depend on density, only on parameters)
  
  # times to
  devRateEggs <- EnvTimeSerie(list(stack(developmentRateLogan(getValues(Tmean),"Bf","Egg")),getDates(Tmean)))
  devTimeEggs <- developmentTime(devRateEggs)
  
  # Egg laying
  
  EggLayed
  
  # Affectation des valeurs pour la migration, 
  # le temps de developpement et le temps de generation
  
  dispersionRate = .025;  dispersionDistance=300;      
  
  generationTime = ceiling(25/10);
  generationTimeSD=ceiling(3/10);    
  dvlpTime=1+ceiling(5/10);
  dvlpTimeSD=1;
  
  # generationTime = 25;
  # generationTimeSD = 3;    
  # dvlpTime= 5;
  # dvlpTimeSD=1;
  
  
  # Matrice des individus à l'intérieur des mais.
  larveSizes <- array(data = 0,
                      dim = c( nrow(EnvData2), ncol(EnvData2)),
                      dimnames = list(as.character(1:nrow(EnvData2)), colnames(EnvData2))
  )
  
  # Matrice de migration
  migrationMatrix = migrationRateMatrix(fatTail1(distMat,100,2))
  
  ind1 = which((distMat != 0) & (distMat < dispersionDistance))
  ind2 = which(distMat == 0)
  
  migrationMatrix[ind1] = dispersionRate
  migrationMatrix[ind2] = 1-dispersionRate*4
  
  # Densite de probabilite du temps de generation dans un intervalle
  generationTimeInterval <- (generationTime-generationTimeSD):(generationTime+generationTimeSD)
  generationTimeDensity <- dnorm(generationTimeInterval,generationTime,generationTimeSD)
  
  dvlpTimeInterval <- (dvlpTime-dvlpTimeSD):(dvlpTime+dvlpTimeSD)
  dvlpTimeDensity <- dnorm(dvlpTimeInterval,dvlpTime,dvlpTimeSD)
  
  # Calcul du nombre d'individus attendus en fonction des parametres
  for (i in 2:(ncol(larveSizes)-max(generationTimeInterval))) 
  {
    # Calcul des parametres K et R en fonction des parametres et de la precipitation + temperature
    R.tasmin <- conquadraticSkewed1(EnvData2[,i,"tasmin"], R.tas.Xmin, R.tas.Xmax, R.tas.Xopt, R.tas.Yopt)
    R.tasmax <- conquadraticSkewed1(EnvData2[,i,"tasmax"], R.tas.Xmin, R.tas.Xmax, R.tas.Xopt, R.tas.Yopt)
    R.pr <- conquadraticSkewed1(EnvData2[,i,"pr"], R.pr.Xmin, R.pr.Xmax, R.pr.Xopt, R.pr.Yopt)
    R <- R.tasmax*R.tasmin*R.pr
    
    K <- conquadraticSkewed1(EnvData2[,i,"pr"], K.pr.Xmin, K.pr.Xmax, K.pr.Xopt, K.pr.Yopt)  
    
    R[is.na(R)]<-0
    K[is.na(K)]<-0
    
    R[is.nan(R)]<-0
    K[is.nan(K)]<-0
    
    # Migration des adultes
    migratedAtDate = parentSizes[,(i-1)]%*%migrationMatrix
    parentSizes[,i] = parentSizes[,i] + migratedAtDate[1,]
    parentSizes[which(parentSizes[,i]<0),i] = 0
    
    # Reproduction des adultes
    nbNaissancesOld = parentSizes[,i]*R
    nbNaissances = nbNaissancesOld
    
    tmp = larveSizes[,i-1] + nbNaissancesOld + larveSizes[,i]
    ind = which(tmp >= K)
    nbNaissances[ ind ] = (K[ind] - larveSizes[ind,i-1] - larveSizes[ind,i])*((K[ind] - larveSizes[ind,i-1] - larveSizes[ind,i])>0)
    
    larveSizes[,i] = larveSizes[,i-1] + nbNaissances + larveSizes[,i]
    larveSizes[which(larveSizes[,i]<0),i] = 0
    
    # Programmation de leur eclosion en papillon
    larveSizes[,i+generationTimeInterval] =  larveSizes[,i+generationTimeInterval] - outer(nbNaissances,generationTimeDensity,"*")
    parentSizes[,i+generationTimeInterval] = parentSizes[,i+generationTimeInterval] + outer(nbNaissances,generationTimeDensity,"*")
    
    # Programmation de leur mort
    # Attention, suprression des adultes dans leur deme de naissance, ne prends pas en compte la migration, c'est pas bien...
    tempsVie = 2
    if(i+max(generationTimeInterval)+tempsVie <= dim(parentSizes)[2]){
      parentSizes[,i+tempsVie+generationTimeInterval] = parentSizes[,i+tempsVie+generationTimeInterval] - outer(nbNaissancesOld,generationTimeDensity,"*")
    } 
  }
  return(larveSizes)
}

expectedInd.1 <- function(
  K.pr.Xmin=0.5, K.pr.Xmax=10, K.pr.Xopt=4, K.pr.Yopt=20,
  R.pr.Xmin=0.5, R.pr.Xmax=10, R.pr.Xopt=4, R.pr.Yopt=10,
  R.tas.Xmin=285, R.tas.Xmax=305, R.tas.Xopt=295, R.tas.Yopt=1){
  # Fonction qui calcule le nombre d'individus attendus
  # Variables: 
  #           K.pr: parametres pour la fonction K=f(precipitation)
  #           R.pr: parametres pour la fonction R=f(precipitation)
  #           R.tas: parametres pour la fonction R=f(temperature)
  
  
  # Affectation des valeurs pour la migration, 
  # le temps de developpement et le temps de generation
  dispersionRate = .025;dispersionDistance=300;      
  
  generationTime = ceiling(25/10);
  generationTimeSD=ceiling(3/10);    
  dvlpTime=1+ceiling(5/10);
  dvlpTimeSD=1;
  
  # generationTime = 25;
  # generationTimeSD = 3;    
  # dvlpTime= 5;
  # dvlpTimeSD=1;
  
  
  # Matrice des individus à l'intérieur des mais.
  larveSizes <- array(0,dim=c(nrow(EnvData2),length(Dates)),dimnames = list(1:nrow(EnvData2),as.character(Dates)))
  
  # Matrice de migration
  migrationMatrix = Matrix(0, nrow = dim(distMat)[1], ncol = dim(distMat)[2], sparse = TRUE)
  ind1 = which((distMat != 0) & (distMat < dispersionDistance))
  ind2 = which(distMat == 0)
  
  migrationMatrix[ind1] = dispersionRate
  migrationMatrix[ind2] = 1-dispersionRate*4
  
  # Densite de probabilite du temps de generation dans un intervalle
  generationTimeInterval <- (generationTime-generationTimeSD):(generationTime+generationTimeSD)
  generationTimeDensity <- dnorm(generationTimeInterval,generationTime,generationTimeSD)
  
  dvlpTimeInterval <- (dvlpTime-dvlpTimeSD):(dvlpTime+dvlpTimeSD)
  dvlpTimeDensity <- dnorm(dvlpTimeInterval,dvlpTime,dvlpTimeSD)
  
  # Calcul du nombre d'individus attendus en fonction des parametres
  for (i in 2:(ncol(larveSizes)-max(generationTimeInterval))) 
  {
    # Calcul des parametres K et R en fonction des parametres et de la precipitation + temperature
    R.tasmin <- conquadraticSkewed1(EnvData2[,i,"tasmin"], R.tas.Xmin, R.tas.Xmax, R.tas.Xopt, R.tas.Yopt)
    R.tasmax <- conquadraticSkewed1(EnvData2[,i,"tasmax"], R.tas.Xmin, R.tas.Xmax, R.tas.Xopt, R.tas.Yopt)
    R.pr <- conquadraticSkewed1(EnvData2[,i,"pr"], R.pr.Xmin, R.pr.Xmax, R.pr.Xopt, R.pr.Yopt)
    R <- R.tasmax*R.tasmin*R.pr
    
    K <- conquadraticSkewed1(EnvData2[,i,"pr"], K.pr.Xmin, K.pr.Xmax, K.pr.Xopt, K.pr.Yopt)  
    
    R[is.na(R)]<-0
    K[is.na(K)]<-0
    
    R[is.nan(R)]<-0
    K[is.nan(K)]<-0
    
    # Migration des adultes
    migratedAtDate = parentSizes[,(i-1)]%*%migrationMatrix
    parentSizes[,i] = parentSizes[,i] + migratedAtDate[1,]
    parentSizes[which(parentSizes[,i]<0),i] = 0
    
    # Reproduction des adultes
    nbNaissancesOld = parentSizes[,i]*R
    nbNaissances = nbNaissancesOld
    
    tmp = larveSizes[,i-1] + nbNaissancesOld + larveSizes[,i]
    ind = which(tmp >= K)
    nbNaissances[ ind ] = (K[ind] - larveSizes[ind,i-1] - larveSizes[ind,i])*((K[ind] - larveSizes[ind,i-1] - larveSizes[ind,i])>0)
    
    larveSizes[,i] = larveSizes[,i-1] + nbNaissances + larveSizes[,i]
    larveSizes[which(larveSizes[,i]<0),i] = 0
    
    # Programmation de leur eclosion en papillon
    larveSizes[,i+generationTimeInterval] =  larveSizes[,i+generationTimeInterval] - outer(nbNaissances,generationTimeDensity,"*")
    parentSizes[,i+generationTimeInterval] = parentSizes[,i+generationTimeInterval] + outer(nbNaissances,generationTimeDensity,"*")
    
    # Programmation de leur mort
    # Attention, suprression des adultes dans leur deme de naissance, ne prends pas en compte la migration, c'est pas bien...
    tempsVie = 2
    if(i+max(generationTimeInterval)+tempsVie <= dim(parentSizes)[2]){
      parentSizes[,i+tempsVie+generationTimeInterval] = parentSizes[,i+tempsVie+generationTimeInterval] - outer(nbNaissancesOld,generationTimeDensity,"*")
    } 
  }
  return(larveSizes)
}

