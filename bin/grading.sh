#!/bin/bash

# grade_assignment.sh
# Usage: ./grade_assignment.sh <assignment_dir> <student_file>

assignment_dir="$1"
student_file="$2"

input_file="$assignment_dir/input.txt"
output_file="$assignment_dir/output.txt"

# Kiểm tra tồn tại output chuẩn
if [ ! -f "$output_file" ]; then
    echo "0.00"
    exit 0
fi

# Đọc test cases
if [ -f "$input_file" ]; then
    mapfile -t inputs < "$input_file"
else
    inputs=("")
fi

mapfile -t expected_outputs < "$output_file"

total_cases=${#expected_outputs[@]}
if [ $total_cases -eq 0 ]; then
    echo "0.00"
    exit 0
fi

correct=0

for i in "${!expected_outputs[@]}"; do
    input="${inputs[$i]}"
    expected="${expected_outputs[$i]}"

    # Nếu là file .sh
    if [[ "$student_file" == *.sh ]]; then
        actual=$(bash "$student_file" $input 2>/dev/null)
    else
        # giả định .o (file thực thi)
        actual=$("$student_file" $input 2>/dev/null)
    fi

    if [ "$actual" == "$expected" ]; then
        correct=$((correct+1))
    fi
done

# Tính điểm
score=$(echo "scale=4; $correct*100/$total_cases" | bc)
printf "%.2f\n" "$score"

