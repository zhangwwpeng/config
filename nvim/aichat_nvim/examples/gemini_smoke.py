"""Manual Gemini smoke test.

Run explicitly with: uv run python examples/gemini_smoke.py
"""

from google import genai


def main() -> None:
    client = genai.Client()
    response = client.models.generate_content(
        model="gemini-3.1-pro",
        contents="Explain how AI works in a few words",
    )
    print(response.text)


if __name__ == "__main__":
    main()
