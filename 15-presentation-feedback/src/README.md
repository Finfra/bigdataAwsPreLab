# This directory contains example files for project presentation and feedback.

# Example: presentation_outline.md
# # FMS BigData AWS Pre-Lab Final Presentation Outline
#
# ## 1. Introduction (5 min)
# *   Project Goal & Background
# *   Key Technologies Used
#
# ## 2. Architecture Design (8 min)
# *   High-Level Architecture Diagram
# *   Component Roles & Data Flow
# *   Security & Cost Considerations
#
# ## 3. Implementation & Demo (12 min)
# *   Terraform Infrastructure Provisioning
# *   Ansible Automation (Hadoop, Spark, Kafka)
# *   Live Demo: Data Ingestion -> Processing -> Monitoring
#
# ## 4. Challenges & Lessons Learned (5 min)
# *   Technical Hurdles & Solutions
# *   Key Takeaways
#
# ## 5. Future Work & Q&A (5 min)
# *   Potential Enhancements
# *   Open Discussion

# Example: demo_script.sh
# #!/bin/bash
#
# echo "Starting FMS BigData AWS Pre-Lab Demo..."
#
# # 1. Show EC2 Instances
# echo "\n--- 1. EC2 Instances ---"
# aws ec2 describe-instances --filters "Name=tag:Name,Values=console-server,s1,s2,s3" --query "Reservations[*].Instances[*].{Name:Tags[?Key==`Name`].Value|[0],State:State.Name,PublicIp:PublicIpAddress,PrivateIp:PrivateIpAddress}" --output table
#
# # 2. Show Hadoop NameNode UI (requires SSH tunneling setup)
# echo "\n--- 2. Hadoop NameNode UI ---"
# echo "Please open http://localhost:9870 in your browser (ensure SSH tunnel is active)"
#
# # 3. Show Spark Master UI (requires SSH tunneling setup)
# echo "\n--- 3. Spark Master UI ---"
# echo "Please open http://localhost:8080 in your browser (ensure SSH tunnel is active)"
#
# # 4. Start Kafka Producer and show Spark Streaming processing
# echo "\n--- 4. Kafka Producer & Spark Streaming ---"
# echo "Starting Kafka console producer on s1..."
# # In a real demo, you'd have a separate terminal for this or automate it.
# # For now, just simulate the command.
# echo "/opt/kafka/bin/kafka-console-producer.sh --broker-list s1:9092 --topic logs"
# echo "Type some messages and press Enter:"
# # Simulate sending a message
# sleep 5
# echo "Simulating a new sensor data message..."
#
# echo "\n--- Demo Complete ---"
