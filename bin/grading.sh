#!/bin/bash
# grading.sh
# Usage: ./grading.sh <MãSV> <BàiTập> <FileBàiTậpSinhVien>

print_help() {
    cat <<EOF
Usage:
  ./grading.sh <MãSV> <BàiTập> <FileBàiTậpSinhVien>

Description:
  Script chấm bài tập cho sinh viên.
  - <MãSV>: mã sinh viên (ví dụ: 12345)
  - <BàiTập>: tên bài tập đã tạo trong hệ thống (tương ứng thư mục trong ../data/assignments)
  - <FileBàiTậpSinhVien>: file bài tập .sh hoặc thực thi

Workflow:
  1. Lấy input/output chuẩn từ ../data/assignments/<BàiTập>
  2. Chạy bài nộp với input đó
  3. So sánh output với chuẩn để tính % số test đúng
  4. Cập nhật điểm cao nhất vào lớp (nếu có quyền)
EOF
}

# ==== Kiểm tra tham số ====
if [[ "$1" == "--help" || $# -lt 3 ]]; then
    print_help
    exit 0
fi

MASV="$1"
ASSIGNMENT="$2"
STUDENT_FILE="$3"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$SCRIPT_DIR/../data/classes"
ASSIGNMENTS_DIR="$SCRIPT_DIR/../data/assignments"

ASSIGNMENT_DIR="$ASSIGNMENTS_DIR/$ASSIGNMENT"
INPUT_FILE="$ASSIGNMENT_DIR/input.txt"
OUTPUT_FILE="$ASSIGNMENT_DIR/output.txt"

# ==== Kiểm tra bài tập ====
if [[ ! -d "$ASSIGNMENT_DIR" ]]; then
    echo "[ERR] Bài tập '$ASSIGNMENT' không tồn tại."
    exit 1
fi

if [[ ! -f "$OUTPUT_FILE" ]]; then
    echo "0.00"
    exit 0
fi

# ==== Đọc test cases ====
if [[ -f "$INPUT_FILE" ]]; then
    mapfile -t inputs < "$INPUT_FILE"
else
    inputs=()
fi
mapfile -t expected_outputs < "$OUTPUT_FILE"

TOTAL=${#expected_outputs[@]}
if [[ $TOTAL -eq 0 ]]; then
    echo "0.00"
    exit 0
fi

CORRECT=0

for i in "${!expected_outputs[@]}"; do
    input_line="${inputs[$i]}"
    expected="${expected_outputs[$i]}"

    # Tách input thành mảng tham số
    read -r -a args <<< "$input_line"

    # Chạy file sinh viên
    if [[ "$STUDENT_FILE" == *.sh ]]; then
        actual=$("$STUDENT_FILE" "${args[@]}")
    else
        actual=$("$STUDENT_FILE" "${args[@]}")
    fi

    # So sánh output, bỏ khoảng trắng đầu/cuối
    if [[ "$(echo "$actual" | xargs)" == "$(echo "$expected" | xargs)" ]]; then
        CORRECT=$((CORRECT+1))
    fi
done

# ==== Tính điểm ====
SCORE=$(echo "scale=4; $CORRECT*100/$TOTAL" | bc)
printf "%.2f\n" "$SCORE"

# ==== Cập nhật điểm vào lớp ====
for class_file in "$DATA_DIR"/*.csv; do
    [[ ! -f "$class_file" ]] && continue

    if grep -q "^$MASV," "$class_file"; then
        col=$(head -n1 "$class_file" | tr ',' '\n' | grep -n "^$ASSIGNMENT$" | cut -d: -f1)
        if [[ -n "$col" ]]; then
            old_score=$(awk -F',' -v id="$MASV" -v col="$col" '$1==id {print $col}' "$class_file")
            if [[ -z "$old_score" || $(echo "$SCORE > $old_score" | bc) -eq 1 ]]; then
                awk -F',' -v id="$MASV" -v col="$col" -v new="$SCORE" 'BEGIN{OFS=","}
                    NR==1{print $0; next}
                    $1==id{$col=new}1' "$class_file" > "$class_file.tmp" && mv "$class_file.tmp" "$class_file"
                echo "[INFO] Cập nhật điểm SV-$MASV trong lớp $(basename "$class_file" .csv)"
            fi
        fi
    fi
done

