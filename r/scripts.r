library(ggplot2)


data <- read.csv("../feature_extraction/samples.csv");
data$user_id = as.factor(data$user_id)

sz <- nrow(data)
perm <- sample(1:sz)
data.train <- data[perm[1:round(0.8*sz)],]
data.test <- data[perm[(round(0.8*sz)+1):sz],]

m.log <- glm(user_id ~ speed,
             data = data.train,
             family = binomial(link="logit"))

m.pred <- predict.glm(m.log, data.test, type="response")
tb <- table(data.train$user_id, m.pred)

g <- ggplot()
g <- g + geom_point(data = data, aes(x = speed, y = overlaps_1))
print(g)

