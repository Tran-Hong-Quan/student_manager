#!/bin/bash
# class_manager.sh - Quản lý lớp học (không cần sudo)
# Lưu dữ liệu tại ../data/classes
# Mỗi lớp là 1 file chứa danh sách mã sinh viên (MãSV)

# ==== Cấu hình ====
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$SCRIPT_DIR/../data/classes"

# ==== Tạo thư mục dữ liệu nếu chưa có ====
mkdir -p "$DATA_DIR"

# ==== Hàm: Thêm lớp ====
add_class() {
    CLASS="$1"
    FILE="$DATA_DIR/$CLASS.txt"
    if [[ -f "$FILE" ]]; then
        echo "[ERR] Lớp '$CLASS' đã tồn tại."
        return
    fi
    touch "$FILE"
    echo "[OK] Đã tạo lớp '$CLASS'."
}

# ==== Hàm: Xóa lớp ====
delete_class() {
    CLASS="$1"
    FILE="$DATA_DIR/$CLASS.txt"
    if [[ ! -f "$FILE" ]]; then
        echo "[ERR] Lớp '$CLASS' không tồn tại."
        return
    fi
    rm "$FILE"
    echo "[OK] Đã xóa lớp '$CLASS'."
}

# ==== Hàm: Liệt kê lớp ====
list_classes() {
    ls "$DATA_DIR" | sed 's/.txt$//' | sort
}

# ==== Hàm: Thêm sinh viên vào lớp ====
add_student_to_class() {
    CLASS="$1"
    MASV="$2"
    FILE="$DATA_DIR/$CLASS.txt"

    if [[ ! -f "$FILE" ]]; then
        echo "[ERR] Lớp '$CLASS' không tồn tại."
        return
    fi

    if grep -q "^$MASV$" "$FILE"; then
        echo "[ERR] Sinh viên $MASV đã có trong lớp '$CLASS'."
        return
    fi

    echo "$MASV" >> "$FILE"
    echo "[OK] Đã thêm sinh viên $MASV vào lớp '$CLASS'."
}

# ==== Hàm: Xóa sinh viên khỏi lớp ====
remove_student_from_class() {
    CLASS="$1"
    MASV="$2"
    FILE="$DATA_DIR/$CLASS.txt"

    if [[ ! -f "$FILE" ]]; then
        echo "[ERR] Lớp '$CLASS' không tồn tại."
        return
    fi

    if ! grep -q "^$MASV$" "$FILE"; then
        echo "[ERR] Sinh viên $MASV không có trong lớp '$CLASS'."
        return
    fi

    grep -v "^$MASV$" "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"
    echo "[OK] Đã xóa sinh viên $MASV khỏi lớp '$CLASS'."
}

# ==== Hàm: Liệt kê sinh viên trong lớp ====
list_students_in_class() {
    CLASS="$1"
    FILE="$DATA_DIR/$CLASS.txt"

    if [[ ! -f "$FILE" ]]; then
        echo "[ERR] Lớp '$CLASS' không tồn tại."
        return
    fi

    echo "[INFO] Danh sách sinh viên lớp '$CLASS':"
    sort "$FILE"
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
        [[ $# -ne 3 ]] && { echo "Dùng: $0 add-student <TênLớp> <MãSV>"; exit 1; }
        add_student_to_class "$2" "$3"
        ;;
    remove-student)
        [[ $# -ne 3 ]] && { echo "Dùng: $0 remove-student <TênLớp> <MãSV>"; exit 1; }
        remove_student_from_class "$2" "$3"
        ;;
    list-students)
        [[ $# -ne 2 ]] && { echo "Dùng: $0 list-students <TênLớp>"; exit 1; }
        list_students_in_class "$2"
        ;;
    *)
        echo "Cách dùng:"
        echo "  $0 add-class <TênLớp>"
        echo "  $0 delete-class <TênLớp>"
        echo "  $0 list-classes"
        echo "  $0 add-student <Lớp> <MãSV>"
        echo "  $0 remove-student <Lớp> <MãSV>"
        echo "  $0 list-students <Lớp>"
        exit 1
        ;;
esac

