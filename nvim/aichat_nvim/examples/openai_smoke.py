"""Manual smoke test for the local OpenAI-compatible provider.

Run explicitly with: uv run python examples/openai_smoke.py
"""

from openai import OpenAI


def main() -> None:
    client = OpenAI(api_key="dummy", base_url="http://127.0.0.1:15721")
    stream = client.chat.completions.create(
        model="[pro]gpt-5.5",
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
