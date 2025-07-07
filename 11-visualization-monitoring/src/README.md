# This directory contains example configuration files for Prometheus and Grafana.

# Example: prometheus.yml
# global:
#   scrape_interval: 15s

# scrape_configs:
#   - job_name: 'node'
#     static_configs:
#       - targets: ['s1_private_ip:9100', 's2_private_ip:9100', 's3_private_ip:9100']

#   - job_name: 'hadoop_namenode'
#     static_configs:
#       - targets: ['s1_private_ip:9870'] # JMX Exporter port

# Example: grafana_dashboard.json (Simplified example of a Grafana dashboard JSON)
# {
#   "annotations": {
#     "list": [
#       {
#         "builtIn": 1,
#         "datasource": "-- Grafana --",
#         "enable": true,
#         "hide": true,
#         "iconColor": "rgba(0, 211, 255, 1)",
#         "name": "Annotations",
#         "type": "dashboard"
#       }
#     ]
#   },
#   "editable": true,
#   "gnetId": null,
#   "graphTooltip": 1,
#   "id": null,
#   "links": [],
#   "panels": [
#     {
#       "datasource": "Prometheus",
#       "fieldConfig": {
#         "defaults": {
#           "custom": {},
#           "links": []
#         },
#         "overrides": []
#       },
#       "gridPos": {
#         "h": 8,
#         "w": 12,
#         "x": 0,
#         "y": 0
#       },
#       "id": 2,
#       "options": {
#         "legend": {
#           "calcs": [],
#           "displayMode": "list",
#           "placement": "bottom",
#           "showLegend": true
#         },
#         "tooltip": {
#           "mode": "single",
#           "sort": "none"
#         }
#       },
#       "targets": [
#         {
#           "expr": "node_cpu_seconds_total{mode=\"idle\"}",
#           "refId": "A"
#         }
#       ],
#       "title": "Node CPU Idle Time",
#       "type": "timeseries"
#     }
#   ],
#   "schemaVersion": 30,
#   "style": "dark",
#   "tags": [],
#   "templating": {
#     "list": []
#   },
#   "time": {
#     "from": "now-6h",
#     "to": "now"
#   },
#   "timepicker": {},
#   "timezone": "",
#   "title": "My First Monitoring Dashboard",
#   "uid": "myfirstdashboard",
#   "version": 1
# }
