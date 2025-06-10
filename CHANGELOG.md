# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased] - feature/managed-identity-authentication

### Added
- **ChainedTokenCredential authentication** for intelligent fallback between managed identity and Azure CLI
- **User-assigned managed identity support** with configurable client ID
- **System-assigned managed identity support** for Azure environments
- **Azure CLI fallback authentication** for local development
- **Enhanced security practices** following Azure best practices
- **Comprehensive authentication logging** for troubleshooting
- **Production-ready configuration** with no hardcoded secrets
- **New test scripts** for verifying authentication chains
- **Updated .gitignore** to prevent committing sensitive files
- **Environment configuration examples** for different deployment scenarios

### Changed
- **Removed API key dependency** - now uses only Azure AD authentication
- **Updated requirements.txt** to include azure-identity package
- **Enhanced error handling** with better authentication failure messages
- **Improved logging** with detailed authentication flow information
- **Updated README.md** with managed identity setup instructions
- **Modified Streamlit app** to use new authentication method

### Security
- **Eliminated API key storage** - no secrets in code or configuration
- **Implemented Azure AD token-based authentication**
- **Added RBAC support** for fine-grained access control
- **Enhanced credential rotation** - automatic token refresh
- **Improved audit trail** - all access logged through Azure AD

### Fixed
- **Authentication fallback logic** - graceful handling when managed identity is unavailable
- **Token provider reliability** - robust error handling and retry logic
- **Cross-environment compatibility** - works in both Azure and local development

### Developer Experience
- **Simplified local development** - automatic Azure CLI integration
- **Enhanced debugging** - detailed authentication logs
- **Better error messages** - clear guidance for authentication issues
- **Multiple test scripts** - comprehensive verification tools

## [Previous] - main branch

### Features
- Basic image analysis using Azure OpenAI GPT-4o Vision
- Streamlit web interface
- Command-line interface
- Support for multiple image formats
- Custom prompt support
- API key-based authentication (deprecated in favor of managed identity)
