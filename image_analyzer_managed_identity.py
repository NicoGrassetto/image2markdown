#!/usr/bin/env python3
"""
Image Analysis Module using Azure OpenAI with Managed Identity
Provides secure, stateless image analysis capabilities using Azure AD authentication.
"""

import base64
import os
import logging
from typing import Optional
from pathlib import Path

from openai import AzureOpenAI
from azure.identity import DefaultAzureCredential, ManagedIdentityCredential
from azure.keyvault.secrets import SecretClient
from dotenv import load_dotenv
from PIL import Image

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Load environment variables
load_dotenv()


class AzureImageAnalyzerManagedIdentity:
    """
    Secure image analyzer using Azure OpenAI with Managed Identity authentication.
    Follows Azure security best practices with Azure AD authentication and no API keys.
    """
    
    def __init__(self, client_id: Optional[str] = None):
        """
        Initialize the image analyzer with Managed Identity authentication.
        
        Args:
            client_id: Optional client ID for user-assigned managed identity
        """
        self.endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
        self.api_version = "2024-12-01-preview"
        self.deployment_name = os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME", "gpt-4o")
        self.client_id = client_id or os.getenv("AZURE_CLIENT_ID")
        
        # Validate configuration
        if not self.endpoint:
            raise ValueError(
                "AZURE_OPENAI_ENDPOINT environment variable is required. "
                "This should be your Azure OpenAI endpoint URL."
            )
        
        # Initialize Azure credential with fallback options
        self.credential = self._get_azure_credential()
        
        # Initialize Azure OpenAI client with managed identity
        try:
            self.client = AzureOpenAI(
                api_version=self.api_version,
                azure_endpoint=self.endpoint,
                azure_ad_token_provider=self._get_token_provider(),
            )
            logger.info("Successfully initialized Azure OpenAI client with managed identity")
        except Exception as e:
            logger.error(f"Failed to initialize Azure OpenAI client: {str(e)}")
            raise RuntimeError(f"Failed to initialize Azure OpenAI client: {str(e)}")
    
    def _get_azure_credential(self):
        """
        Get Azure credential with fallback chain for different deployment scenarios.
        
        Returns:
            Azure credential object
        """
        try:
            if self.client_id:
                # Use user-assigned managed identity if client ID is provided
                logger.info(f"Using user-assigned managed identity: {self.client_id}")
                return ManagedIdentityCredential(client_id=self.client_id)
            else:
                # Use DefaultAzureCredential for automatic credential chain
                logger.info("Using DefaultAzureCredential for authentication")
                return DefaultAzureCredential()
        except Exception as e:
            logger.error(f"Failed to initialize Azure credential: {str(e)}")
            raise
    
    def _get_token_provider(self):
        """
        Get token provider function for Azure OpenAI client.
        
        Returns:
            Token provider function
        """
        def token_provider():
            try:
                # Request token for Cognitive Services scope
                token = self.credential.get_token("https://cognitiveservices.azure.com/.default")
                return token.token
            except Exception as e:
                logger.error(f"Failed to get access token: {str(e)}")
                raise
        
        return token_provider
    
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
        Analyze an image using Azure OpenAI GPT-4o vision with managed identity.
        
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
            
            # Make API call with retry logic
            response = self._call_with_retry(messages, max_tokens, temperature)
            
            return response.choices[0].message.content
            
        except FileNotFoundError as e:
            raise ValueError(f"Image file error: {str(e)}")
        except Exception as e:
            logger.error(f"Failed to analyze image: {str(e)}")
            raise RuntimeError(f"Failed to analyze image: {str(e)}")
    
    def _call_with_retry(self, messages, max_tokens: int, temperature: float, max_retries: int = 3):
        """
        Call Azure OpenAI API with exponential backoff retry logic.
        Implements Azure best practices for handling transient failures.
        """
        import time
        
        for attempt in range(max_retries):
            try:
                response = self.client.chat.completions.create(
                    model=self.deployment_name,
                    messages=messages,
                    max_tokens=max_tokens,
                    temperature=temperature
                )
                return response
            
            except Exception as e:
                if attempt == max_retries - 1:
                    logger.error(f"All retry attempts failed: {str(e)}")
                    raise
                
                wait_time = (2 ** attempt) + 1  # Exponential backoff
                logger.warning(f"Attempt {attempt + 1} failed, retrying in {wait_time} seconds: {str(e)}")
                time.sleep(wait_time)
    
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
                logger.error(f"Failed to analyze image {i}: {str(e)}")
                results.append({
                    "index": i,
                    "success": False,
                    "error": str(e)
                })
        
        return results
    
    def get_service_info(self) -> dict:
        """
        Get information about the Azure OpenAI service configuration.
        
        Returns:
            Dictionary with service information
        """
        return {
            "endpoint": self.endpoint,
            "deployment_name": self.deployment_name,
            "api_version": self.api_version,
            "authentication": "Managed Identity",
            "client_id": self.client_id or "System-assigned",
            "service": "Azure OpenAI",
            "model": "GPT-4o Vision"
        }
    
    def test_connection(self) -> bool:
        """
        Test the connection to Azure OpenAI service.
        
        Returns:
            True if connection is successful, False otherwise
        """
        try:
            # Simple test call
            response = self.client.chat.completions.create(
                model=self.deployment_name,
                messages=[{"role": "user", "content": "Hello"}],
                max_tokens=10
            )
            logger.info("Connection test successful")
            return True
        except Exception as e:
            logger.error(f"Connection test failed: {str(e)}")
            return False


# For backward compatibility and ease of migration
class AzureImageAnalyzer(AzureImageAnalyzerManagedIdentity):
    """
    Backward compatible alias that uses managed identity by default.
    """
    pass


# Example usage and testing
if __name__ == "__main__":
    import sys
    
    try:
        # Initialize analyzer with managed identity
        print("Initializing Azure Image Analyzer with Managed Identity...")
        analyzer = AzureImageAnalyzerManagedIdentity()
        
        # Print service info
        print("\nAzure OpenAI Configuration:")
        info = analyzer.get_service_info()
        for key, value in info.items():
            print(f"  {key}: {value}")
        
        # Test connection
        print("\nTesting connection...")
        if analyzer.test_connection():
            print("✅ Connection successful!")
        else:
            print("❌ Connection failed!")
            sys.exit(1)
        
        print("\n" + "="*50)
        print("SETUP COMPLETE")
        print("="*50)
        print("Your application is now configured to use managed identity for secure authentication.")
        print("No API keys are stored or transmitted - authentication is handled by Azure AD.")
        
    except Exception as e:
        print(f"❌ Setup failed: {str(e)}")
        print("\nTroubleshooting steps:")
        print("1. Ensure you're running on Azure (App Service, Container Apps, etc.) or have Azure CLI logged in")
        print("2. Verify the managed identity has 'Cognitive Services OpenAI User' role")
        print("3. Check that AZURE_OPENAI_ENDPOINT environment variable is set")
        print("4. Ensure Azure OpenAI service has disableLocalAuth set to true")
        sys.exit(1)
