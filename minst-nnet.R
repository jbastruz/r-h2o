
library(h2o)

h2oServer <- h2o.init(nthreads=-1, max_mem_size = '4G')

datadir <- file.path(getwd(), 'data')

TRAIN <- 'train.csv.gz'
TEST <- 'test.csv.gz'

train_hex <- h2o.uploadFile(path=file.path(datadir, TRAIN), header=F, sep=',')
test_hex <- h2o.uploadFile(path=file.path(datadir, TEST), header=F, sep=',')

summary(train_hex)

dlmodel <- h2o.deeplearning(
  x=1:length(train_hex),
  y=length(train_hex),
  training_frame = train_hex,
  validation_frame = test_hex,
  hidden=c(50,50), epochs=0.1, activation="Tanh")

dlmodel

# Need to update for 3.6
# grid_search <- h2o.deeplearning(x=c(1:784), y=785, training_frame=train_hex, 
#                                 validation_frame=test_hex,
#                                 hidden=list(c(10,10),c(20,20)), epochs=0.1,
#                                 activation=c("Tanh", "Rectifier"), l1=c(0,1e-5))

Sys.time()

record_model <- h2o.deeplearning(
  x = 1:length(train_hex), 
  y = length(train_hex), 
  training_frame = train_hex, 
  validation_frame = test_hex,
  activation = "RectifierWithDropout", 
  hidden = c(1024,1024,2048),
  epochs = 8000, 
  l1 = 1e-5, 
  input_dropout_ratio = 0.2,
  train_samples_per_iteration = -1, 
  classification_stop = -1
)

Sys.time()

h2o.clusterInfo()
h2o.ls()

h2o.saveModel(record_model, path=getwd(), force=TRUE)

h2o.shutdown(prompt = FALSE)


