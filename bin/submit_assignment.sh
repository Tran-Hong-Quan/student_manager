#!/bin/bash
# submit_assignment.sh <Assignment> <FileSinhVien>

if [ $# -ne 2 ]; then
    echo "Usage: $0 <Assignment> <FileSinhVien>"
    exit 1
fi

ASSIGNMENT=$1
FILE=$2
MSSV=$(whoami | sed 's/^SV-//')  # lấy mã SV từ user SV-xxxx

# Kiểm tra file sinh viên có tồn tại
if [ ! -f "$FILE" ]; then
    echo "Error: file $FILE not found"
    exit 1
fi

# Dùng đường dẫn tuyệt đối
FILE_PATH=$(realpath "$FILE")   
REQ="$MSSV $ASSIGNMENT $FILE_PATH"

# Socket path trùng với server
SCRIPT_DIR="$(dirname "$0")"
SOCKET_PATH="$SCRIPT_DIR/../data/tmp/grading_socket"

if [ ! -S "$SOCKET_PATH" ]; then
    echo "Error: grading server not running."
    exit 1
fi

# Debug (có thể bỏ nếu muốn)
# echo "[DEBUG] Sending request: $REQ"

# Gửi yêu cầu qua socket
echo "$REQ" | socat - UNIX-CONNECT:"$SOCKET_PATH"

