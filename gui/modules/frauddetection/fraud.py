import sys
from pyspark.sql import SQLContext
from pyspark.sql import SparkSession
from pyspark.ml.linalg import DenseVector
from pyspark.sql import functions as F
import pyspark.sql.types as T

spark = SparkSession \
        .builder \
        .appName("Python Spark SQL basic example") \
        .config("spark.driver.extraClassPath", "/usr/share/java/mysql-connector-java.jar") \
        .config("spark.executor.extraClassPath", "/usr/share/java/mysql-connector-java.jar") \
	.config("spark.pyspark.python","/usr/bin/python3.6") \
        .getOrCreate()

sc = spark.sparkContext

sqlContext = SQLContext(sc)

url = "jdbc:mysql://localhost:3306/kamailio?user=kamailio;password=kamailiorw"

df = sqlContext \
  .read \
  .format("jdbc") \
  .option("url", url) \
  .option("dbtable", "cdrs") \
  .option("user","kamailio") \
  .option("password", "kamailiorw") \
  .load()

df.printSchema()

df1 = df.select("fraud","src_username","dst_username","call_start_time")

df1.show()

def removeTechPrefix(col):
   techprefix,dst_username = col.split("*")
   return dst_username

my_udf = F.UserDefinedFunction(removeTechPrefix, T.StringType())

df2=df1.withColumn("dst_username",my_udf(df1.dst_username))
df2=df2.withColumn("call_start_time",F.hour(df2.call_start_time))

df2.show()

input_data = df2.rdd.map(lambda x: (x[0],DenseVector(x[1:])))

df3 = spark.createDataFrame(input_data, ["label", "features"])

df3.show()
