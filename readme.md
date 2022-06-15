# obsidian-zola github pages deploy action

This is a github actions script to build an obsidian-zola site, and push it to the gh-pages branch of a repo.

# Steps to Use

1. Create a public Github repo with a copy of your notes, and a netlify.toml file just like regular
2. Create a gh-pages branch in the repo with or without contents
3. In the repo settings set Github Pages to use the gh-pages branch
4. Click the actions tab, then click new workflow, then click ```set up a workflow yourself```
5. Copy the contents of example.main.yml into the file and save it

# TODO

- [ ] Pull the domain of the site that is being published automatically, to not rely on user input
- [ ] Describe some of the other global variables that can be set
- [ ] See if this can work by pulling from a private repo and only pushing the site to a public repo, so that if obsidian-zola allows for hidden pages that can be done like that
- [ ] Publish on github marketplace for easier use
- [ ] Speed improvements?
- [ ] Fix issues that arise in documentation or code
- [ ] Don't just pull obsidian-zola straight, pull a versioned instead

## Currently there is a release thay v0.1.1-testing which fixes path issues, but needs some changes in netlify.toml
Change BASE_PATH to have the base path without any /s
Change the SITE_URL to include the whole site including the path with a trailing /
