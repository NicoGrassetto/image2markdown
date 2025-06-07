#!/usr/bin/env python3
"""
Image Analysis CLI using LangChain and Azure AI Foundry
Analyzes images using multimodal AI models and outputs descriptions.
"""

import argparse
import base64
import os
import sys
from pathlib import Path
from typing import Optional

from azure.ai.inference import ChatCompletionsClient
from azure.ai.inference.models import SystemMessage, UserMessage, ImageContentItem, TextContentItem
from azure.core.credentials import AzureKeyCredential
from azure.identity import DefaultAzureCredential, ManagedIdentityCredential
from dotenv import load_dotenv
from PIL import Image
import logging

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)


class ImageAnalyzer:
    """
    Image analyzer using Azure AI Foundry multimodal models via LangChain.
    Follows Azure best practices with managed identity authentication.
    """
    
    def __init__(self, endpoint: str, model_name: str = "gpt-4o", use_managed_identity: bool = True):
        """
        Initialize the image analyzer.
        
        Args:
            endpoint: Azure AI Foundry endpoint URL
            model_name: Name of the multimodal model to use
            use_managed_identity: Whether to use managed identity for authentication
        """
        self.endpoint = endpoint
        self.model_name = model_name
        self.client = self._create_client(use_managed_identity)
    
    def _create_client(self, use_managed_identity: bool) -> ChatCompletionsClient:
        """
        Create Azure AI client with appropriate authentication.
        Follows Azure security best practices.
        """
        try:
            if use_managed_identity:
                # Preferred: Use managed identity for Azure-hosted applications
                credential = DefaultAzureCredential()
                logger.info("Using managed identity authentication")
            else:
                # Fallback: Use API key (not recommended for production)
                api_key = os.getenv("AZURE_AI_API_KEY")
                if not api_key:
                    raise ValueError("AZURE_AI_API_KEY environment variable not set")
                credential = AzureKeyCredential(api_key)
                logger.info("Using API key authentication")
            
            return ChatCompletionsClient(endpoint=self.endpoint, credential=credential)
        
        except Exception as e:
            logger.error(f"Failed to create Azure AI client: {e}")
            raise
    
    def _encode_image(self, image_path: str) -> str:
        """
        Encode image to base64 string for API consumption.
        Includes validation and error handling.
        """
        try:
            # Validate image file exists
            if not Path(image_path).exists():
                raise FileNotFoundError(f"Image file not found: {image_path}")
            
            # Validate image can be opened
            with Image.open(image_path) as img:
                logger.info(f"Image loaded: {img.size} pixels, format: {img.format}")
            
            # Read and encode image
            with open(image_path, "rb") as image_file:
                encoded_image = base64.b64encode(image_file.read()).decode('utf-8')
            
            return encoded_image
        
        except Exception as e:
            logger.error(f"Failed to encode image {image_path}: {e}")
            raise
    
    def analyze_image(self, image_path: str, custom_prompt: Optional[str] = None) -> str:
        """
        Analyze an image and return a description.
        
        Args:
            image_path: Path to the image file
            custom_prompt: Optional custom prompt for analysis
            
        Returns:
            String description of the image
        """
        try:
            # Encode image
            encoded_image = self._encode_image(image_path)
            
            # Prepare prompt
            default_prompt = (
                "Analyze this image and provide a detailed description. "
                "Include information about objects, people, setting, colors, mood, "
                "and any text visible in the image. Be descriptive but concise."
            )
            prompt = custom_prompt or default_prompt
            
            # Prepare messages for multimodal input
            messages = [
                SystemMessage(content="You are an expert image analyst. Provide detailed, accurate descriptions of images."),
                UserMessage(content=[
                    TextContentItem(text=prompt),
                    ImageContentItem(image_url=f"data:image/jpeg;base64,{encoded_image}")
                ])
            ]
            
            # Call Azure AI with retry logic
            logger.info(f"Analyzing image: {image_path}")
            response = self._call_with_retry(messages)
            
            return response.choices[0].message.content
        
        except Exception as e:
            logger.error(f"Failed to analyze image: {e}")
            raise
    
    def _call_with_retry(self, messages, max_retries: int = 3):
        """
        Call Azure AI API with exponential backoff retry logic.
        Implements Azure best practices for handling transient failures.
        """
        import time
        
        for attempt in range(max_retries):
            try:
                response = self.client.complete(
                    messages=messages,
                    model=self.model_name,
                    max_tokens=1000,
                    temperature=0.1
                )
                return response
            
            except Exception as e:
                if attempt == max_retries - 1:
                    raise
                
                wait_time = (2 ** attempt) + 1  # Exponential backoff
                logger.warning(f"API call failed (attempt {attempt + 1}), retrying in {wait_time}s: {e}")
                time.sleep(wait_time)


def main():
    """
    Main CLI function with comprehensive argument parsing and error handling.
    """
    parser = argparse.ArgumentParser(
        description="Analyze images using Azure AI Foundry multimodal models",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python app.py image.jpg
  python app.py image.png --prompt "Describe the technical aspects of this diagram"
  python app.py photo.jpg --endpoint "https://your-endpoint.inference.ai.azure.com" --model "gpt-4o"
        """
    )
    
    parser.add_argument(
        "image_path",
        help="Path to the image file to analyze"
    )
    
    parser.add_argument(
        "--endpoint",
        default=os.getenv("AZURE_AI_ENDPOINT"),
        help="Azure AI Foundry endpoint URL (or set AZURE_AI_ENDPOINT env var)"
    )
    
    parser.add_argument(
        "--model",
        default="gpt-4o",
        help="Model name to use (default: gpt-4o)"
    )
    
    parser.add_argument(
        "--prompt",
        help="Custom prompt for image analysis"
    )
    
    parser.add_argument(
        "--use-api-key",
        action="store_true",
        help="Use API key authentication instead of managed identity"
    )
    
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Enable verbose logging"
    )
    
    args = parser.parse_args()
    
    # Configure logging level
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # Validate required parameters
    if not args.endpoint:
        logger.error("Azure AI endpoint not provided. Set --endpoint or AZURE_AI_ENDPOINT environment variable.")
        sys.exit(1)
    
    try:
        # Create analyzer instance
        analyzer = ImageAnalyzer(
            endpoint=args.endpoint,
            model_name=args.model,
            use_managed_identity=not args.use_api_key
        )
        
        # Analyze image
        description = analyzer.analyze_image(args.image_path, args.prompt)
        
        # Output result
        print("\n" + "="*50)
        print("IMAGE ANALYSIS RESULT")
        print("="*50)
        print(description)
        print("="*50)
        
    except Exception as e:
        logger.error(f"Application failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()