library(h2o)

h2o.init(nthreads=-1, max_mem_size = '4G')

#' builds a vector of autoencoder models, one per layer
#'
#' @param training_data
#' @param layers
#' @param args
#' @return 
#' 
get_stacked_ae_array <- function(training_data, layers, args) {  
  vector <- c()
  index = 0

  for(i in 1:length(layers)) {
    index = index + 1
    
    ae_model <- do.call(h2o.deeplearning, 
                        modifyList(list(x=names(training_data),
                                        training_frame=training_data,
                                        autoencoder=T,
                                        hidden=layers[i]),
                                   args))
    
    training_data = h2o.deepfeatures(ae_model,training_data,layer=1)
    
    names(training_data) <- gsub("DF", paste0("L",index,sep=""), names(training_data)) 
    
    vector <- c(vector, ae_model)    
  }
  
  vector
}

#' returns final encoded contents
#' 
#' @param data
#' @param ae
#' 
#' @return 
#' 
apply_stacked_ae_array <- function(data, ae) {
  
  index = 0
  
  for(i in 1:length(ae)) {
    index = index + 1
    
    data = h2o.deepfeatures(ae[[i]],data,layer=1)
    
    names(data) <- gsub("DF", paste0("L",index,sep=""), names(data)) 
  }
  
  data
}

datadir <- file.path(getwd(), 'data')

TRAIN <- 'train.csv.gz'
TEST <- 'test.csv.gz'

train_hex <- h2o.uploadFile(path=file.path(datadir, TRAIN), header=F, sep=',')
test_hex <- h2o.uploadFile(path=file.path(datadir, TEST), header=F, sep=',')

summary(train_hex)

# last column is the response
response <- length(train_hex)

train <- train_hex[,-response]
test  <- test_hex [,-response]
train_hex[,response] <- as.factor(train_hex[,response])
test_hex [,response] <- as.factor(test_hex [,response])

## Build reference model on full dataset and evaluate it on the test set
model_ref <- h2o.deeplearning(training_frame=train_hex, x=1:(ncol(train_hex)-1), y=response, hidden=c(10), epochs=1)

p_ref <- h2o.performance(model_ref, test_hex)
h2o.logloss(p_ref)

## Now build a stacked autoencoder model with three stacked layer AE models
## First AE model will compress the 717 non-const predictors into 200
## Second AE model will compress 200 into 100
## Third AE model will compress 100 into 50
layers <- c(200,100,50)
args <- list(activation="Tanh", epochs=1, l1=1e-5)
ae <- get_stacked_ae_array(train, layers, args)

## Now compress the training/testing data with this 3-stage set of AE models
train_compressed <- apply_stacked_ae_array(train, ae)
test_compressed <- apply_stacked_ae_array(test, ae)

## Build a simple model using these new features (compressed training data) and evaluate it on the compressed test set.
train_w_resp <- h2o.cbind(train_compressed, train_hex[,response])
test_w_resp <- h2o.cbind(test_compressed, test_hex[,response])

model_on_compressed_data <- h2o.deeplearning(training_frame=train_w_resp, x=1:(ncol(train_w_resp)-1), y=ncol(train_w_resp), hidden=c(10), epochs=1)

p <- h2o.performance(model_on_compressed_data, test_w_resp)
h2o.logloss(p)

h2o.shutdown(prompt = FALSE)


