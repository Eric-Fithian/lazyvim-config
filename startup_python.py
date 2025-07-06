# ~/.config/nvim/scripts/python-repl/startup_python.py
"""
Standard Python REPL startup script for LazyVim integration
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


def setup_python_repl(venv_name="system"):
    """Set up standard Python REPL with enhanced features"""

    print("🚀 Python REPL Ready!")
    print(f"🐍 Environment: {venv_name}")
    print("📍 Python:", sys.executable)
    print("💡 Tip: Install IPython for enhanced features!")
    print("   pip install ipython")
    print()

    # Set up enhanced plotting
    common_utils.setup_enhanced_plotting()

    # Set up better exception handling
    import traceback

    def better_excepthook(exc_type, exc_value, exc_traceback):
        """Enhanced exception display"""
        print("🚨 Exception occurred:")
        traceback.print_exception(exc_type, exc_value, exc_traceback)

    sys.excepthook = better_excepthook

    # Import commonly used libraries if available
    # try:
    #     import numpy as np
    #     import pandas as pd
    #     print("📊 Imported: numpy as np, pandas as pd")
    # except ImportError:
    #     print("💡 Tip: pip install numpy pandas for data science")

    print()
    print("🎯 Useful Python tricks:")
    print("   help(object)       - Get help")
    print("   dir(object)        - List attributes")
    print("   vars()             - Show local variables")
    print("   import pdb; pdb.set_trace()  - Debug breakpoint")
    print()

    print("✨ Ready for coding!")
    print()


if __name__ == "__main__":
    # Get venv name from command line argument if provided
    venv_name = sys.argv[1] if len(sys.argv) > 1 else "system"
    setup_python_repl(venv_name)
