# This directory contains example configuration files for Kafka and Spark Streaming applications.

# Example: server.properties (Kafka Broker Configuration)
# broker.id=0
# listeners=PLAINTEXT://:9092
# advertised.listeners=PLAINTEXT://s1:9092
# num.network.threads=3
# num.io.threads=8
# socket.send.buffer.bytes=102400
# socket.receive.buffer.bytes=102400
# socket.request.max.bytes=104857600
# log.dirs=/tmp/kafka-logs
# num.partitions=1
# num.recovery.threads.per.data.dir=1
# offsets.topic.replication.factor=1
# transaction.state.log.replication.factor=1
# transaction.state.log.min.isr=1
# log.retention.hours=168
# log.segment.bytes=1073741824
# log.retention.check.interval.ms=300000
# zookeeper.connect=s1:2181,s2:2181,s3:2181
# zookeeper.connection.timeout.ms=18000

# Example: kafka_wordcount.py (Spark Streaming Application)
# from pyspark.sql import SparkSession
# from pyspark.sql.functions import explode, split

# if __name__ == "__main__":
#     spark = SparkSession \
#         .builder \
#         .appName("KafkaWordCount") \
#         .getOrCreate()

#     lines = spark \
#         .readStream \
#         .format("kafka") \
#         .option("kafka.bootstrap.servers", "s1:9092,s2:9092,s3:9092") \
#         .option("subscribe", "logs") \
#         .load() \
#         .selectExpr("CAST(value AS STRING)")

#     words = lines.select(
#         explode(
#             split(lines.value, ' ')
#         ).alias('word')
#     )

#     wordCounts = words.groupBy('word').count()

#     query = wordCounts \
#         .writeStream \
#         .outputMode('complete') \
#         .format('console') \
#         .start()

#     query.awaitTermination()
