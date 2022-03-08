name := "smarcql"

version := "0.1"

//scalaVersion := "2.11.12"
scalaVersion := "2.12.15"

excludeDependencies += "org.apache.logging.log4j"

// https://mvnrepository.com/artifact/org.apache.spark/spark-core
libraryDependencies += "org.apache.spark" %% "spark-core" % "2.4.0"

// https://mvnrepository.com/artifact/org.apache.spark/spark-sql
libraryDependencies += "org.apache.spark" %% "spark-sql" % "2.4.0" //% "provided"

libraryDependencies += "org.apache.jena" % "apache-jena-libs" % "3.13.1" // exclude("org.slf4j", "slf4j-api" )

// https://mvnrepository.com/artifact/com.fasterxml.jackson.module/jackson-module-scala
libraryDependencies += "com.fasterxml.jackson.module" %% "jackson-module-scala" % "2.13.0"

libraryDependencies += "org.apache.logging.log4j" % "log4j-api" % "2.15.0"
libraryDependencies += "org.apache.logging.log4j" % "log4j-core" % "2.15.0"