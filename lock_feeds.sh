#!/bin/bash

# 1. 确保已更新 feeds 仓库
#./scripts/feeds update -a

# 2. 备份原有的配置文件
cp feeds.conf.default feeds.conf.default.bak
> feeds.conf.default.new

# 3. 遍历解析并生成带有 commit 的配置
while IFS= read -r line || [ -n "$line" ]; do
    # 忽略空行和注释行
    if [[ "$line" =~ ^[[:space:]]*# ]] || [[ -z "$line" ]]; then
        echo "$line" >> feeds.conf.default.new
        continue
    fi

    type=$(echo "$line" | awk '{print $1}')
    name=$(echo "$line" | awk '{print $2}')
    url=$(echo "$line" | awk '{print $3}')

    # 判断是否为 src-git 且本地已拉取代码
    if [[ "$type" == "src-git"* ]] && [ -d "feeds/$name/.git" ]; then
        # 获取当前子库的 HEAD commit
        commit=$(git -C "feeds/$name" rev-parse HEAD)
        
        # 清理 URL 中可能原有的 ';' 或 '^' 后缀
        clean_url=$(echo "$url" | sed -E 's/[;\^].*//')
        
        # 写入带有具体 commit 的新规则
        echo "$type $name ${clean_url}^${commit}" >> feeds.conf.default.new
    else
        echo "$line" >> feeds.conf.default.new
    fi
done < feeds.conf.default.bak

# 4. 替换原文件
mv feeds.conf.default.new feeds.conf.default
rm -f feeds.conf.default.bak

echo "✅ feeds.conf.default 已更新，所有 Git 版本的 feed 已成功锁定！"
