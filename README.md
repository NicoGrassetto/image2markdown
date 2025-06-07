# Image Analysis CLI with Azure AI Foundry

A command-line tool that uses Azure AI Foundry's multimodal models to analyze images and provide detailed descriptions.

## Features

- Analyzes images using GPT-4o or other multimodal models
- Supports various image formats (JPEG, PNG, etc.)
- Custom prompts for specific analysis needs
- Secure authentication with managed identity (recommended) or API keys
- Comprehensive error handling and retry logic
- Verbose logging for debugging

## Setup

1. **Create and activate virtual environment:**
   ```powershell
   python -m venv venv
   .\venv\Scripts\Activate.ps1
   ```

2. **Install dependencies:**
   ```powershell
   pip install -r requirements.txt
   ```

3. **Configure Azure AI Foundry:**
   - Copy `.env.example` to `.env`
   - Set your Azure AI Foundry endpoint URL
   - Optionally set API key (for development only)

## Usage

### Basic Usage
```powershell
python app.py path/to/your/image.jpg
```

### With Custom Prompt
```powershell
python app.py image.png --prompt "Describe the technical aspects of this diagram"
```

### With Specific Endpoint and Model
```powershell
python app.py photo.jpg --endpoint "https://your-project.region.inference.ai.azure.com" --model "gpt-4o"
```

### Using API Key Authentication (Development Only)
```powershell
python app.py image.jpg --use-api-key
```

### Verbose Logging
```powershell
python app.py image.jpg --verbose
```

## Command Line Options

- `image_path`: Path to the image file to analyze (required)
- `--endpoint`: Azure AI Foundry endpoint URL
- `--model`: Model name to use (default: gpt-4o)
- `--prompt`: Custom prompt for image analysis
- `--use-api-key`: Use API key authentication instead of managed identity
- `--verbose`: Enable verbose logging

## Authentication

### Managed Identity (Recommended for Production)
The application uses Azure managed identity by default, which is the most secure approach for Azure-hosted applications.

### API Key (Development Only)
For local development, you can use an API key by setting `AZURE_AI_API_KEY` in your `.env` file and using the `--use-api-key` flag.

## Supported Image Formats

- JPEG (.jpg, .jpeg)
- PNG (.png)
- BMP (.bmp)
- GIF (.gif)
- TIFF (.tiff, .tif)

## Error Handling

The application includes comprehensive error handling for:
- Missing or invalid image files
- Network connectivity issues
- Authentication failures
- API rate limits (with automatic retry)
- Invalid model responses

## Examples

```powershell
# Basic image analysis
python app.py vacation_photo.jpg

# Technical diagram analysis
python app.py architecture_diagram.png --prompt "Explain the system architecture shown in this diagram"

# Medical image analysis
python app.py xray.jpg --prompt "Describe what you see in this medical image"

# Art analysis
python app.py painting.jpg --prompt "Analyze the artistic style, composition, and color palette"
```
