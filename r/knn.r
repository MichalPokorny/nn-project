library(ggplot2)
library(class)

#extract_id <- function(x) as.integer(substr(x,6,1000))

data <- read.csv("../feature_extraction/samples.csv");
data$user_id <- as.factor(data$user_id)
data <- data[complete.cases(data),]
reps <- 10
knum <- 200
accs <- rep(0, knum)

for (rep in 1:reps) {
  print(rep)
  
  sz <- nrow(data)
  perm <- sample(1:sz)
  train <- data[perm[1:round(0.8*sz)],]
  test <- data[perm[(round(0.8*sz)+1):sz],]
  rownames(test) <- NULL
  rownames(train) <- NULL
  
  # g <- ggplot()
  # g <- g + geom_point(data = data, aes(x = user_id, y = space_length_ms_avg))
  # print(g)
  
  train.knn <- subset(train, select=-c(user_id, sentence_id))
  test.knn <- subset(test, select=-c(user_id, sentence_id))
  train.true <- subset(train, select=c(user_id))
  test.true <- subset(test, select=c(user_id))
  
  train.true <- as.factor(train.true[[1]])
  test.true <- as.vector(test.true[[1]])
  
  for (k in 1:knum) {
    knn.res <- knn(train.knn, test.knn, train.true, k = k)
    acc <- sum(knn.res == test.true) / length(test.true)
    accs[k] <- accs[k] + acc
    #print(acc)
  }
}

accs <- accs / reps

theme_set(theme_bw(15))
g <- ggplot() + geom_line(aes(x=1:length(accs),y=accs))
g <- g + xlab("K") + ylab("Accuracy")
print(g)

