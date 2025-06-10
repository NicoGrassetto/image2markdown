# Image Analysis CLI with Azure AI Foundry (Managed Identity)

A command-line tool that uses Azure AI Foundry's multimodal models to analyze images and provide detailed descriptions. **Now secured with managed identity authentication** for enhanced security.

## 🔐 Security Features

- **Managed Identity Authentication**: No API keys stored or transmitted
- **Azure AD Integration**: Secure token-based authentication
- **RBAC Support**: Fine-grained access control using Azure roles
- **Zero Secret Management**: No credentials in code or configuration files

## Features

- Analyzes images using GPT-4o or other multimodal models
- Supports various image formats (JPEG, PNG, etc.)  
- Custom prompts for specific analysis needs
- **Secure managed identity authentication** (recommended for production)
- Fallback to interactive browser authentication for development
- Comprehensive error handling and retry logic
- Connection testing capabilities

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

3. **Configure Azure OpenAI with Managed Identity:**
   - Copy `.env.managed-identity` to `.env`
   - Set your Azure OpenAI endpoint URL
   - **No API key needed** - managed identity handles authentication

4. **Deploy Infrastructure (if not already deployed):**
   ```powershell
   azd up
   ```

5. **Assign RBAC Role** (if running locally):
   ```powershell
   # Get your user principal ID
   $userPrincipalId = az ad signed-in-user show --query id -o tsv
   
   # Assign Cognitive Services OpenAI User role
   az role assignment create `
     --role "Cognitive Services OpenAI User" `
     --assignee $userPrincipalId `
     --scope "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/YOUR_RESOURCE_GROUP/providers/Microsoft.CognitiveServices/accounts/YOUR_OPENAI_SERVICE"
   ```

## Usage

### Basic Usage
```powershell
python app.py path/to/your/image.jpg
```

### Test Connection
```powershell
python app.py --test-connection
```

### With Custom Prompt
```powershell
python app.py image.png --prompt "Describe the technical aspects of this diagram"
```

### With User-Assigned Managed Identity
```powershell
python app.py photo.jpg --client-id "your-managed-identity-client-id"
```

### With System Prompt
```powershell
python app.py image.jpg --system-prompt "You are a technical analyst" --prompt "Analyze this architecture"
```

### Streamlit Web Interface
```powershell
streamlit run streamlit_app.py
```

## Command Line Options

- `image_path`: Path to the image file to analyze (required)
- `--prompt`: Custom prompt for image analysis
- `--system-prompt`: Custom system prompt to guide AI behavior
- `--client-id`: Client ID for user-assigned managed identity (optional)
- `--test-connection`: Test the connection to Azure OpenAI service

## 🔐 Authentication

### Managed Identity (Recommended for Production)
The application uses Azure managed identity by default, which provides:
- **Secure**: No secrets stored in code or configuration
- **Automatic**: Token refresh handled automatically
- **Auditable**: All access logged through Azure AD
- **Scalable**: Works across all Azure services

### Authentication Methods (in order of precedence):
1. **User-Assigned Managed Identity** (if `--client-id` specified)
2. **System-Assigned Managed Identity** (in Azure environments)
3. **Azure CLI** (for local development)
4. **Interactive Browser** (fallback for local development)

### Local Development Setup:
```powershell
# Login to Azure CLI
az login

# Verify your identity
az account show

# Test the application
python app.py --test-connection
```

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

# Image Analysis with Azure OpenAI (Managed Identity Edition)

A secure, production-ready image analysis application using Azure OpenAI with **managed identity authentication**. This enhanced version eliminates the need for API keys and provides enterprise-grade security.

## 🚀 What's New in This Branch

This `feature/managed-identity-authentication` branch includes:

- **🔐 ChainedTokenCredential**: Intelligent fallback authentication (Managed Identity → Azure CLI)
- **🏢 Production Ready**: No API keys, secure for enterprise deployment
- **🔄 Smart Fallback**: Works in Azure (managed identity) and locally (Azure CLI)
- **📊 Enhanced Logging**: Detailed authentication flow visibility
- **🛡️ Azure Best Practices**: Follows Microsoft recommended security patterns
- **⚡ Zero Configuration**: Automatic credential discovery and token refresh

## 🏗️ Architecture

```
Local Development:          Azure Production:
┌─────────────────┐         ┌─────────────────┐
│ Managed Identity│──❌──┐  │ Managed Identity│──✅──┐
│ (Not Available) │       │  │ (Available)     │      │
└─────────────────┘       │  └─────────────────┘      │
                          │                           │
┌─────────────────┐       │  ┌─────────────────┐      │
│ Azure CLI       │──✅──┘  │ Azure CLI       │──⏸️──┘
│ (Fallback)      │          │ (Not Needed)    │
└─────────────────┘          └─────────────────┘
```
