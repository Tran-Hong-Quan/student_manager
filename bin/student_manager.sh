#!/bin/bash

# File: grade_student_assignment_with_args.sh

if [ $# -ne 2 ]; then
    echo "Usage: $0 <assignment_directory> <student_file>"
    echo "  <assignment_directory>: thư mục chứa input.txt và output.txt"
    echo "  <student_file>: file thực thi (.o) hoặc script (.sh) của sinh viên"
    exit 1
fi

ASSIGN_DIR="$1"
STUDENT_FILE="$2"

INPUT_FILE="$ASSIGN_DIR/input.txt"
OUTPUT_FILE="$ASSIGN_DIR/output.txt"

if [ ! -f "$STUDENT_FILE" ]; then
    echo "Error: Student file '$STUDENT_FILE' does not exist!"
    exit 1
fi

# Nếu có input.txt thì sẽ đọc test case từ đó
if [ -f "$INPUT_FILE" ] && [ -f "$OUTPUT_FILE" ]; then
    TOTAL=$(wc -l < "$INPUT_FILE")
    CORRECT=0

    for i in $(seq 1 $TOTAL); do
        INPUT_LINE=$(sed -n "${i}p" "$INPUT_FILE")
        EXPECTED=$(sed -n "${i}p" "$OUTPUT_FILE")

        ACTUAL=$("$STUDENT_FILE" $INPUT_LINE 2>/dev/null)

        if [ "$ACTUAL" = "$EXPECTED" ]; then
            CORRECT=$((CORRECT+1))
        fi
    done
else
    # Không có input/output.txt thì chỉ kiểm tra chạy chương trình không lỗi
    if "$STUDENT_FILE" >/dev/null 2>&1; then
        TOTAL=1
        CORRECT=1
    else
        TOTAL=1
        CORRECT=0
    fi
fi

# Tính điểm theo thang 100
SCORE=$(echo "scale=2; 100 * $CORRECT / $TOTAL" | bc)
printf "Score: %.2f\n" "$SCORE"

