# This directory contains example configuration files for Hadoop and Spark.
# These files are typically managed by Ansible playbooks.

# Example: core-site.xml (Hadoop)
# <configuration>
#     <property>
#         <name>fs.defaultFS</name>
#         <value>hdfs://s1:9000</value>
#     </property>
# </configuration>

# Example: hdfs-site.xml (Hadoop)
# <configuration>
#     <property>
#         <name>dfs.replication</name>
#         <value>2</value>
#     </property>
#     <property>
#         <name>dfs.namenode.name.dir</name>
#         <value>file:///data/hadoop/hdfs/namenode</value>
#     </property>
#     <property>
#         <name>dfs.datanode.data.dir</name>
#         <value>file:///data/hadoop/hdfs/datanode</value>
#     </property>
# </configuration>

# Example: spark-defaults.conf (Spark)
# spark.master                     yarn
# spark.eventLog.enabled           true
# spark.eventLog.dir               hdfs:///spark-logs
# spark.history.fs.logDirectory    hdfs:///spark-logs
