# version to download
#h2oVersion <- "http://h2o-release.s3.amazonaws.com/h2o/rel-turchin/9/R"
#h2oVersion <- "http://h2o-release.s3.amazonaws.com/h2o/rel-turing/7/R"
h2oVersion <- "http://h2o-release.s3.amazonaws.com/h2o/rel-tutte/1/R"

# The following two commands remove any previously installed H2O packages for R.
if ("package:h2o" %in% search()) { detach("package:h2o", unload=TRUE) }
if ("h2o" %in% rownames(installed.packages())) { remove.packages("h2o") }

# Next, we download packages that H2O depends on.
pkgs <- c("methods","statmod","stats","graphics","RCurl","jsonlite","tools","utils")
for (pkg in pkgs) {
  if (! (pkg %in% rownames(installed.packages()))) { install.packages(pkg) }
}

# Now we download, install and initialize the H2O package for R.
install.packages("h2o", type="source", repos=h2oVersion)

library(h2o)
h2o.init(ip="localhost", startH2O = TRUE)

h2o.getVersion()

# Finally, let's run a demo to see H2O at work.
# all demos under demo(package="h2o")
# h2o.anomaly                    H2O anomaly using prostate cancer data
# h2o.deeplearning               H2O deeplearning using prostate cancer data
# h2o.gbm                        H2O generalized boosting machines using prostate cancer data
# h2o.glm                        H2O GLM using prostate cancer data
# h2o.glrm                       H2O GLRM using walking gait data
# h2o.kmeans                     H2O K-means using prostate cancer data
# h2o.naiveBayes                 H2O naive Bayes using iris and Congressional voting data
# h2o.prcomp                     H2O PCA using Australia coast data
# h2o.randomForest               H2O random forest classification using iris data

demo(h2o.kmeans)
demo(h2o.deeplearning)

h2o.shutdown(prompt = FALSE)
