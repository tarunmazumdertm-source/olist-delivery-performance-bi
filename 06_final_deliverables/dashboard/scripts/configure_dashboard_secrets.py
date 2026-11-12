
import getpass
import secrets
import stat
from pathlib import Path

import mysql.connector

# Project paths
script_dir = Path(__file__).resolve().parents[1]
secrets_dir = script_dir / ".streamlit"
secrets_file = secrets_dir / "secrets.toml"
gitignore_file = script_dir / ".gitignore"

# Database settings
host = "127.0.0.1"
port = 3306
user = "olist_dashboard"
database = "olist_dm_test"

print("Olist Dashboard - Secure Database Setup")

root_password = getpass.getpass(
    "MySQL root password (press Enter if none): "
)

# Generate a new private password on this Mac.
dashboard_password = secrets.token_urlsafe(36)

connection = None

try:
    connection = mysql.connector.connect(
        host=host,
        port=port,
        user="root",
        password=root_password,
        autocommit=True
    )

    cursor = connection.cursor()

    # Create account if it does not already exist.
    cursor.execute(
        f"CREATE USER IF NOT EXISTS '{user}'@'{host}' "
        f"IDENTIFIED BY '{dashboard_password}'"
    )

    # Rotate its password.
    cursor.execute(
        f"ALTER USER '{user}'@'{host}' "
        f"IDENTIFIED BY '{dashboard_password}'"
    )

    # Grant read-only access.
    cursor.execute(
        f"GRANT SELECT ON `{database}`.* "
        f"TO '{user}'@'{host}'"
    )

    cursor.execute(
        f"GRANT SELECT ON `olist_meta_test`.`etl_run` "
        f"TO '{user}'@'{host}'"
    )

    cursor.close()
    connection.close()
    connection = None

    # Test the dashboard account.
    test_connection = mysql.connector.connect(
        host=host,
        port=port,
        user=user,
        password=dashboard_password,
        database=database
    )

    test_cursor = test_connection.cursor()

    test_cursor.execute(
        "SELECT COUNT(*) FROM fact_order_fulfillment"
    )
    row_count = test_cursor.fetchone()[0]

    test_cursor.close()
    test_connection.close()

    # Create private Streamlit configuration.
    secrets_dir.mkdir(parents=True, exist_ok=True)

    secrets_content = f"""[mysql]
host = "{host}"
port = {port}
user = "{user}"
password = "{dashboard_password}"
database = "{database}"
"""

    secrets_file.write_text(secrets_content, encoding="utf-8")
    secrets_file.chmod(stat.S_IRUSR | stat.S_IWUSR)

    # Protect secrets.toml from Git.
    ignore_line = ".streamlit/secrets.toml"

    existing = (
        gitignore_file.read_text(encoding="utf-8")
        if gitignore_file.exists()
        else ""
    )

    if ignore_line not in existing.splitlines():
        with gitignore_file.open("a", encoding="utf-8") as file:
            if existing and not existing.endswith("\n"):
                file.write("\n")
            file.write(ignore_line + "\n")

    print("\nSUCCESS")
    print("MySQL dashboard account configured.")
    print("Read-only database access verified.")
    print(f"Verified fulfillment rows: {row_count:,}")
    print(f"Private credentials saved: {secrets_file}")
    print("Password was not displayed.")

except Exception as error:
    print("\nSETUP FAILED")
    print("Error:", error)

finally:
    if connection and connection.is_connected():
        connection.close()
