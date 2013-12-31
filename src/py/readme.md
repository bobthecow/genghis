# Genghis - Python

Python implementation of the backend of Genghis.

Current version expects the 4 asset files (style.css, script.js, error/index.html.mustache) to be next to the py packages.

Uses Flask as lightweight HTTPD.

Dependencies:

- Flask==0.10.1
- pymongo==2.5.2
- pystache==0.5.3

TODO:

- Cleanup to_json/as_json functions
- Review overuse of @property
- Merge into https://github.com/bobthecow/genghis/tree/feature/three-dot-oh-my

