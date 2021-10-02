library(caret) # Huge machine learning library for the train() function
library(FNN) # KNN.Reg() Function
library(fitdistrplus) # Distribution Fit Plots descdist() function
library(psych) # describe() Func

LA_Housing <- read.csv("Final_Housing_Updated3.csv")
colnames(LA_Housing)
LA_Housing <- LA_Housing[LA_Housing$PROPERTY.TYPE == "Single Family Residential",]
LA_Housing <- LA_Housing[LA_Housing$PRICE <= quantile(LA_Housing$PRICE,.99),]
#LA_Housing <- LA_Housing[!duplicated(LA_Housing),]
LA_Housing$LONG_LAT <- LA_Housing$LATITUDE * LA_Housing$LONGITUDE
LA_Housing$SQ_LOT <- as.double(LA_Housing$SQUARE.FEET) * as.double(LA_Housing$LOT.SIZE)
feb_first <- as.Date("2020-02-01")
train <- LA_Housing[LA_Housing$Date <= feb_first,]
test <- LA_Housing[LA_Housing$Date > feb_first,]

#### KNN Regression
knnRegression <- train(PRICE ~ ZIP + BEDS + BATHS + SQUARE.FEET * LOT.SIZE + Age  + LATITUDE * LONGITUDE + numCrimes , data = train, method = "knn",
                       trControl = trainControl("cv", number = 10), preProcess = c("center","scale"), tuneLength = 9)
knnRegression$results
prediction <- predict(knnRegression,train)
bestRMSE <- RMSE(prediction,train$PRICE)
bestRMSE
knnRegression$finalModel # The final Model
plot(knnRegression) # The plot of K to use.

# Trying another model
model3 <- train(PRICE ~ ZIP + BEDS + BATHS + SQUARE.FEET + LOT.SIZE + Age  + LATITUDE * LONGITUDE + numCrimes , data = train, method = "knn",
                trControl = trainControl("cv", number = 10), preProcess = c("center","scale"), tuneLength = 5) # No interaction between sq.ft & lot.size
model3$results
RMSE(predict(model3,train), train$PRICE)

# model4 <- train(PRICE ~ ZIP + BEDS + BATHS + SQUARE.FEET + LOT.SIZE + Age  + LATITUDE * LONGITUDE + numCrimes + PrcRank, data = train, method = "knn",
#                 trControl = trainControl("cv", number = 5), preProcess = c("center","scale"), tuneLength = 9)
# model4$results
# RMSE(predict(model4,train),train$PRICE)
#########

### Manual Cross Validation
rmseFun <- function(predicted,y){
  return(sqrt(mean((predicted - y)^2)))
}
numK <- 3:17
rmseList = rep(list(numeric(nrow(train))),length(numK))

### LOOCV - This will take 4+ hours to run according to your laptop speed.
# Needs to scale the data because units differs between variables. The Sq_ft distance is squared but beds and baths add little distances.
knnDF <- as.data.frame(scale(train[c("ZIP","BEDS","BATHS","SQUARE.FEET","SQ_LOT","Age","LATITUDE","LONGITUDE","LOT.SIZE","LONG_LAT", "numCrimes")]))
for(i in 1:length(numK)) {
  for(k in 1:nrow(train)) {
    model <- knn.reg(train = knnDF[-k,], # Everything but one training
                     test = knnDF[k,], # Test just one
                     y = train[-k,]$PRICE, k = numK[i])
    rmseList[[i]][k] <- rmseFun(model$pred,train[k,]$PRICE)
  }
}
rmseK <- numeric(length(numK))
for(i in 1:length(rmseList)) {
  rmseK[i] <- sqrt(mean(rmseList[[i]]^2))
}

numK[which.min(rmseK)] # Best K to use
rmseK[which.min(rmseK)] # lowest RMSE for that best K.
plot(numK, rmseK, xlab = "K", ylab = "RMSE", type = "b", main = "RMSE vs. K LOOCV", lwd = 1)
points(numK[which.min(rmseK)],rmseK[which.min(rmseK)], col = "red", pch = 16)
#####

# Another package to run KNN instead of using caret. Caret cross-validates weird.
# Final result, pick knn = 14 because of KNN
# Training KNN
knnReg14train <- knn.reg(train = scale(train[c("ZIP","BEDS","BATHS","SQUARE.FEET","SQ_LOT","Age","LATITUDE","LONGITUDE","LOT.SIZE","LONG_LAT", "numCrimes")]),
                         test = scale(train[c("ZIP","BEDS","BATHS","SQUARE.FEET","SQ_LOT","Age","LATITUDE","LONGITUDE","LOT.SIZE","LONG_LAT", "numCrimes")]),
                         y = train$PRICE, k = 14)
sqrt(mean((knnReg14train$pred - train$PRICE)^2))

### Average Error per Zip Code ###
train$knn14Pred <- knnReg14train$pred
train$Error <- train$knn14Pred - train$PRICE
train$Pct_Error <- train$knn14Pred / train$PRICE - 1
train$AbsPct_Err <- abs(train$Pct_Error)
#descdist(train$Pct_Error, boot = nrow(train)) # This will take 30 minutes to run.
summary(train$Pct_Error)

plot(train$Error, ylab = "Residuals", main = "14-NN Residual Plot")
hist(train$Pct_Error, breaks = 50, xlab = "Percentage Error", main = "Histogram of Percentage Error")
describe(train$Pct_Error)

# Analyzing the percentage error. Removing the top .1% outliers.
describe(train[train$Pct_Error <= quantile(train$Pct_Error,.999),]$Pct_Error)
hist(train[train$Pct_Error <= quantile(train$Pct_Error,.999),]$Pct_Error,breaks = 50, xlab = "Percentage Eror", main = "Histogram (removed .1% outlier)")
boxplot(train[train$Pct_Error <= quantile(train$Pct_Error,.999),]$Pct_Error, xlab = "Residual", ylab = "Percentage Error", main = "Boxplot (removed .1% of Outlier)")

ZipCodes <- unique(train$ZIP)
train$UpperCI <- numeric(nrow(train))
train$LowerCI <- numeric(nrow(train))
for(i in ZipCodes) { # 90% confidence interval by zipcodes by buckets.
  train[train$ZIP == i,]$UpperCI <- train[train$ZIP == i,]$knn14Pred * (1 +  quantile(train[train$ZIP == i,]$Pct_Error,.95))
  train[train$ZIP == i,]$LowerCI <- train[train$ZIP == i,]$knn14Pred * (1 + quantile(train[train$ZIP == i,]$Pct_Error,.05))
}

#train <- train[,-c(12,13,18:24,26)] # Remove the extraneous columns
#output <- write.csv(train,"CI_14knn.csv", row.names = FALSE)
#######

## After February 1st 2020, Use KNN 14 because of LOOCV on training
knnReg14test <- knn.reg(train = scale(train[c("ZIP","BEDS","BATHS","SQUARE.FEET","SQ_LOT","Age","LATITUDE","LONGITUDE","LOT.SIZE","LONG_LAT", "numCrimes")]),
                        test = scale(test[c("ZIP","BEDS","BATHS","SQUARE.FEET","SQ_LOT","Age","LATITUDE","LONGITUDE","LOT.SIZE","LONG_LAT", "numCrimes")]),
                        y = train$PRICE, k = 14)
sqrt(mean((knnReg14test$pred - test$PRICE)^2))

test$knn14Pred <- knnReg14test$pred
test$Error <- test$knn14Pred - test$PRICE
test$Pct_Error <- test$knn14Pred / test$PRICE - 1
test$AbsPct_Err <- abs(test$Pct_Error)
summary(test$Pct_Error)
test$UpperCI <- numeric(nrow(test))
test$LowerCI <- numeric(nrow(test))
for(i in ZipCodes){
  test[test$ZIP == i,]$UpperCI <- test[test$ZIP == i,]$knn14Pred * (1 + quantile(train[train$ZIP == i,]$Pct_Error,.95))
  test[test$ZIP == i,]$LowerCI <- test[test$ZIP == i,]$knn14Pred * (1 + quantile(train[train$ZIP == i,]$Pct_Error,.05))
}
#test <- test[,-c(12,13,18:24,26)]
#output2 <- write.csv(test,"CI_14knnTest.csv", row.names = FALSE)
