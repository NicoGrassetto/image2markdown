#!/usr/bin/env python3
"""
Image Analysis CLI using Azure OpenAI with Managed Identity
Analyzes images using GPT-4o vision capabilities with secure Azure AD authentication.
"""

import argparse
import sys
import os
from pathlib import Path

from image_analyzer import AzureImageAnalyzer


def main():
    """
    Main CLI function with comprehensive argument parsing and error handling.
    """
    parser = argparse.ArgumentParser(
        description="Analyze images using Azure OpenAI GPT-4o vision with managed identity",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python app.py image.jpg
  python app.py image.png --prompt "Describe the technical aspects of this diagram"
  python app.py photo.jpg --system-prompt "You are a technical analyst"
  python app.py image.jpg --client-id "your-managed-identity-client-id"        """
    )
    
    parser.add_argument(
        "image_path",
        nargs="?",
        help="Path to the image file to analyze (required unless using --test-connection)"
    )
    
    parser.add_argument(
        "--system-prompt",
        help="Custom system prompt to guide the AI's behavior"
    )
    
    parser.add_argument(
        "--prompt",
        help="Custom prompt for image analysis"
    )
    
    parser.add_argument(
        "--client-id",
        help="Client ID for user-assigned managed identity (optional)"
    )
    
    parser.add_argument(
        "--test-connection",
        action="store_true",
        help="Test the connection to Azure OpenAI service"    )
    
    args = parser.parse_args()
    
    # Validate arguments
    if not args.test_connection and not args.image_path:
        print("Error: image_path is required unless using --test-connection")
        parser.print_help()
        sys.exit(1)
    
    # Validate image file exists (unless just testing connection)
    if not args.test_connection and args.image_path:
        image_path = Path(args.image_path)
        if not image_path.exists():
            print(f"Error: Image file not found: {args.image_path}")
            sys.exit(1)
    
    try:
        # Create analyzer instance with optional client ID
        print("Initializing Azure OpenAI client with managed identity...")
        analyzer = AzureImageAnalyzer(client_id=args.client_id)
        
        # Display service info
        info = analyzer.get_service_info()
        print(f"Endpoint: {info['endpoint']}")
        print(f"Model: {info['deployment_name']}")
        print(f"Authentication: {info['authentication']}")
        print(f"Identity: {info['client_id']}")
        
        # Test connection if requested
        if args.test_connection:
            print("\nTesting connection...")
            if analyzer.test_connection():
                print("✅ Connection successful!")
                return
            else:
                print("❌ Connection failed!")
                sys.exit(1)
        
        # Read and analyze image
        print(f"\nAnalyzing image: {args.image_path}")
        with open(args.image_path, "rb") as image_file:
            image_data = image_file.read()
        
        # Analyze image
        description = analyzer.analyze_image(
            image_data=image_data,
            system_prompt=args.system_prompt,
            user_prompt=args.prompt
        )
        
        # Output result
        print("\n" + "="*50)
        print("IMAGE ANALYSIS RESULT")
        print("="*50)
        print(description)
        print("="*50)
        
    except Exception as e:
        print(f"❌ Application failed: {e}")
        print("\nTroubleshooting steps:")
        print("1. Ensure you're running on Azure (App Service, Container Apps, etc.) or have Azure CLI logged in")
        print("2. Verify the managed identity has 'Cognitive Services OpenAI User' role")
        print("3. Check that AZURE_OPENAI_ENDPOINT environment variable is set")
        print("4. Ensure Azure OpenAI service has managed identity authentication enabled")
        sys.exit(1)


if __name__ == "__main__":
    main()