# code_preview.lua 说明

文件路径：`nvim/lua/code_preview.lua`

## 模块目标

- 在指定行显示结构化预览（error/warn/info/msg/suggestion）
- 用 float window 显示主内容
- 自动补偿 float 覆盖到的代码（`virt_lines`）
- 与 `vim.diagnostic.virtual_lines` 做开关联动

## 核心状态（state）

- `win`: 当前预览 float 窗口 id
- `float_bufnr`: float 对应 buffer
- `source_bufnr`: 源代码 buffer
- `virtual_lines_paused`: 是否临时关闭了 `virtual_lines`
- `anchor_bufnr` / `anchor_lnum`: 锚点位置（用于判断是否需要关闭）

## 主要函数

- `set_virtual_lines_active(active)`
  - `true`: `virtual_lines = { current_line = true }`
  - `false`: `virtual_lines = false`

- `clear()`
  - 关闭 float
  - 清理 covered code 的 namespace
  - 恢复 `virtual_lines`
  - 重置状态

- `normalize_message(msg)`
  - 把多行内容压成单行
  - 清理多余空格

- `to_list(value)`
  - 把输入统一成字符串数组（支持 `nil/string/table`）

- `build_virt_lines(payload)`
  - 把外部 payload 解析成 section 列表
  - 支持字段：`error/warn/info/msg(msm)/suggestion`

- `get_covered_buffer_lines(cur_win, row, height)`
  - 计算 float 遮挡了哪些源代码行
  - 包含“少 1 行”补偿逻辑

- `render_shadow_lines(source_bufnr, cursor_lnum, covered_lines)`
  - 把被遮挡代码渲染为 `virt_lines`（显示在锚点行下）

- `open_float(sections, cursor_lnum)`
  - 创建并渲染 float
  - 设置高亮与窗口属性
  - 暂停 `virtual_lines`
  - 触发 covered code 补偿渲染

- `resolve_target_lnum(line, bufnr)`
  - 把 1-based 行号转换成 0-based，并做边界裁剪

## 对外 API

- `setup()`
  - 注册自动命令：
    - `CursorMoved`: 仅当离开锚点行时关闭
    - `BufLeave/WinLeave`: 关闭

- `preview(payload)`
  - 用当前光标行展示 payload

- `preview_at(line, payload)`
  - 在指定行展示 payload（`line` 为 1-based）

- `preview_current_line()`
  - 把当前行 `vim.diagnostic.get` 转成 payload 后展示

## payload 示例

```lua
require("code_preview").preview_at(12, {
  error = { "undefined symbol: foo" },
  warn = { "unused variable: bar" },
  info = { "type inferred as any" },
  msm = { "custom note" }, -- 或 msg
  suggestion = { "consider renaming variable" },
})
```

