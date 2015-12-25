library(nnet)

normalize <- function(vec) {
  if (max(vec) == (min(vec)))
    return (vec * 0 + max(vec))
  return ((vec - min(vec)) / (max(vec) - min(vec)))
}

iters <- 1
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
  
  model <- multinom(user_id ~ speed + overlaps_0 + overlaps_1 + key_press_ms_avg
                    + key_press_ms_sd + space_length_ms_avg + space_length_ms_sd
                    + backspaces_deletes,
                    data = train,
                    maxit = 50000,
                    model = T)
  #mdata <- mlogit.data(train, choice = "choice", shape = "long")
  
  pred <- predict(model, type="class", newdata = test)
  accs[i] <- sum(pred == test$user_id) / length(pred)
}

#mlogit(user_id ~ speed, data = mdata)