#!/usr/bin/env python3
"""
Streamlit Image Analysis App with Managed Identity
Upload images and analyze them using Azure OpenAI GPT-4o vision with secure authentication.
"""

import streamlit as st
from PIL import Image
import io
from typing import List
import logging

from image_analyzer import AzureImageAnalyzer

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Configure Streamlit page
st.set_page_config(
    page_title="Azure AI Image Analyzer (Managed Identity)",
    page_icon="🔍",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Initialize session state
if 'analyzer' not in st.session_state:
    try:
        # Get client ID from environment or user input
        client_id = st.sidebar.text_input(
            "Managed Identity Client ID (optional)", 
            value="",
            help="Leave empty to use system-assigned managed identity"
        )
        
        st.session_state.analyzer = AzureImageAnalyzer(
            client_id=client_id if client_id.strip() else None
        )
        st.sidebar.success("✅ Connected with managed identity")
        
        # Display connection info
        info = st.session_state.analyzer.get_service_info()
        st.sidebar.info(f"Authentication: {info['authentication']}")
        st.sidebar.info(f"Identity: {info['client_id']}")
        
    except Exception as e:
        st.error(f"Failed to initialize Azure OpenAI with managed identity: {str(e)}")
        st.error("Please ensure:")
        st.error("1. You're running on Azure or have Azure CLI logged in")
        st.error("2. Managed identity has 'Cognitive Services OpenAI User' role")
        st.error("3. AZURE_OPENAI_ENDPOINT environment variable is set")
        st.stop()

def analyze_single_image(image_bytes: bytes, system_prompt: str, user_prompt: str) -> str:
    """Analyze a single image and return the result."""
    try:
        result = st.session_state.analyzer.analyze_image(
            image_data=image_bytes,
            system_prompt=system_prompt if system_prompt.strip() else None,
            user_prompt=user_prompt if user_prompt.strip() else None
        )
        return result
    except Exception as e:
        logger.error(f"Error analyzing image: {str(e)}")
        return f"Error analyzing image: {str(e)}"

def main():
    """Main Streamlit application."""
      # Header
    st.title("🔍 Azure AI Image Analyzer (Managed Identity)")
    st.markdown("Upload images and analyze them using Azure OpenAI GPT-4o vision with secure managed identity authentication.")
    
    # Connection test
    col_test1, col_test2 = st.columns([3, 1])
    with col_test2:
        if st.button("🔄 Test Connection", type="secondary"):
            with st.spinner("Testing connection..."):
                if st.session_state.analyzer.test_connection():
                    st.success("✅ Connection successful!")
                else:
                    st.error("❌ Connection failed!")
    
    # Sidebar for configuration
    with st.sidebar:
        st.header("⚙️ Configuration")
        
        # System prompt configuration
        st.subheader("System Prompt")
        st.info("The system prompt defines the AI's role and behavior for all image analyses.")
        
        system_prompt = st.text_area(
            "System Prompt",
            value="You are an expert image analyst. Provide detailed, accurate descriptions of images. Be thorough but concise in your analysis.",
            height=120,
            help="This prompt will be used for all image analyses to guide the AI's behavior."
        )
        
        # User prompt configuration
        st.subheader("Analysis Prompt")
        st.info("The analysis prompt specifies what you want to know about each image.")
        
        user_prompt = st.text_area(
            "Analysis Prompt",
            value="Analyze this image and provide a detailed description. Include information about objects, people, setting, colors, mood, and any text visible in the image.",
            height=100,
            help="This prompt specifies what analysis you want performed on each image."
        )
          # Model information
        st.subheader("ℹ️ Model Info")
        info = st.session_state.analyzer.get_service_info()
        st.markdown(f"""
        - **Model**: {info['model']}
        - **Provider**: {info['service']}
        - **Authentication**: {info['authentication']}
        - **Identity**: {info['client_id']}
        - **Mode**: Stateless (no conversation history)
        """)
    
    # Main content area
    col1, col2 = st.columns([1, 1])
    
    with col1:
        st.header("📁 Upload Images")
        
        # File uploader
        uploaded_files = st.file_uploader(
            "Choose image files",
            type=['png', 'jpg', 'jpeg', 'webp', 'bmp'],
            accept_multiple_files=True,
            help="Upload one or more images for analysis. Supported formats: PNG, JPG, JPEG, WebP, BMP"
        )
        
        if uploaded_files:
            st.success(f"✅ {len(uploaded_files)} image(s) uploaded successfully!")
              # Display uploaded images
            st.subheader("Uploaded Images")
            for i, uploaded_file in enumerate(uploaded_files):
                with st.expander(f"📷 {uploaded_file.name}", expanded=True):
                    # Display image
                    image = Image.open(uploaded_file)
                    st.image(image, caption=uploaded_file.name, use_container_width=True)
                    
                    # Image info
                    st.caption(f"Size: {image.size[0]}x{image.size[1]} pixels | Format: {image.format}")
    
    with col2:
        st.header("🤖 Analysis Results")
        
        if uploaded_files:
            # Analyze button
            if st.button("🔍 Analyze All Images", type="primary", use_container_width=True):
                
                # Create progress bar
                progress_bar = st.progress(0)
                status_text = st.empty()
                
                results = []
                
                for i, uploaded_file in enumerate(uploaded_files):
                    # Update progress
                    progress = (i + 1) / len(uploaded_files)
                    progress_bar.progress(progress)
                    status_text.text(f"Analyzing {uploaded_file.name}... ({i+1}/{len(uploaded_files)})")
                    
                    # Read image bytes
                    uploaded_file.seek(0)  # Reset file pointer
                    image_bytes = uploaded_file.read()
                    
                    # Analyze image
                    with st.spinner(f"Analyzing {uploaded_file.name}..."):
                        result = analyze_single_image(image_bytes, system_prompt, user_prompt)
                        results.append((uploaded_file.name, result))
                
                # Clear progress indicators
                progress_bar.empty()
                status_text.empty()
                
                # Display results
                st.success("✅ Analysis complete!")
                
                for filename, result in results:
                    with st.expander(f"📋 Analysis: {filename}", expanded=True):
                        st.markdown("**Result:**")
                        st.write(result)
                        
                        # Copy button for result
                        st.code(result, language=None)
        else:
            st.info("👆 Upload images to see analysis results here.")
            
            # Example section
            st.subheader("💡 How to use")
            st.markdown("""
            1. **Configure prompts** in the sidebar to customize the AI's behavior
            2. **Upload one or more images** using the file uploader
            3. **Click "Analyze All Images"** to process your images
            4. **View the results** for each image below
            
            The app works in a **stateless manner** - each image is analyzed independently without conversation history.
            """)

if __name__ == "__main__":
    main()
