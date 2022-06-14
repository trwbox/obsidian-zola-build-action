#!/bin/bash
set -o pipefail

# For backwards compatibility
if [[ -n "$TOKEN" ]]; then
    GITHUB_TOKEN=$TOKEN
fi

if [[ -z "$PAGES_BRANCH" ]]; then
    PAGES_BRANCH="gh-pages"
fi

if [[ -z "$BUILD_DIR" ]]; then
    BUILD_DIR="."
fi

if [[ -n "$REPOSITORY" ]]; then
    TARGET_REPOSITORY=$REPOSITORY
else
    if [[ -z "$GITHUB_REPOSITORY" ]]; then
        echo "Set the GITHUB_REPOSITORY env variable."
        exit 1
    fi
    TARGET_REPOSITORY=${GITHUB_REPOSITORY}
fi

if [[ -z "$BUILD_ONLY" ]]; then
    BUILD_ONLY=false
fi

if [[ -z "$BUILD_THEMES" ]]; then
    BUILD_THEMES=true
fi

if [[ -z "$CHECK_LINKS" ]]; then
    CHECK_LINKS=false
fi

if [[ -z "$GITHUB_TOKEN" ]] && [[ "$BUILD_ONLY" == false ]]; then
    echo "Set the GITHUB_TOKEN or TOKEN env variables."
    exit 1
fi

if [[ -z "$GITHUB_HOSTNAME" ]]; then
    GITHUB_HOSTNAME="github.com"
fi

main() {
    echo "Starting deploy..."

    git config --global url."https://".insteadOf git://
    ## $GITHUB_SERVER_URL is set as a default environment variable in all workflows, default is https://github.com
    git config --global url."$GITHUB_SERVER_URL/".insteadOf "git@${GITHUB_HOSTNAME}":
    if [[ "$BUILD_THEMES" ]]; then
        echo "Fetching themes"
        git submodule update --init --recursive
    fi

    version=$(zola --version)
    mkdir public
    echo "Version: $version"
    remote_repo="https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@${GITHUB_HOSTNAME}/${TARGET_REPOSITORY}.git"
    remote_branch=$PAGES_BRANCH

    echo "Making __obsidian directory"
    mkdir __obsidian
    # This will throw a subdirectory error, so temp turn off error checking
    mv * __obsidian
    
    # Pull out enviroment variables
    eval $(awk '/\[build.environment\]/{flag=1;next}/^\s*$/{flag=0} {if (flag && $1 != "#" && $1 != "") {printf("export %s=", $1)} if (flag && $1 != "#" && $1 != "") for(i=3;  i<=NF;  i++) if(i==NF) {printf("%s\n", $i)} else printf("%s ", $i)}' __obsidian/netlify.toml | sed 's/\r$//')
    
    # Clone the main repo
    git clone https://github.com/trwbox/obsidian-zola.git __site

    # Do  the things from run.sh
    echo "Moving zola to build"
    rsync -a __site/zola/ __site/build
    echo "Moving content to content"
    rsync -a __site/content/ __site/build/content   
    
    mkdir -p __site/build/content/docs __site/build/__docs
    if [ -z "$STRICT_LINE_BREAKS" ]; then
	    __site/bin/obsidian-export --frontmatter=never --hard-linebreaks --no-recursive-embeds __obsidian __site/build/__docs
    else
	    __site/bin/obsidian-export --frontmatter=never --no-recursive-embeds __obsidian __site/build/__docs
    fi    
    
    if [ ! -f __obsidian/netlify.toml ]; then
    	echo "No netlify.toml. Exiting"
	exit 1
    fi
    echo "Found netlify.toml"
    
    python __site/convert.py
    
    zola --root __site/build build --output-dir public

    if [ -f __obsidian/CNAME ]; then
        echo "Found a CNAME record copying"
	cp  __obsidian/CNAME public/
    fi

    if ${BUILD_ONLY}; then
        echo "Build complete. Deployment skipped by request"
        exit 0
    else
        echo "Pushing artifacts to ${TARGET_REPOSITORY}:$remote_branch"

	echo "Going into build branch?"
        cd public
        git init
        git branch -m main
        git config user.name "GitHub Actions"
        git config user.email "github-actions-bot@users.noreply.${GITHUB_HOSTNAME}"
        git add .

        git commit -m "Deploy ${TARGET_REPOSITORY} to ${TARGET_REPOSITORY}:$remote_branch"
        echo "Trying main instead of master"
        git push --force "${remote_repo}" main:${remote_branch}

        echo "Deploy complete"
    fi
}

main "$@"
