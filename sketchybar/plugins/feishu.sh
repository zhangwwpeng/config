#!/bin/bash

# 获取某个 app 的角标数字，$1 是 display name 列表（空格分隔）
get_badge_count() {
    for name in $1; do
        local RAW=$(lsappinfo info -only StatusLabel "$(lsappinfo find LSDisplayName=$name)" 2>/dev/null)
        if [ -n "$RAW" ]; then
            local COUNT=$(echo "$RAW" | awk -F'"' '{print $(NF-1)}')
            if [[ "$COUNT" =~ ^[0-9]+$ ]] && [ "$COUNT" != "0" ]; then
                echo "$COUNT"
                return
            fi
        fi
    done
    echo "0"
}

FEISHU_COUNT=$(get_badge_count "飞书 Feishu")
WCHAT_COUNT=$(get_badge_count "企业微信 WeCom")

# 都没消息时隐藏组件
if [ "$FEISHU_COUNT" = "0" ] && [ "$WCHAT_COUNT" = "0" ]; then
    sketchybar --set $NAME drawing=on label="(0)"    
    exit 0
else
    # sketchybar --set $NAME drawing=on label="(Feishu:${FEISHU_COUNT},WeCom:${WCHAT_COUNT})"
    # 有消息，更新数字并强制显示
    sketchybar --set $NAME drawing=on label="(Feishu:${FEISHU_COUNT},WeCom:${WCHAT_COUNT})"

    for i in {1..6}; do
        sketchybar --set $NAME drawing=off
        sleep 0.8
        sketchybar --set $NAME drawing=on
        sleep 0.8
    done
fi

