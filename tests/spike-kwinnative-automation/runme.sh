rm *.png

# 1. Spin up the background context
docker run -d \
  --name=webtop_automation \
  --shm-size=1gb \
  --security-opt seccomp=unconfined \
  -v "$(pwd)":/app \
  kwin-appimage-automation:latest

# 2. Wait for the Python run block to process completion
docker logs -f webtop_automation | grep -m 1 "\[\*\] Automation task completed\."

# 3. Drop the container session silently
docker stop -t 0 webtop_automation > /dev/null && docker rm webtop_automation > /dev/null

