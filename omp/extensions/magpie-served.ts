/**
 * magpie-served — 在状态栏显示 magpie 网关实际服务的模型。
 *
 * magpie 把 group/smart-split 路由到具体模型后，会在响应头里带上
 * X-Magpie-Model / X-Magpie-Provider；omp 自己只记录选择器
 * （magpie/group/smart-split），所以这里把真实模型写进 footer status。
 *
 * 一个会话里可能被路由到多个模型：按最近使用顺序保留最近 3 个，每个缩写到
 * 最多 5 个字符，其余折叠成 +N。
 *
 * 需要 statusLine 里包含 `status` 段，或打开 statusLine.showHookStatus。
 */

type StatusUI = { setStatus?: (key: string, text: string) => void };
type ExtensionCtx = { ui?: StatusUI; model?: { id?: unknown } };
type ProviderResponseEvent = { headers?: unknown };
type ExtensionAPI = {
	on(
		event: "after_provider_response",
		handler: (event: ProviderResponseEvent, ctx: ExtensionCtx) => void,
	): void;
	on(event: "session_start", handler: (event: unknown, ctx: ExtensionCtx) => void): void;
};

/** 每个模型名的最大长度。 */
const MAX_LABEL = 5;

/** 状态栏宽度有限，只显示最近使用的几个模型，其余折叠成 +N。 */
const MAX_SHOWN = 3;

/** 模型名首段的缩写；没列到的保持原样。 */
const ALIASES: Record<string, string> = {
	deepseek: "ds",
	gemini: "gem",
	claude: "cl",
	mistral: "mis",
	codestral: "cod",
	ministral: "mini",
	zai: "",
};

/**
 * `deepseek-v4-1-flash-1017` → `ds41f`
 * `gemini-4-hydrogen`        → `gem4h`
 * `zai-glm-5-3`              → `glm53`
 * `gpt-5.6-luna`             → `gpt56`
 * `claude-opus-5.5`          → `cl55o`
 * `codestral-2508`           → `cod25`
 */
function shorten(model: string): string {
	const parts = model.replace(/-latest$/, "").split("-");
	const head = ALIASES[parts[0]];
	if (head !== undefined) {
		if (head === "") parts.shift();
		else parts[0] = head;
	}

	const alias = parts.shift() ?? "";
	let digits = "";
	for (const part of parts) {
		const d = part.replace(/\D/g, "");
		if (!d) continue;
		digits += d;
		if (digits.length >= 2) break;
	}
	digits = digits.slice(0, 2);
	const variant = parts.filter((p) => /[a-z]/i.test(p)).pop()?.[0] ?? "";

	const full = alias + digits + variant;
	if (full.length <= MAX_LABEL) return full;
	const noVariant = alias + digits;
	return noVariant.slice(0, MAX_LABEL);
}

function header(headers: unknown, name: string): string | undefined {
	if (typeof headers !== "object" || headers === null) return undefined;
	if ("get" in headers && typeof headers.get === "function") {
		// Headers 实例：get 是方法，不是可枚举属性
		const got: unknown = headers.get(name);
		return typeof got === "string" ? got : undefined;
	}
	const lower = name.toLowerCase();
	for (const [key, value] of Object.entries(headers)) {
		if (key.toLowerCase() === lower && typeof value === "string") return value;
	}
	return undefined;
}

export default function (pi: ExtensionAPI) {
	// 插入顺序 = 最近使用顺序；重复使用会移到末尾。
	const used = new Set<string>();

	pi.on("session_start", () => {
		used.clear();
	});

	pi.on("after_provider_response", (event, ctx) => {
		// 只统计走路由组的请求；标题生成之类的旁路调用会直接打具体模型，不算
		const requested = ctx.model?.id;
		if (typeof requested !== "string" || !requested.startsWith("group/")) return;
		const served = header(event.headers, "x-magpie-model");
		if (!served) return;
		const provider = header(event.headers, "x-magpie-provider");
		const label = shorten(provider ? served.replace(`${provider}/`, "") : served);

		used.delete(label);
		used.add(label);

		const shown = [...used].slice(-MAX_SHOWN);
		const hidden = used.size - shown.length;
		ctx.ui?.setStatus?.("magpie", shown.join(" · ") + (hidden > 0 ? ` +${hidden}` : ""));
	});
}