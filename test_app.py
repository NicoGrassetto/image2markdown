#!/usr/bin/env python3
"""
Test script to debug the Azure OpenAI image analysis
"""

import os
from openai import AzureOpenAI
from dotenv import load_dotenv
import base64

# Load environment variables
load_dotenv()

def test_azure_openai():
    print("Testing Azure OpenAI connection...")
    
    # Configuration
    endpoint = os.getenv("AZURE_AI_ENDPOINT")
    api_key = os.getenv("AZURE_AI_API_KEY")
    
    print(f"Endpoint: {endpoint}")
    print(f"API Key: {api_key[:10]}..." if api_key else "No API key")
    
    # Create client
    client = AzureOpenAI(
        api_version="2024-12-01-preview",
        azure_endpoint=endpoint,
        api_key=api_key,
    )
    
    # Test with a simple text message
    print("Testing simple chat completion...")
    response = client.chat.completions.create(
        messages=[
            {
                "role": "system",
                "content": "You are a helpful assistant."
            },
            {
                "role": "user",
                "content": "Say hello!"
            }
        ],
        model="gpt-4o",
        max_tokens=100
    )
    
    print("Response:", response.choices[0].message.content)
    
    # Now test with image
    print("\nTesting image analysis...")
    image_path = "images/Screenshot 2025-06-07 151823.png"
    
    # Encode image
    with open(image_path, "rb") as image_file:
        encoded_image = base64.b64encode(image_file.read()).decode('utf-8')
    
    # Create messages with image
    messages = [
        {
            "role": "system",
            "content": "You are an expert image analyst."
        },
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": "Describe this image in detail."
                },
                {
                    "type": "image_url",
                    "image_url": {
                        "url": f"data:image/png;base64,{encoded_image}"
                    }
                }
            ]
        }
    ]
    
    # Call Azure OpenAI
    response = client.chat.completions.create(
        messages=messages,
        model="gpt-4o",
        max_tokens=1000,
        temperature=0.1
    )
    
    print("Image Analysis Result:")
    print("="*50)
    print(response.choices[0].message.content)
    print("="*50)

if __name__ == "__main__":
    try:
        test_azure_openai()
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
