#!/bin/bash
# shellcheck disable=SC2153 # NAME is injected by SketchyBar.

# 获取某个 app 的角标数字，$1 是 display name 列表（空格分隔）
get_badge_count() {
    local name raw count
    for name in $1; do
        raw="$(lsappinfo info -only StatusLabel "$(lsappinfo find "LSDisplayName=$name")" 2>/dev/null)"
        if [ -n "$raw" ]; then
            count="$(printf '%s\n' "$raw" | awk -F'"' '{print $(NF-1)}')"
            if [[ "$count" =~ ^[0-9]+$ ]] && [ "$count" != "0" ]; then
                printf '%s\n' "$count"
                return
            fi
        fi
    done
    printf '0\n'
}

FEISHU_COUNT=$(get_badge_count "飞书 Feishu")
WCHAT_COUNT=$(get_badge_count "企业微信 WeCom")

# 都没消息时隐藏组件
if [ "$FEISHU_COUNT" = "0" ] && [ "$WCHAT_COUNT" = "0" ]; then
    sketchybar --set "$NAME" drawing=off label=""
    exit 0
fi

sketchybar --set "$NAME" drawing=on label="(Feishu:${FEISHU_COUNT},WeCom:${WCHAT_COUNT})"
