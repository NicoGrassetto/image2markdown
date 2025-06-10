#!/usr/bin/env python3
"""
Updated Image Analysis Module for Azure AI Foundry
Provides stateless image analysis capabilities using the deployed GPT-4o model.
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
# Load Azure AI Foundry configuration
load_dotenv('.env.aiFoundry')


class AzureAIFoundryImageAnalyzer:
    """
    Stateless image analyzer using Azure AI Foundry GPT-4o vision.
    Configured to work with the deployed Azure AI Foundry resources.
    """
    
    def __init__(self):
        """Initialize the image analyzer with Azure AI Foundry configuration."""
        self.endpoint = os.getenv("AZURE_OPENAI_ENDPOINT", "https://openai-73uqkh3mopzeg.openai.azure.com/")
        self.api_key = os.getenv("AZURE_OPENAI_API_KEY")  # You'll need to set this
        self.api_version = os.getenv("AZURE_OPENAI_API_VERSION", "2024-02-01")
        self.deployment_name = os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME", "gpt-4o")
        
        # Validate configuration
        if not self.endpoint:
            raise ValueError("AZURE_OPENAI_ENDPOINT environment variable is required")
        
        if not self.api_key:
            raise ValueError(
                "AZURE_OPENAI_API_KEY environment variable is required. "
                "Run: az cognitiveservices account keys list --name openai-73uqkh3mopzeg --resource-group koloko"
            )
        
        # Initialize Azure OpenAI client
        try:
            self.client = AzureOpenAI(
                azure_endpoint=self.endpoint,
                api_key=self.api_key,
                api_version=self.api_version,
            )
        except Exception as e:
            raise RuntimeError(f"Failed to initialize Azure OpenAI client: {str(e)}")
    
    def encode_image(self, image_path_or_bytes) -> str:
        """
        Encode image to base64 string.
        
        Args:
            image_path_or_bytes: Path to image file or bytes data
            
        Returns:
            Base64 encoded image string
        """
        if isinstance(image_path_or_bytes, (str, Path)):
            # Handle file path
            image_path = Path(image_path_or_bytes)
            if not image_path.exists():
                raise FileNotFoundError(f"Image file not found: {image_path}")
            
            with open(image_path, "rb") as image_file:
                image_data = image_file.read()
        else:
            # Handle bytes data
            image_data = image_path_or_bytes
        
        return base64.b64encode(image_data).decode('utf-8')
    
    def analyze_image(
        self, 
        image_data, 
        system_prompt: Optional[str] = None, 
        user_prompt: Optional[str] = None,
        max_tokens: int = 1000,
        temperature: float = 0.1
    ) -> str:
        """
        Analyze an image using Azure AI Foundry GPT-4o vision.
        
        Args:
            image_data: Image file path (str/Path) or image bytes
            system_prompt: Optional system prompt to guide AI behavior
            user_prompt: Optional user prompt for specific analysis
            max_tokens: Maximum tokens in response
            temperature: Response creativity (0.0-1.0)
            
        Returns:
            Analysis result as string
            
        Raises:
            ValueError: If image_data is invalid
            RuntimeError: If API call fails
        """
        try:
            # Encode image
            base64_image = self.encode_image(image_data)
            
            # Prepare messages
            messages = []
            
            # Add system prompt if provided
            if system_prompt and system_prompt.strip():
                messages.append({
                    "role": "system", 
                    "content": system_prompt.strip()
                })
            
            # Prepare user message with image
            user_content = []
            
            # Add text prompt if provided
            if user_prompt and user_prompt.strip():
                user_content.append({
                    "type": "text",
                    "text": user_prompt.strip()
                })
            else:
                # Default prompt if none provided
                user_content.append({
                    "type": "text",
                    "text": "Analyze this image and provide a detailed description."
                })
            
            # Add image
            user_content.append({
                "type": "image_url",
                "image_url": {
                    "url": f"data:image/jpeg;base64,{base64_image}",
                    "detail": "high"
                }
            })
            
            messages.append({
                "role": "user",
                "content": user_content
            })
            
            # Make API call to Azure AI Foundry
            response = self.client.chat.completions.create(
                model=self.deployment_name,  # Uses the deployed gpt-4o model
                messages=messages,
                max_tokens=max_tokens,
                temperature=temperature
            )
            
            return response.choices[0].message.content
            
        except FileNotFoundError as e:
            raise ValueError(f"Image file error: {str(e)}")
        except Exception as e:
            raise RuntimeError(f"Failed to analyze image: {str(e)}")
    
    def analyze_multiple_images(
        self, 
        image_list, 
        system_prompt: Optional[str] = None, 
        user_prompt: Optional[str] = None
    ) -> list:
        """
        Analyze multiple images individually.
        
        Args:
            image_list: List of image paths or bytes
            system_prompt: Optional system prompt
            user_prompt: Optional user prompt
            
        Returns:
            List of analysis results
        """
        results = []
        for i, image_data in enumerate(image_list):
            try:
                result = self.analyze_image(
                    image_data=image_data,
                    system_prompt=system_prompt,
                    user_prompt=user_prompt
                )
                results.append({
                    "index": i,
                    "success": True,
                    "result": result
                })
            except Exception as e:
                results.append({
                    "index": i,
                    "success": False,
                    "error": str(e)
                })
        
        return results
    
    def get_service_info(self) -> dict:
        """
        Get information about the Azure AI Foundry service configuration.
        
        Returns:
            Dictionary with service information
        """
        return {
            "endpoint": self.endpoint,
            "deployment_name": self.deployment_name,
            "api_version": self.api_version,
            "service": "Azure AI Foundry",
            "model": "GPT-4o Vision"
        }


# Backward compatibility - alias to existing class name
AzureImageAnalyzer = AzureAIFoundryImageAnalyzer

# Example usage
if __name__ == "__main__":
    # Initialize analyzer
    analyzer = AzureAIFoundryImageAnalyzer()
    
    # Print service info
    print("Azure AI Foundry Configuration:")
    info = analyzer.get_service_info()
    for key, value in info.items():
        print(f"  {key}: {value}")
    
    print("\nTo use this analyzer, you need to:")
    print("1. Set your AZURE_OPENAI_API_KEY environment variable")
    print("2. Run: az cognitiveservices account keys list --name openai-73uqkh3mopzeg --resource-group koloko")
    print("3. Copy one of the keys to your .env file or .env.aiFoundry file")
    print("4. Example: AZURE_OPENAI_API_KEY=your_key_here")
