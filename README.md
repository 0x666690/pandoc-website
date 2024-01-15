# The code that powers my website

## Installation

Make sure that both `pandoc` and `imagemagick` are installed and reachable from your user's PATH.

If the commands `pandoc --help` or `magick convert`/`magick identify`/`convert`/`identify` don't work then the script will abort on its own.

## Usage

All markdown files are to be placed within the `markdown` folder. Their relative location directly corresponds to where they will end up in the final output folder.

All images are to be placed somewhere within the `markdown` folder. The same thing applies for their location.

Example: a photo placed in `/markdown/images/blog/article1/image1.jpg` will end up in `/website/images/blog/article1/image1.webp`.

All images will be converted to .webp by default to save space. Responsive images will be used, meaning that one source image will generate about a dozen images in the output folder for the browser to switch between depending on the size of the window.

The following behavior can be controlled via site metadata:

```
show_about: false
show_home: false
```

Can be used to hide the buttons in the footer.

And of course ...

```
shiba_inu_above_title: true
```


Alternative text for images (since that's not very well implemented in pandoc) can be specified as follows:

```markdown
![](/images/example_image.jpg){alternative_text="Photo showing something really interesting"}

```

Carousels can be embedded as follows:

```markdown
===carousel

![](/images/image1.jpg)

![](/images/image2.jpg)

![](/images/image3.jpg)

===carousel
```

## Build

Simply run `python build.py` to build the static web page to a folder called `website`.

If you want to try out the site locally using python's built-in web server, simply run `python build_and_run.py`.

Both scripts only take one optional parameter, `--rebuild`. By default the script will not convert images twice if it doesn't have to.
If you want to clean out the build folder and start fresh, this option lets you override that behaviour.

## Deployment

Since this website is just a bunch of static files within a folder we can deploy said static folder to the web using GitHub Pages:

```yaml
jobs:
  # Single deploy job since we're just deploying
  deploy:
    environment:
      name: github-pages
      url: ${{ steps.deployment.outputs.page_url }}
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v3
      - name: Setup Pages
        uses: actions/configure-pages@v3
      - name: Upload artifact
        uses: actions/upload-pages-artifact@v2
        with:
          # Upload only the relevant folder
          path: 'website/'
      - name: Deploy to GitHub Pages
        id: deployment
        uses: actions/deploy-pages@v2
```