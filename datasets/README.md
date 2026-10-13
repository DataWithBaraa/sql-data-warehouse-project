# Project datasets

Two source systems, six CSV files:

| Folder | Files |
|---|---|
| `source_crm/` | `cust_info.csv`, `prd_info.csv`, `sales_details.csv` |
| `source_erp/` | `CUST_AZ12.csv`, `LOC_A101.csv`, `PX_CAT_G1V2.csv` |

## Where SQL Server expects the files

The bronze loader, `scripts/bronze/proc_load_bronze.sql`, reads the files with `BULK INSERT` from `C:\sql\dwh_project\datasets\`. That is the folder used in the videos. Either put the `datasets` folder there, or change the six paths in the script to your folder.

SQL Server reads the files itself, not your user account. So the folder must be readable by the SQL Server service. A folder directly on `C:\` works. `Downloads` or `Desktop` often fails with "Cannot bulk load" (Msg 4860).

On Mac or Linux with Docker, copy the `datasets` folder into the container and use that path in the script. The steps are in the course's environment setup guide: [sql-ultimate-course/docs/environment_setup.md](https://github.com/DataWithBaraa/sql-ultimate-course/blob/main/docs/environment_setup.md).
