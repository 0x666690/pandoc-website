import subprocess
from pathlib import Path
import shutil
import os
import os.path
import glob
from itertools import chain
import sys

rebuild = "--rebuild" in sys.argv


def flat(matrix):
    """
    flattens a matrix, used here to flatten lists
    of commands that themselves contain lists
    """
    return list(chain.from_iterable(matrix))


if __name__ == "__main__":
    # check if pandoc is installed
    try:
        sp = subprocess.Popen(
            ["pandoc", "--help"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        sp.communicate()
    except FileNotFoundError:
        print("pandoc is not installed! Exiting...")
        exit()

    # check if imagemagick is installed
    magick_cmd = ["magick"]
    convert_cmd = ["magick", "convert"]
    identify_cmd = ["magick", "identify"]
    try:
        sp = subprocess.Popen(
            magick_cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        sp.communicate()
    except FileNotFoundError:
        try:
            magick_cmd = ["convert"]
            sp = subprocess.Popen(
                magick_cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE
            )
            sp.communicate()
            convert_cmd = ["convert"]
            identify_cmd = ["identify"]
        except FileNotFoundError:
            print("ImageMagick is not installed! Exiting...")
            exit()

    # find all the .md files
    files_for_pandoc = []

    for filename in glob.glob("markdown/**/*.md", recursive=True):
        if filename.startswith("markdown"):
            files_for_pandoc.append(
                [
                    filename,
                    "website"
                    + filename.removeprefix("markdown").removesuffix(".md")
                    + ".html",
                ]
            )

    # clean out the 'website' folder

    if rebuild:
        shutil.rmtree("website", ignore_errors=False)
        os.makedirs("website")

    for f in files_for_pandoc:
        p = Path(f[1])
        if not p.absolute().parents[0].exists():
            os.makedirs(p.absolute().parents[0], exist_ok=True)

    shutil.copytree(
        "styling",
        os.path.join("website", "styling"),
        dirs_exist_ok=True
        )

    images_for_magick = []

    # find all images, convert them to webp
    image_file_extensions = ["png", "jpg", "jpeg"]
    for ext in image_file_extensions:
        for i in glob.glob(f"markdown/**/*.{ext}", recursive=True):
            if i.startswith("markdown"):
                if "favicon" in i:
                    images_for_magick.append(
                        [i, os.path.join("website", "favicon.ico")]
                    )
                else:
                    images_for_magick.append([
                            i,
                            "website" + i.removeprefix("markdown").removesuffix(f".{ext}"),
                        ])

    for i in images_for_magick:
        p = Path(i[1])
        if not p.absolute().parents[0].exists():
            os.makedirs(p.absolute().parents[0], exist_ok=True)

    for i in images_for_magick:
        if i[1] == os.path.join("website", "favicon.ico"):
            # Re-create favicon only if such a file doesn't already exists
            # or a full rebuild is specified
            if rebuild or not os.path.isfile(os.path.join("website", "favicon.ico")):
                sp = subprocess.Popen(
                    flat([convert_cmd, [i[0], "-resize", "32x32", i[1]]])
                )
        else:
            sizes = [
                3840, 2560, 1920,
                1600, 1366, 1024,
                 768,  640,  480,
                 320,  240
                ]

            # Get width of image
            x = subprocess.Popen(
                flat([identify_cmd, ["-ping", "-format", "%w", i[0]]]),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            )
            w = int(x.communicate()[0].decode())

            for s in sizes:
                if w >= s:
                    if rebuild or not os.path.isfile(i[1] + f"-{s}w.webp"):
                        sp = subprocess.Popen(
                            flat([
                                    convert_cmd,
                                    [
                                        i[0],
                                        "-quality",
                                        "80",
                                        "-resize",
                                        f"{s}x",
                                        i[1] + f"-{s}w.webp",
                                    ],
                                ])
                        )

            if rebuild or not os.path.isfile(i[1] + ".webp"):
                sp = subprocess.Popen(
                    flat([
                            convert_cmd,
                            [
                                i[0],
                                "-quality",
                                "80",
                                i[1] + ".webp"
                            ]
                        ])
                )
        sp.communicate()

    for f in files_for_pandoc:
        sp = subprocess.Popen(
            [
                "pandoc",
                "--metadata-file",
                os.path.join("styling", "metadata.yml"),
                f[0],
                "-o",
                f[1],
                "--standalone",
                "--template",
                os.path.join("styling", "template.html"),
                "--css",
                # this is not an OS path, this is where the
                # browser is supposed to look for the CSS
                "/styling/main.css",
                "--css",
                "/styling/generated.css",
                "--lua-filter",
                os.path.join("styling", "filter.lua"),
            ]
        )
        sp.communicate()

    shutil.copytree(
        "styling",
        os.path.join("website", "styling"),
        dirs_exist_ok=True
        )
