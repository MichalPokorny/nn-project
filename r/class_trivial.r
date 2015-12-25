iters <- 1000
accs <- rep(0, iters)

data <- read.csv("../feature_extraction/samples.csv");
data$user_id <- as.factor(data$user_id)
data <- data[complete.cases(data),]

# NORMALIZE DATA
for (i in 3:ncol(data)) {
  data[,i] <- normalize(data[,i])
}

for (i in 1:iters) {
  print(sprintf("Iter %d",i))
  # SPLIT INTO TRAINING AND TEST
  sz <- nrow(data)
  perm <- sample(1:sz)
  train <- data[perm[1:round(0.8*sz)],]
  test <- data[perm[(round(0.8*sz)+1):sz],]
  
  model <- names(sort(table(train$user_id),decreasing=TRUE))[1]
  
  pred <- rep(model, nrow(test))
  accs[i] <- sum(pred == test$user_id) / length(pred)
}