#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/stat.h>
#include <libgen.h>

#define BUFFER_SIZE 1024

int main(int argc, char *argv[]) {
    int server_fd, client_fd;
    struct sockaddr_un addr;
    char buffer[BUFFER_SIZE];

    // Tính thư mục script
    char script_dir[BUFFER_SIZE];
    strncpy(script_dir, argv[0], BUFFER_SIZE-1);
    script_dir[BUFFER_SIZE-1] = '\0';
    dirname(script_dir); // lấy thư mục chứa script

    // Socket path: ../data/tmp/grading_socket
    char socket_path[BUFFER_SIZE];
    snprintf(socket_path, BUFFER_SIZE, "%s/../data/tmp/grading_socket", script_dir);

    // Tạo thư mục nếu chưa tồn tại
    char tmp_dir[BUFFER_SIZE];
    strncpy(tmp_dir, socket_path, BUFFER_SIZE-1);
    tmp_dir[BUFFER_SIZE-1] = '\0';
    char *last_slash = strrchr(tmp_dir, '/');
    if (last_slash) *last_slash = '\0';
    mkdir(tmp_dir, 0777); // tạo nếu chưa có

    // Xoá socket cũ nếu tồn tại
    unlink(socket_path);

    if ((server_fd = socket(AF_UNIX, SOCK_STREAM, 0)) < 0) {
        perror("socket");
        exit(1);
    }

    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, socket_path, sizeof(addr.sun_path) - 1);
    
    char cmd[BUFFER_SIZE * 2];
    char grading_path[BUFFER_SIZE];
    
    snprintf(grading_path, sizeof(grading_path), "%s/grading.sh", script_dir);

    if (bind(server_fd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        perror("bind");
        exit(1);
    }

    if (chmod(socket_path, 0666) < 0) {
        perror("chmod socket");
        exit(1);
    }

    if (listen(server_fd, 5) < 0) {
        perror("listen");
        exit(1);
    }

    printf("Grading server started. Listening on %s...\n", socket_path);
    printf("ffaf\n");

    while (1) {
        if ((client_fd = accept(server_fd, NULL, NULL)) < 0) {
            perror("accept");
            continue;
        }

        memset(buffer, 0, BUFFER_SIZE);
        int n = read(client_fd, buffer, BUFFER_SIZE - 1);
        if (n <= 0) {
            close(client_fd);
            continue;
        }

        buffer[n] = '\0';
        printf("[DEBUG] Received request: %s\n", buffer);

        char cmd[BUFFER_SIZE * 2];
        snprintf(cmd, sizeof(cmd), "sudo %s %s", grading_path, buffer);

        FILE *fp = popen(cmd, "r");
        if (!fp) {
            char *err = "Error: cannot execute grading script.\n";
            write(client_fd, err, strlen(err));
            close(client_fd);
            continue;
        }

        char result[BUFFER_SIZE];
        while (fgets(result, sizeof(result), fp) != NULL) {
            write(client_fd, result, strlen(result));
        }
        pclose(fp);

        close(client_fd);
    }

    close(server_fd);
    unlink(socket_path);
    return 0;
}

