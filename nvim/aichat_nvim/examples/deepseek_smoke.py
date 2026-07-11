"""Manual DeepSeek smoke test.

Run explicitly with: uv run python examples/deepseek_smoke.py
"""

import os

from openai import OpenAI


def main() -> None:
    client = OpenAI(
        api_key=os.environ["DEEPSEEK_API_KEY"],
        base_url="https://api.deepseek.com",
    )
    stream = client.chat.completions.create(
        model="deepseek-chat",
        messages=[
            {
                "role": "user",
                "content": "用中文写一首关于编程的五言绝句",
            }
        ],
        stream=True,
    )

    for chunk in stream:
        delta = chunk.choices[0].delta.content
        if delta:
            print(delta, end="", flush=True)
    print()


if __name__ == "__main__":
    main()
