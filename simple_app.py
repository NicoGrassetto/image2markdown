#!/usr/bin/env python3
"""
Simple Image Analysis using Azure OpenAI
Analyzes images using GPT-4o vision capabilities.
"""

import argparse
import base64
import os
import sys
from pathlib import Path
from typing import Optional

from openai import AzureOpenAI
from dotenv import load_dotenv
from PIL import Image

# Load environment variables
load_dotenv()

def encode_image(image_path: str) -> str:
    """
    Encode image to base64 string for API consumption.
    """
    try:
        # Validate image file exists
        if not Path(image_path).exists():
            raise FileNotFoundError(f"Image file not found: {image_path}")
        
        # Validate image can be opened
        with Image.open(image_path) as img:
            print(f"Image loaded: {img.size} pixels, format: {img.format}")
        
        # Read and encode image
        with open(image_path, "rb") as image_file:
            encoded_image = base64.b64encode(image_file.read()).decode('utf-8')
        
        return encoded_image
    
    except Exception as e:
        print(f"Failed to encode image {image_path}: {e}")
        raise

def analyze_image(image_path: str, custom_prompt: Optional[str] = None) -> str:
    """
    Analyze an image using Azure OpenAI GPT-4o vision.
    """
    # Configuration
    endpoint = os.getenv("AZURE_AI_ENDPOINT")
    api_key = os.getenv("AZURE_AI_API_KEY")
    api_version = "2024-12-01-preview"
    deployment = "gpt-4o"  # This should match your deployment name
    
    if not endpoint or not api_key:
        raise ValueError("AZURE_AI_ENDPOINT and AZURE_AI_API_KEY must be set in environment variables")
    
    # Create client
    client = AzureOpenAI(
        api_version=api_version,
        azure_endpoint=endpoint,
        api_key=api_key,
    )
    
    # Encode image
    encoded_image = encode_image(image_path)
    
    # Prepare prompt
    default_prompt = (
        "Analyze this image and provide a detailed description. "
        "Include information about objects, people, setting, colors, mood, "
        "and any text visible in the image. Be descriptive but concise."
    )
    prompt = custom_prompt or default_prompt
    
    # Create messages with image
    messages = [
        {
            "role": "system",
            "content": "You are an expert image analyst. Provide detailed, accurate descriptions of images."
        },
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": prompt
                },
                {
                    "type": "image_url",
                    "image_url": {
                        "url": f"data:image/jpeg;base64,{encoded_image}"
                    }
                }
            ]
        }
    ]
    
    # Call Azure OpenAI
    print(f"Analyzing image: {image_path}")
    response = client.chat.completions.create(
        messages=messages,
        model=deployment,
        max_tokens=1000,
        temperature=0.1
    )
    
    return response.choices[0].message.content

def main():
    """
    Main CLI function.
    """
    parser = argparse.ArgumentParser(
        description="Analyze images using Azure OpenAI GPT-4o vision",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python simple_app.py image.jpg
  python simple_app.py image.png --prompt "Describe the technical aspects of this diagram"
        """
    )
    
    parser.add_argument(
        "image_path",
        help="Path to the image file to analyze"
    )
    
    parser.add_argument(
        "--prompt",
        help="Custom prompt for image analysis"
    )
    
    args = parser.parse_args()
    
    try:
        # Analyze image
        description = analyze_image(args.image_path, args.prompt)
        
        # Output result
        print("\n" + "="*50)
        print("IMAGE ANALYSIS RESULT")
        print("="*50)
        print(description)
        print("="*50)
        
    except Exception as e:
        print(f"Application failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
