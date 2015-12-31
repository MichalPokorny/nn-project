library(ggplot2)
library(class)
library(doBy)
library(Hmisc)
library(DMwR)

normalize <- function(vec) {
  if (max(vec) == (min(vec)))
    return (vec * 0 + max(vec))
  return ((vec - min(vec)) / (max(vec) - min(vec)))
}

data <- read.csv("../feature_extraction/samples.csv");
data$user_id <- as.factor(data$user_id)
data <- data[complete.cases(data),]

data <- subset(data, select = -c(sentence_id, overlaps_2, overlaps_3, overlaps_4))

k <- 98

lev <- levels(data$user_id)
lev <- lev[3:length(lev)] # filter user_000 and user_001

reps <- 1000

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
  
  model <- glm(is_user ~ . - is_user - user_id,
               data = train,
               family = binomial(link="logit"))
  #options(warn=-1)
  pred <- predict.glm(model, test, type="response")
  allFloats = list(pred, allFloats)
  allTrues = list(test$is_user, allTrues)
}

allFloats = as.vector(unlist(allFloats))
allTrues = as.vector(unlist(allTrues))

PRcurve(allFloats, allTrues)

# plotting ROC
pred <- prediction(allFloats, allTrues)
roc.perf <- performance(pred, measure = "tpr", x.measure = "fpr")
plot(roc.perf)
abline(a=0, b=1)