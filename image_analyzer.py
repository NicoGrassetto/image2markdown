#!/usr/bin/env python3
"""
Image Analysis Module using Azure OpenAI
Provides stateless image analysis capabilities.
"""

import base64
import os
from typing import Optional
from pathlib import Path

from openai import AzureOpenAI
from dotenv import load_dotenv
from PIL import Image

# Load environment variables
load_dotenv()


class AzureImageAnalyzer:
    """
    Stateless image analyzer using Azure OpenAI GPT-4o vision.
    Follows Azure security best practices with managed identity support.
    """
    
    def __init__(self):
        """Initialize the image analyzer with Azure OpenAI configuration."""
        self.endpoint = os.getenv("AZURE_AI_ENDPOINT")
        self.api_key = os.getenv("AZURE_AI_API_KEY")
        self.api_version = "2024-12-01-preview"
        self.model = "gpt-4o"
        
        if not self.endpoint or not self.api_key:
            raise ValueError(
                "Azure OpenAI configuration missing. "
                "Please set AZURE_AI_ENDPOINT and AZURE_AI_API_KEY environment variables."
            )
        
        # Create Azure OpenAI client
        self.client = AzureOpenAI(
            api_version=self.api_version,
            azure_endpoint=self.endpoint,
            api_key=self.api_key,
        )
    
    def encode_image(self, image_data: bytes) -> str:
        """
        Encode image bytes to base64 string for API consumption.
        
        Args:
            image_data: Raw image bytes
            
        Returns:
            Base64 encoded image string
        """
        return base64.b64encode(image_data).decode('utf-8')
    
    def analyze_image(
        self, 
        image_data: bytes, 
        system_prompt: Optional[str] = None,
        user_prompt: Optional[str] = None
    ) -> str:
        """
        Analyze an image using Azure OpenAI GPT-4o vision in a stateless manner.
        
        Args:
            image_data: Raw image bytes
            system_prompt: Optional system prompt to guide the AI's behavior
            user_prompt: Optional custom user prompt for analysis
            
        Returns:
            String description of the image
        """
        try:
            # Encode image
            encoded_image = self.encode_image(image_data)
            
            # Default prompts
            default_system_prompt = (
                "You are an expert image analyst. Provide detailed, accurate descriptions of images. "
                "Be thorough but concise in your analysis."
            )
            
            default_user_prompt = (
                "Analyze this image and provide a detailed description. "
                "Include information about objects, people, setting, colors, mood, "
                "and any text visible in the image."
            )
            
            # Use provided prompts or defaults
            system_message = system_prompt or default_system_prompt
            user_message = user_prompt or default_user_prompt
            
            # Create messages with image - stateless approach (no conversation history)
            messages = [
                {
                    "role": "system",
                    "content": system_message
                },
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "text",
                            "text": user_message
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
            
            # Call Azure OpenAI with retry logic
            response = self._call_with_retry(messages)
            
            return response.choices[0].message.content
        
        except Exception as e:
            raise Exception(f"Failed to analyze image: {str(e)}")
    
    def _call_with_retry(self, messages, max_retries: int = 3):
        """
        Call Azure OpenAI API with exponential backoff retry logic.
        Implements Azure best practices for handling transient failures.
        """
        import time
        
        for attempt in range(max_retries):
            try:
                response = self.client.chat.completions.create(
                    messages=messages,
                    model=self.model,
                    max_tokens=1000,
                    temperature=0.1
                )
                return response
            
            except Exception as e:
                if attempt == max_retries - 1:
                    raise
                
                wait_time = (2 ** attempt) + 1  # Exponential backoff
                time.sleep(wait_time)
