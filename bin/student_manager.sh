#!/bin/bash
# student_manager.sh
# Quản lý tài khoản sinh viên

# ===== Kiểm tra quyền sudo =====
if [[ $EUID -ne 0 ]]; then
    echo "[ERR] Vui lòng chạy script với quyền root hoặc sudo."
    exit 1
fi

# ===== Thư mục gốc lưu sinh viên =====
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
BASE_HOME="$SCRIPT_DIR/../data/classes"

# ===== Hàm: Thêm 1 sinh viên =====
add_student() {
    MASV="$1"
    USERNAME="SV-$MASV"
    PASSWORD="$USERNAME"
    USER_HOME="$BASE_HOME/$USERNAME"

    if id "$USERNAME" &>/dev/null; then
        echo "[ERR] User '$USERNAME' đã tồn tại."
        return
    fi

    mkdir -p "$BASE_HOME" || { echo "[ERR] Không thể tạo thư mục gốc."; return; }

    useradd -m -d "$USER_HOME" "$USERNAME"
    if [[ $? -ne 0 ]]; then
        echo "[ERR] Không thể tạo user '$USERNAME'."
        return
    fi

    echo "$USERNAME:$PASSWORD" | chpasswd
    passwd -e "$USERNAME" >/dev/null

    echo "[OK] Đã tạo user '$USERNAME' (home: $USER_HOME)"
}

# ===== Hàm: Thêm nhiều sinh viên từ file =====
add_students_batch() {
    FILE="$1"

    if [[ ! -f "$FILE" ]]; then
        echo "[ERR] File '$FILE' không tồn tại."
        return
    fi

    while read -r MASV; do
        [[ -z "$MASV" ]] && continue
        add_student "$MASV"
    done < "$FILE"
}

# ===== Hàm: Xóa 1 sinh viên =====
delete_student() {
    MASV="$1"
    USERNAME="SV-$MASV"

    if ! id "$USERNAME" &>/dev/null; then
        echo "[ERR] User '$USERNAME' không tồn tại."
        return
    fi

    userdel -r "$USERNAME"
    echo "[OK] Đã xóa user '$USERNAME' và thư mục home."
}

# ===== Hàm: Xóa nhiều sinh viên từ file =====
delete_students_batch() {
    FILE="$1"

    if [[ ! -f "$FILE" ]]; then
        echo "[ERR] File '$FILE' không tồn tại."
        return
    fi

    while read -r MASV; do
        [[ -z "$MASV" ]] && continue
        delete_student "$MASV"
    done < "$FILE"
}

# ===== Hàm: Liệt kê sinh viên (full username) =====
list_students() {
    awk -F: '$1 ~ /^SV-/ {print $1}' /etc/passwd
}

# ===== Hàm: Liệt kê chỉ mã sinh viên =====
list_student_ids() {
    awk -F: '$1 ~ /^SV-/ {sub(/^SV-/, "", $1); print $1}' /etc/passwd
}

# ===== Main =====
case "$1" in
    add)
        # add <MãSV>
        if [[ $# -ne 2 ]]; then
            echo "Cách dùng: $0 add <MãSV>"
            exit 1
        fi
        add_student "$2"
        ;;
    add-batch)
        # add-batch <FileDanhSach>
        if [[ $# -ne 2 ]]; then
            echo "Cách dùng: $0 add-batch <FileDanhSach>"
            exit 1
        fi
        add_students_batch "$2"
        ;;
    delete)
        # delete <MãSV>
        if [[ $# -ne 2 ]]; then
            echo "Cách dùng: $0 delete <MãSV>"
            exit 1
        fi
        delete_student "$2"
        ;;
    delete-batch)
        # delete-batch <FileDanhSach>
        if [[ $# -ne 2 ]]; then
            echo "Cách dùng: $0 delete-batch <FileDanhSach>"
            exit 1
        fi
        delete_students_batch "$2"
        ;;
    list)
        list_students
        ;;
    list-id)
        list_student_ids
        ;;
    *)
        echo "Cách dùng:"
        echo "  $0 add <MãSV>             # Thêm 1 sinh viên"
        echo "  $0 add-batch <File>       # Thêm nhiều sinh viên từ file"
        echo "  $0 delete <MãSV>          # Xóa 1 sinh viên"
        echo "  $0 delete-batch <File>    # Xóa nhiều sinh viên từ file"
        echo "  $0 list                   # Liệt kê user (SV-xxxx)"
        echo "  $0 list-id                # Liệt kê chỉ mã sinh viên"
        exit 1
        ;;
esac

