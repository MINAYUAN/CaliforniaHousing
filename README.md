# Los Angeles, California Predictive Appraisal Model

## Introduction


Los Angeles in California has one of the highest housing price in the US. Like other metropolitan area, housing price has been on a upward trend.


S&P/Case-Shiller CA-Los Angeles Home Price Index

Source: https://fred.stlouisfed.org/series/LXXRSA

We want to build a free property appraisal model that consideres historical traded prices, the neighborhood, tax policy and property-related factors for sellers and buyers in the general public to understand how competitive their listing price is. Through looking at historical prices, the appraisal model takes into account of possibilities of a house being overpriced and underprice by the housing market momentum. 

Appearance in the order of the least to most expansive postal code in Los Angeles.


## Model Results and Demontration
We applied seven modelling methods in this prediction problem: OLS Linear Regression, Polynomial Regression, Ridge, Lasso, Elastic Net Regularized Regression, Tree-based (Random Forest), and K Nearnest Neighbor. Our associated quantitative measure of success is Root Mean Squared Errors (RMSE). This measure will reflect error in dollar term. 

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



## Non-linear Methods





