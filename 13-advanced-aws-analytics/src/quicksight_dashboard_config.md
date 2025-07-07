# Amazon QuickSight 대시보드 설정 가이드

## 1. QuickSight 계정 설정

### Enterprise Edition 활성화
```bash
aws quicksight create-account-subscription \
    --edition ENTERPRISE \
    --authentication-method IAM_AND_QUICKSIGHT \
    --aws-account-id $(aws sts get-caller-identity --query Account --output text) \
    --account-name "BigData Analytics" \
    --notification-email "admin@company.com"
```

### IAM 역할 권한 설정
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "athena:*",
                "s3:GetBucketLocation",
                "s3:GetObject",
                "s3:ListBucket",
                "s3:ListBucketMultipartUploads",
                "s3:ListMultipartUploadParts",
                "s3:AbortMultipartUpload",
                "s3:PutObject",
                "s3:DeleteObject",
                "glue:GetDatabase*",
                "glue:GetTable*",
                "glue:GetPartition*"
            ],
            "Resource": "*"
        }
    ]
}
```

## 2. 데이터 소스 연결

### Athena 데이터 소스 설정
```json
{
    "DataSourceId": "athena-fms-data",
    "Name": "FMS Sensor Data",
    "Type": "ATHENA",
    "DataSourceParameters": {
        "AthenaParameters": {
            "WorkGroup": "bigdata-analytics"
        }
    },
    "Permissions": [
        {
            "Principal": "arn:aws:quicksight:ap-northeast-2:123456789012:user/default/admin",
            "Actions": [
                "quicksight:DescribeDataSource",
                "quicksight:DescribeDataSourcePermissions",
                "quicksight:PassDataSource",
                "quicksight:UpdateDataSource",
                "quicksight:DeleteDataSource",
                "quicksight:UpdateDataSourcePermissions"
            ]
        }
    ]
}
```

## 3. 데이터셋 생성

### 실시간 센서 데이터셋
```json
{
    "DataSetId": "fms-realtime-dataset",
    "Name": "FMS Real-time Sensor Data",
    "PhysicalTableMap": {
        "fms-sensor-table": {
            "CustomSql": {
                "DataSourceArn": "arn:aws:quicksight:ap-northeast-2:123456789012:datasource/athena-fms-data",
                "Name": "FMS Sensor Query",
                "SqlQuery": "SELECT device_id, temperature, humidity, pressure, timestamp, anomaly_flag FROM bigdata_catalog.fms_sensor_data WHERE year = YEAR(CURRENT_DATE) AND month = MONTH(CURRENT_DATE) AND day >= DAY(CURRENT_DATE - INTERVAL '1' DAY)",
                "Columns": [
                    {
                        "Name": "device_id",
                        "Type": "STRING"
                    },
                    {
                        "Name": "temperature",
                        "Type": "DECIMAL"
                    },
                    {
                        "Name": "humidity",
                        "Type": "DECIMAL"
                    },
                    {
                        "Name": "pressure",
                        "Type": "DECIMAL"
                    },
                    {
                        "Name": "timestamp",
                        "Type": "DATETIME"
                    },
                    {
                        "Name": "anomaly_flag",
                        "Type": "BIT"
                    }
                ]
            }
        }
    },
    "LogicalTableMap": {
        "fms-sensor-logical": {
            "Alias": "Sensor Data",
            "DataTransforms": [
                {
                    "CreateColumnsOperation": {
                        "Columns": [
                            {
                                "ColumnName": "hour",
                                "ColumnId": "hour",
                                "Expression": "extract('HH',{timestamp})"
                            },
                            {
                                "ColumnName": "temperature_fahrenheit",
                                "ColumnId": "temp_f",
                                "Expression": "{temperature} * 9/5 + 32"
                            },
                            {
                                "ColumnName": "anomaly_count",
                                "ColumnId": "anomaly_count",
                                "Expression": "ifelse({anomaly_flag}, 1, 0)"
                            }
                        ]
                    }
                }
            ],
            "Source": {
                "PhysicalTableId": "fms-sensor-table"
            }
        }
    },
    "ImportMode": "DIRECT_QUERY"
}
```

## 4. 대시보드 시각화 정의

### 실시간 온도 모니터링 차트
```json
{
    "VisualId": "temperature-timeline",
    "Title": {
        "Visibility": "VISIBLE",
        "FormatText": {
            "PlainText": "Real-time Temperature Monitoring"
        }
    },
    "LineChartVisual": {
        "VisualId": "temperature-timeline",
        "Title": {
            "Visibility": "VISIBLE",
            "FormatText": {
                "PlainText": "Temperature Timeline (°C)"
            }
        },
        "FieldWells": {
            "LineChartAggregatedFieldWells": {
                "Category": [
                    {
                        "DateDimensionField": {
                            "FieldId": "timestamp",
                            "Column": {
                                "DataSetIdentifier": "fms-realtime-dataset",
                                "ColumnName": "timestamp"
                            },
                            "DateGranularity": "MINUTE"
                        }
                    }
                ],
                "Values": [
                    {
                        "MeasureField": {
                            "FieldId": "avg_temperature",
                            "Column": {
                                "DataSetIdentifier": "fms-realtime-dataset",
                                "ColumnName": "temperature"
                            },
                            "AggregationFunction": {
                                "SimpleNumericalAggregation": "AVERAGE"
                            }
                        }
                    }
                ],
                "Colors": [
                    {
                        "CategoricalDimensionField": {
                            "FieldId": "device_id",
                            "Column": {
                                "DataSetIdentifier": "fms-realtime-dataset",
                                "ColumnName": "device_id"
                            }
                        }
                    }
                ]
            }
        },
        "SortConfiguration": {
            "CategorySort": [
                {
                    "FieldSort": {
                        "FieldId": "timestamp",
                        "Direction": "ASC"
                    }
                }
            ]
        }
    }
}
```

### 이상값 알림 카드
```json
{
    "VisualId": "anomaly-kpi",
    "KPIVisual": {
        "VisualId": "anomaly-kpi",
        "Title": {
            "Visibility": "VISIBLE",
            "FormatText": {
                "PlainText": "Anomaly Detection Alert"
            }
        },
        "FieldWells": {
            "Values": [
                {
                    "MeasureField": {
                        "FieldId": "total_anomalies",
                        "Column": {
                            "DataSetIdentifier": "fms-realtime-dataset",
                            "ColumnName": "anomaly_count"
                        },
                        "AggregationFunction": {
                            "SimpleNumericalAggregation": "SUM"
                        }
                    }
                }
            ]
        },
        "ConditionalFormatting": {
            "ConditionalFormattingOptions": [
                {
                    "PrimaryValue": {
                        "TextColor": {
                            "Solid": {
                                "Expression": "ifelse({total_anomalies} > 10, 'red', ifelse({total_anomalies} > 5, 'orange', 'green'))"
                            }
                        },
                        "BackgroundColor": {
                            "Solid": {
                                "Expression": "ifelse({total_anomalies} > 10, '#ffebee', ifelse({total_anomalies} > 5, '#fff3e0', '#e8f5e8'))"
                            }
                        }
                    }
                }
            ]
        }
    }
}
```

### 장비별 성능 히트맵
```json
{
    "VisualId": "device-heatmap",
    "HeatMapVisual": {
        "VisualId": "device-heatmap",
        "Title": {
            "Visibility": "VISIBLE",
            "FormatText": {
                "PlainText": "Device Performance Heatmap"
            }
        },
        "FieldWells": {
            "HeatMapAggregatedFieldWells": {
                "Rows": [
                    {
                        "CategoricalDimensionField": {
                            "FieldId": "device_id",
                            "Column": {
                                "DataSetIdentifier": "fms-realtime-dataset",
                                "ColumnName": "device_id"
                            }
                        }
                    }
                ],
                "Columns": [
                    {
                        "CategoricalDimensionField": {
                            "FieldId": "hour",
                            "Column": {
                                "DataSetIdentifier": "fms-realtime-dataset",
                                "ColumnName": "hour"
                            }
                        }
                    }
                ],
                "Values": [
                    {
                        "MeasureField": {
                            "FieldId": "avg_temperature",
                            "Column": {
                                "DataSetIdentifier": "fms-realtime-dataset",
                                "ColumnName": "temperature"
                            },
                            "AggregationFunction": {
                                "SimpleNumericalAggregation": "AVERAGE"
                            }
                        }
                    }
                ]
            }
        },
        "ColorScale": {
            "ColorFillType": "GRADIENT",
            "Colors": [
                {
                    "Color": "#1f77b4"
                },
                {
                    "Color": "#ff7f0e"
                },
                {
                    "Color": "#d62728"
                }
            ]
        }
    }
}
```

## 5. 대시보드 설정

### 대시보드 메인 구성
```json
{
    "DashboardId": "fms-realtime-dashboard",
    "Name": "FMS Real-time Monitoring Dashboard",
    "Definition": {
        "DataSetIdentifiers": [
            "fms-realtime-dataset"
        ],
        "Sheets": [
            {
                "SheetId": "main-overview",
                "Name": "Overview",
                "Visuals": [
                    "temperature-timeline",
                    "anomaly-kpi",
                    "device-heatmap"
                ],
                "FilterControls": [
                    {
                        "DateTimePicker": {
                            "FilterControlId": "time-filter",
                            "Title": "Time Range",
                            "SourceFilterId": "timestamp-filter"
                        }
                    },
                    {
                        "Dropdown": {
                            "FilterControlId": "device-filter",
                            "Title": "Device Selection",
                            "SourceFilterId": "device-filter",
                            "SelectableValues": {
                                "Values": ["ALL"]
                            }
                        }
                    }
                ]
            }
        ],
        "AnalysisDefaults": {
            "DefaultNewSheetConfiguration": {
                "InteractiveLayoutConfiguration": {
                    "Grid": {
                        "CanvasSizeOptions": {
                            "ScreenCanvasSizeOptions": {
                                "ResizeOption": "RESPONSIVE"
                            }
                        }
                    }
                }
            }
        }
    },
    "Permissions": [
        {
            "Principal": "arn:aws:quicksight:ap-northeast-2:123456789012:user/default/admin",
            "Actions": [
                "quicksight:DescribeDashboard",
                "quicksight:ListDashboardVersions",
                "quicksight:UpdateDashboardPermissions",
                "quicksight:QueryDashboard",
                "quicksight:UpdateDashboard",
                "quicksight:DeleteDashboard"
            ]
        }
    ]
}
```

## 6. 실시간 갱신 설정

### SPICE 데이터셋 자동 갱신
```json
{
    "DataSetId": "fms-spice-dataset",
    "RefreshProperties": {
        "RefreshConfiguration": {
            "IncrementalRefresh": {
                "LookbackWindow": {
                    "ColumnName": "timestamp",
                    "Size": 1,
                    "SizeUnit": "HOUR"
                }
            }
        }
    },
    "IngestionSchedule": {
        "Schedule": "rate(5 minutes)",
        "RefreshType": "INCREMENTAL_REFRESH"
    }
}
```

### CloudWatch Events 기반 자동 갱신
```json
{
    "Rules": [
        {
            "Name": "quicksight-dataset-refresh",
            "Description": "Refresh QuickSight dataset every 5 minutes",
            "ScheduleExpression": "rate(5 minutes)",
            "State": "ENABLED",
            "Targets": [
                {
                    "Id": "1",
                    "Arn": "arn:aws:lambda:ap-northeast-2:123456789012:function:refresh-quicksight-dataset",
                    "Input": "{\"dataSetId\": \"fms-spice-dataset\"}"
                }
            ]
        }
    ]
}
```

## 7. 알림 및 임계값 설정

### 이상값 알림 구성
```json
{
    "AlertName": "High-Temperature-Alert",
    "AlertDescription": "Alert when average temperature exceeds 50°C",
    "AlertCondition": {
        "Field": "temperature",
        "Operator": "GREATER_THAN",
        "Value": 50,
        "AggregationFunction": "AVERAGE"
    },
    "Recipients": [
        "operations@company.com",
        "maintenance@company.com"
    ],
    "Schedule": {
        "Frequency": "HOURLY"
    }
}
```

## 8. 모바일 최적화

### 반응형 레이아웃 설정
```json
{
    "MobileDeviceLayout": {
        "Configurations": [
            {
                "Device": "PHONE",
                "Layout": {
                    "GridLayout": {
                        "Elements": [
                            {
                                "ElementId": "anomaly-kpi",
                                "ElementType": "VISUAL",
                                "ColumnIndex": 0,
                                "ColumnSpan": 12,
                                "RowIndex": 0,
                                "RowSpan": 4
                            },
                            {
                                "ElementId": "temperature-timeline",
                                "ElementType": "VISUAL",
                                "ColumnIndex": 0,
                                "ColumnSpan": 12,
                                "RowIndex": 4,
                                "RowSpan": 8
                            }
                        ]
                    }
                }
            },
            {
                "Device": "TABLET",
                "Layout": {
                    "GridLayout": {
                        "Elements": [
                            {
                                "ElementId": "anomaly-kpi",
                                "ElementType": "VISUAL",
                                "ColumnIndex": 0,
                                "ColumnSpan": 6,
                                "RowIndex": 0,
                                "RowSpan": 6
                            },
                            {
                                "ElementId": "device-heatmap",
                                "ElementType": "VISUAL",
                                "ColumnIndex": 6,
                                "ColumnSpan": 6,
                                "RowIndex": 0,
                                "RowSpan": 6
                            },
                            {
                                "ElementId": "temperature-timeline",
                                "ElementType": "VISUAL",
                                "ColumnIndex": 0,
                                "ColumnSpan": 12,
                                "RowIndex": 6,
                                "RowSpan": 8
                            }
                        ]
                    }
                }
            }
        ]
    }
}
```

## 9. 성능 최적화

### SPICE 용량 관리
```bash
# SPICE 용량 확인
aws quicksight describe-account-settings \
    --aws-account-id $(aws sts get-caller-identity --query Account --output text)

# 데이터셋 크기 최적화
aws quicksight describe-data-set \
    --aws-account-id $(aws sts get-caller-identity --query Account --output text) \
    --data-set-id fms-realtime-dataset
```

### 쿼리 성능 최적화
- Athena 파티션 프로젝션 사용
- 컬럼 선택 최소화
- 적절한 필터링 적용
- SPICE vs Direct Query 적절한 선택

## 10. 사용자 권한 관리

### 그룹별 권한 설정
```json
{
    "Groups": [
        {
            "GroupName": "Operations",
            "Description": "Operations team dashboard access",
            "Members": [
                "operator1@company.com",
                "operator2@company.com"
            ],
            "Permissions": [
                "quicksight:DescribeDashboard",
                "quicksight:QueryDashboard"
            ]
        },
        {
            "GroupName": "Managers",
            "Description": "Management team with full access",
            "Members": [
                "manager1@company.com",
                "director@company.com"
            ],
            "Permissions": [
                "quicksight:*"
            ]
        }
    ]
}
```
