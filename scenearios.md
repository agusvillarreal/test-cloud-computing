# Healthcare Lab Platform - Team Scenario Variants

## Base Architecture (All Teams)

All scenarios share the core Healthcare Lab Results Processing Platform, but each team will solve a different business problem with different architectural emphasis.
Common Requirements (All Scenarios)

- Must use Terraform (IaC)
- Must handle sensitive healthcare data (HIPAA considerations)
- Must implement encryption at rest and in transit
- Must have audit logging
- You can use Cognito for authentication
- Must process data asynchronously (SQS)
- Must provide patient-facing portal

## Scenario A: Multi-Laboratory Aggregation Platform

### "LabHub" - Centralized Results Aggregator

#### Business Problem

A regional health network has 15 independent laboratories. Each lab uses different systems, formats, and delivery schedules. Patients receive results from multiple labs and can't see them in one place.

Your challenge: Build a platform that aggregates results from multiple lab systems with different data formats and delivery patterns.

#### Unique Architectural Challenges

**Challenge 1: Data Format Heterogeneity**

- Lab A sends JSON via REST API
- Lab B sends HL7 messages via SFTP to S3
- Lab C sends XML via SOAP
- Lab D sends CSV files via email attachments

**Decision Required:** How do you normalize this data?

- Option A: Lambda function per lab format (12+ Lambda functions)
- Option B: Single processor with format detection (complex logic)
- Option C: ETL pipeline with AWS Glue (higher cost)

**Challenge 2: Laboratory Authentication**

- Each lab needs API credentials
- Some labs have static IPs, others don't
- Some can use API keys, others need OAuth 2.0
- How do you manage 15+ different authentication patterns?

**Challenge 3: Data Reconciliation**

- Same patient might have different IDs at different labs
- Patient "John Smith" at Lab A = "J. Smith" at Lab B
- How do you match patients across systems?
- Master Patient Index (MPI) required?

#### Specific Requirements

**Must Handle Multiple Data Formats:**

**Format 1: JSON (Quest Diagnostics style)**

```json
{
  "lab_id": "QUEST001",
  "format": "json",
  "data": {
    "patient_id": "P123456",
    "results": [...]
  }
}
```

**Format 2: HL7 Message (LabCorp style)**

```txt
MSH|^~\&|LABCORP|LAB002|PORTAL|SYSTEM|20240115103000||ORU^R01|MSG001|P|2.5
PID|1||P234567||Smith^John^A||19850315|M
OBR|1||20240115-001|CBC^Complete Blood Count
OBX|1|NM|WBC^White Blood Cell Count||7.5|10^3/uL|4.5-11.0|N|||F
```

**Format 3: XML (Hospital Lab style)**

```xml
<LabResult>
  <LabID>HOSP001</LabID>
  <Patient ID="P345678">
    <Name>Maria Garcia</Name>
  </Patient>
  <Tests>
    <Test code="CBC">
      <Component code="WBC" value="7.5" unit="10^3/uL"/>
    </Test>
  </Tests>
</LabResult>
```

**Format 4: CSV (Small Lab style)**

```csv
PatientID,LabID,TestDate,TestCode,TestName,Value,Unit,RefRange
P456789,SMALL001,2024-01-15,WBC,"White Blood Cell Count",7.5,"10^3/uL","4.5-11.0"
```

#### Architecture Decisions

**Decision 1: Data Ingestion Strategy**

| Approach | Pros | Cons | Cost |
|----------|------|------|------|
| Lambda per format | Simple, isolated | Many functions to manage | Low |
| Unified processor | Single service | Complex logic, hard to test | Medium |
| AWS Glue ETL | Built for transformations | Overkill, expensive | High |
| Step Functions | Orchestration, visibility | Complexity, state management | Medium |

You must choose and justify.

**Decision 2: Laboratory Management**

How do you store laboratory configurations?

- DynamoDB table with lab metadata?
- RDS table with connection details?
- AWS Secrets Manager for credentials?
- Combination?

**Decision 3: Patient Matching**

Two patients with similar data - same name, close birthdate:

```json
// Lab A
{"patient_id": "P123", "name": "John Smith", "dob": "1985-03-15"}

// Lab B  
{"patient_id": "JS456", "name": "J. Smith", "dob": "1985-03-15"}

// Lab C
{"patient_id": "12345", "name": "Smith, John", "dob": "03/15/1985"}
```

Are these the same person? How do you decide?

#### Required Deliverables (Scenario A Specific)

1. Lab Adapter System - Handle all 4 formats
2. Laboratory Registry - Manage 15 lab configurations
3. Patient Matching Algorithm - Documented matching rules
4. Format Validation - Reject invalid data with clear errors
5. Lab-Specific Dashboards - Show per-lab statistics
6. Data Quality Report - Track format errors by lab

#### Evaluation Emphasis (40% of grade)

- Successfully parses all 4 data formats
- Handles format errors gracefully
- Patient matching accuracy > 95%
- Separate processing queues per lab (optional)
- Lab performance metrics dashboard

---

## Scenario B: Real-Time Critical Results Alerting System

### "CritAlert" - Emergency Lab Results Notification

#### Business Problem

Some lab results are life-threatening and require immediate physician notification. Current system: lab emails results, doctor might see it hours later. Patient could die.

Your challenge: Build a system that detects critical values and immediately alerts the ordering physician via multiple channels.

#### Unique Architectural Challenges

**Challenge 1: Latency Requirements**

- Critical result must trigger alert within 60 seconds
- Can't wait for batch processing
- Can't tolerate SQS delays
- Need real-time processing path

**Decision Required:** Do you need TWO processing paths?

- Path 1: Fast lane (critical results) → Direct Lambda invocation
- Path 2: Normal lane (routine results) → SQS queue
- How do you detect which path at ingestion time?

**Challenge 2: Alert Escalation**

- 0-5 min: Page physician via SMS + App notification
- 5-15 min: If no acknowledgment, page backup physician
- 15-30 min: Escalate to department head
- 30+ min: Hospital administrator alerted

How do you implement time-based escalation?

- Step Functions with Wait states?
- DynamoDB with TTL + Lambda?
- EventBridge scheduled rules?

**Challenge 3: Alert Fatigue Prevention**

- Too many false positives → physicians ignore alerts
- Must be accurate: True critical vs borderline values
- Age-dependent, condition-dependent thresholds
- How do you model complex alert rules?

#### Critical Values Reference

**Immediate Life-Threatening Values:**

```json
{
  "critical_thresholds": {
    "potassium": {
      "critically_low": {"value": 2.5, "unit": "mmol/L", "danger": "Cardiac arrest risk"},
      "critically_high": {"value": 6.0, "unit": "mmol/L", "danger": "Cardiac arrhythmia"}
    },
    "glucose": {
      "critically_low": {"value": 40, "unit": "mg/dL", "danger": "Hypoglycemic coma"},
      "critically_high": {"value": 500, "unit": "mg/dL", "danger": "Diabetic ketoacidosis"}
    },
    "hemoglobin": {
      "critically_low": {"value": 5.0, "unit": "g/dL", "danger": "Severe anemia, organ failure"}
    },
    "platelet_count": {
      "critically_low": {"value": 20, "unit": "10^3/uL", "danger": "Spontaneous bleeding risk"}
    },
    "white_blood_cells": {
      "critically_low": {"value": 1.0, "unit": "10^3/uL", "danger": "Severe infection risk"},
      "critically_high": {"value": 50.0, "unit": "10^3/uL", "danger": "Possible leukemia"}
    }
  }
}
```

**Age-Dependent Thresholds:**

```json
{
  "glucose_pediatric": {
    "age_months": 0-12,
    "critically_low": 30  // Newborns tolerate lower glucose
  },
  "glucose_adult": {
    "age_years": 18+,
    "critically_low": 40
  }
}
```

**Sample Critical Result Event**

```json
{
  "result_id": "RES-CRIT-20240115-001",
  "patient_id": "P123456",
  "patient_name": "John Smith",
  "patient_age": 67,
  "test_code": "K",
  "test_name": "Potassium",
  "value": 6.8,
  "unit": "mmol/L",
  "reference_range": "3.5-5.0",
  "is_critical": true,
  "criticality": {
    "level": "SEVERE",
    "reason": "Critically high potassium - cardiac arrhythmia risk",
    "action_required": "Immediate physician notification and ECG monitoring"
  },
  "ordering_physician": {
    "physician_id": "DR001",
    "name": "Dr. Sarah Johnson",
    "npi": "1234567890",
    "phone": "+1-555-0101",
    "pager": "555-0102",
    "email": "s.johnson@hospital.com"
  },
  "backup_physician": {
    "physician_id": "DR002",
    "name": "Dr. Michael Chen",
    "phone": "+1-555-0201"
  },
  "test_timestamp": "2024-01-15T14:35:00Z",
  "alert_timestamp": "2024-01-15T14:35:45Z",
  "time_to_alert_seconds": 45
}
```

### Architecture Decisions

**Decision 1: Dual Processing Path**

Normal results go through standard queue. Critical results need express lane:
```
Ingestion API
    |
    ├─> Is Critical? ──YES──> Direct Lambda → Immediate Alert
    |                                    ↓
    └─> Is Normal? ──YES───> SQS Queue → Batch Processing
```

Trade-off:

- Express lane: Higher cost (Lambda concurrency), but meets SLA
- Queue only: Lower cost, but delays might be fatal
- What do you choose?

**Decision 2: Alert Delivery Mechanism**

| Method | Reliability | Latency | Cost | Acknowledgment? |
|--------|-------------|---------|------|-----------------|
| SMS | High | 5-30 sec | Medium | No (one-way) |
| Phone Call | Highest | 5-10 sec | High | Yes (can confirm) |
| App Push | Medium | 1-5 sec | Low | Yes |
| Email | Low | 30-300 sec | Lowest | No |
| Pager | High | 10-60 sec | High | No |

You must implement at least 3 methods and justify priorities.

**Decision 3: Escalation State Management**

How do you track: "Alert sent at 14:35, no ack by 14:40, escalate to backup"?

**Option A: Step Functions**

```json
{
  "StartAt": "SendPrimaryAlert",
  "States": {
    "SendPrimaryAlert": {...},
    "WaitForAck": {
      "Type": "Wait",
      "Seconds": 300
    },
    "CheckAcknowledgment": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.acknowledged",
          "BooleanEquals": true,
          "Next": "Complete"
        }
      ],
      "Default": "EscalateToBackup"
    },
    "EscalateToBackup": {...}
  }
}
```

**Option B: DynamoDB + Streams**

- Write alert to DDB with TTL = now + 5 minutes
- TTL expires → DDB Stream triggers Lambda → Escalate
- Problem: Can't cancel if physician acknowledges

**Option C: EventBridge Scheduler**

- Create scheduled rule for escalation time
- If acked, delete the rule
- More complex to manage

Which do you choose? Why?

#### Required Deliverables (Scenario B Specific)

1. Critical Value Detection Engine - Rule engine with thresholds
2. Dual Processing Architecture - Fast lane + normal lane
3. Multi-Channel Alert System - At least 3 delivery methods
4. Escalation Workflow - Automated escalation with timing
5. Acknowledgment System - Physicians can confirm receipt
6. Alert Dashboard - Real-time view of critical alerts
7. Performance SLA Report - % of alerts delivered < 60 seconds

#### Evaluation Emphasis (40% of grade)

- Critical results detected accurately (no false positives)
- Alert latency < 60 seconds (measured)
- Escalation works (tested with delayed acknowledgment)
- Multiple delivery channels implemented
- Acknowledgment tracking functional

---

## Scenario C: Longitudinal Health Analytics Platform

### "HealthTrends" - Long-Term Health Monitoring

#### Business Problem

Physicians need to see trends over time, not just individual results. Is patient's cholesterol improving? Is diabetes control getting worse? Pattern recognition requires storing and analyzing years of lab history.

Your challenge: Build a platform optimized for time-series queries and trend analysis.

#### Unique Architectural Challenges

**Challenge 1: Data Volume & Historical Storage**

- 100,000 patients
- 12 lab tests per year per patient (average)
- 10 years of history
- = 12 million lab result records
- Storage: S3 cheap, but query performance?
- RDS expensive, but fast queries?

**Decision Required:** Hot/Cold storage strategy?

- Recent data (6 months): RDS for fast queries
- Historical data (older): S3 + Athena for analytics
- How do you manage the split?

**Challenge 2: Time-Series Queries**

Physicians ask questions like:

- "Show me this patient's HbA1c trend over last 2 years"
- "Compare current cholesterol to 6-month rolling average"
- "Alert me if glucose variance increased significantly"

SQL query for this is complex:

```sql
SELECT 
  test_date,
  value,
  AVG(value) OVER (
    ORDER BY test_date 
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) as moving_avg,
  value - LAG(value) OVER (ORDER BY test_date) as delta
FROM lab_results
WHERE patient_id = 'P123456'
  AND test_code = 'HBA1C'
  AND test_date >= DATE_SUB(NOW(), INTERVAL 2 YEAR)
ORDER BY test_date;
```

**Is RDS the right choice? What about:**

- **DynamoDB:** Fast, but time-series queries are painful
- **Timestream:** AWS time-series database, but expensive
- **RDS:** Good for this, but scaling issues at millions of records
- **Athena + S3:** Cheap storage, but slow queries

**Challenge 3: Predictive Analytics**

Can you detect health deterioration **before** it becomes critical?

Example: Patient's kidney function (creatinine) slowly increasing:

```
Jan 2023: 0.9 mg/dL (normal)
Apr 2023: 1.0 mg/dL (normal)
Jul 2023: 1.2 mg/dL (normal)
Oct 2023: 1.5 mg/dL (borderline)
Jan 2024: 1.9 mg/dL (abnormal) ← Should have alerted earlier!
```

How do you detect gradual trends?

- Machine learning model?
- Statistical analysis (moving average, standard deviation)?
- Simple rules (if 3 consecutive tests increased, alert)?

#### Sample Time-Series Data

**Single Patient's HbA1c History (Diabetes Control):**

```json
{
  "patient_id": "P123456",
  "test_code": "HBA1C",
  "test_name": "Hemoglobin A1c",
  "unit": "%",
  "target_range": "<7.0",
  "time_series": [
    {"date": "2022-01-15", "value": 8.2, "status": "poor_control"},
    {"date": "2022-04-10", "value": 7.8, "status": "poor_control"},
    {"date": "2022-07-20", "value": 7.1, "status": "fair_control"},
    {"date": "2022-10-05", "value": 6.9, "status": "good_control"},
    {"date": "2023-01-18", "value": 6.5, "status": "good_control"},
    {"date": "2023-04-25", "value": 6.4, "status": "good_control"},
    {"date": "2023-07-12", "value": 6.7, "status": "good_control"},
    {"date": "2023-10-30", "value": 7.2, "status": "fair_control"},
    {"date": "2024-01-15", "value": 7.8, "status": "poor_control"}
  ],
  "trend_analysis": {
    "direction": "worsening",
    "last_6_months_avg": 7.2,
    "previous_6_months_avg": 6.6,
    "change_percent": 9.1,
    "alert": "Control deteriorating - medication adjustment may be needed"
  }
}
```

**Multi-Test Dashboard Data:**

```json
{
  "patient_id": "P123456",
  "patient_name": "John Smith",
  "age": 67,
  "conditions": ["Type 2 Diabetes", "Hypertension", "Hyperlipidemia"],
  "monitoring_panel": {
    "diabetes_control": {
      "test": "HBA1C",
      "latest_value": 7.8,
      "latest_date": "2024-01-15",
      "trend": "worsening",
      "target": "<7.0"
    },
    "kidney_function": {
      "test": "Creatinine",
      "latest_value": 1.3,
      "latest_date": "2024-01-15",
      "trend": "stable",
      "target": "0.7-1.3"
    },
    "cholesterol": {
      "test": "LDL",
      "latest_value": 95,
      "latest_date": "2023-12-10",
      "trend": "improving",
      "target": "<100"
    }
  }
}
```

### Architecture Decisions

**Decision 1: Database Strategy for Time-Series**

| Option | Query Speed | Cost (10M records) | Best For |
|--------|-------------|-------------------|----------|
| **RDS (single table)** | Fast | $500/month | Recent data only |
| **RDS (partitioned)** | Medium | $500/month | Split by year |
| **DynamoDB** | Fast (with GSI) | $300/month | NoSQL patterns |
| **Timestream** | Fastest | $800/month | True time-series |
| **Athena + S3** | Slow (10-30 sec) | $50/month | Historical data |
| **Hybrid (RDS + S3)** | Fast recent, slow historical | $250/month | Best of both |

**What do you choose? Show cost calculation.**

**Decision 2: Data Lifecycle Management**

```
New result arrives
    ↓
Store in RDS (hot storage)
    ↓
After 6 months?
    ↓
Move to S3 (cold storage)
    ↓
Delete from RDS
```

How do you implement the migration?

- Lambda on CloudWatch schedule?
- DynamoDB TTL + Lambda?
- Manual archival process?

**Decision 3: Trend Detection Algorithm**

**Simple Moving Average (easy):**

```python
def detect_trend(values):
    if len(values) < 3:
        return "insufficient_data"
    
    recent_avg = sum(values[-3:]) / 3
    previous_avg = sum(values[-6:-3]) / 3
    
    change = (recent_avg - previous_avg) / previous_avg
    
    if change > 0.15:
        return "worsening"
    elif change < -0.15:
        return "improving"
    else:
        return "stable"
```

**Statistical Analysis (better):**

```python
import numpy as np

def detect_trend_statistical(dates, values):
    # Linear regression
    x = np.array([(d - dates[0]).days for d in dates])
    y = np.array(values)
    
    slope, intercept = np.polyfit(x, y, 1)
    r_squared = np.corrcoef(x, y)[0, 1] ** 2
    
    if slope > 0 and r_squared > 0.7:
        return "significant_increase"
    elif slope < 0 and r_squared > 0.7:
        return "significant_decrease"
    else:
        return "no_significant_trend"
```

**Machine Learning (complex):**

- Use SageMaker to train model
- Predict future values
- Alert if prediction is concerning
- Cost: High, Accuracy: Best

Which approach do you implement?

#### Required Deliverables (Scenario C Specific)

1. Time-Series Database Design - Optimized for trend queries
2. Data Lifecycle Management - Hot/cold storage automation
3. Trend Detection Engine - Mathematical trend analysis
4. Historical Comparison Views - Side-by-side time periods
5. Patient Dashboard - Multi-test trend visualization
6. Predictive Alerts - Warn before values become critical
7. Performance Report - Query response times for various lookups

#### Evaluation Emphasis (40% of grade)

- Can query 10+ years of history efficiently (< 2 seconds)
- Trend detection works accurately
- Cost optimization demonstrated (hot/cold strategy)
- Visualization shows trends clearly
- Predictive alerts functional

---

## Scenario D: Multi-Tenant Laboratory SaaS Platform

### "LabCloud" - White-Label Lab Results Platform

#### Business Problem

You're building a SaaS product that small laboratories can subscribe to. Each lab is a separate tenant with isolated data, but they share infrastructure. Need to support 50+ laboratory clients on the same AWS account.

Your challenge: Build a multi-tenant architecture with complete data isolation.

#### Unique Architectural Challenges

**Challenge 1: Data Isolation**

- Lab A's patients CANNOT see Lab B's data
- Lab A's staff CANNOT access Lab B's database
- Regulatory requirement: Logical data isolation insufficient
- Need physical data separation?

**Decisions Required:**

| Isolation Level | Implementation | Cost | Security |
|-----------------|----------------|------|----------|
| Separate AWS Accounts | One account per tenant | Very High | Perfect isolation |
| Separate Databases | One RDS instance per tenant | High | Strong isolation |
| Separate Tables | Shared RDS, table per tenant | Medium | Good isolation |
| Row-Level Security | Shared table, filter by tenant_id | Low | Weak isolation |

What do you choose for 50 tenants?

**Challenge 2: Tenant Onboarding Automation**

New laboratory signs up online. System must automatically:

1. Provision dedicated infrastructure (database, S3 bucket, Cognito pool)
2. Create API credentials
3. Generate tenant-specific endpoint
4. Configure branding (logo, colors)
5. Complete in < 5 minutes

How do you automate this?

- Terraform workspace per tenant?
- CloudFormation StackSet?
- Custom Lambda provisioning orchestrator?
- AWS Control Tower?

**Challenge 3: Tenant Billing & Usage Tracking**

Each tenant pays based on:

- Number of results processed
- Storage used (S3)
- API calls made
- Compute time (ECS)

How do you track usage per tenant?

- CloudWatch metrics with tenant_id dimension?
- Cost allocation tags?
- Custom usage tracking table?
- AWS Cost and Usage Reports?

#### Sample Multi-Tenant Architecture

**Tenant Registry:**

```json
{
  "tenant_id": "LAB001",
  "company_name": "City Medical Laboratory",
  "subscription": {
    "tier": "professional",
    "monthly_fee": 299,
    "included_results": 1000,
    "overage_rate": 0.50
  },
  "infrastructure": {
    "database": "rds-lab001.cluster-abc.us-east-1.rds.amazonaws.com",
    "s3_bucket": "labcloud-lab001-data",
    "cognito_pool_id": "us-east-1_abc123",
    "api_endpoint": "https://lab001.labcloud.com/api"
  },
  "branding": {
    "logo_url": "s3://labcloud-assets/lab001/logo.png",
    "primary_color": "#0066CC",
    "portal_subdomain": "lab001"
  },
  "usage_current_month": {
    "results_processed": 850,
    "storage_gb": 12.5,
    "api_calls": 15000,
    "overage_charges": 0
  },
  "status": "active",
  "created_at": "2023-06-15T10:00:00Z"
}
```

#### Tenant Isolation Patterns

**Pattern 1: Shared RDS with Row-Level Security (Cheapest)**

```sql
-- All tenants in one table
CREATE TABLE lab_results (
  result_id VARCHAR(50) PRIMARY KEY,
  tenant_id VARCHAR(20) NOT NULL,  -- Isolation key
  patient_id VARCHAR(50),
  test_data JSONB,
  created_at TIMESTAMP
);

-- Index for tenant queries
CREATE INDEX idx_tenant ON lab_results(tenant_id);

-- Application enforces filtering
SELECT * FROM lab_results 
WHERE tenant_id = 'LAB001' 
  AND patient_id = 'P123456';
```

**Problem:** One misconfigured query leaks all tenant data!

**Pattern 2: Separate Schema per Tenant (Better)**

```sql
-- Each tenant gets isolated schema
CREATE SCHEMA lab001;
CREATE SCHEMA lab002;
CREATE SCHEMA lab003;

-- Tenant A's data
CREATE TABLE lab001.lab_results (...);

-- Tenant B's data
CREATE TABLE lab002.lab_results (...);

-- Application connects to correct schema
SET search_path TO lab001;
SELECT * FROM lab_results WHERE patient_id = 'P123456';
```

**Better:** Schema-level isolation, but still shared RDS.

**Pattern 3: Separate Database per Tenant (Best)**

```
RDS Cluster 1 → LAB001 (10 tenants)
RDS Cluster 2 → LAB002-LAB010 (9 tenants)
RDS Cluster 3 → LAB011-LAB020 (10 tenants)
```

**Pros:** Strong isolation
**Cons:** High cost, connection management

Which pattern do you choose for 50 tenants? Justify.

#### Architecture Decisions

**Decision 1: Onboarding Automation**

New tenant signs up. You need to provision:

1. Cognito User Pool
2. S3 Bucket (with encryption)
3. Database schema or instance
4. API Gateway custom domain
5. CloudWatch log group
6. IAM roles

**Option A: Terraform Workspace**

```bash
# Create new workspace
terraform workspace new lab001

# Apply infrastructure
terraform apply -var="tenant_id=LAB001"

# Takes 5-10 minutes
```

**Option B: Custom Lambda Orchestrator**

```python
def provision_tenant(tenant_id):
    # Step 1: Create S3 bucket
    s3.create_bucket(Bucket=f'labcloud-{tenant_id}')
    
    # Step 2: Create Cognito pool
    cognito.create_user_pool(PoolName=f'lab-{tenant_id}')
    
    # Step 3: Create database
    rds.create_db_cluster(DBClusterIdentifier=f'lab-{tenant_id}')
    
    # Step 4: Configure API Gateway
    apigw.create_domain_name(DomainName=f'{tenant_id}.labcloud.com')
    
    # Takes 3-5 minutes
```

**Option C: CloudFormation StackSet**

- Template defines all tenant resources
- Create new stack instance per tenant
- Automatic rollback on failure

**Which do you implement? Show comparison table.**

**Decision 2: Tenant Routing**

Request comes in: `https://lab001.labcloud.com/api/ingest`

How do you route to correct tenant infrastructure?

**Option A: Subdomain-based**

```
lab001.labcloud.com → API Gateway 1 → Lambda 1 → RDS Cluster 1
lab002.labcloud.com → API Gateway 2 → Lambda 2 → RDS Cluster 2
```

**Option B: API Key-based**

```
labcloud.com/api/ingest
Header: X-API-Key: lab001_abc123

Lambda checks API key → Determines tenant → Routes to correct DB
```

**Option C: JWT Token-based**

```
Authorization: Bearer eyJ...

Decode JWT → Extract tenant_id → Route to tenant resources
```

Which routing strategy? Trade-offs?

**Decision 3: Billing Calculation**

Track tenant usage for monthly invoicing:

```python
# Calculate monthly bill
def calculate_tenant_bill(tenant_id, month):
    # Base subscription
    subscription = get_subscription(tenant_id)
    base_fee = subscription['monthly_fee']
    included_results = subscription['included_results']
    
    # Get actual usage
    usage = get_usage_metrics(tenant_id, month)
    results_processed = usage['results_processed']
    
    # Calculate overage
    if results_processed > included_results:
        overage = results_processed - included_results
        overage_charge = overage * subscription['overage_rate']
    else:
        overage_charge = 0
    
    # Storage charges (per GB)
    storage_charge = usage['storage_gb'] * 0.50
    
    # API charges (per 1000 calls)
    api_charge = (usage['api_calls'] / 1000) * 0.10
    
    total = base_fee + overage_charge + storage_charge + api_charge
    
    return {
        'base_fee': base_fee,
        'overage_charge': overage_charge,
        'storage_charge': storage_charge,
        'api_charge': api_charge,
        'total': total
    }
```

**Where do you store usage metrics?**

- CloudWatch → Query with Insights → Slow, expensive
- DynamoDB → Write on every API call → Fast, but extra writes
- Custom metrics table → Aggregate periodically → Balanced

#### Required Deliverables (Scenario D Specific)

1. Multi-Tenant Architecture - Complete isolation design
2. Tenant Provisioning System - Automated onboarding
3. Tenant Management Dashboard - Admin interface for tenant CRUD
4. Usage Tracking System - Per-tenant metrics collection
5. Billing Calculator - Monthly invoice generation
6. Tenant Isolation Tests - Prove tenant A cannot access tenant B
7. Cost Analysis - Cost per tenant at different scales

#### Evaluation Emphasis (40% of grade)

- Complete data isolation demonstrated
- Automated tenant provisioning works
- Usage tracking accurate
- Billing calculation correct
- Scalability analysis (what happens at 100 tenants?)

---

## Scenario E: Mobile-First Patient App with Offline Support

### "LabResults Go" - Mobile-Optimized Patient Portal

#### Business Problem
Patients want to check lab results on mobile devices, often in areas with poor connectivity. Need offline-capable mobile app with sync capabilities.

**Your challenge:** Build a mobile-responsive patient portal with offline caching and background sync.

#### Unique Architectural Challenges

**Challenge 1: Offline Data Sync**

- Patient opens app without internet
- Shows cached results from last sync
- New results available on server
- How do you sync when connection restored?

**Conflict scenarios:**

```
Time: 10:00 AM
User views result offline (cached version)

Time: 10:30 AM  
Lab updates result on server (corrected typo)

Time: 11:00 AM
User's app comes online
Which version is correct?
```

**Challenge 2: Mobile Performance**

- Large result sets slow on mobile
- Images and PDFs eat bandwidth
- Need progressive loading
- Need image compression

**Decision:** How do you optimize payload size?

- Paginate results?
- Lazy-load images?
- Use CloudFront for caching?
- Compress JSON responses?

**Challenge 3: Push Notifications**

- New result arrives while app closed
- Must notify patient immediately
- iOS: APNS, Android: FCM
- How do you integrate with AWS?

#### Architecture Decisions

**Decision 1: Mobile App Technology**

| Option | Pros | Cons | Offline Support |
|--------|------|------|-----------------|
| React Native | Cross-platform, one codebase | Performance | Good (AsyncStorage) |
| Flutter | Fast, beautiful UI | Dart language | Good (Hive) |
| Native (Swift/Kotlin) | Best performance | Two codebase | Excellent |
| PWA (Progressive Web App) | No app store | Limited features | Good (Service Workers) |

What do you choose? Why?

**Decision 2: Offline Storage Strategy**

```javascript
// Service Worker for PWA
self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((response) => {
      // Return cached version if available
      if (response) {
        return response;
      }
      
      // Otherwise fetch from network
      return fetch(event.request).then((networkResponse) => {
        // Cache the new response
        return caches.open('v1').then((cache) => {
          cache.put(event.request, networkResponse.clone());
          return networkResponse;
        });
      });
    })
  );
});
```

**Problem:** Stale data. How do you invalidate cache?

**Decision 3: Push Notification Architecture**

```
New Result Arrives
    ↓
Lambda Processor saves to database
    ↓
Lambda sends SNS message
    ↓
SNS Topic triggers notification Lambda
    ↓
Lambda calls Pinpoint/SNS
    ↓
Pinpoint → APNS → iOS device
Pinpoint → FCM → Android device
```

Alternative: Use AWS AppSync for real-time subscriptions?

#### Required Deliverables (Scenario E Specific)

1. Mobile-Responsive Portal - Works on all screen sizes
2. Offline Mode - App functions without internet
3. Background Sync - Auto-sync when connection restored
4. Push Notifications - Alert on new results
5. Image Optimization - Compressed images, lazy loading
6. Performance Report - Load times, bundle size, cache hit rate

#### Evaluation Emphasis (40% of grade)

- Works offline (tested with network disabled)
- Sync works correctly
- Push notifications delivered
- Mobile performance (< 3 second load)

---

## Scenario F: Compliance & Audit-Focused Platform

### "LabSecure" - Maximum Compliance Healthcare Platform

#### Business Problem

Laboratory handles highly sensitive VIP patient data (politicians, celebrities). Need maximum security, complete audit trails, and compliance with HIPAA, GDPR, and institutional policies.

Your challenge: Build the most secure version of the platform with comprehensive auditing.

#### Unique Architectural Challenges

**Challenge 1: Complete Audit Trail**

- Who accessed what data, when?
- Every API call logged
- Every database query logged
- Every S3 object access logged
- Immutable audit logs (can't be deleted)

**Challenge 2: Data Access Justification**

- Users must provide reason for accessing patient data
- "Break glass" emergency access
- Audit committee reviews suspicious access
- How do you enforce this?

**Challenge 3: Data Retention & Destruction**

- HIPAA: Must keep data 7 years
- GDPR: Patient can request deletion ("right to be forgotten")
- How do you handle conflicting requirements?
- What if patient is in US (HIPAA) but EU citizen (GDPR)?

#### Required Deliverables (Scenario F Specific)

1. Complete Audit Logging - Every action logged
2. Access Justification System - Users explain why accessing data
3. Immutable Audit Trail - Logs cannot be modified/deleted
4. Data Lifecycle Management - Automated retention/deletion
5. Security Dashboard - Real-time security monitoring
6. Compliance Reports - HIPAA, GDPR compliance evidence

---

## Scenario Comparison Matrix

| Scenario | Primary Challenge | DB Recommendation | Compute Recommendation | Difficulty |
|----------|-------------------|-------------------|------------------------|------------|
| A: Multi-Lab Aggregation | Data format heterogeneity | RDS (relational mapping) | Lambda (per-format parsers) | ⭐⭐⭐⭐ |
| B: Critical Alerts | Real-time latency | DynamoDB (fast) | Lambda (direct invoke) | ⭐⭐⭐⭐⭐ |
| C: Health Trends | Time-series queries | RDS (SQL analytics) or Timestream | ECS (analytical processing) | ⭐⭐⭐⭐ |
| D: Multi-Tenant SaaS | Tenant isolation | RDS per tenant cluster | ECS (shared) | ⭐⭐⭐⭐⭐ |
| E: Mobile Offline | Offline sync | DynamoDB (conflict resolution) | Lambda + AppSync | ⭐⭐⭐⭐ |
| F: Compliance Max | Audit everything | RDS (audit tables) | Lambda (logging) | ⭐⭐⭐ |

---

## Team Selection Process

Each team must:

1. Choose ONE scenario (no duplicates allowed)
2. Justify their choice in writing (why this scenario fits team skills)
3. Identify their biggest concern about the chosen scenario