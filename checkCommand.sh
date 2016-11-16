command=$(which $1 2>&1 || true)
if [ -e "$command" ]; then
        echo "1"
else
        echo "0"
fi
