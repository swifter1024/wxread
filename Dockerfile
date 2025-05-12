FROM python:3.10-slim

WORKDIR /app

# 设置时区
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 安装 cron 和必要的工具（pkill用于终止旧进程）
RUN apt-get update && apt-get install -y cron procps && rm -rf /var/lib/apt/lists/*
ENV PATH="/usr/local/bin:${PATH}"

# 复制代码
COPY main.py push.py config.py ./

# 创建日志目录
RUN mkdir -p /app/logs && chmod 777 /app/logs

# 安装依赖
RUN pip install --no-cache-dir requests>=2.32.3 urllib3>=2.2.3

# 配置Cron：每3分钟执行，先终止旧任务再启动新任务
RUN echo "*/3 * * * * cd /app && (pkill -f 'python3 main.py' || true) && /usr/local/bin/python3 main.py >> /app/logs/wxread-\$(date +\\%Y-\\%m-\\%d-\\%H\\%M\\%S).log 2>&1" > /etc/cron.d/wxread-cron
RUN chmod 0644 /etc/cron.d/wxread-cron
RUN crontab /etc/cron.d/wxread-cron

# 启动命令
CMD ["sh", "-c", "service cron start && tail -f /dev/null"]
