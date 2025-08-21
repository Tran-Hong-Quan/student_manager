#!/bin/bash

# grading.sh
# Usage: ./grading.sh <assignment_dir> <student_file>

assignment_dir="$1"
student_file="$2"

input_file="$assignment_dir/input.txt"
output_file="$assignment_dir/output.txt"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$SCRIPT_DIR/../data/classes"

# ==== Lấy MãSV từ username (SV-12345) ====
username=$(whoami)
if [[ "$username" =~ ^SV-([A-Za-z0-9]+)$ ]]; then
    masv="${BASH_REMATCH[1]}"
else
    masv=""
fi

# ==== Kiểm tra tồn tại output chuẩn ====
if [ ! -f "$output_file" ]; then
    echo "0.00"
    exit 0
fi

# ==== Đọc test cases ====
if [ -f "$input_file" ]; then
    mapfile -t inputs < "$input_file"
else
    inputs=(" ")
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
        actual=$(echo "$input" | bash "$student_file" 2>/dev/null)
    else
        # giả định file thực thi
        actual=$(echo "$input" | "$student_file" 2>/dev/null)
    fi

    # So sánh output (bỏ khoảng trắng 2 đầu)
    if [[ "$(echo "$actual" | xargs)" == "$(echo "$expected" | xargs)" ]]; then
        correct=$((correct+1))
    fi
done

# ==== Tính điểm ====
score=$(echo "scale=4; $correct*100/$total_cases" | bc)
printf "%.2f\n" "$score"

# ==== Nếu có masv thì cập nhật điểm vào lớp ====
if [[ -n "$masv" ]]; then
    # Lấy tên bài tập = tên thư mục assignment
    assignment_name=$(basename "$assignment_dir")

    # Duyệt tất cả lớp để tìm sinh viên
    for class_file in "$DATA_DIR"/*.csv; do
        [[ ! -f "$class_file" ]] && continue

        # Kiểm tra sinh viên có trong lớp này không
        if grep -q "^$masv," "$class_file"; then
            # Lấy cột của bài tập
            col=$(head -n1 "$class_file" | tr ',' '\n' | grep -n "^$assignment_name$" | cut -d: -f1)

            if [[ -n "$col" ]]; then
                # Lấy điểm hiện tại
                old_score=$(awk -F',' -v id="$masv" -v col="$col" '$1==id {print $col}' "$class_file")

                # Nếu chưa có hoặc điểm mới cao hơn → cập nhật
                if [[ -z "$old_score" || $(echo "$score > $old_score" | bc) -eq 1 ]]; then
                    awk -F',' -v id="$masv" -v col="$col" -v new="$score" 'BEGIN{OFS=","} 
                        NR==1{print $0; next} 
                        $1==id{$col=new} {print $0}' "$class_file" > "$class_file.tmp" \
                        && mv "$class_file.tmp" "$class_file"

                    echo "[INFO] Đã cập nhật điểm cho SV-$masv trong lớp $(basename "$class_file" .csv)"
                fi
            fi
        fi
    done
fi

