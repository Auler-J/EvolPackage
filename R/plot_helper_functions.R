#' @import withr
#' @import graphics
NULL

#plot = animate not working
#old par restoration is resetting par defaut, not old par

#' Plot WFDriftSim output
#'
#' @param p_through_time Matrix with nGens collums and nSim lines
#' @param plot_type String. Options are "static" or "animate"
#'
#' @return A static or animated plot of populations under genetic drift through time
#' @export plotWFDrift
#'
#' @examples
#' store_p = WFDriftSim(Ne = 5, nGens = 10, p0=.2, nSim=5, plot = "none", printData = TRUE)
#' plotWFDrift(store_p, "static")
plotWFDrift = function(p_through_time, plot_type = plot){
  
  if(plot_type == "none")  {
    warning("plotWFDrift argument plot can only be \"static\" or \"animate\"")
    return(NULL)
  }
  nGens = dim(p_through_time)[2]-1
  nSim = dim(p_through_time)[1]
  
  time = 1:((nGens)+1)
  cols=grDevices::rainbow(nSim)
  
  dev.new()
  opar =  par(mar = (c(5, 4, 4, 0) + 0.1))
  defer(par(opar))
  layout(matrix(c(1,2), ncol = 2), widths=c(8, 2))
  
  plot(NA, xlim=c(0,nGens), ylim=c(0,1),
       ylab="Allelic frequency", xlab="Generation",frame.plot=F)
  
  if(plot_type == "animate"){
    
    # setting animation time:
    if(nGens < 20&nSim < 20){
      animation_time = 0.1
    }else{
      animation_time = 0.05
    }
    
    for(j in (time[-length(time)])){
      for(i in 1:nSim){
        segments(x0 = time[(j)]-1,x1 = time[j+1]-1, 
                 y0= p_through_time[i, (j)], 
                 y1 = p_through_time[i, (j+1)],
                 col=cols[i])
      }
      Sys.sleep(animation_time)  
    }
    Sys.sleep(1)
    par(mar = c(5, 0, 4, 2) + 0.1)
    auxhist = hist(p_through_time[,nGens+1], breaks = seq(0,1, by=0.05), plot = FALSE)
    barplot(auxhist$counts, axes = TRUE, space = 0, horiz=TRUE, xlab= "Counts", ylab=NULL, border = NA, col = "black")
    #dev.off()
  } 
  
  if(plot_type=="static"){
    for(i in 1:nSim){
      graphics::lines(x = 0:(nGens), y = p_through_time[i,], col=cols[i])
    }
    #hist
    par(mar = c(5, 0, 4, 2) + 0.1)
    auxhist = hist(p_through_time[,nGens+1], breaks = seq(0,1, by=0.05), plot = FALSE)
    barplot(auxhist$counts, axes = TRUE, space = 0, horiz=TRUE, xlab= "Counts", ylab=NULL, border = NA, col = "black")
  }
}

####################################
# w11 = .4; w12 = .5; w22 = .4; p0 = 0.35; printData = TRUE;NGen = 10

#' Plot NatSelSim output
#'
#' @param gen_HW Dataframe with A1A1, A1A2 and A2A2 genotypic 
#' frequencies in each generation (nrows = NGen)
#' @param p_t Allelic frequency through time
#' @param w_t Mean population fitness through time
#' @param t time
#' @param W_gntp Initial genotypic fitness
#' @param plot_type String indicating if plot should be "static" or animated. 
#' The defaut, "animateall", animate all possible pannels. 
#' Other options are "animate1", "animate3", or "animate4".
#'
#' @return Plot of NatSelSim's output
#' @export plotNatSel
plotNatSel = function(gen_HW = gen_HW, p_t = p_t, w_t = w_t, t = t, W_gntp = c(w11, w12, w22), plot_type = "animateall"){
  
  if(plot_type == "animateall"){
    plot_type = c("animate1", "animate2", "animate3", "animate4")
  }
  
  # user input on simulations
  w11 = W_gntp[1]
  w12 = W_gntp[2]
  w22 = W_gntp[3]
  p0 = p_t[1]
  
  #final states of simulation:
  p_end <- p_t[length(p_t)]
  p0_prime <- ( (p0^2 * w11) + (p0*(1-p0)*w12) ) / w_t[1] 
  pend_prime <- ( (p_end^2 * w11) +(p_end*(1-p_end)*w12) ) / w_t[length(w_t)]
  
  delta_p0 <- p0_prime - p0 
  delta_p_end <- pend_prime - p_end # end of simulation in time #####
  
  #####
  # Now we will estimate the behavior of this system under different values of p
  # creating vector with many values of p:
  p <- seq(0,1, by=0.01) #values of p
  #genotype as a function of p:
  gntp_p <- data.frame(gntp11=p^2, gntp12=2*p*(1-p), gntp22=(1-p)^2)
  
  #auxiliary data frame with the fitness for each genotype
  w_aux <- data.frame(W11=rep(W_gntp[1], times=length(p)), W12=rep(W_gntp[2], times=length(p)), W22=rep(W_gntp[3], times=length(p)))
  #mean fitness as a function of p
  w_p <- apply(gntp_p * w_aux, 1, sum)
  #This is just an auxiliary dataframe containig a weight.
  # Basically, it stores the "contribution" of each genotype # to "p". 
  # If this still seems too abstract, call your GSI 
  a_aux <- data.frame(W11=rep(1, times=length(p)),
                      W12=rep(0.5, times=length(p)), W22=rep(0, times=length(p)))
  #Delta p as a function of p:
  # apply selection to HWE genotypes, then multiply by # the weight just created:
  new_p_aux <- (gntp_p * w_aux* a_aux)
  
  #normalize by mean fitness:
  p_prime <- ((new_p_aux[,1]+new_p_aux[,2])/w_p)
  # calculate diff between p pre and post selection: 
  delta_p <- p_prime-p
  
  
  ######################
  #Plotting all panels##
  ######################
  
  dev.new()
  par(mfrow=c(2,2))
  
  ################# pannel 1
  #Difference in p as a function of p:
  if("animate1" %in% plot_type){
    Sys.sleep(0.1)
    plot(x=p, y=delta_p, type="l", lwd=4, col="blue",
         ylim=c(min(c(0-(.1*max(delta_p)), delta_p)), max(c(0, 1.1*delta_p))),
         xlab="p", ylab=expression(Delta * "p"),
         main="Relative allele frequency change", frame.plot = F, 
         xlim = c(-0.05, 1.05))
    abline(v=p_t[1], col="red", lty=3, lwd = 2)
    abline(h=0, col="black", lty=2)
    
    colss=rep(rgb(red = 1,green = 0,blue = 0, alpha = 0.15), times=length(p_t)+2)
    
    for(time in 2:length(p_t)){
      Sys.sleep(0.1)
      abline(h=0, col="black", lty=2)
      abline(v=p_t[time], col=colss[time], lty=3, lwd = 2)
      #abline(v=p_t[time-1], col="white", lty=1, lwd = 2)
      lines(x=p, y=delta_p, type="l", lwd=4, col="blue")
    }
    abline(v=p0, col="red", lty=3, lwd = 2)
    abline(v=p_t[length(p_t)], col="red", lty=3, lwd = 2)
    text(x=c(p0-0.05, p_end+0.075),y=c(delta_p0, delta_p_end),
         labels=c("p0","p_end"), col="red", cex=0.7)
    
  }else{
    
    colss=rep(rgb(red = 1,green = 0,blue = 0, alpha = 0.15), times=length(p_t)+2)
    
    plot(x=p, y=delta_p, type="l", lwd=4, col="blue", 
         ylim=c(min(c(0-(.1*max(delta_p)), delta_p)), max(c(0, delta_p*1.1))), 
         xlab="p", ylab=expression(Delta * "p"),
         main="Relative allele frequency change", frame.plot = F)
    
    #now just adding some extra info:
    # zero change in fitness line:
    abline(h=0, col="black", lty=2)
    abline(v=p_t, col=colss, lty=2)
    #adding simulation???s initial/final allele freq 
    abline(v=c(p0, p_end), col="red", lty=3, lwd = 2)
    text(x=c(p0-0.05, p_end+0.05),y=c(delta_p0, delta_p_end),
         labels=c("p0","p_end"), col="red", cex=0.7)
  }
  
  
  ############### pannel 2
  #Mean fitness as a function of p:
  if("animate2" %in% plot_type){Sys.sleep(0.1)}
  
  plot(x=p, y=w_p, type="l", lwd=3, xlab="p",
       ylab="Mean population fitness", col="red",
       ylim=c(min(c(w_t, w11, w12, w22)*0.8), max(c(w_t, w11, w12, w22))),
       frame.plot = F, main="Adaptive landscape")
  points(x=c(0,0.5,1),
         y=c(w22, w12, w11), pch=16, col="blue", cex=1.5)
  text(x=c(0.05,0.55,0.95)+0.01,y=c(w22, w12, w11)-0.02, pch=16, col="blue", 
       cex=1, labels = c("w22", "w12", "w11"), srt=-20)
  
  
  ############### pannel 3
  #Mean fitness as a function of time:
  if("animate3" %in% plot_type){
    Sys.sleep(0.1)
    plot(NA, xlim=c(0,length(t)), ylim=c(range(w_t)), frame.plot = F,
         ylab="Mean population fitness", xlab="Time", col="red",
         lty=6, main="Mean fitness through time")
    
    for(i in 2:length(t)){
      segments(x0 = t[(i-1)],x1 = t[i], 
               y0= w_t[(i-1)],
               y1 = w_t[i],
               col="red",
               lty = 2, lwd=2)
      Sys.sleep(0.1)  
    }
    
  }else{
    plot(x=t, y=w_t, type="l", lwd=3, frame.plot = F,
         ylab="Mean population fitness", xlab="Time", col="red",
         lty=6, main="Mean fitness through time")
  }
  
  ############### pannel 4
  #Genotype frequencies through time:
  
  if("animate4" %in% plot_type){
    Sys.sleep(0.1)
    par(las =1)
    plot(NA, xlim=c(0,length(t)), xlab="Time", 
         frame.plot = F, main="Genotypic frequency through time",
         ylab="Genotypic Frequency", ylim=c(0,1.1))
    for(i in 2:length(t)){
      segments(x0 = t[i-1], x1 = t[i], y0 = gen_HW[i-1,1],y1 = gen_HW[i,1], col = "black", lwd=3, lty=2)
      segments(x0 = t[i-1], x1 = t[i], y0 = gen_HW[i-1,2],y1 = gen_HW[i,2], col = "grey60", lwd=3, lty=2)
      segments(x0 = t[i-1], x1 = t[i], y0 = gen_HW[i-1,3],y1 = gen_HW[i,3], col = "grey80", lwd=3, lty=2)
      Sys.sleep(0.1)
    }
    mtext(text = c("A1A1", "A1A2", "A2A2"), side = 4, at = gen_HW[nrow(gen_HW),], col = c("black", "grey60", "grey80"), adj = 1, cex = 0.8)
  }else{
    par(las =1)
    plot(x=t, y=gen_HW[,1], type="l", lwd=3, xlab="Time", 
         frame.plot = F, main="Genotypic frequency through time",
         ylab="Genotypic Frequency", ylim=c(0,1.1))
    lines(x=t, y=gen_HW[,2], col="grey60", lwd=3) 
    lines(x=t, y=gen_HW[,3], col="grey80", lwd=3, lty=2) 
    abline(h=c(1,0), lty=3, cex=0.55)
    mtext(text = c("A1A1", "A1A2", "A2A2"), side = 4, at = gen_HW[nrow(gen_HW),], col = c("black", "grey60", "grey80"), adj = 0, cex = 0.8)
  }
  par(mfrow=c(1,1))
}

