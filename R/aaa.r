SG <- function(x, alpha) {

  t1 <- proc.time()

  sgp <- function(c) {

    s <- sum(x)  ##SUM(Cell_Counts)
    k <- length(x)
    b <- x - c
    a <- x + c

    ###FINDING FACTORIAL MOMENTS-TRUNCATED POISSON
    fm1 <- fm2 <- fm3 <- fm4 <- 0
    for (i in 1:k) {
      fm1[i] <- x[i]^1 * (ppois(a[i]-1, x[i]) - ppois(b[i]-2, x[i])) / (ppois(a[i], x[i]) - ppois(b[i]-1, x[i]))
      fm2[i] <- x[i]^2 * (ppois(a[i]-2, x[i]) - ppois(b[i]-3, x[i])) / (ppois(a[i], x[i]) - ppois(b[i]-1, x[i]))
      fm3[i] <- x[i]^3 * (ppois(a[i]-3, x[i]) - ppois(b[i]-4, x[i])) / (ppois(a[i], x[i]) - ppois(b[i]-1, x[i]))
      fm4[i] <- x[i]^4 * (ppois(a[i]-4, x[i]) - ppois(b[i]-5, x[i])) / (ppois(a[i], x[i]) - ppois(b[i]-1, x[i]))
    }
    ##FINDING CENTRAL MOMENTS-TRUNCATED POISSON
    m1 <- m2 <- m3 <- m4 <- m4t <- 0
    for (i in 1:k) {
      m1[i]  <- fm1[i]
      m2[i]  <- fm2[i] + fm1[i] - (fm1[i]*fm1[i])
      m3[i]  <- fm3[i] + fm2[i] * (3-(3*fm1[i])) + (fm1[i] - (3*fm1[i]*fm1[i]) + (2*fm1[i]^3))
      m4[i]  <- fm4[i] + fm3[i] * (6-(4*fm1[i])) + fm2[i]*(7-(12*fm1[i]) + (6*fm1[i]^2)) +
        fm1[i]-(4*fm1[i]^2)+(6*fm1[i]^3)-(3*fm1[i]^4)
      m4t[i] <- m4[i] - (3*m2[i]^2) #Temporary Variable for next step
    }

    s1 <- sum(m1)
    s2 <- sum(m2)
    s3 <- sum(m3)
    s4 <- sum(m4t)

    ##FINDING GAMMAS ---> EDGEWORTH EXPANSION
    g1 <- s3/(s2^(3/2))
    g2 <- s4/(s2^2)

    ##FINDING CHEBYSHEV-HERMITE POLYNOMIALS ---> EDGEWORTH EXPANSION
    z <- (s-s1)/sqrt(s2)
    z2 <- z^2
    z3 <- z^3
    z4 <- z^4
    z6 <- z^6
    poly <- 1+  g1*(z3-(3*z))/6+g2*(z4-(6*z2)+3)/24+(g1^2)*(z6-(15*z4)+(45*z2)-15)/72
    f <- poly * exp(-z2/2)/sqrt(2*pi)

    ##FINDING PROBABILITY FUNCTION BASED ON 'c'
    pc <- 0
    for (i in 1:k) pc[i] <- ppois(a[i],x[i])-ppois(b[i]-1,x[i])
    pcp <- prod(pc) #PRODUCT OF pc THAT HAS k ELEMENTS
    pps <- 1/dpois(s,s)#POISSON PROB FOR s WITH PARAMETER AS s
    rp <- pps * pcp*f / sqrt(s2)##REQUIRED PROBABILITY
    rp

  }

  proc.time()-t1
  t <- proc.time()
  y <- 0
  s <- sum(x)
  M1 <- 1
  M2 <- s
  c <- M1:M2
  M <- length(c)

  for (i in 1:M) y[i] <- round(sgp(c[i]), 4)

  j <- 1
  vc <- 0
  while(j<=M){
    if (y[j]<1-alpha && 1-alpha < y[j+1]) {
      vc <- j
    } else {
      vc <- vc
    }
    j <-  j + 1
  }

  # vc##REQUIRED VALUE OF C
  delta <- ((1-alpha)-y[vc])/(y[vc+1]-y[vc])

  ## FINDING LIMITS
  sp <- x/s #SAMPLE PROPORTION
  LL <- round(sp-(vc/s), 4) #LOWER LIMIT
  UL <- round(sp+(vc/s) + (2*delta/s), 4) #UPPER LIMIT
  LLA <- ULA <- 0
  for (r in 1:length(x)) {
    if (LL[r] < 0) LLA[r] <-  0 else LLA[r] <- LL[r]
    if (UL[r] > 1) ULA[r] <-  1 else ULA[r] <- UL[r]
  }
  diA <- ULA - LLA##FIND LENGTH OF CIs
  VOL <- round(prod(diA), 8)##PRODUCT OF LENGTH OF CIs

  data_frame(
    method = "sg",
    lower_limit = LL,
    upper_limit = UL,
    adj_ll = LLA,
    adj_ul = ULA,
    volume = VOL
  )

}


BMDU <- function(x, d, seed=1492) {

  set.seed(seed)

  k <- length(x)

  for (m in 1:k) {
    if (x[m]<0) { warning('Arguments must be non-negative integers') }
  }

  if (d>=1 && d<=k) {
    m <- l <- u <- diff <- 0
    s <- sum(x)
    s1 <- floor(k/d)
    d1 <- runif(s1,0,1)                        ###First half of the vector
    d2 <- runif(k-s1,1,2)                      ###Second half of the vector
    a <- c(d1,d2)
    p <- x+a                                   ###Prior for Dirichlet
    dr <- rdirichlet(10000, p)                 ###Posterior
    for(j in 1:k) {
      l[j] <- round(quantile(dr[,j],0.025), 4) ###Lower Limit
      u[j] <- round(quantile(dr[,j],0.975), 4) ###Upper Limit
      m[j] <- round(mean(dr[,j]), 4)           ###Point Estimate
      diff[j] <- u[j] - l[j]
    }

    data_frame(
      method = "bmdu",
      lower_limit = l,
      upper_limit = m,
      volume = prod(diff),
      mean = m
    )

  } else {
    warning('Size of the division should be less than the size of the input matrix')
    data_frame(
      method = "bmdu",
      lower_limit = l,
      upper_limit = m,
      volume = prod(diff),
      mean = m
    )
  }

}
