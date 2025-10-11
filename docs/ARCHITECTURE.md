# E-commerce Data Warehouse Architecture

## Overview

This document describes the architecture of our modern, cloud-native data warehouse built on Google Cloud Platform using the Medallion Architecture pattern with dbt for transformations.

## Architecture Diagrams

### 1. Entity Relationship Diagram (Gold Layer)
![ER Diagram](diagrams/er_gold.mmd)

### 2. Complete Architecture Flow
![Architecture](diagrams/architecture.mmd)

### 3. dbt Model Lineage
![Lineage](diagrams/lineage.mmd)

## Medallion Architecture Implementation

### Bronze Layer (`bronze_ds`)
**Purpose**: Raw data preservation with zero transformations

| Table | Records | Description |
|-------|---------|-------------|
| `crm_cust_info` | 18,494 | Customer information from CRM system |
| `crm_prd_info` | 397 | Product catalog from CRM system |
| `crm_sales_details` | 60,398 | Sales transactions from CRM system |
| `erp_cust_az12` | 18,484 | Customer details from ERP system |
| `erp_loc_a101` | 18,484 | Location data from ERP system |
| `erp_px_cat_g1v2` | 37 | Product categories from ERP system |

**Total Bronze Records**: 116,294

### Silver Layer (`silver_ds_silver_ds`)
**Purpose**: Cleaned, deduplicated, and standardized data

#### `customers` Model
```sql
-- Schema
customer_key: STRING (PK, deterministic surrogate key)
customer_id: INT64 (business key)
full_name: STRING (with ERP fallback and placeholder logic)
gender: STRING (standardized M/F)
create_date: DATE
dwh_create_date: TIMESTAMP

-- Key Features
- Deduplication by customer_id with name completeness prioritization
- NULL-safe surrogate key generation using farm_fingerprint()
- Robust full_name construction with fallbacks
- 18,494 unique customer records
```

#### `products` Model
```sql
-- Schema
product_id: INT64 (PK)
product_key: STRING
product_name: STRING
product_cost: INT64
product_line: STRING
start_date: DATE
end_date: DATE
dwh_create_date: TIMESTAMP

-- Key Features
- Product standardization and data type casting
- 397 product records
```

#### `sales` Model
```sql
-- Schema
sale_key: STRING (PK, deterministic surrogate key)
sale_id: STRING (business key)
customer_id: INT64 (FK to customers)
product_key: INT64 (FK to products)
order_date: DATE
ship_date: DATE
due_date: DATE
quantity: INT64
price: NUMERIC
sales_amount: NUMERIC (computed when missing)
dwh_create_date: TIMESTAMP

-- Key Features
- Deduplication from 60,398 → 27,659 records (58% deduplication)
- Sales amount computation: COALESCE(original, quantity × price)
- NULL-safe sale_key generation
- Priority-based deduplication favoring complete data
```

### Gold Layer (`silver_ds_gold_ds`)
**Purpose**: Analytics-ready dimensional model (Star Schema)

#### `dim_customers` - Customer Dimension
```sql
-- Schema
customer_key: STRING (PK)
customer_id: INT64
full_name: STRING
gender: STRING
create_date: DATE
last_seen: TIMESTAMP

-- Configuration
materialized: incremental
unique_key: customer_key
strategy: merge
```

#### `dim_products` - Product Dimension
```sql
-- Schema
product_id: INT64 (PK)
product_key: STRING
product_name: STRING
product_cost: INT64
product_line: STRING
start_date: DATE
end_date: DATE
last_updated: TIMESTAMP

-- Configuration
materialized: incremental
unique_key: product_id
strategy: merge
```

#### `fact_sales` - Sales Fact Table
```sql
-- Schema
sale_key: STRING (PK)
sale_id: STRING
customer_id: INT64 (FK to dim_customers)
product_key: INT64 (FK to dim_products)
order_date: DATE
ship_date: DATE
due_date: DATE
quantity: INT64
price: NUMERIC
sales_amount: NUMERIC
dwh_create_date: TIMESTAMP

-- Configuration
materialized: incremental
unique_key: sale_key
strategy: merge
-- Filters out NULL surrogate keys
```

### QA Layer (`silver_ds`)
**Purpose**: Data governance and audit trail

#### `qa_issues` - Quality Audit Table
```sql
-- Purpose
- Logs all filtered/duplicated records
- Tracks data quality decisions
- Enables root cause analysis
- 17,996 audit records for complete transparency

-- Content Types
- Bronze duplicate tracking
- Filtered customer records
- Data quality violations
- Transformation decisions
```

## Data Quality Framework

### Testing Strategy
- **19 comprehensive tests** across all layers
- **18 passing tests** + 1 expected warning
- **100% critical test coverage**

### Test Categories

#### Surrogate Key Tests (Strict)
```yaml
- not_null: sale_key, customer_key (must pass)
- unique: sale_key, customer_key (must pass)
```

#### Business Key Tests (Warning Level)
```yaml
- unique: customer_id, sale_id (warn only)
- Purpose: Alert to duplicates without breaking CI
```

#### Data Quality Tests
```yaml
- not_null: full_name, sales_amount, product_name
- referential_integrity: customer/product relationships
```

### Deduplication Logic

#### Sales Deduplication
```sql
ROW_NUMBER() OVER (
  PARTITION BY COALESCE(sale_id, synthetic_key)
  ORDER BY 
    CASE WHEN sales_amount IS NOT NULL THEN 1 ELSE 2 END,
    dwh_create_date DESC
)
-- Prioritizes: complete sales_amount > latest timestamp
```

#### Customer Deduplication
```sql
ROW_NUMBER() OVER (
  PARTITION BY customer_id
  ORDER BY
    name_completeness_score ASC,  -- 1=both names, 2=one name, 3=no names
    dwh_create_date DESC
)
-- Prioritizes: complete names > partial names > latest timestamp
```

## Performance Characteristics

### Processing Metrics
- **End-to-end Runtime**: 8-10 seconds for full pipeline
- **Data Reduction**: 116,294 → 79,289 records (32% deduplication)
- **Test Execution**: 9 seconds for 19 comprehensive tests

### Storage Optimization
- **BigQuery Columnar Storage**: Automatic compression and optimization
- **Incremental Models**: Only process changed data (MERGE strategy)
- **Partitioning**: Date-based where applicable
- **Clustering**: On frequently-queried dimensions

## Technology Stack

### Core Components
- **Data Warehouse**: Google BigQuery (serverless, auto-scaling)
- **Transformation**: dbt Core v1.10.2
- **Orchestration**: dbt run/test commands
- **Version Control**: Git with feature branch workflow
- **Documentation**: Auto-generated dbt docs with lineage

### Key dbt Features Used
- **Incremental Models**: MERGE strategy for upserts
- **Sources**: Bronze layer table definitions
- **Tests**: Comprehensive data quality validation
- **Macros**: Reusable transformation logic
- **Documentation**: Auto-generated catalog with lineage

## Development Workflow

### Git Workflow
```bash
# Feature development
git checkout -b feature/new-feature
# Make changes to dbt models
dbt run --select modified_models+
dbt test --select modified_models+
git commit -m "feat(silver): description"
git push origin feature/new-feature
# Create pull request
```

### Testing Workflow
```bash
# Development testing
dbt run --select silver+     # Run models
dbt test --select silver+    # Run tests
dbt docs generate            # Update docs
dbt docs serve --port 8080   # Review changes
```

### Deployment Workflow
```bash
# Production deployment
dbt run --profiles-dir ~/.dbt           # Full pipeline
dbt test --profiles-dir ~/.dbt          # All tests
dbt docs generate --profiles-dir ~/.dbt # Update docs
```

## Data Governance

### Audit Trail
- **Complete Transparency**: No data lost silently
- **QA Issues Table**: 17,996 audit records
- **Deduplication Tracking**: All decisions logged
- **Change Tracking**: dwh_create_date on all records

### Data Quality Assurance
- **NULL-Safe Transformations**: COALESCE patterns throughout
- **Deterministic Keys**: farm_fingerprint() for reproducible results
- **Robust Error Handling**: Graceful handling of data quality issues
- **Comprehensive Testing**: 19 tests covering all critical paths

### Compliance Features
- **Data Lineage**: Complete visibility through dbt docs
- **Transformation Logic**: All SQL available in version control
- **Change History**: Git history of all modifications
- **Quality Metrics**: Automated test results and reporting

## Future Enhancements

### Immediate Priorities
1. **CI/CD Pipeline**: Automated testing and deployment
2. **Data Quality Monitoring**: Automated alerts and dashboards
3. **Performance Optimization**: Query tuning and partitioning
4. **Business User Documentation**: Self-service data catalog

### Advanced Features
1. **Real-time Streaming**: CDC from operational systems
2. **Machine Learning**: Feature engineering and model serving
3. **Data Mesh**: Domain-oriented data ownership
4. **Advanced Governance**: Privacy compliance and data classification

---

*This architecture demonstrates enterprise-grade data engineering with modern cloud-native tools, comprehensive testing, and production-ready practices suitable for analytics at scale.*