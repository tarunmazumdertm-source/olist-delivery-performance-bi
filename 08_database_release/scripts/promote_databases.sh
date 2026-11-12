#!/bin/bash
set -Eeuo pipefail

BACKUP_DIR="08_database_release/backups/20261112_104634"
STAGE_DIR="08_database_release/prepared_dumps/$(date +%Y%m%d_%H%M%S)"

SOURCES=(
  olist_meta_test
  olist_psa_test
  olist_dwh_test
  olist_dm_test
)

TARGETS=(
  olist_meta
  olist_psa
  olist_dwh
  olist_dm
)

echo "=== OLIST PRODUCTION DATABASE PROMOTION ==="

if [[ "$(basename "$PWD")" != "Olist_Project" ]]; then
    echo "ERROR: Run this script from Olist_Project."
    exit 1
fi

# Check all source databases and backup files.
for db in "${SOURCES[@]}"; do
    count=$(mysql -u root -N -B -e \
      "SELECT COUNT(*) FROM information_schema.schemata
       WHERE schema_name='$db'")

    if [[ "$count" != "1" ]]; then
        echo "ERROR: Source database $db is missing."
        exit 1
    fi

    if [[ ! -s "$BACKUP_DIR/$db.sql" ]]; then
        echo "ERROR: Backup file for $db is missing or empty."
        exit 1
    fi
done

# Never overwrite an existing production database.
existing=$(mysql -u root -N -B -e "
SELECT schema_name
FROM information_schema.schemata
WHERE schema_name IN (
'olist_meta','olist_psa','olist_dwh','olist_dm'
)")

if [[ -n "$existing" ]]; then
    echo "ERROR: A production database already exists:"
    echo "$existing"
    echo "No production databases were modified."
    exit 1
fi

# Prepare transformed copies. Original backups remain unchanged.
mkdir -p "$STAGE_DIR"

echo "Preparing database dumps..."

cp "$BACKUP_DIR/olist_meta_test.sql" \
   "$STAGE_DIR/olist_meta.sql"

# Redirect all nine PSA foreign keys to the production metadata schema.
sed 's/REFERENCES `olist_meta_test`\./REFERENCES `olist_meta`./g' \
  "$BACKUP_DIR/olist_psa_test.sql" \
  > "$STAGE_DIR/olist_psa.sql"

# Update descriptive comments only; preserve data values.
sed "s/COMMENT 'olist_meta_test\.etl_run/COMMENT 'olist_meta.etl_run/g" \
  "$BACKUP_DIR/olist_dwh_test.sql" \
  > "$STAGE_DIR/olist_dwh.sql"

sed "s/COMMENT 'olist_meta_test\.etl_run/COMMENT 'olist_meta.etl_run/g" \
  "$BACKUP_DIR/olist_dm_test.sql" \
  > "$STAGE_DIR/olist_dm.sql"

# Verify all nine cross-database references were updated.
psa_refs=$(grep -c 'REFERENCES `olist_meta`\.`etl_run`' \
  "$STAGE_DIR/olist_psa.sql" || true)

if [[ "$psa_refs" != "9" ]]; then
    echo "ERROR: Expected 9 corrected PSA foreign keys; found $psa_refs."
    exit 1
fi

echo "PSA foreign-key references: $psa_refs verified."

# Create production databases.
echo "Creating production schemas..."

mysql -u root -e "
CREATE DATABASE olist_meta CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE DATABASE olist_psa CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE DATABASE olist_dwh CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE DATABASE olist_dm CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
"

# Restore in dependency order.
echo "Restoring metadata..."
mysql -u root --show-warnings olist_meta \
  < "$STAGE_DIR/olist_meta.sql"

echo "Restoring PSA..."
mysql -u root --show-warnings olist_psa \
  < "$STAGE_DIR/olist_psa.sql"

echo "Restoring DWH..."
mysql -u root --show-warnings olist_dwh \
  < "$STAGE_DIR/olist_dwh.sql"

echo "Restoring Data Mart..."
mysql -u root --show-warnings olist_dm \
  < "$STAGE_DIR/olist_dm.sql"

# Final object inventory.
echo ""
echo "=== PRODUCTION OBJECT INVENTORY ==="

mysql -u root --table -e "
SELECT table_schema, table_type, COUNT(*) AS object_count
FROM information_schema.tables
WHERE table_schema IN (
'olist_meta','olist_psa','olist_dwh','olist_dm'
)
GROUP BY table_schema, table_type
ORDER BY table_schema, table_type;

SELECT routine_schema, routine_name, routine_type
FROM information_schema.routines
WHERE routine_schema IN (
'olist_meta','olist_psa','olist_dwh','olist_dm'
);

SELECT
    COUNT(*) AS remaining_test_schema_foreign_keys
FROM information_schema.key_column_usage
WHERE referenced_table_schema IN (
'olist_meta_test','olist_psa_test',
'olist_dwh_test','olist_dm_test'
)
AND table_schema IN (
'olist_meta','olist_psa','olist_dwh','olist_dm'
);
"

echo ""
echo "PROMOTION RESTORE COMPLETED."
echo "Prepared SQL files: $STAGE_DIR"
echo "Original test databases and backups were not modified."
echo "Next: run production row-count and KPI validation."
