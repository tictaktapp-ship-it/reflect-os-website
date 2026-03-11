# Reflect OS — Marketing Website

Static HTML/CSS site for [reflect-os.com](https://www.reflect-os.com).

## Stack

- Pure HTML + CSS (no build step required)
- Hosted on Cloudflare Pages
- DNS managed via Cloudflare

## File structure

```
/
├── index.html              # Home
├── product.html
├── how-it-works.html
├── pricing.html
├── security.html
├── about.html
├── use-cases.html
├── blog.html
├── contact.html
├── privacy.html
├── terms.html
├── cookies.html
├── use-cases/
│   ├── executives.html
│   └── investment-management.html
├── blog/
│   ├── why-good-decision-makers-keep-a-record.html
│   └── confidence-calibration-what-it-means-and-why-it-matters.html
├── src/styles/
│   └── global.css
└── public/
    ├── _redirects          # Cloudflare Pages URL rewrites
    ├── _headers            # Security + cache headers
    ├── robots.txt
    └── sitemap.xml
```

## Deployment

This site is deployed automatically via Cloudflare Pages on every push to `main`.

**Live URL:** https://www.reflect-os.com

## Adding a new page

1. Create `new-page.html` in the root (or a subdirectory)
2. Copy nav + footer from an existing page
3. Add the URL to `public/sitemap.xml`
4. Add a clean URL rewrite to `public/_redirects` if needed
5. Commit and push — Cloudflare Pages deploys automatically

## Adding a blog post

1. Create `blog/your-slug.html`
2. Add it to `blog.html` (the hub)
3. Add to `public/sitemap.xml`
4. Commit and push
