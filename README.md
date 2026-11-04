# Gifhari portfolio - cloud editing source

This package contains the published static website source, assets and resume. No Git history, source credentials or local private documents are included.

## Edit from another computer

Source repository: https://github.com/heryndra86/portofolio-ds

Browser editor: https://github.dev/heryndra86/portofolio-ds

Open the repository on any computer and press the period key to open github.dev. Edit files and commit your changes so they are saved to GitHub, rather than only your browser storage.

For a running preview, open the repository in GitHub Codespaces and run:

```sh
python3 -m http.server 8000 --directory dist
```

Open the forwarded port 8000 preview. Stop unused Codespaces when finished; usage is subject to GitHub's account quota and billing settings.

## Where to edit

- Home: dist/index.html
- Project collection: dist/work.html
- About, experience and education: dist/about.html
- Skills and certifications: dist/expertise.html
- Reflection: dist/journey.html
- Contact: dist/contact.html
- Case studies: dist/*-case-study.html
- Latest shared layout additions: dist/assets/audit-improvements.css
- Shared typography and mobile rules: dist/assets/editorial-system.css
- Resume: dist/assets/Gifhari-Heryndra-Resume.pdf

Keep local image paths relative to each HTML page. Preserve the in-progress status on unearned certifications. Never put secrets or access tokens in the repository.

## Publishing

Public website: https://heryndra86.github.io/portofolio-ds/

Every push to `main` runs `.github/workflows/pages.yml`: installs the locked dependencies, rebuilds the project lab, checks the site, and publishes only `dist/` to GitHub Pages. Check the repository's Actions tab for deployment status. Failed checks prevent publication. No personal deployment token is required.

GitHub Pages must use **Settings > Pages > Source > GitHub Actions**. Keep asset and navigation paths relative so the project works under `/portofolio-ds/`.

The original chatgpt.site deployment remains separate; GitHub commits update the GitHub Pages website automatically, not that original host. Its existing Sites identity is preserved in `.openai/hosting.json`.

## Cloud preview

Open the repository, choose Code > Codespaces > Create codespace. The dev-container starts a port-8000 preview. Open it from the Ports panel. Commit and push your work before switching computers. This does not deploy to the existing live site.

## Check edits

Run `python3 scripts/check_site.py` before publishing. No package installation is required.

## Featured project lab

The home and Work pages share a progressive Three.js project lab. The rest of the site remains buildless HTML. Three.js and GSAP are loaded only when a desktop scene is needed; mobile and reduced-motion visitors get a still preview with the same data controls and case-study links. Mobile visitors can explicitly enable 3D.

To change the lab implementation:

```sh
npm ci
npm run build
npm run check
npm run preview
```

Edit `src/lab/controller.js` for controls, `src/lab/scene.js` for geometry/camera/lighting, `src/lab/data.js` for the explicitly illustrative input formula, and `dist/assets/featured-lab.css` for layout. Commit both source and generated `dist/assets/lab/` files. The build regenerates the emissions preview from the unchanged saved source extract and bundles the scene locally; no CDN runtime imports are used.

Actual CogniCompass captures and their provenance are in `dist/assets/lab/`. Wine model errors are saved evaluation results; slider outputs are separately labelled illustrative and must never be described as actual model inference without a verified implementation or endpoint.
