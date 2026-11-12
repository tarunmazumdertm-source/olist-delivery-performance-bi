#!/usr/bin/env bash
set -euo pipefail

# Start the dashboard for teammates on the same trusted Wi-Fi.
# This file lives in: Olist_Project/06_final_deliverables/dashboard/scripts/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DASHBOARD_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"          # .../06_final_deliverables/dashboard
DELIVERABLES_DIR="$(cd "${DASHBOARD_DIR}/.." && pwd)"   # .../06_final_deliverables
PROJECT_ROOT="$(cd "${DELIVERABLES_DIR}/.." && pwd)"    # .../Olist_Project
APP_PATH="${DASHBOARD_DIR}/app.py"

if [[ ! -f "$APP_PATH" ]]; then
  echo "ERROR: Dashboard app.py not found at: $APP_PATH"
  echo "Check that the restored dashboard is saved in 06_final_deliverables/dashboard/app.py"
  exit 1
fi

if ! command -v streamlit >/dev/null 2>&1; then
  echo "Streamlit was not found. Activate the hfu_ml Conda environment first."
  exit 1
fi

MAC_IP="$(ipconfig getifaddr en0 2>/dev/null || true)"
echo "Project: $PROJECT_ROOT"
echo "Dashboard: $APP_PATH"
echo "On this Mac: http://localhost:8501"
if [[ -n "$MAC_IP" ]]; then
  echo "For teammates on the same trusted Wi-Fi: http://${MAC_IP}:8501"
else
  echo "Could not detect Wi-Fi IP on en0. Run: ipconfig getifaddr en0"
fi
echo "Stop sharing with Ctrl+C. Keep the macOS firewall enabled."
exec streamlit run "$APP_PATH" --server.address 0.0.0.0 --server.port 8501
