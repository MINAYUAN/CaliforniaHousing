# Los Angeles, California Predictive Appraisal Model

## Introduction


Los Angeles in California has one of the highest housing price in the US. Like other metropolitan area, housing price has been on a upward trend.


S&P/Case-Shiller CA-Los Angeles Home Price Index
<img width=“964” src="https://github.com/MINAYUAN/CaliforniaHousing/blob/main/CS%20Housing%20Index.png">

Source: https://fred.stlouisfed.org/series/LXXRSA

We want to build a free property appraisal model that consideres historical traded prices, the neighborhood, tax policy and property-related factors for sellers and buyers in the general public to understand how competitive their listing price is. Through looking at historical prices, the appraisal model takes into account of possibilities of a house being overpriced and underprice by the housing market momentum. 

Appearance in the order of the least to most expansive postal code in Los Angeles.
[image]

## Model Results and Demontration
We applied seven modelling methods in this prediction problem: OLS Linear Regression, Polynomial Regression, Ridge, Lasso, Elastic Net Regularized Regression, Tree-based (Random Forest), and K Nearnest Neighbor. Our associated quantitative measure of success is Root Mean Squared Errors (RMSE). This measure will reflect error in dollar term. It helps understand the performance of each model by measuring how far away the the predicted houses price could be from the sold price, given the information in various factors we considered. 

| Method | RMSE ($) |
| ------------- | ------------- |
| Linear Regression   | $476,465  |
| Linear Regression (Lasso)  | $487,748  |
| Linear Regression - Single Family Only  | $473,872  |
| Linear Regression (Lasso) - Single Family Only  | $449,114  |
| Linear Regression - Enet  | $488,014  |
| Linear Regression - Ridge  | $542,271  |
| Random Forest   | $342,028  |
| PCR (ncomp 13-Max) 10-fold CV  | $365,157  |
| KNN-14 (Top 1% price removed - Single Family)  | $291.658  |

By comparing RMSEs, we recognized nonlinear methods generate lower MSE than linear methods, sepcifically, we see better results when we tailor our model specifically for regular single family homes, which is the majority of the real estates in Los Angeles.
 

Demonstration
The following is the property located in 21512 Broadwell Ave, Torrance, CA 90502. The single family house has 3 beds and 2.5 bath with 1905 sqft. It has sold for $659,700 on 4/30/2019. Our model predicts its current value to be $636,785 with a 90% confidence interval between $ 568,089 and $ 721,367.
[image]


## Data Collection
Data used in this model comed from five sources:
1. Redfin: data size is around 300,000 entries after data cleaning
2. US Government Internal Revenue Services (IRS)
3. S&P/Case-Shiller CA-Los Angeles Home Price Index
4. Crime Rates data from LA Sheiff Department

12 intrinsic value variables: Zip code (primary key), property type (single, multi home), Longtitude, Latitude, City, Address, Number of Beds, Number of Bath, Square Feet, Lot Size, Year Built, Number of Crimes.

6 neighborhood variables: Zip code (primary key), Avg total income, Avg real estate tax, Avg property tax, Avg mortgage interest payment a person pay, Avg number of crimes


## Data Cleaning in Redfin
1. Excluding top 0.1% of prices: removing outliers to minimize predictive error for the general home buyer and seller population
2. Excluding listing prices below $100,000: removing easily identified erroneous listing prices such as (2001 built house, 1800 square feet with price listed under $100,000)
3. Excluding lost size smaller than 100: removing easily identified erroneous entries or specialty houses
4. NA and missing gdata removing 
5. Log Housing Price: the distribution of housing price is log normal, thus it's appropriate to apply log transformation to the price variable. 


## Exploratory Analysis
Using pairs plot to view relationships between variables. We can see some relationships are non-linear, specifically price and square feet, price and average total income, etc. Next, we are start fitting data to a model with target price.  

## Linear Methods
### OLS Linear Regression
We use OLS to fit the model and test out-of-sample for the full data set and also single family only dataset. To reduce potential noise in the last-sold price, we group them into 21 groups, since thre are 21 police stations to match crime rate by Zip. We also applied fixed effect on rank zip by price and property type to account for unknown/omitted variable bias. Since single family data has smaller RMSE, nonlinear methods will focus seprately on single family properties.
| ------------- | ------------- |
| R-Square   | 0.89  |
| Out-Sample RMSE  | $476,465 and $473,872 (single-family)   |
| Large and significant predictors  | beds, baths, square feet, lot size, average real estate tax, average property tax, average mortgage interest rate  |
| ------------- | ------------- |

We also need to make sure the residuals are stationary.

### Regularized Linear Regression: Lasso, Ridge, and Elastic Net with Cross Validation
Lasso penalizes additional use of the factors the heaviest among the three. It has also yielded the lowest out of sample RMSE among them. In both Lasso and Ridge Regularization, the most imporatant predictors are sqft and property tax. In the prediction, we use lambda at 1se.

We observed non-linear relationship exists, which is why we should apply non-linear method next.
[photo] [photo]


## Non-linear Methods
### Random Forest
*Why Random Forest?*
Random Forecast is a type of decision tree method. In classic bagging approach, we resample data from the same sample space and fit a model on each tree with re-sampled data. We takes the average of their predictions as our final recommendation. If the re-sampled dataset are independent, variance of the average will decrease by 1/n, where n is the sample size, and can therefore improve our prediction. However, such method produces resampled data set that are correlated because ultimately they come from the same sample space. To de-correlate the resamples, Random Forecast ramdomly selected n out of p predictors (x variables) for each tree/bootstrapped sample. Often, n = \sqrt{p}. In the end, as with classic bagging approach, we also uses the final average as prediction. 

In this project, we set n as 4 (square root of the number of predictors), and ntree as 500, maxnode as 31. We tested maxnodes from 1 to 60 to find out the number of maxnodes that optimized MSE. 


Below are the results of Random Forecast on full data and truncated data (single family only and remove data with prices outside of 99% quantile). The full data set out-of-sample RMSE is $423,185, while the truncted sample out-of-sample RMSE reduced to $342,028. Notice the variables that are ranked with higher importance share common varaibles, but ranking changes for some. Random Forest is an improvement on linear methods.

[photo] [photo]

## K-Nearest Neighbors (KNN Regression)
Similar to Random Forecast, KNN is a non-linear and non-parametric method. The main idea behind KNN algorithm is to find home prices that is closest to the home value in question and takes the average of the K nearest prices. We suspect this will do very well because a home down the block that has the same structure and properties (Bed, Baths, SQ. FT, etc…) should be similar in prices. 

We need to tune KNN model and decide how many neighbors we should consider for our predictional problem. From the summarized table below of our 10-fold cross validation, we found  RMSE of the 13-nearest neighbor regressional model are the lowest. As expected, its out-of-sample RMSE is also the lower than linear methods and Randome Forest at $290,026. 

[photo]

However, in  a special case of k-Fold Cross-Validation where k is equal to the size of data (n), called Leave-One-Out Cross Validation (LOOCV), we found 14-nearest neighbor regressional model to have the lowest RMSE. LOOCV is the case of Cross-Validation where just a single observation is held out for validation. The LOOCV method is computationally expensive, and subject to high variance or overfitting. However, its benefit is ensuring a larger number of training data. 

Using it as an example, we demonstrate how the model choose k and the distribution of the percentage error of our fitted values below. 



This is a incredibly fun project to applied linear and non-linear methods. Non-linear methods do no always perform linear methods, but in real life dataset, they are needed. Variance-bias traded off should always be in the back of our minds when thinking about predicitional problems!




