import subprocess
import platform
import sys

from build import flat

python = "python3"

if platform.system() == "Windows":
    python = "python"


subprocess.run(
    flat([
            [python, "build.py"],
            sys.argv[1:],
        ])
)

try:
    subprocess.run([python, "-m", "http.server", "-d", "website/"])
except KeyboardInterrupt:
    pass
