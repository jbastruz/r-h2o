

library(RJDBC)
.jinit()
.jaddClassPath("/Users/vinnys/jdbc/hadoop-common.jar")

drv <- JDBC("org.apache.hive.jdbc.HiveDriver",
            "/Users/vinnys/jdbc/hive-jdbc.jar",
            identifier.quote="`")
conn <- dbConnect(drv, "jdbc:hive2://centos2.saulys.com:10000")
dbGetTables(conn)

