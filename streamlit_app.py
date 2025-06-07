#!/usr/bin/env python3
"""
Streamlit Image Analysis App
Upload images and analyze them using Azure OpenAI GPT-4o vision.
"""

import streamlit as st
from PIL import Image
import io
from typing import List

from image_analyzer import AzureImageAnalyzer

# Configure Streamlit page
st.set_page_config(
    page_title="Azure AI Image Analyzer",
    page_icon="🔍",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Initialize session state
if 'analyzer' not in st.session_state:
    try:
        st.session_state.analyzer = AzureImageAnalyzer()
    except Exception as e:
        st.error(f"Failed to initialize Azure OpenAI: {str(e)}")
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
        return f"Error analyzing image: {str(e)}"

def main():
    """Main Streamlit application."""
    
    # Header
    st.title("🔍 Azure AI Image Analyzer")
    st.markdown("Upload images and analyze them using Azure OpenAI GPT-4o vision capabilities.")
    
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
        st.markdown("""
        - **Model**: GPT-4o Vision
        - **Provider**: Azure OpenAI
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
                    st.image(image, caption=uploaded_file.name, use_column_width=True)
                    
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
