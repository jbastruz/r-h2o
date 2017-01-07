#
# From
# http://h2o-release.s3.amazonaws.com/h2o/rel-tutte/1/docs-website/h2o-docs/booklets/GBMBooklet.pdf
#

# Chapter 5

library(h2o)
h2o.init()

weather.hex <- h2o.uploadFile(path  = h2o:::.h2o.locate("data/weather.csv"), 
                              header =TRUE, sep = ",", destination_frame = "weather.hex"
)

# Get a summary of the data
summary(weather.hex)

# Load the data and prepare for modeling
airlines.hex <- h2o.uploadFile(path = h2o:::.h2o.locate("data/allyears2k_headers.csv"), 
                               header = TRUE, sep = ",", destination_frame = "airlines.hex")

# Generate random numbers and create training, validation, testing splits
r <- h2o.runif(airlines.hex)
air_train.hex <- airlines.hex[r  < 0.6,]
air_valid.hex <- airlines.hex[(r >= 0.6) & (r < 0.9),]
air_test.hex  <- airlines.hex[r  >= 0.9,]
myX <- c("DayofMonth", "DayOfWeek")

# Now, train the GBM model:
air.model <- h2o.gbm(y = "IsDepDelayed", x = myX,
                     distribution="bernoulli",
                     training_frame = air_train.hex,
                     validation_frame = air_valid.hex,
                     ntrees=100, max_depth=4, learn_rate=0.1)

# Examine the performance of the trained model
air.model

# View the specified parameters of your GBM model
air.model@parameters

# Perform classification on the held out data
prediction = h2o.predict(air.model, newdata=air_test.hex)

# Copy predictions from H2O to R
pred = as.data.frame(prediction)
head(pred)

# Variable Importance
h2o.varimp(air.model)

# 5.8 Grid Search
ntrees_opt <- c(5,10,15)
maxdepth_opt <- c(2,3,4)
learnrate_opt <- c(0.1,0.2)
hyper_parameters <- list(ntrees=ntrees_opt,
                         max_depth=maxdepth_opt, learn_rate=learnrate_opt)

grid <- h2o.grid("gbm", hyper_params = hyper_parameters,
                 y = "IsDepDelayed", x = myX, distribution="bernoulli",
                 training_frame = air_train.hex, validation_frame =
                   air_valid.hex)

# print out all prediction errors and run times of the models
grid

# print out the auc for all of the models
grid_models <- lapply(grid@model_ids, function(model_id) { model = h2o.getModel(model_id) })

for (i in 1:length(grid_models)) {
  print(sprintf("auc: %f", h2o.auc(grid_models[[i]])))
}

# 5.8.2 Random Grid Search
ntrees_opt <- seq(1,100)
maxdepth_opt <- seq(1,10)
learnrate_opt <- seq(0.001,0.1,0.001)

hyper_parameters <- list(ntrees=ntrees_opt, max_depth=maxdepth_opt, learn_rate=learnrate_opt)

search_criteria = list(strategy = "RandomDiscrete", 
                       max_models = 10, max_runtime_secs=100, seed=123456)

grid <- h2o.grid("gbm", hyper_params = hyper_parameters,
                 search_criteria = search_criteria,
                 y = "IsDepDelayed", x = myX, distribution="bernoulli",
                 training_frame = air_train.hex, validation_frame = air_valid.hex)
grid
