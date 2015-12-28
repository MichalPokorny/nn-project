library(ggplot2)
library(class)
library(doBy)
library(Hmisc)
library(DMwR)


data <- read.csv("../feature_extraction/samples.csv");
data$user_id <- as.factor(data$user_id)
data <- data[complete.cases(data),]

k <- 98

lev <- levels(data$user_id)
lev <- lev[3:length(lev)] # filter user_000 and user_001

reps <- 10000

# floating point prediction
allFloats <- NULL
allTrues <- NULL

for (rep in 1:reps) {
  print(rep)
  
  user <- sample(lev, 1)
  #user <- lev[4]
  #print(user)
  
  data$is_user <- data$user_id == user
  data$is_user[data$is_user] <- 1
  data$is_user[!data$is_user] <- 0
  
  goodIx <- (1:(nrow(data)))[data$is_user == 1]
  badIx <- (1:(nrow(data)))[data$is_user == 0]
  goodIx <- sample(goodIx)
  badIx <- sample(badIx)
  gsz <- length(goodIx)
  bsz <- length(badIx)
  
  train <- rbind(data[goodIx[1:round(0.8*gsz)],], data[badIx[1:round(0.8*bsz)],])
  test <- rbind(data[goodIx[(round(0.8*gsz)+1):gsz],], data[badIx[(round(0.8*bsz)+1):bsz],])
  
  rownames(test) <- NULL
  rownames(train) <- NULL
  
  # g <- ggplot()
  # g <- g + geom_point(data = data, aes(x = user_id, y = space_length_ms_avg))
  # print(g)
  
  train.knn <- subset(train, select=-c(user_id, sentence_id, is_user))
  test.knn <- subset(test, select=-c(user_id, sentence_id, is_user))
  train.true <- subset(train, select=c(is_user))
  test.true <- subset(test, select=c(is_user))
  
  train.true <- as.factor(train.true[[1]])
  test.true <- as.vector(test.true[[1]])
  
  knn.res <- knn(train.knn, test.knn, train.true, k = k, prob = T)
  prob <- attributes(knn.res)["prob"]
  prob <- as.vector(unlist(prob))
  
  knn.float <- as.numeric(as.vector(knn.res))
  knn.float[knn.res == 1] <- prob[knn.res == 1]
  knn.float[knn.res == 0] <- 1 - prob[knn.res == 0]
  
  allFloats <- list(allFloats, knn.float)
  allTrues <- list(allTrues, test.true)
  #tb <- tb + table(knn.res, test.true)
}

allFloats <- as.vector(unlist(allFloats))
allTrues <- as.vector(unlist(allTrues))

p <- PRcurve(allFloats, allTrues)