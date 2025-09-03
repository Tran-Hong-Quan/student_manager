#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/stat.h>
#include <libgen.h>
#include <signal.h>

#define BUFFER_SIZE 1024

void handle_client(int client_fd, const char *grading_path, const char *buffer) {
    char cmd[BUFFER_SIZE * 2];
    snprintf(cmd, sizeof(cmd), "timeout 5s sudo %s %s", grading_path, buffer);

    FILE *fp = popen(cmd, "r");
    if (!fp) {
        char *err = "Error: cannot execute grading script.\n";
        write(client_fd, err, strlen(err));
        close(client_fd);
        return;
    }

    char result[BUFFER_SIZE];
    while (fgets(result, sizeof(result), fp) != NULL) {
        write(client_fd, result, strlen(result));
    }
    pclose(fp);

    close(client_fd);
}

int main(int argc, char *argv[]) {
    int server_fd, client_fd;
    struct sockaddr_un addr;
    char buffer[BUFFER_SIZE];

    // --- Đường dẫn ---
    char script_dir[BUFFER_SIZE];
    strncpy(script_dir, argv[0], BUFFER_SIZE-1);
    script_dir[BUFFER_SIZE-1] = '\0';
    dirname(script_dir);

    char socket_path[BUFFER_SIZE];
    snprintf(socket_path, BUFFER_SIZE, "%s/../data/tmp/grading_socket", script_dir);

    unlink(socket_path); // xoá socket cũ

    if ((server_fd = socket(AF_UNIX, SOCK_STREAM, 0)) < 0) {
        perror("socket");
        exit(1);
    }

    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, socket_path, sizeof(addr.sun_path) - 1);

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

    // tránh zombie process
    signal(SIGCHLD, SIG_IGN);

    printf("Grading server started. Listening on %s...\n", socket_path);

    char grading_path[BUFFER_SIZE];
    snprintf(grading_path, sizeof(grading_path), "%s/grading.sh", script_dir);

    while (1) {
        if ((client_fd = accept(server_fd, NULL, NULL)) < 0) {
            perror("accept");
            continue;
        }

        int n = read(client_fd, buffer, BUFFER_SIZE - 1);
        if (n <= 0) {
            close(client_fd);
            continue;
        }
        buffer[n] = '\0';

        printf("[DEBUG] Received request: %s\n", buffer);

        pid_t pid = fork();
        if (pid == 0) {
            // tiến trình con
            close(server_fd); // con không cần socket server
            handle_client(client_fd, grading_path, buffer);
            exit(0);
        } else if (pid > 0) {
            // tiến trình cha
            close(client_fd); // cha không cần client_fd
        } else {
            perror("fork");
            close(client_fd);
        }
    }

    close(server_fd);
    unlink(socket_path);
    printf("Server closed\n");
    return 0;
}
