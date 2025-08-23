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
BASE_HOME="$SCRIPT_DIR/../data/students"

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

    useradd -m -d "$USER_HOME" -k /etc/skel -s /bin/bash "$USERNAME"
    if [[ $? -ne 0 ]]; then
        echo "[ERR] Không thể tạo user '$USERNAME'."
        return
    fi

    cp -r /etc/skel/. "$USER_HOME/"
    chown -R "$USERNAME:$USERNAME" "$USER_HOME"

    echo "$USERNAME:$PASSWORD" | chpasswd
    passwd -e "$USERNAME" >/dev/null

    echo "[OK] Đã tạo user '$USERNAME' (home: $USER_HOME)"
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

# ===== Hàm: Liệt kê sinh viên (full username) =====
list_students() {
    awk -F: '$1 ~ /^SV-/ {print $1}' /etc/passwd
}

# ===== Hàm: Liệt kê chỉ mã sinh viên =====
list_student_ids() {
    awk -F: '$1 ~ /^SV-/ {sub(/^SV-/, "", $1); print $1}' /etc/passwd
}

# ===== Hàm: Hiển thị hướng dẫn =====
show_help() {
    echo "Usage: sudo $0 [OPTION] [ARGS...]"
    echo
    echo "Options:"
    echo "  -a <MãSV...|File>       Thêm sinh viên (1, nhiều, từ file hoặc pipe)"
    echo "  -d <MãSV...|File>       Xóa sinh viên (1, nhiều, từ file hoặc pipe)"
    echo "  -l                      Liệt kê tất cả username (SV-xxxx)"
    echo "  -li                     Liệt kê chỉ mã sinh viên"
    echo "  --help                  Hiển thị hướng dẫn này"
    echo
    echo "Examples:"
    echo "  sudo $0 -a 12345 67890"
    echo "  sudo $0 -a danhsach.txt"
    echo "  cat danhsach.txt | sudo $0 -a"
    echo "  sudo $0 -d 12345"
    echo "  sudo $0 -li | sudo $0 -d"
    echo "  sudo $0 -l"
    echo "  sudo $0 -li"
}

# ===== Main =====
if [[ $# -lt 1 ]]; then
    show_help
    exit 1
fi

case "$1" in
    --help)
        show_help
        ;;
    -a)
        shift
        if [[ $# -eq 0 && ! -t 0 ]]; then
            while read -r MASV; do
                [[ -z "$MASV" ]] && continue
                add_student "$MASV"
            done
        elif [[ $# -eq 1 && -f "$1" ]]; then
            while read -r MASV; do
                [[ -z "$MASV" ]] && continue
                add_student "$MASV"
            done < "$1"
        else
            for MASV in "$@"; do
                add_student "$MASV"
            done
        fi
        ;;
    -d)
        shift
        if [[ $# -eq 0 && ! -t 0 ]]; then
            while read -r MASV; do
                [[ -z "$MASV" ]] && continue
                delete_student "$MASV"
            done
        elif [[ $# -eq 1 && -f "$1" ]]; then
            while read -r MASV; do
                [[ -z "$MASV" ]] && continue
                delete_student "$MASV"
            done < "$1"
        else
            for MASV in "$@"; do
                delete_student "$MASV"
            done
        fi
        ;;
    -l)
        list_students
        ;;
    -li)
        list_student_ids
        ;;
    *)
        echo "[ERR] Tham số không hợp lệ."
        show_help
        exit 1
        ;;
esac

