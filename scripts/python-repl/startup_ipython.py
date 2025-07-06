# ~/.config/nvim/scripts/python-repl/startup_ipython.py
"""
IPython REPL startup script for LazyVim integration
"""

import sys
import os
from datetime import datetime

# Import common utilities
import importlib.util

script_dir = os.path.dirname(os.path.abspath(__file__))
common_utils_path = os.path.join(script_dir, "common_utils.py")
spec = importlib.util.spec_from_file_location("common_utils", common_utils_path)
common_utils = importlib.util.module_from_spec(spec)
spec.loader.exec_module(common_utils)


def setup_ipython_repl(venv_name="system"):
    """Set up IPython REPL with enhanced features"""

    print("🚀 IPython REPL Ready!")
    print(f"🐍 Environment: {venv_name}")
    print("📍 Python:", sys.executable)
    print("✨ IPython version:", __import__("IPython").__version__)
    print()

    # Configure IPython for better experience
    from IPython import get_ipython

    ip = get_ipython()

    if ip:
        # Load useful extensions
        try:
            ip.run_line_magic("load_ext", "autoreload")
            ip.run_line_magic("autoreload", "2")
            print("🔄 Autoreload", "enabled")
        except Exception as e:
            print(f"⚠️  Autoreload setup failed: {e}")

        # Set up better exception handling
        ip.run_line_magic("pdb", "on")

        # Configure inline backend if available
        try:
            ip.run_line_magic("config", "InlineBackend.figure_format = 'retina'")
        except:
            pass

    # Set up enhanced plotting
    common_utils.setup_enhanced_plotting()
    common_utils.create_quick_plot_function()
    common_utils.load_common_imports()

    # Display helpful commands
    print()
    print("🎯 Useful IPython commands:")
    print("   %timeit <code>     - Time execution")
    print("   %run <file>        - Run Python file")
    print("   <object>?          - Get help")
    print("   <object>??         - View source")
    print("   %debug             - Debug last exception")
    print("   %who               - List variables")
    print("   %whos              - Detailed variable info")
    print("   %history           - Show command history")
    print("   %matplotlib inline - Inline plots")
    print("   %load_ext <ext>    - Load extension")
    print()

    # Import commonly used libraries
    # try:
    #     import numpy as np
    #     import pandas as pd
    #     print("📊 Imported: numpy as np, pandas as pd")
    # except ImportError:
    #     print("💡 Tip: pip install numpy pandas for data science")

    print("🔥 Ready for interactive coding!")
    print()


if __name__ == "__main__":
    # Get venv name from command line argument if provided
    venv_name = sys.argv[1] if len(sys.argv) > 1 else "system"
    setup_ipython_repl(venv_name)
