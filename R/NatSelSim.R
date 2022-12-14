#'@import graphics
#'@importFrom utils head
NULL

#' Simulating natural selection through time in a bi-allelic gene
#'
#' \code{NatSelSim} simulates natural selection in a bi-allelic gene through 
#' \code{NGen} generations.
#'
#' @param w11 Number giving the fitness of genotype A1A1. Values will be 
#' normalized if any genotype fitness exceeds one.
#' @param w12 Number giving the fitness of genotype A1A2. Values will be 
#' normalized if any genotype fitness exceeds one.
#' @param w22 Number giving the fitness of genotype A2A2. Values will be 
#' normalized if any genotype fitness exceeds one.
#' @param p0 Initial (time = 0) allelic frequency of A1. 
#' A2's initial allelic frequency is \code{1-p0}.
#' @param NGen Number of generation that will be simulated.
#' @param plot_type String indicating if plot should be "static" or animated. 
#' The defaut, "animateall", animate all possible pannels. 
#' Other options are "animate1", "animate3", or "animate4".
#' @param printData Logical indicating whether all simulation results should be
#' returned as a \code{data.frame}. Default value is \code{FALSE}.
#' 
#' @return A \code{data.frame} containing the number of individuals for each 
#' genotype.
#' 
#' @export NatSelSim
#' 
#' @details If any value of fitness (i.e., \code{w11}, \code{w12}, 
#' \code{w22}) is larger than one, fitness is interpreted as absolute fitness 
#' and values are re-normalized.
#' 
#' @references 
#' 
#' 
#' @author Matheus Januario, Jennifer Auler, Dan Rabosky
#' 
#' @examples
#' 
#' #using the default values (w11=1, w12=1, w22=0.9, p0=0.5, NGen=10):
#' NatSelSim()
#' 
#' # Continuing a simulation for extra time:
#' # Run the first simulation
#' sim1=NatSelSim(w11 = .4, w12 = .5, w22 = .4, p0 = 0.35, printData = TRUE)
#' 
#' # Then take the allelic frequency form the first sim:
#' new_p0 <- (sim1$AA[nrow(sim1)] + sim1$Aa[nrow(sim1)]*1/2) 
#' # and use as p0 for a second one:
#' 
#' NatSelSim(w11 = .4, w12 = .5, w22 = .4, p0 = new_p0, NGen = 20)
#' 
#' 
NatSelSim <- function(w11=1, w12=1, w22=0.9, p0=0.5, NGen=10, plot_type = "animateall", printData=FALSE){
  
  #checking input:
  if(length(plot_type)!=1 | class(plot_type) != "character" | any(!plot_type %in% c("animateall", "static", "animate1", "animate3", "animate4")))
  {
    warning("Invalid plot type. Plotting as \"animateall\"")
  }
  
  if(any(c(w11, w12, w22)>1)){
    #normalizing W to get relative fitness   
    warning("Absolute fitness will be transformed into relative fitness")
    
    w11 <- w11/max(c(w11, w12, w22))
    w12 <- w12/max(c(w11, w12, w22))
    w22 <- w22/max(c(w11, w12, w22))
  }
  
  #Make genotypes
  gen_HW0 <- data.frame(AA = p0^2, Aa = 2*p0*(1-p0), aa=(1-p0)^2)
  gen_HW <- gen_HW0 
  
  #creating table that will store the simulated genot. freqs.:
  W_gntp <- c(w11, w12, w22) #making a fitness vector
  t <- 0 #vector to store time
  p_t <- p0 #vector to store p through time
  w_t <- vector()#apply(gen_HW0 * W_gntp, 1, sum) #vector to store mean population fitness through time
  
  s <- abs(diff(c(w11, w22))) #calculating s h <- (-w12+1)/s #calculating h (!!!)
  #####
  # Now we run the simulation in time: 
  for(gen in 1:NGen){
    #multiply genotype frequencies by genotype relat. fitness:
    aux <- gen_HW[gen,] * W_gntp
    #normalize frequencies and store new genot. freq.
    aux2 <- aux/sum(aux)
    #calc mean population fitness:
    w_t <- c(w_t, round(sum(aux), digits = 15)) #get new p from normalized genotypes:
    p_sel <- p_t[length(p_t)] #p before selection
    #apply selection to:
    p_gen <- ( (p_sel^2 * w11) +
                 (p_sel*(1-p_sel)*w12) ) / w_t[length(w_t)]
    #store new p:
    p_t <- c(p_t, p_gen)
    #create next generation genotypes following HWE:
    gen_HW[gen+1,] <- c(p_gen^2, 2*(p_gen)*(1-p_gen), (1-p_gen)^2)
    #update t:
    t <- c(t, gen) 
  }
  
  plotNatSel(gen_HW = gen_HW, p_t = p_t, w_t = w_t, t = t, W_gntp = c(w11, w12, w22), plot_type = plot_type)
  
  if(printData){
    return(gen_HW)
  }
}