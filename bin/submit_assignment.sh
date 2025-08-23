#!/bin/bash
# submit_assignment.sh <Assignment> <FileSinhVien>

if [ $# -ne 2 ]; then
    echo "Usage: $0 <Assignment> <FileSinhVien>"
    exit 1
fi

ASSIGNMENT=$1
FILE=$2
MSSV=$(whoami | sed 's/^SV-//')  # lấy mã SV từ user SV-xxxx

if [ ! -S /tmp/grading_socket ]; then
    echo "Error: grading server not running."
    exit 1
fi

FILE_PATH=$(realpath "$FILE")   # dùng đường dẫn tuyệt đối
REQ="$MSSV $ASSIGNMENT $FILE_PATH"

# Gửi yêu cầu qua socket
echo "$REQ" | socat - UNIX-CONNECT:/tmp/grading_socket

