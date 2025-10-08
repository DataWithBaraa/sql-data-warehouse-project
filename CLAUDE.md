# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Database Commands

This project uses SQL Server and requires SQL Server Management Studio (SSMS) or similar SQL client. The project follows a structured ETL pipeline with specific execution order:

### Initial Database Setup
```sql
-- Run once to create database and schemas
sqlcmd -S <server> -d master -i scripts/init_database.sql
```

### DDL Scripts (Data Definition Language)
```sql
-- Create Bronze layer tables
sqlcmd -S <server> -d DataWarehouse -i scripts/bronze/ddl_bronze.sql

-- Create Silver layer tables  
sqlcmd -S <server> -d DataWarehouse -i scripts/silver/ddl_silver.sql

-- Create Gold layer views
sqlcmd -S <server> -d DataWarehouse -i scripts/gold/ddl_gold.sql
```

### ETL Pipeline Execution
```sql
-- Load data into Bronze layer from CSV files
EXEC bronze.load_bronze;

-- Transform and load data into Silver layer
EXEC silver.load_silver;
```

### Data Quality Tests
```sql
-- Run quality checks on Silver layer
sqlcmd -S <server> -d DataWarehouse -i tests/quality_checks_silver.sql

-- Run quality checks on Gold layer
sqlcmd -S <server> -d DataWarehouse -i tests/quality_checks_gold.sql
```

## Architecture Overview

This is a **Data Warehouse and Analytics Project** implementing the **Medallion Architecture** with three distinct layers:

### Data Flow Architecture
- **Bronze Layer**: Raw data ingestion from CSV files (ERP and CRM systems)
  - Tables follow naming pattern: `<sourcesystem>_<entity>` 
  - Example: `crm_cust_info`, `erp_loc_a101`
  - Data loaded via BULK INSERT from CSV files

- **Silver Layer**: Cleaned and standardized data
  - Same naming pattern as Bronze but with data cleansing applied
  - Stored procedures transform data: `bronze.load_bronze` → `silver.load_silver`
  - Includes data quality validations and standardization

- **Gold Layer**: Business-ready dimensional model (Star Schema)
  - Fact and dimension tables/views for analytics
  - Naming pattern: `dim_<entity>` for dimensions, `fact_<entity>` for facts
  - Views combining Silver layer data: `dim_customers`, `dim_products`, `fact_sales`

### Schema Structure
- **bronze**: Raw data tables matching source system formats
- **silver**: Cleansed and standardized tables
- **gold**: Dimensional views for reporting and analytics

### Data Sources
- **CRM System**: Customer info, product info, sales details (CSV files)
- **ERP System**: Customer details, location data, product categories (CSV files)

## Key Implementation Details

### Naming Conventions
- Database objects use **snake_case** with lowercase letters
- Bronze/Silver: `<sourcesystem>_<entity>` pattern
- Gold: `<category>_<entity>` pattern (`dim_`, `fact_`, `report_`)
- Surrogate keys: `<table_name>_key` suffix
- Technical columns: `dwh_` prefix (e.g., `dwh_create_date`)

### ETL Process
1. **Extract**: BULK INSERT from CSV files to Bronze layer
2. **Transform**: Data cleansing and standardization to Silver layer  
3. **Load**: Dimensional modeling views in Gold layer

### Data Quality Framework
- Comprehensive quality checks in `tests/` directory
- Validates primary keys, data consistency, date ranges, and business rules
- Must run after each layer transformation

### File Structure
- `datasets/`: Source CSV files (CRM and ERP data)
- `scripts/`: SQL DDL and stored procedures organized by layer
- `docs/`: Architecture diagrams, data catalog, and documentation
- `tests/`: Quality validation scripts

This project demonstrates enterprise data warehousing best practices including data lineage, quality validation, and dimensional modeling suitable for analytics and reporting.