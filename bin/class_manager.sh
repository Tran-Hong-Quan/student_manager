#!/bin/bash
# class_manager.sh - Quản lý lớp học (CSV)
# Lưu dữ liệu tại ../data/classes
# Mỗi lớp là 1 file CSV: cột 1 là MãSV, các cột sau là điểm từng bài tập

# ==== Cấu hình ====
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$SCRIPT_DIR/../data/classes"

# ==== Tạo thư mục dữ liệu nếu chưa có ====
mkdir -p "$DATA_DIR"

# ==== Hàm: Thêm lớp (tạo file CSV với tiêu đề MãSV) ====
add_class() {
    local class="$1"
    local file="$DATA_DIR/$class.csv"

    if [[ -f "$file" ]]; then
        echo "[ERR] Lớp '$class' đã tồn tại."
        return
    fi

    echo "MaSV" > "$file"
    echo "[OK] Đã tạo lớp '$class' (CSV)."
}

# ==== Hàm: Xóa lớp ====
delete_class() {
    local class="$1"
    local file="$DATA_DIR/$class.csv"

    if [[ ! -f "$file" ]]; then
        echo "[ERR] Lớp '$class' không tồn tại."
        return
    fi

    rm "$file"
    echo "[OK] Đã xóa lớp '$class'."
}

# ==== Hàm: Liệt kê lớp ====
list_classes() {
    ls "$DATA_DIR" | sed 's/.csv$//' | sort
}

# ==== Hàm: Thêm sinh viên vào lớp ====
add_student_to_class() {
    local class="$1"
    local masv="$2"
    local file="$DATA_DIR/$class.csv"

    if [[ ! -f "$file" ]]; then
        echo "[ERR] Lớp '$class' không tồn tại."
        return
    fi

    if grep -q "^${masv}," "$file"; then
        echo "[ERR] Sinh viên $masv đã có trong lớp '$class'."
        return
    fi

    # Đếm số cột bài tập để thêm số lượng 0 tương ứng
    local num_assignments
    num_assignments=$(head -n1 "$file" | awk -F',' '{print NF-1}')

    local zeros
    zeros=$(yes 0 | head -n "$num_assignments" | tr '\n' ',' | sed 's/,$//')

    if [[ -z "$zeros" ]]; then
        echo "$masv" >> "$file"
    else
        echo "$masv,$zeros" >> "$file"
    fi

    echo "[OK] Đã thêm sinh viên $masv vào lớp '$class'."
}

# ==== Hàm: Xóa sinh viên khỏi lớp ====
remove_student_from_class() {
    local class="$1"
    local masv="$2"
    local file="$DATA_DIR/$class.csv"

    if [[ ! -f "$file" ]]; then
        echo "[ERR] Lớp '$class' không tồn tại."
        return
    fi

    if ! grep -q "^${masv}," "$file"; then
        echo "[ERR] Sinh viên $masv không có trong lớp '$class'."
        return
    fi

    grep -v "^${masv}," "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    echo "[OK] Đã xóa sinh viên $masv khỏi lớp '$class'."
}

# ==== Hàm: Liệt kê sinh viên trong lớp ====
list_students_in_class() {
    local class="$1"
    local file="$DATA_DIR/$class.csv"

    if [[ ! -f "$file" ]]; then
        echo "[ERR] Lớp '$class' không tồn tại."
        return
    fi

    echo "[INFO] Danh sách sinh viên lớp '$class':"
    column -s, -t "$file"
}

# ==== Hàm: Thêm bài tập vào lớp ====
add_assignment_to_class() {
    local class="$1"
    local assignment="$2"
    local file="$DATA_DIR/$class.csv"

    if [[ ! -f "$file" ]]; then
        echo "[ERR] Lớp '$class' không tồn tại."
        return
    fi

    # Kiểm tra bài tập đã tồn tại chưa
    if head -n1 "$file" | grep -q "$assignment"; then
        echo "[ERR] Bài tập '$assignment' đã tồn tại trong lớp '$class'."
        return
    fi

    # Thêm vào header
    sed -i "1s/$/,$assignment/" "$file"

    # Thêm điểm 0 cho mỗi sinh viên
    tail -n +2 "$file" | while read -r line; do
        echo "$line,0"
    done > "$file.tmp"

    # Ghép header + dữ liệu mới
    head -n1 "$file" > "$file.new"
    cat "$file.tmp" >> "$file.new"
    mv "$file.new" "$file"
    rm -f "$file.tmp"

    echo "[OK] Đã thêm bài tập '$assignment' vào lớp '$class'."
}

# ==== Hàm: Xóa bài tập khỏi lớp ====
remove_assignment_from_class() {
    local class="$1"
    local assignment="$2"
    local file="$DATA_DIR/$class.csv"

    if [[ ! -f "$file" ]]; then
        echo "[ERR] Lớp '$class' không tồn tại."
        return
    fi

    # Lấy số thứ tự cột
    local col
    col=$(head -n1 "$file" | tr ',' '\n' | grep -n "^$assignment$" | cut -d: -f1)

    if [[ -z "$col" ]]; then
        echo "[ERR] Không tìm thấy bài tập '$assignment' trong lớp '$class'."
        return
    fi

    # Xóa cột bằng awk
    awk -F',' -v col="$col" '{
        for(i=1;i<=NF;i++){
            if(i==1){printf "%s",$i}
            else if(i!=col){printf ",%s",$i}
        }
        printf "\n"
    }' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

    echo "[OK] Đã xóa bài tập '$assignment' khỏi lớp '$class'."
}

# ==== Main ====
case "$1" in
    add-class)
        [[ $# -ne 2 ]] && { echo "Dùng: $0 add-class <TênLớp>"; exit 1; }
        add_class "$2"
        ;;
    delete-class)
        [[ $# -ne 2 ]] && { echo "Dùng: $0 delete-class <TênLớp>"; exit 1; }
        delete_class "$2"
        ;;
    list-classes)
        list_classes
        ;;
    add-student)
        [[ $# -ne 3 ]] && { echo "Dùng: $0 add-student <Lớp> <MãSV>"; exit 1; }
        add_student_to_class "$2" "$3"
        ;;
    remove-student)
        [[ $# -ne 3 ]] && { echo "Dùng: $0 remove-student <Lớp> <MãSV>"; exit 1; }
        remove_student_from_class "$2" "$3"
        ;;
    list-students)
        [[ $# -ne 2 ]] && { echo "Dùng: $0 list-students <Lớp>"; exit 1; }
        list_students_in_class "$2"
        ;;
    add-assignment)
        [[ $# -ne 3 ]] && { echo "Dùng: $0 add-assignment <TênLớp> <TênBàiTập>"; exit 1; }
        add_assignment_to_class "$2" "$3"
        ;;
    remove-assignment)
        [[ $# -ne 3 ]] && { echo "Dùng: $0 remove-assignment <TênLớp> <TênBàiTập>"; exit 1; }
        remove_assignment_from_class "$2" "$3"
        ;;
    *)
        echo "Cách dùng:"
        echo "  $0 add-class <TênLớp>"
        echo "  $0 delete-class <TênLớp>"
        echo "  $0 list-classes"
        echo "  $0 add-student <Lớp> <MãSV>"
        echo "  $0 remove-student <Lớp> <MãSV>"
        echo "  $0 list-students <Lớp>"
        echo "  $0 add-assignment <Lớp> <TênBàiTập>"
        echo "  $0 remove-assignment <Lớp> <TênBàiTập>"
        exit 1
        ;;
esac

