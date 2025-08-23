#!/bin/bash
# class_manager.sh - Quản lý lớp học (CSV + assignments thư mục) với bảo mật chmod

# ==== Kiểm tra quyền root ====
if [[ $EUID -ne 0 ]]; then
    echo "[ERR] Vui lòng chạy script với quyền root hoặc sudo."
    exit 1
fi

# ==== Cấu hình ====
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATA_DIR="$SCRIPT_DIR/../data/classes"
ASSIGN_DIR="$SCRIPT_DIR/../data/assignments"

mkdir -p "$DATA_DIR"
mkdir -p "$ASSIGN_DIR"

# ==== Bảo mật thư mục và file ====
secure_data_dirs() {
    mkdir -p "$DATA_DIR" "$ASSIGN_DIR"

    # Quyền cho thư mục gốc
    chmod 700 "$DATA_DIR" "$ASSIGN_DIR"

    # File CSV lớp
    shopt -s nullglob
    for f in "$DATA_DIR"/*.csv; do
        chmod 600 "$f"
    done
    shopt -u nullglob

    # Thư mục bài tập
    shopt -s nullglob
    for d in "$ASSIGN_DIR"/*; do
        chmod 700 "$d"
    done
    shopt -u nullglob
}
secure_data_dirs

# ==== Lớp ====
add_class() {
    local class="$1"; local file="$DATA_DIR/$class.csv"
    [[ -f "$file" ]] && { echo "[ERR] Lớp '$class' đã tồn tại."; return; }
    echo "MaSV" > "$file"
    chmod 600 "$file"
    echo "[OK] Đã tạo lớp '$class'."
}
delete_class() {
    local class="$1"; local file="$DATA_DIR/$class.csv"
    [[ ! -f "$file" ]] && { echo "[ERR] Lớp '$class' không tồn tại."; return; }
    rm "$file"
    echo "[OK] Đã xóa lớp '$class'."
}
list_classes() { ls "$DATA_DIR" 2>/dev/null | sed 's/.csv$//' | sort; }

# ==== Sinh viên ====
add_student_to_class() {
    local class="$1"; shift
    local file="$DATA_DIR/$class.csv"
    [[ ! -f "$file" ]] && { echo "[ERR] Lớp '$class' không tồn tại."; return; }

    for masv in "$@"; do
        [[ -z "$masv" ]] && continue
        if grep -q "^${masv}," "$file"; then
            echo "[ERR] Sinh viên $masv đã có trong lớp '$class'."
            continue
        fi
        local num_assignments=$(head -n1 "$file" | awk -F',' '{print NF-1}')
        local zeros=$(yes 0 | head -n "$num_assignments" | tr '\n' ',' | sed 's/,$//')
        [[ -z "$zeros" ]] && echo "$masv" >> "$file" || echo "$masv,$zeros" >> "$file"
        echo "[OK] Thêm sinh viên $masv vào lớp '$class'."
    done
    chmod 600 "$file"
}
remove_student_from_class() {
    local class="$1"; shift
    local file="$DATA_DIR/$class.csv"
    [[ ! -f "$file" ]] && { echo "[ERR] Lớp '$class' không tồn tại."; return; }

    for masv in "$@"; do
        [[ -z "$masv" ]] && continue
        if ! grep -q "^${masv}," "$file"; then
            echo "[ERR] Sinh viên $masv không có trong lớp '$class'."
            continue
        fi
        grep -v "^${masv}," "$file" > "$file.tmp" && mv "$file.tmp" "$file"
        echo "[OK] Xóa sinh viên $masv khỏi lớp '$class'."
    done
    chmod 600 "$file"
}
list_students_in_class() {
    local class="$1"; local file="$DATA_DIR/$class.csv"
    [[ ! -f "$file" ]] && { echo "[ERR] Lớp '$class' không tồn tại."; return; }
    column -s, -t "$file"
}

# ==== Assignment kho ====
add_assignment() {
    local assignment="$1"; local dir="$ASSIGN_DIR/$assignment"
    [[ -d "$dir" ]] && { echo "[ERR] Bài tập '$assignment' đã tồn tại."; return; }
    mkdir -p "$dir"; chmod 700 "$dir"
    echo "[OK] Thêm bài tập '$assignment' vào kho."
}
remove_assignment() {
    local assignment="$1"; local dir="$ASSIGN_DIR/$assignment"
    [[ ! -d "$dir" ]] && { echo "[ERR] Bài tập '$assignment' không tồn tại."; return; }
    rm -rf "$dir"
    echo "[OK] Xóa bài tập '$assignment' khỏi kho."
}
list_assignments() { ls "$ASSIGN_DIR" 2>/dev/null | sort; }

# ==== Giao/xóa bài tập lớp ====
assign_to_class() {
    local class="$1"; shift
    local file="$DATA_DIR/$class.csv"
    [[ ! -f "$file" ]] && { echo "[ERR] Lớp '$class' không tồn tại."; return; }

    for assignment in "$@"; do
        [[ ! -d "$ASSIGN_DIR/$assignment" ]] && { echo "[ERR] Bài tập '$assignment' chưa có."; continue; }
        if head -n1 "$file" | grep -q "$assignment"; then
            echo "[ERR] Bài tập '$assignment' đã giao lớp '$class'."
            continue
        fi
        sed -i "1s/$/,$assignment/" "$file"
        tail -n +2 "$file" | while read -r line; do echo "$line,0"; done > "$file.tmp"
        head -n1 "$file" > "$file.new"; cat "$file.tmp" >> "$file.new"; mv "$file.new" "$file"; rm -f "$file.tmp"
        echo "[OK] Giao bài tập '$assignment' cho lớp '$class'."
    done
    chmod 600 "$file"
}
remove_assignment_from_class() {
    local class="$1"; shift
    local file="$DATA_DIR/$class.csv"
    [[ ! -f "$file" ]] && { echo "[ERR] Lớp '$class' không tồn tại."; return; }

    for assignment in "$@"; do
        local col=$(head -n1 "$file" | tr ',' '\n' | grep -n "^$assignment$" | cut -d: -f1)
        [[ -z "$col" ]] && { echo "[ERR] Bài tập '$assignment' không có trong lớp '$class'."; continue; }
        awk -F',' -v col="$col" '{
            for(i=1;i<=NF;i++){if(i==1){printf "%s",$i}else if(i!=col){printf ",%s",$i}}; printf "\n"
        }' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
        echo "[OK] Xóa bài tập '$assignment' khỏi lớp '$class'."
    done
    chmod 600 "$file"
}

# ==== Help ====
show_help() {
    echo "Usage: sudo $0 [OPTION] [ARGS...]"
    echo
    echo "Class operations:"
    echo "  -ac <TênLớp>          Thêm lớp"
    echo "  -dc <TênLớp>          Xóa lớp"
    echo "  -lc                    Liệt kê lớp"
    echo
    echo "Student operations:"
    echo "  -a <Lớp> <MãSV...|File|Pipe>   Thêm sinh viên"
    echo "  -d <Lớp> <MãSV...|File|Pipe>   Xóa sinh viên"
    echo "  -ls <Lớp>                       Liệt kê sinh viên lớp"
    echo
    echo "Assignment operations:"
    echo "  -aa <TênBàiTập>       Thêm bài tập vào kho"
    echo "  -da <TênBàiTập>       Xóa bài tập khỏi kho"
    echo "  -la                    Liệt kê tất cả bài tập"
    echo "  assign <Lớp> <TênBàiTập...|Pipe>    Giao bài tập cho lớp"
    echo "  -ra <Lớp> <TênBàiTập...|Pipe>      Xóa bài tập khỏi lớp"
}

# ==== Main ====
[[ $# -lt 1 ]] && { show_help; exit 1; }

case "$1" in
    --help) show_help ;;
    -ac) [[ $# -ne 2 ]] && { echo "[ERR] Thiếu TênLớp"; show_help; exit 1; }; add_class "$2" ;;
    -dc) [[ $# -ne 2 ]] && { echo "[ERR] Thiếu TênLớp"; show_help; exit 1; }; delete_class "$2" ;;
    -lc) list_classes ;;
    -ls) [[ $# -ne 2 ]] && { echo "[ERR] Thiếu lớp"; show_help; exit 1; }; list_students_in_class "$2" ;;
    -a)
        shift; [[ $# -lt 2 ]] && { echo "[ERR] Thiếu lớp hoặc mã SV"; show_help; exit 1; }
        CLASS="$1"; shift
        if [[ $# -eq 1 && -f "$1" ]]; then add_student_to_class "$CLASS" $(cat "$1")
        elif [[ $# -eq 0 && ! -t 0 ]]; then add_student_to_class "$CLASS" $(cat)
        else add_student_to_class "$CLASS" "$@"; fi
        ;;
    -d)
        shift; [[ $# -lt 2 ]] && { echo "[ERR] Thiếu lớp hoặc mã SV"; show_help; exit 1; }
        CLASS="$1"; shift
        if [[ $# -eq 1 && -f "$1" ]]; then remove_student_from_class "$CLASS" $(cat "$1")
        elif [[ $# -eq 0 && ! -t 0 ]]; then remove_student_from_class "$CLASS" $(cat)
        else remove_student_from_class "$CLASS" "$@"; fi
        ;;
    -aa) [[ $# -ne 2 ]] && { echo "[ERR] Thiếu tên bài tập"; show_help; exit 1; }; add_assignment "$2" ;;
    -da) [[ $# -ne 2 ]] && { echo "[ERR] Thiếu tên bài tập"; show_help; exit 1; }; remove_assignment "$2" ;;
    -la) list_assignments ;;
    assign)
        [[ $# -lt 3 && -t 0 ]] && { echo "[ERR] Dùng: assign <Lớp> <TênBàiTập...|Pipe>"; show_help; exit 1; }
        CLASS="$2"; shift 2
        [[ $# -eq 0 && ! -t 0 ]] && assign_to_class "$CLASS" $(cat) || assign_to_class "$CLASS" "$@"
        ;;
    -ra)
        [[ $# -lt 3 && -t 0 ]] && { echo "[ERR] Dùng: -ra <Lớp> <TênBàiTập...|Pipe>"; show_help; exit 1; }
        CLASS="$2"; shift 2
        [[ $# -eq 0 && ! -t 0 ]] && remove_assignment_from_class "$CLASS" $(cat) || remove_assignment_from_class "$CLASS" "$@"
        ;;
    *) echo "[ERR] Tham số không hợp lệ."; show_help; exit 1 ;;
esac

