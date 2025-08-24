#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_BIN="$SCRIPT_DIR/grading_server.o"
PID_FILE="$SCRIPT_DIR/grading_server.pid"
LOG_FILE="$SCRIPT_DIR/grading_server.log"

# 🔒 Bắt buộc phải chạy bằng sudo
if [ "$EUID" -ne 0 ]; then
  echo "❌ Bạn phải chạy script này bằng: sudo $0 {run|stop|status}"
  exit 1
fi

case "$1" in
    run)
        if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            echo "⚠️ Server đã chạy với PID $(cat $PID_FILE)"
            echo "📜 Xem log: tail -f $LOG_FILE"
            exit 0
        fi

        echo "🚀 Chạy server với quyền root..."
        # Chạy server nền, redirect stdout/stderr vào log
        sudo rm -r "$SCRIPT_DIR/../data/tmp/grading_socket" 2>/dev/null
        sudo "$SERVER_BIN" > "$LOG_FILE" 2>&1 &
        SERVER_PID=$!
        echo $SERVER_PID > "$PID_FILE"
        echo "✅ Server chạy với PID $SERVER_PID"
        echo "📜 Log được lưu tại: $LOG_FILE"
        ;;

    stop)
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            if kill -0 $PID 2>/dev/null; then
                echo "🛑 Dừng server với PID $PID..."
                sudo rm -r "$SCRIPT_DIR/../data/tmp/grading_socket" 2>/dev/null
                sudo kill $PID
                rm -f "$PID_FILE"
                echo "✅ Server đã dừng"
            else
                echo "⚠️ Không tìm thấy process với PID $PID"
                rm -f "$PID_FILE"
            fi
        else
            echo "⚠️ Server chưa chạy"
        fi
        ;;

    status)
        if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            echo "✅ Server đang chạy với PID $(cat "$PID_FILE")"
            echo "📜 Log file: $LOG_FILE"
        else
            echo "⚠️ Server chưa chạy"
        fi
        ;;

    *)
        echo "Usage: $0 {run|stop|status}"
        exit 1
        ;;
esac

