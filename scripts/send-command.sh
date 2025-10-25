#!/bin/bash
# Script to send commands from n8n container to Windows host
# Mount shared directory at /shared in the container
# Usage: ./send-command.sh "dir C:\"

COMMAND_DIR="/shared/commands"
RESPONSE_DIR="/shared/responses"

if [ -z "$1" ]; then
    echo "Usage: $0 \"command to execute\""
    exit 1
fi

COMMAND="$1"
CMD_ID=$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)

# Create command file
cat > "${COMMAND_DIR}/${CMD_ID}.json" <<EOF
{
  "command": "${COMMAND}",
  "timestamp": "$(date -Iseconds)"
}
EOF

echo "Command submitted: ${CMD_ID}"
echo "Waiting for response..."

# Wait for response (timeout after 30 seconds)
TIMEOUT=30
ELAPSED=0
RESPONSE_FILE="${RESPONSE_DIR}/${CMD_ID}.json"

while [ ! -f "$RESPONSE_FILE" ] && [ $ELAPSED -lt $TIMEOUT ]; do
    sleep 0.5
    ELAPSED=$((ELAPSED + 1))
done

if [ -f "$RESPONSE_FILE" ]; then
    echo ""
    echo "Response received:"
    cat "$RESPONSE_FILE"
    rm -f "$RESPONSE_FILE"
else
    echo ""
    echo "ERROR: Timeout - no response after ${TIMEOUT} seconds"
    echo "Make sure the command listener is running on the host!"
    exit 1
fi
