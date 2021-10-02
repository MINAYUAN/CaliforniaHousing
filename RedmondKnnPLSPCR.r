library(pls)
library(caret)
library(FNN)

LA_Housing <- read.csv("Final_Housing_Updated3.csv")
colnames(LA_Housing)
LA_Housing <- LA_Housing[LA_Housing$PROPERTY.TYPE == "Single Family Residential",]
#LA_Housing <- LA_Housing[!duplicated(LA_Housing),]
LA_Housing$LONG_LAT <- LA_Housing$LATITUDE * LA_Housing$LONGITUDE
LA_Housing$SQ_LOT <- as.double(LA_Housing$SQUARE.FEET) * as.double(LA_Housing$LOT.SIZE)
feb_first <- as.Date("2020-02-01")
train <- LA_Housing[LA_Housing$Date <= feb_first,]
test <- LA_Housing[LA_Housing$Date > feb_first,]


# PLS 
pcr.fit = pcr(PRICE ~ ZIP + BEDS + BATHS + SQUARE.FEET + Age + LOT.SIZE + LATITUDE * LONGITUDE + numCrimes+ AvgMortgageInt*AvgTotalIncome*AvgRealEstateTax, data = train, scale = TRUE, validation = "CV")
summary(pcr.fit)
pcr.fit = pcr(PRICE ~ ZIP + PROPERTY.TYPE + BEDS + BATHS + SQUARE.FEET + LOT.SIZE + Age + LATITUDE * LONGITUDE + numCrimes, data = train, scale = TRUE, validation = "CV")
#pcr.fit = pcr(PRICE ~ ZIP + PROPERTY.TYPE + BEDS + BATHS + SQUARE.FEET + LOT.SIZE + Age, data = train, scale = TRUE, validation = "CV")
pls.fit = plsr (PRICE ~ ZIP + PROPERTY.TYPE + BEDS + BATHS + SQUARE.FEET + LOT.SIZE + Age + LATITUDE*LONGITUDE + numCrimes, data = train, scale = TRUE, validation = "CV")


trainMSE <- mean((predict(pcr.fit, newdata = train, ncomp = 17) - train$PRICE)^2)
trainMSE
sqrt(trainMSE)

summary(pls.fit)
trainMSE <- mean((predict(pls.fit, newdata = train, ncomp = 14) - train$PRICE)^2)
trainMSE
sqrt(trainMSE)

for(i in 1:nrow(data)) {
  train <- data[-(i),] 
  test <- data[i,]
  model1 <- fitModel()
  predict(model1, test)
}

#knnRegression <- train(PRICE ~ ZIP + PROPERTY.TYPE + BEDS + BATHS + SQUARE.FEET + LATITUDE + LONGITUDE, data = train, method = "knn", trControl = trainControl("cv", number = 2), preProcess = c("center","scale"), tuneLength = 5)
+
  AvgMortgageInt*AvgTotalIncome * AvgRealEstateTax
#### KNN Regression
knnRegression <- train(PRICE ~ ZIP + BEDS + BATHS + SQUARE.FEET + LOT.SIZE + Age  + LATITUDE * LONGITUDE + numCrimes , data = train, method = "knn",
                       trControl = trainControl("LOOCV"), preProcess = c("center","scale"), tuneLength = 9)
knnRegression$results #best is 7
prediction <- predict(knnRegression,train)
RMSE(prediction,train$PRICE)
plot(knnRegression)



model2 <- train(PRICE ~ ZIP + BEDS + BATHS + SQUARE.FEET*LOT.SIZE + Age  + LATITUDE * LONGITUDE + numCrimes , data = train, method = "knn",
                trControl = trainControl("cv", number = 5), preProcess = c("center","scale"), tuneLength = 9)
model2$results
RMSE(predict(model2,train),train$PRICE)



model3 <- train(PRICE ~ ZIP + BEDS + BATHS + SQUARE.FEET + LOT.SIZE + Age  + LATITUDE * LONGITUDE + numCrimes , data = train, method = "knn",
                trControl = trainControl("cv", number = 10), preProcess = c("center","scale"), tuneLength = 5)
model3$results
RMSE(predict(model3,train), train$PRICE)


model4 <- train(PRICE ~ ZIP + BEDS + BATHS + SQUARE.FEET + LOT.SIZE + Age  + LATITUDE * LONGITUDE + numCrimes + PrcRank, data = train, method = "knn",
                trControl = trainControl("cv", number = 5), preProcess = c("center","scale"), tuneLength = 9)
model4$results
RMSE(predict(model4,train),train$PRICE)


### Cross Validation
rmseFun <- function(predicted,y){
  return(sqrt(mean((predicted - y)^2)))
}
numK <- 2:15
rmseList = rep(list(numeric(nrow(train))),length(numK))

knnDF <- as.data.frame(scale(train[c("ZIP","BEDS","BATHS","SQUARE.FEET","SQ_LOT","Age","LATITUDE","LONGITUDE","LOT.SIZE","LONG_LAT", "numCrimes")]))
#saveRmse <- rep(list(numeric(length(numK))),length(numK)
for(i in 1:length(numK)) {
  for(k in 1:nrow(train)) {
    model <- knn.reg(train = knnDF[-k,],
                     test = knnDF[k,],
                     y = train[-k,]$PRICE, k = numK[i])
    rmseList[[i]][k] <- rmseFun(model$pred,temp2$PRICE)
  }
}


testPrediction <- predict(knnRegression,test)
RMSE(test)
#sqrt(mean((predict(knnRegression, newdata = train) - train$PRICE)^2))

# Final result, pick knn = 7
knnReg7 <- knn.reg(train = scale(train[c("ZIP","BEDS","BATHS","SQUARE.FEET","SQ_LOT","Age","LATITUDE","LONGITUDE","LOT.SIZE","LONG_LAT", "numCrimes")]),
                   test = scale(train[c("ZIP","BEDS","BATHS","SQUARE.FEET","SQ_LOT","Age","LATITUDE","LONGITUDE","LOT.SIZE","LONG_LAT", "numCrimes")]),
                   y = train$PRICE, k = 7)
sqrt(mean((knnReg7$pred - train$PRICE)^2))

### Average Error per Zip Code ###
train$knn7Pred <- knnReg7$pred
train$Error <- train$knn7Pred - train$PRICE
train$Pct_Error <- knnReg7$pred / train$PRICE - 1

# Analyzing the percentage error. Removing the top .005 outliers.
train <- train[train$Pct_Error <= quantile(train$Pct_Error,.995),]
train$AbsPct_Err <- abs(train$Pct_Error)
hist(train$Pct_Error, breaks = 50)


ZipCodes <- unique(train$ZIP)
for(i in ZipCodes) {
  train$UpperCI <- train$knn7Pred * (1 +  quantile(train[train$ZIP == i,]$Pct_Error,.95))
  train$LowerCI <- train$knn7Pred * (1 + quantile(train[train$ZIP == i,]$Pct_Error,.05))
}
train$Compare <- train$PRICE
#######

# for(i in ZipCodes) {
#   if(nrow(train[train$ZIP == i,]) == 1) {
#     print(i)
#   }
# }

output <- write.csv(train,"CI_7knn.csv", row.names = FALSE)
