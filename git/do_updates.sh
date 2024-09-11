#!/bin/zsh

# Set the date string once at the beginning of the script
date_str=$(date +%Y%m%d%H%M)

# Function to parse the input data
parse_input() {
    local input_file=$1
    local repo=""
    local updates=""

    while IFS= read -r line; do
        if [[ -z "$line" ]]; then
            if [[ -n "$repo" ]]; then
                create_pr "$repo" "$updates"
                repo=""
                updates=""
            fi
        elif [[ $line =~ ^- ]]; then
            repo=$(echo $line | sed 's/- repo: //')
            echo "********************************************************************************************************"
            echo "Processing repository: $repo"
            echo "********************************************************************************************************"
            process_repo "$repo"
        elif [[ $line =~ ^[[:space:]]+- ]]; then
            name=$(echo $line | sed 's/.*name: \([^,]*\),.*/\1/')
            current_version=$(echo $line | sed 's/.*current version: \([^,]*\),.*/\1/')
            latest_version=$(echo $line | sed 's/.*latest: \([^,]*\)/\1/')
            update_dependency "$repo" "$name" "$latest_version"
            updates="${updates}\n- Updated $name from $current_version to $latest_version"
        fi
    done < "$input_file"

    # Create PR for the last repository if any
    if [[ -n "$repo" ]]; then
        create_pr "$repo" "$updates"
    fi
}

# Function to process each repository
process_repo() {
    local repo=$1
    local branch_name="agilbert/nojira-major-update-$date_str"

    if [[ ! -d "$repo_dir" ]]; then
        echo "Error: Repository directory '$repo_dir' does not exist."
        return
    fi

    cd "$repo_dir" || return

    # Ensure there are no pending local changes
    if [[ -n $(git status --porcelain) ]]; then
        echo "Error: Repository '$repo' has pending local changes."
        cd - || return
        return
    fi

    # Checkout the master to refresh
    git fetch origin
    git checkout master
    git reset --hard origin/master
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to checkout master branch in repository '$repo'."
        exit 1
    fi

    git pull origin master
    # Checkout the branch
    git checkout -b "$branch_name"
    if [[ $? -ne 0 ]]; then
        echo "Error: Failed to checkout branch $branch_name"
        exit 1
    fi

    cd - || return
}

# Function to update dependencies in pom.xml
update_dependency() {
    local repo=$1
    local name=$2
    local latest_version=$3
    local repo_dir="$HOME/git/$repo"
    local pom_file="$repo_dir/pom.xml"

    if [[ ! -f "$pom_file" ]]; then
        echo "Error: pom.xml file not found in repository '$repo'."
        return
    fi

    cd "$repo_dir" || return

    # Update the dependency version in pom.xml
    sed -i '' "s/<$name.version>.*<\/$name.version>/<$name.version>$latest_version<\/$name.version>/" "$pom_file"
    git add "$pom_file"
    git commit -m "Update $name to version $latest_version"

    cd - || return
}

# Function to create a pull request
create_pr() {
    local repo=$1
    local updates=$2
    local repo_dir="$HOME/git/$repo"
    local branch_name="agilbert/nojira-major-update-$date_str"

    cd "$repo_dir" || return

    # Push the branch to the remote repository
    git push origin "$branch_name"

    # Create the pull request
    pr_url=$(gh pr create --title "[NOJIRA] Major dependency updates" --body "$(echo -e "$updates")")
    pr_urls+=("$pr_url")

    echo -n ""

    cd - || return
}

# Main script execution
input_file="input.txt"  # Replace with the path to your input file
pr_urls=()

# Check if the input file exists
if [[ ! -f "$input_file" ]]; then
    echo "Error: Input file '$input_file' does not exist."
    exit 1
fi

set -xe

parse_input "$input_file"

# Output the list of PRs that were created
if [[ "${#pr_urls[@]}" -gt 0 ]]; then
    echo "Pull requests created:"
    for pr_url in "${pr_urls[@]}"; do
        echo "$pr_url"
    done
else
    echo "No pull requests were created."
fi
