#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/stat.h>

#define SOCKET_PATH "/tmp/grading_socket"
#define BUFFER_SIZE 1024

int main() {
    int server_fd, client_fd;
    struct sockaddr_un addr;
    char buffer[BUFFER_SIZE];

    // Xoá socket cũ nếu tồn tại
    unlink(SOCKET_PATH);

    if ((server_fd = socket(AF_UNIX, SOCK_STREAM, 0)) < 0) {
        perror("socket");
        exit(1);
    }

    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, SOCKET_PATH, sizeof(addr.sun_path) - 1);

    if (bind(server_fd, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        perror("bind");
        exit(1);
    }

    // Cho phép tất cả user connect
    if (chmod(SOCKET_PATH, 0666) < 0) {
        perror("chmod socket");
        exit(1);
    }

    if (listen(server_fd, 5) < 0) {
        perror("listen");
        exit(1);
    }

    printf("Grading server started. Listening on %s...\n", SOCKET_PATH);

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

        buffer[n] = '\0'; // đảm bảo null-terminated
        printf("[DEBUG] Received request: %s\n", buffer);

        // Gọi grading script
        char cmd[BUFFER_SIZE * 2];
        snprintf(cmd, sizeof(cmd), "sudo ./grading.sh %s", buffer);

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
    unlink(SOCKET_PATH);
    return 0;
}

