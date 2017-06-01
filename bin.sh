FILE="$1"
API_KEY="$2"
APP_KEY="$3"
URL='https://app.datadoghq.com/api/v1/events'

if [ -z "$FILE" ]; then
  echo >&2 "Usage: datadog-watch [file] [api_key] [app_key]"
  exit 1
fi

json_escape () {
  printf '%s' "$1" | python -c 'import json,sys; print(json.dumps(sys.stdin.read()))'
}

json_body() {
  printf '{
    "title": "[Log] New entries in %s",
    "text": %s,
    "priority": "normal",
    "host": %s,
    "alert_type": "warning",
    "date_happened": %s
  }' "$FILE" "$(json_escape "$1")" "$(json_escape "$(hostname)")" "$(date +%s)"
}

log() {
  echo >&2 "[$(date)] $1"
}

capture() {
  while read initial; do
    while read -t 2 data; do
      initial+=$'\n'
      initial+="$data"
    done

    log "Sending data to datadog"

    curl -sS -X POST -H "Content-Type: application/json" \
      -d "$(json_body "$initial")" \
      "${URL}?api_key=${API_KEY}&application_key=${APP_KEY}" > /dev/null

    if [ $? -ne 0 ]; then
      log "Failed to send data"
    else
      log "Successfully sent data"
    fi
  done

  log "Capture exited"
}

log "Watching $FILE"

tail -f -n 0 $1 | capture
