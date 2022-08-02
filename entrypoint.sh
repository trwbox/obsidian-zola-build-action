#!/bin/bash
set -o pipefail

# For backwards compatibility
if [[ -n "$TOKEN" ]]; then
    GITHUB_TOKEN=$TOKEN
fi

if [[ -z "$ZOLA_VERSION" ]]; then
    ZOLA_VERSION="v1.3.1"
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
    git config --global url."$GITHUB_SERVER_URL/".insteadOf "git@${GITHUB_HOSTNAME}":
    if [[ "$BUILD_THEMES" ]]; then
        echo "Fetching themes"
        git submodule update --init --recursive
    fi
    
    # Printing out the zola version
    version=$(zola --version)
    echo "Version: $version"
    
    # Set the remote repo
    remote_repo="https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@${GITHUB_HOSTNAME}/${TARGET_REPOSITORY}.git"
    remote_branch=$PAGES_BRANCH
    
    # Making the needed directories
    echo "Making public directory"
    mkdir public
    echo "Making __obsidian directory"
    mkdir __obsidian
    # This will throw a subdirectory error, that is okay
    mv * __obsidian
    echo "If there is a subdirectory error that is fine"
    
    # If there is a ZOLA_REPO enviroment variable specified by the user clone that
    if [[ -n "$ZOLA_REPO" ]]; then 
        echo "Cloning from the user specified obsidian-zola repo"
	echo "Cloning: $ZOLA_REPO"
        git clone $ZOLA_REPO __site
    else
        # Clone the main repo at a specific version
        echo "Using obsidian-zola version: v1.3.1"
        git clone https://github.com/ppeetteerrs/obsidian-zola.git --branch $ZOLA_VERSION __site
    fi 

    # Move the netlify.toml into that directory
    if [ ! -f __obsidian/netlify.toml ]; then
    	echo "No netlify.toml. Exiting"
	exit 1
    fi
    echo "Found netlify.toml"
    
    export VAULT="../__obsidian"
    echo "Vault path: $VAULT"
    
    # Getting the enviroment variables, and setting them
    echo "Getting and setting enviroment variables"
    cd __site
    python env.py
    source env.sh && rm env.sh
    cd ..
    
    # Do the things from run.sh
    echo "Moving zola to build"
    rsync -a __site/zola/ __site/build
    echo "Moving content to content"
    rsync -a __site/content/ __site/build/content   
    mkdir -p __site/build/content/docs __site/build/__docs
    
    # Use obsidian-export
    if [ -z "$STRICT_LINE_BREAKS" ]; then
	    __site/bin/obsidian-export --frontmatter=never --hard-linebreaks --no-recursive-embeds __obsidian __site/build/__docs
    else
	    __site/bin/obsidian-export --frontmatter=never --no-recursive-embeds __obsidian __site/build/__docs
    fi
    
    # Run the conversion script
    python __site/convert.py
    
    # Build the site
    zola --root __site/build build --output-dir public

    # If there was a CNAME file for a custom subdomain, copy it
    if [ -f __obsidian/CNAME ]; then
        echo "Found a CNAME record copying"
	cp  __obsidian/CNAME public/
    fi

    # If set to build only as a non-deployment test stop, otherwise push to gh-pages branch
    if ${BUILD_ONLY}; then
        echo "Build complete. Deployment skipped by request"
        exit 0
    else
        echo "Pushing artifacts to ${TARGET_REPOSITORY}:$remote_branch"

	echo "Going into build directory"
        cd public
        git init
        git branch -m main
        git config user.name "GitHub Actions"
        git config user.email "github-actions-bot@users.noreply.${GITHUB_HOSTNAME}"
        git add .

        git commit -m "Deploy ${TARGET_REPOSITORY} to ${TARGET_REPOSITORY}:$remote_branch"
        git push --force "${remote_repo}" main:${remote_branch}

        echo "Deploy complete"
    fi
}

main "$@"
