# 🚀 Student Manager System

Hệ thống quản lý sinh viên, lớp học và bài tập được xây dựng bằng
**Shell Script** trên Linux.\
Toàn bộ các script chính nằm trong thư mục **bin/**.

------------------------------------------------------------------------

## 💡 Các tính năng nổi bật

-   **Quản lý sinh viên**: Thêm, xóa, và liệt kê một hoặc nhiều sinh
    viên cùng lúc.
-   **Quản lý lớp học**: Tạo, xóa và quản lý danh sách sinh viên trong
    từng lớp.
-   **Quản lý bài tập**: Giao bài tập cho các lớp và theo dõi tiến độ.
-   **Hệ thống chấm điểm linh hoạt**: Hỗ trợ chấm điểm thủ công hoặc qua
    server chấm điểm tự động.
-   **Nộp bài tiện lợi**: Sinh viên có thể SSH vào hệ thống để nộp bài
    trực tiếp.

------------------------------------------------------------------------

## 🛠️ Hướng dẫn cài đặt

### 1. Phân quyền thư mục

Để script có thể hoạt động, bạn cần cấp quyền thực thi cho thư mục
`/home/$(whoami)`:

``` bash
chmod a+x /home/$(whoami)
```

### 2. Clone project

Sử dụng lệnh `git clone` để tải toàn bộ mã nguồn về máy:

``` bash
git clone https://github.com/Tran-Hong-Quan/student_manager.git
```

### 3. Cấu hình SSH Server

Hệ thống yêu cầu **SSH server** có thể kết nối từ bên ngoài.\
Nếu SSH đang chỉ lắng nghe trên `127.0.0.1`, bạn cần chỉnh sửa file cấu
hình.

**Cài SSH:**
``` bash
sudo apt update
sudo apt install openssh-server
```
Khởi động lại dịch vụ SSH
``` bash
sudo systemctl restart sshd
```

------------------------------------------------------------------------

## 4. 👨‍🏫 Hướng dẫn sử dụng cho giáo viên

### Quản lý sinh viên

Sử dụng script:

``` bash
sudo ./bin/student_manager.sh [OPTION] [ARGS...]
```

⚠️ **Lưu ý**: Bắt buộc chạy với `sudo` vì script sẽ tạo user thực trên
hệ thống.

**Tùy chọn:**

-   `-a <MãSV...|File>`: Thêm sinh viên.
-   `-d <MãSV...|File>`: Xóa sinh viên.
-   `-l`: Liệt kê username sinh viên (SV-xxxx).
-   `-li`: Liệt kê mã sinh viên.
-   `--help`: Hiển thị hướng dẫn.

**Ví dụ:**

``` bash
# Thêm sinh viên 12345 và 67890
sudo ./bin/student_manager.sh -a 12345 67890

# Thêm sinh viên từ file
sudo ./bin/student_manager.sh -a danhsach.txt

# Xóa sinh viên
sudo ./bin/student_manager.sh -d 12345
```

------------------------------------------------------------------------

### Quản lý lớp học & bài tập

Sử dụng script:

``` bash
./bin/class_manager.sh [OPTION] [ARGS...]
```

**Tùy chọn:**

-   **Lớp học**
    -   `-ac <TênLớp>`: Thêm lớp.
    -   `-dc <TênLớp>`: Xóa lớp.
    -   `-lc`: Liệt kê danh sách lớp.
-   **Sinh viên trong lớp**
    -   `-a <Lớp> <MãSV...|File>`: Thêm sinh viên.
    -   `-d <Lớp> <MãSV...|File>`: Xóa sinh viên.
    -   `-ls <Lớp>`: Liệt kê sinh viên trong lớp và điểm.
-   **Bài tập**
    -   `-aa <TênBT>`: Thêm bài tập.
    -   `-da <TênBT>`: Xóa bài tập.
    -   `-la`: Liệt kê bài tập.
    -   `assign <Lớp> <TênBT...>`: Giao bài tập cho lớp.
    -   `-ra <Lớp> <TênBT...>`: Xóa bài tập khỏi lớp.

------------------------------------------------------------------------

### Chấm điểm thủ công

Sử dụng script:

``` bash
./grading.sh <MãSV> <TênBT> <FileNộpCủaSV>
```

-   `<MãSV>`: Mã số sinh viên (VD: `12345`).
-   `<TênBT>`: Tên bài tập đã tạo trong hệ thống.
-   `<FileNộpCủaSV>`: File bài làm (script hoặc file thực thi).

------------------------------------------------------------------------

## 💻 Server chấm điểm tự động

Quản lý server:

``` bash
./bin/server_ctl.sh {run|stop|status}
```

Build lại server sau khi chỉnh sửa mã nguồn C:

``` bash
gcc scripts/grading_server.c -o bin/grading_server.o
```

------------------------------------------------------------------------

## 🎓5.  Hướng dẫn cho sinh viên

### Đăng nhập SSH

-   **Username**: `SV-<MãSV>` (VD: `SV-12345`)
-   **Password**: Mặc định = Username

``` bash
ssh SV-<MãSV>@<server>
```

### Nộp bài tập

``` bash
../../../bin/submit_assignment.sh <TênBT> <LệnhThựcThiFileNộp>
```

-   `<TênBT>`: Tên bài tập được giao.
-   `<LệnhThựcThiFileNộp>`: Lệnh chạy file nộp (VD: `./sum.sh`,
    `./a.out`).

**Ví dụ:**

``` bash
../../../bin/submit_assignment.sh SUM ./sum.sh
```

------------------------------------------------------------------------

## 6. 🗄️ Cấu trúc dữ liệu

-   `../data/classes/`: Thông tin lớp và điểm số.
-   `../data/assignments/`: Kho bài tập, gồm input & output chuẩn.
-   `../data/students/`: Danh sách thông tin sinh viên.
