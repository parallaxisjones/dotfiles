function cleanup-tags() {
    git ls-remote --tags github | awk '/test/{print $2}' | cut -d/ -f3 | xargs git push --delete github
}
