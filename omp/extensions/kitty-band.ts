interface ComposerStyle {
  id: string;
  sideBorders: boolean;
  verticalChrome: number;
  statusAttachment: string;
  bottomBar: string;
  bottomBarGap: boolean;
  defaultPromptGutter: string;
  defaultPaddingX: () => number;
  sideChromeWidth: () => number;
  renderTop(ctx: { topBorder?: { content: string; width: number } }): string;
  renderRow(ctx: { gutter: string; text: string; pad: string }): string[];
  renderBottom(): undefined;
}

interface ComposerShapeApi {
  registerComposerShape(def: {
    label: string;
    description?: string;
    style: ComposerStyle;
  }): void;
}

const style: ComposerStyle = {
  id: "user.kitty-band",
  sideBorders: false,
  verticalChrome: 1,
  statusAttachment: "top-band",
  bottomBar: "none",
  bottomBarGap: false,
  defaultPromptGutter: "╰─❯ ",
  defaultPaddingX: () => 0,
  sideChromeWidth: () => 1,
  renderTop({ topBorder }) {
    return "╭─" + (topBorder?.content ?? "");
  },
  renderRow({ gutter, text, pad }) {
    return [gutter + text + pad];
  },
  renderBottom() {
    return undefined;
  },
};

export default function (pi: ComposerShapeApi) {
  pi.registerComposerShape({
    label: "Kitty Band",
    description: "Status band with a dash-arrow prompt and no right chrome",
    style,
  });
}
