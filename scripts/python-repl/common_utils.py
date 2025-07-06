# ~/.config/nvim/scripts/python-repl/common_utils.py
"""
Common utilities for Python REPL startup scripts
"""

import os
import sys
from datetime import datetime


def setup_enhanced_plotting():
    """Set up enhanced plotting with Kitty integration"""
    try:
        import matplotlib.pyplot as plt
        import matplotlib

        # Set backend based on environment
        if os.environ.get("KITTY_WINDOW_ID"):
            matplotlib.use("Agg")
        else:
            # Use default interactive backend on macOS
            if sys.platform == "darwin":
                matplotlib.use("MacOSX")
            else:
                matplotlib.use("TkAgg")

        # Enhanced show function
        original_show = plt.show

        def enhanced_show(*args, **kwargs):
            """Enhanced plot display with Kitty integration"""
            plt.tight_layout()
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            filename = f"plot_{timestamp}.png"

            if os.environ.get("KITTY_WINDOW_ID"):
                # Save and display in Kitty
                plt.savefig(
                    filename,
                    dpi=150,
                    bbox_inches="tight",
                    facecolor="white",
                    edgecolor="none",
                )
                print(f"💾 Plot saved: {filename}")

                try:
                    import subprocess

                    result = subprocess.run(
                        ["kitty", "+kitten", "icat", filename],
                        capture_output=True,
                        timeout=5,
                    )
                    if result.returncode != 0:
                        print(
                            f"⚠️  Failed to display image in Kitty: {result.stderr.decode()}"
                        )
                except (subprocess.TimeoutExpired, FileNotFoundError) as e:
                    print(f"⚠️  Kitty icat not available: {e}")

                plt.close()
            else:
                # Use default interactive display
                if hasattr(original_show, "__wrapped__"):
                    # If show is already wrapped, call the original
                    original_show.__wrapped__(*args, **kwargs)
                else:
                    original_show(*args, **kwargs)

        # Replace plt.show with enhanced version
        plt.show = enhanced_show

        # Set up better default style
        try:
            plt.style.use("default")
            plt.rcParams.update(
                {
                    "figure.figsize": (10, 6),
                    "figure.dpi": 100,
                    "savefig.dpi": 150,
                    "font.size": 11,
                    "axes.labelsize": 11,
                    "axes.titlesize": 12,
                    "xtick.labelsize": 10,
                    "ytick.labelsize": 10,
                    "legend.fontsize": 10,
                }
            )
        except:
            pass

        print("🎨 Enhanced plotting enabled")
        return True

    except ImportError:
        print("⚠️  Matplotlib not available")
        return False


def create_quick_plot_function():
    """Create a quick plotting function for data exploration"""
    try:
        import matplotlib.pyplot as plt
        import numpy as np

        def qplot(data, kind="line", **kwargs):
            """Quick plot function for data exploration

            Args:
                data: Array-like data to plot
                kind: Type of plot ('line', 'scatter', 'hist', 'bar')
                **kwargs: Additional matplotlib arguments
            """
            fig, ax = plt.subplots(figsize=(8, 5))

            if kind == "line":
                ax.plot(data, **kwargs)
            elif kind == "scatter":
                ax.scatter(range(len(data)), data, **kwargs)
            elif kind == "hist":
                ax.hist(data, **kwargs)
            elif kind == "bar":
                ax.bar(range(len(data)), data, **kwargs)
            else:
                ax.plot(data, **kwargs)

            plt.tight_layout()
            plt.show()

        # Make it available globally
        import builtins

        builtins.qplot = qplot
        print("📈 Quick plot function 'qplot()' available")

    except ImportError:
        pass


def setup_pandas_display():
    """Configure pandas for better display in terminal"""
    try:
        import pandas as pd

        # Set display options for better terminal output
        pd.set_option("display.max_columns", 20)
        pd.set_option("display.max_rows", 100)
        pd.set_option("display.width", 120)
        pd.set_option("display.precision", 3)
        pd.set_option("display.float_format", "{:.3f}".format)

        print("🐼 Pandas display options configured")
        return True

    except ImportError:
        return False


def load_common_imports():
    """Load commonly used imports into global namespace"""
    common_modules = {
        "os": "os",
        "sys": "sys",
        "json": "json",
        "datetime": "datetime",
        "pathlib": "Path",
        "collections": "defaultdict, Counter",
        "itertools": "itertools",
        "functools": "partial, reduce",
    }

    loaded = []
    for module, items in common_modules.items():
        try:
            exec(f"import {module}")
            loaded.append(module)
        except ImportError:
            pass

    if loaded:
        print(f"📦 Loaded common modules: {', '.join(loaded)}")


def print_system_info():
    """Print useful system information"""
    print("🖥️  System Info:")
    print(f"   Platform: {sys.platform}")
    print(f"   Python: {sys.version.split()[0]}")
    print(f"   Working dir: {os.getcwd()}")
    if "VIRTUAL_ENV" in os.environ:
        print(f"   Virtual env: {os.environ['VIRTUAL_ENV']}")
    print()
