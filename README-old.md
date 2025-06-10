# Azure AI Image Analysis Demo

A secure, production-ready image analysis application using Azure OpenAI GPT-4o Vision with **managed identity authentication**. This application provides both a command-line interface and a web interface for analyzing images.

## 🔐 Security Features

- **Managed Identity Authentication**: No API keys stored or transmitted
- **Azure AD Integration**: Secure token-based authentication
- **ChainedTokenCredential**: Intelligent fallback authentication (Managed Identity → Azure CLI)
- **Zero Secret Management**: No credentials in code or configuration files

## ✨ Features

- **GPT-4o Vision Analysis**: Advanced image understanding and description
- **Multiple Interfaces**: Command-line and Streamlit web interface
- **Flexible Prompting**: Custom system and user prompts
- **Comprehensive Image Support**: JPEG, PNG, BMP, GIF, TIFF formats
- **Robust Error Handling**: Retry logic and graceful failure handling
- **Connection Testing**: Built-in connectivity verification

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

## 🚀 Quick Start

### Prerequisites

- Python 3.8+
- Azure CLI installed and logged in
- Azure OpenAI resource with GPT-4o deployment

### 1. Setup Environment

```powershell
# Clone or download the project
cd image-analysis-demo

# Create and activate virtual environment
python -m venv venv
.\venv\Scripts\Activate.ps1

# Install dependencies
pip install -r requirements.txt
```

### 2. Configure Azure Resources

#### Option A: Deploy Infrastructure (Recommended)
```powershell
# Deploy Azure resources using Azure Developer CLI
azd up
```

#### Option B: Manual Configuration
Create a `.env` file with your Azure OpenAI endpoint:
```
AZURE_OPENAI_ENDPOINT=https://your-openai-resource.openai.azure.com/
AZURE_OPENAI_DEPLOYMENT_NAME=gpt-4o
```

### 3. Configure Authentication

#### For Local Development:
```powershell
# Login to Azure CLI
az login

# Verify your identity
az account show

# Assign required role (if needed)
$userPrincipalId = az ad signed-in-user show --query id -o tsv
az role assignment create --role "Cognitive Services OpenAI User" --assignee $userPrincipalId --scope "/subscriptions/YOUR_SUBSCRIPTION_ID/resourceGroups/YOUR_RESOURCE_GROUP/providers/Microsoft.CognitiveServices/accounts/YOUR_OPENAI_SERVICE"
```

#### For Production (Azure):
- Enable managed identity on your Azure service (App Service, Container Apps, etc.)
- Assign "Cognitive Services OpenAI User" role to the managed identity

## 📖 Usage

### Command Line Interface

#### Basic Analysis
```powershell
python app.py path/to/your/image.jpg
```

#### Test Connection
```powershell
python app.py --test-connection dummy
```

#### Custom Prompts
```powershell
python app.py image.png --prompt "Describe the technical aspects of this diagram"
python app.py image.jpg --system-prompt "You are a technical analyst" --prompt "Analyze this architecture"
```

#### User-Assigned Managed Identity
```powershell
python app.py photo.jpg --client-id "your-managed-identity-client-id"
```

### Web Interface

```powershell
streamlit run streamlit_app.py
```

Then open your browser to `http://localhost:8501` to use the web interface.

## 🛠️ Command Line Options

| Option | Description |
|--------|-------------|
| `image_path` | Path to the image file to analyze (required for analysis) |
| `--prompt` | Custom prompt for image analysis |
| `--system-prompt` | Custom system prompt to guide AI behavior |
| `--client-id` | Client ID for user-assigned managed identity (optional) |
| `--test-connection` | Test the connection to Azure OpenAI service |

## 🔐 Authentication Flow

The application uses `ChainedTokenCredential` with the following priority:

1. **User-Assigned Managed Identity** (if `--client-id` specified)
2. **System-Assigned Managed Identity** (in Azure environments)
3. **Azure CLI** (for local development)

This ensures secure, keyless authentication in all scenarios.

## 📁 Project Structure

```
├── app.py                 # Command-line interface
├── streamlit_app.py       # Web interface
├── image_analyzer.py      # Core image analysis logic
├── requirements.txt       # Python dependencies
├── azure.yaml            # Azure Developer CLI configuration
├── README.md             # This file
└── infra/                # Infrastructure as Code
    ├── main.bicep        # Bicep template
    └── main.parameters.json
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `AZURE_OPENAI_ENDPOINT` | Azure OpenAI endpoint URL | Required |
| `AZURE_OPENAI_DEPLOYMENT_NAME` | Model deployment name | `gpt-4o` |
| `AZURE_CLIENT_ID` | User-assigned managed identity client ID | Optional |

### Supported Image Formats

- JPEG (.jpg, .jpeg)
- PNG (.png)
- BMP (.bmp)
- GIF (.gif)
- TIFF (.tiff, .tif)

## 🚨 Error Handling

The application includes comprehensive error handling for:

- Missing or invalid image files
- Network connectivity issues
- Authentication failures
- API rate limits (with automatic retry)
- Invalid model responses

## 📊 Examples

```powershell
# Basic image analysis
python app.py vacation_photo.jpg

# Technical diagram analysis
python app.py architecture_diagram.png --prompt "Explain the system architecture shown in this diagram"

# Medical image analysis (ensure compliance with your use case)
python app.py scan.jpg --prompt "Describe what you see in this medical image"

# Art analysis
python app.py painting.jpg --prompt "Analyze the artistic style, composition, and color palette"
```

## 🌐 Deployment

### Azure Container Apps (Recommended)

1. Build and deploy using Azure Developer CLI:
```powershell
azd up
```

2. Enable managed identity on the container app
3. Assign appropriate RBAC roles

### Azure App Service

1. Deploy the application to App Service
2. Enable managed identity
3. Configure environment variables
4. Assign RBAC roles

## 📝 License

This project is licensed under the MIT License.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📞 Support

For issues and questions:
- Check the error handling section above
- Ensure proper Azure CLI authentication
- Verify managed identity permissions
- Review Azure OpenAI service status
