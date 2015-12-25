
library(h2o)

h2oServer <- h2o.init(nthreads=-1)

datadir <- file.path(getwd(), 'data')

TRAIN <- 'train.csv.gz'
TEST <- 'test.csv.gz'

train_hex <- h2o.uploadFile(path=file.path(datadir, TRAIN), header=F, sep=',')
test_hex <- h2o.uploadFile(path=file.path(datadir, TEST), header=F, sep=',')

ae_model <- h2o.deeplearning(x=1:length(train_hex),
                             training_frame=train_hex,
                             activation='Tanh',
                             autoencoder=TRUE,
                             hidden=c(50),
                             ignore_const_cols=FALSE,
                             epochs=1)

test_rec_error <- as.data.frame(h2o.anomaly(ae_model, test_hex))

test_features_deep <- h2o.deepfeatures(ae_model, test_hex, layer=1)

summary(test_features_deep)

plotDigit <- function(mydata, rec_error) {
  len <- nrow(mydata)
  N <- ceiling(sqrt(len))
  op <- par(mfrow=c(N,N), pty='s', mar=c(1,1,1,1), xaxt='n', yaxt='n')
  for (i in 1:nrow(mydata)) {
    colors <- c('white', 'black')
    cus_col <- colorRampPalette(colors=colors)
    z <- array(mydata[i,], dim=c(28,28))
    z <- z[,28:1]
    image(1:28, 1:28, z, main=paste0('rec_error: ', round(rec_error[i], 4)), col=cus_col(256))
  }
  on.exit(par(op))
}

plotDigits <- function(data, rec_error, rows) {
  row_idx <- order(rec_error[,1], decreasing=FALSE)[rows]
  my_rec_error <- rec_error[row_idx, ]
  my_data <- as.matrix(as.data.frame(data[row_idx,]))
  plotDigit(my_data, my_rec_error)
}

test_recon <- h2o.predict(ae_model, test_hex)
summary(test_recon)

# the good, best 25
plotDigits(test_recon, test_rec_error, c(1:25))
plotDigits(test_hex, test_rec_error, c(1:25))

# the bad, middle
mm <- nrow(test_recon)/2

plotDigits(test_recon, test_rec_error, c(mm:(mm+25)))
plotDigits(test_hex, test_rec_error, c(mm:(mm+25)))

# the ugly, worst 25
cc <- nrow(test_recon)

plotDigits(test_recon, test_rec_error, c((cc-25):cc))
plotDigits(test_hex, test_rec_error, c((cc-25):cc))

h2o.shutdown(prompt = FALSE)

