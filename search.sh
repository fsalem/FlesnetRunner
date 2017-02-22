

lines=$(grep -n "summary: " job.143599.err)
echo "$lines"
arr=($lines)
echo "${arr[1]}"
