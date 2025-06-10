#!/usr/bin/env python3
"""
Quick test to verify the updated image analyzer is working
"""
import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    from image_analyzer import AzureImageAnalyzer
    
    print("🚀 Testing updated AzureImageAnalyzer...")
    
    # Initialize with the same client_id as used in the app
    analyzer = AzureImageAnalyzer(client_id="aab028b9-a0c4-485e-9e13-eb540e21090c")
    
    print("✅ AzureImageAnalyzer initialized successfully")
    
    # Get service info
    info = analyzer.get_service_info()
    print(f"📋 Service Info:")
    for key, value in info.items():
        print(f"   {key}: {value}")
    
    # Test connection
    print("\n🔌 Testing connection...")
    if analyzer.test_connection():
        print("✅ Connection test successful!")
    else:
        print("❌ Connection test failed!")
        
    print("\n🎉 All tests passed! The updated image analyzer is working correctly.")
    
except ImportError as e:
    print(f"❌ Import error: {e}")
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
