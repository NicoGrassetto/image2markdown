#!/usr/bin/env python3
"""
Image Analysis CLI using Azure OpenAI
Analyzes images using GPT-4o vision capabilities.
"""

import argparse
import sys
from pathlib import Path

from image_analyzer import AzureImageAnalyzer


def main():
    """
    Main CLI function with comprehensive argument parsing and error handling.
    """
    parser = argparse.ArgumentParser(
        description="Analyze images using Azure OpenAI GPT-4o vision",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python app.py image.jpg
  python app.py image.png --prompt "Describe the technical aspects of this diagram"
  python app.py photo.jpg --system-prompt "You are a technical analyst"
        """,
    )

    parser.add_argument("image_path", help="Path to the image file to analyze")

    parser.add_argument(
        "--system-prompt", help="Custom system prompt to guide the AI's behavior"
    )

    parser.add_argument("--prompt", help="Custom prompt for image analysis")

    args = parser.parse_args()

    # Validate image file exists
    image_path = Path(args.image_path)
    if not image_path.exists():
        print(f"Error: Image file not found: {args.image_path}")
        sys.exit(1)

    try:
        # Create analyzer instance
        analyzer = AzureImageAnalyzer()

        # Read image file
        with open(image_path, "rb") as image_file:
            image_data = image_file.read()

        # Analyze image
        description = analyzer.analyze_image(
            image_data=image_data,
            system_prompt=args.system_prompt,
            user_prompt=args.prompt,
        )

        # Output result
        print("\n" + "=" * 50)
        print("IMAGE ANALYSIS RESULT")
        print("=" * 50)
        print(description)
        print("=" * 50)

    except Exception as e:
        print(f"Application failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
