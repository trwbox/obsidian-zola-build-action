# obsidian-zola github pages deploy action

This is a github actions script to build an obsidian-zola site, and push it to the gh-pages branch of a repo. This action can be added to a private github repo, with it pushing to a public branch for the website. 

# Steps to Use

1. Create a public Github repo with a copy of your notes, and a netlify.toml file just like regular usage
2. Create a gh-pages branch in the repo with or without contents
3. In the repo settings set Github Pages to use the gh-pages branch
4. Click the actions tab, then click new workflow, then click ```set up a workflow yourself```
5. Copy the contents of example.main.yml into the file and save it
6. This should automatically force a rebuild, and push to gh-pages, it if doesn't it can invoked with a new push

## Other Environment Variables that can be assigned

These are some other environment variables that can be set in the main.yml to allow for customization

```ZOLA_VERSION``` can be used to set a specific version, must be a string like ```v1.3.1```

```PAGES_BRANCH``` can be used if the branch being used for GitHub Pages is a non-standard branch

```ZOLA_REPO``` can be used to specify a custom repo for obsidian-zola. This needs to be a fully qualified domain name like ```https://github.com/trwbox/obsidian-zola.git```

## TODO

- [ ] Pull the domain of the site that is being published automatically, to not rely on user input
      - This might not be possible with Github given variables
- [X] Describe some of the other global variables that can be set
- [X] See if this can work by pulling from a private repo and only pushing the site to a public repo, so that if obsidian-zola allows for hidden pages that can be done like that
- [ ] Publish on github marketplace for easier use - Want to let the obsidian-zola repo to go through a few updates first to iron out any issues
- [ ] Speed improvements?
- [ ] Fix issues that arise in documentation or code
- [X] Don't just pull obsidian-zola straight, pull a versioned instead

## Currently there is a release that v0.1.1-testing which fixes path issues, but needs some changes in netlify.toml

Change BASE_PATH to have the base path without any /s
Change the SITE_URL to include the whole site including the path with a trailing /
