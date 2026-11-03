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

Saving a GitHub commit does not automatically publish to the existing chatgpt.site URL. This export includes the existing Sites project identity in .openai/hosting.json, but it does not configure a deployment integration or change the current host. A separate publishing workflow must be selected and connected before cloud edits automatically reach production.

The original live portfolio remains at:
https://data-science-portfolio-gifhari-2026.gifhari2000.chatgpt.site/

## Cloud preview

Open the repository, choose Code > Codespaces > Create codespace. The dev-container starts a port-8000 preview. Open it from the Ports panel. Commit and push your work before switching computers. This does not deploy to the existing live site.

## Check edits

Run `python3 scripts/check_site.py` before publishing. No package installation is required.
