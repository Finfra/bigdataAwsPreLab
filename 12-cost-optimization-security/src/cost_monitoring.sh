#!/bin/bash

# AWS 비용 모니터링 및 최적화 스크립트

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== AWS 비용 모니터링 및 최적화 도구 ===${NC}"

# AWS CLI 확인
if ! command -v aws &> /dev/null; then
    echo -e "${RED}AWS CLI가 설치되지 않았습니다.${NC}"
    exit 1
fi

# 리전 설정
REGION=${AWS_REGION:-ap-northeast-2}
echo -e "${YELLOW}리전: ${REGION}${NC}"

# 1. EC2 인스턴스 분석
echo -e "\n${GREEN}1. EC2 인스턴스 Right Sizing 분석${NC}"
aws ec2 describe-instances --region $REGION \
    --query 'Reservations[].Instances[?State.Name==`running`].[InstanceId,InstanceType,State.Name,Tags[?Key==`Name`].Value|[0]]' \
    --output table

# 2. EBS 볼륨 최적화
echo -e "\n${GREEN}2. EBS 볼륨 타입 및 사용률 분석${NC}"
aws ec2 describe-volumes --region $REGION \
    --query 'Volumes[?State==`in-use`].[VolumeId,VolumeType,Size,State]' \
    --output table

# 3. 사용하지 않는 리소스 찾기
echo -e "\n${GREEN}3. 사용하지 않는 EBS 볼륨 찾기${NC}"
aws ec2 describe-volumes --region $REGION \
    --filters Name=status,Values=available \
    --query 'Volumes[*].[VolumeId,Size,VolumeType,CreateTime]' \
    --output table

echo -e "\n${GREEN}4. 사용하지 않는 EIP 찾기${NC}"
aws ec2 describe-addresses --region $REGION \
    --query 'Addresses[?AssociationId==null].[PublicIp,AllocationId]' \
    --output table

# 5. S3 버킷 분석
echo -e "\n${GREEN}5. S3 버킷 Storage Class 분석${NC}"
for bucket in $(aws s3api list-buckets --query 'Buckets[].Name' --output text); do
    echo "버킷: $bucket"
    aws s3api list-objects-v2 --bucket $bucket \
        --query 'Contents[*].[Key,Size,StorageClass,LastModified]' \
        --output table --max-items 5 || echo "접근 권한 없음"
done

# 6. Reserved Instance 권장사항
echo -e "\n${GREEN}6. Reserved Instance 구매 권장사항${NC}"
aws ce get-reservation-purchase-recommendation \
    --service EC2-Instance \
    --payment-option NO_UPFRONT \
    --lookback-period-in-days SIXTY_DAYS \
    --term-in-years ONE_YEAR \
    --query 'Recommendations[*].[InstanceDetails.EC2InstanceDetails.InstanceType,InstanceDetails.EC2InstanceDetails.Region,RecommendationDetails.EstimatedMonthlySavingsAmount]' \
    --output table

# 7. 월간 비용 트렌드
echo -e "\n${GREEN}7. 월간 비용 트렌드 (최근 3개월)${NC}"
START_DATE=$(date -d "3 months ago" +%Y-%m-01)
END_DATE=$(date +%Y-%m-%d)

aws ce get-cost-and-usage \
    --time-period Start=$START_DATE,End=$END_DATE \
    --granularity MONTHLY \
    --metrics BlendedCost \
    --group-by Type=DIMENSION,Key=SERVICE \
    --query 'ResultsByTime[*].[TimePeriod.Start,Total.BlendedCost.Amount]' \
    --output table

# 8. 비용 최적화 권장사항
echo -e "\n${GREEN}8. 비용 최적화 권장사항${NC}"
echo -e "${YELLOW}┌─ Right Sizing 분석${NC}"
echo "   - Compute Optimizer 권장사항 확인"
echo "   - CloudWatch 메트릭으로 실제 사용률 분석"

echo -e "${YELLOW}├─ Reserved Instance 구매${NC}"
echo "   - 1년 예약으로 최대 75% 절감"
echo "   - No Upfront 옵션으로 현금 부담 없음"

echo -e "${YELLOW}├─ Spot Instance 활용${NC}"
echo "   - 비프로덕션 환경 최대 90% 절감"
echo "   - EMR 워커 노드 적용 권장"

echo -e "${YELLOW}├─ Storage 최적화${NC}"
echo "   - gp2 → gp3 전환으로 20% 절감"
echo "   - S3 Intelligent Tiering 설정"

echo -e "${YELLOW}└─ 네트워크 최적화${NC}"
echo "   - VPC Endpoint로 NAT Gateway 비용 절감"
echo "   - CloudFront로 데이터 전송 비용 절감"

# 9. 예산 알림 설정 확인
echo -e "\n${GREEN}9. 예산 알림 설정 확인${NC}"
aws budgets describe-budgets --account-id $(aws sts get-caller-identity --query Account --output text) \
    --query 'Budgets[*].[BudgetName,BudgetLimit.Amount,BudgetLimit.Unit]' \
    --output table

echo -e "\n${GREEN}=== 비용 모니터링 완료 ===${NC}"
echo -e "${YELLOW}권장사항:${NC}"
echo "1. 매주 Cost Explorer 검토"
echo "2. 월간 Right Sizing 분석"
echo "3. 분기별 Reserved Instance 최적화"
echo "4. 사용하지 않는 리소스 정기 정리"
