/*
=========================================================
Create Database: DataWarehouse
=========================================================

Script Purpose:
    This script creates a new database named 'DataWarehouse'.
    If the database already exists, it will be dropped and
    recreated.

WARNING:
    Running this script will permanently delete the existing
    'DataWarehouse' database and all data stored in it.
    Proceed with caution and ensure you have proper backups
    before running this script.

PostgreSQL Note:
    This script must be executed while connected to another
    database, such as the default 'postgres' database.
    After creating 'DataWarehouse', connect to it before
    running the next scripts.
=========================================================
*/

-- Drop and recreate the 'DataWarehouse' database

DROP DATABASE IF EXISTS "DataWarehouse";

CREATE DATABASE "DataWarehouse";
