#!/bin/bash

SERVER_BIN="$(dirname "$0")/grading_server.o"
PID_FILE="$(dirname "$0")/grading_server.pid"

case "$1" in
    run)
        if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            echo "✅ Server is already running with PID $(cat $PID_FILE)"
        else
            echo "🚀 Starting server..."
            nohup "$SERVER_BIN" > grading_server.log 2>&1 &
            echo $! > "$PID_FILE"
            echo "✅ Server started with PID $(cat $PID_FILE)"
        fi
        ;;
    stop)
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            if kill -0 $PID 2>/dev/null; then
                echo "🛑 Stopping server with PID $PID..."
                kill $PID
                rm -f "$PID_FILE"
                echo "✅ Server stopped"
            else
                echo "⚠️ No process found with PID $PID"
                rm -f "$PID_FILE"
            fi
        else
            echo "⚠️ Server is not running"
        fi
        ;;
    status)
        if [ -f "$PID_FILE" ] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            echo "✅ Server is running with PID $(cat $PID_FILE)"
        else
            echo "⚠️ Server is not running"
        fi
        ;;
    *)
        echo "Usage: $0 {run|stop|status}"
        exit 1
        ;;
esac

