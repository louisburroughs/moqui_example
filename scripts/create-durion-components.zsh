#!/usr/bin/env zsh
# Durion Component Creation Automation Script
# Creates all required Durion components with proper structure

set -e  # Exit on error

# Configuration
GITHUB_ORG="louisburroughs"
PROJECT_ROOT="/home/n541342/IdeaProjects/moqui_example"
COMPONENT_BASE="$PROJECT_ROOT/runtime/component"
MYADDONS_FILE="$PROJECT_ROOT/myaddons.xml"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Component definitions (name:description:dependencies)
declare -A COMPONENTS=(
    ["durion-common"]="Shared entities, services, and utilities:framework,mantle-udm"
    ["durion-crm"]="Customer Relationship Management:durion-common"
    ["durion-product"]="Product Catalog and Management:durion-common,PopCommerce"
    ["durion-inventory"]="Inventory Management:durion-product,durion-common"
    ["durion-accounting"]="Financial Management:durion-common,mantle-udm,SimpleScreens"
    ["durion-workexec"]="Work Execution and Scheduling:durion-product,durion-inventory,durion-common,HiveMind"
    ["durion-experience"]="Customer Experience and Portal:durion-crm,durion-product,durion-accounting"
    ["durion-positivity"]="External System Integrations:durion-common"
    ["durion-demo-data"]="Demo and Sample Data:durion-common,durion-crm,durion-product,durion-inventory,durion-accounting"
)

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to create component directory structure
create_component_structure() {
    local component_name=$1
    local component_dir="$COMPONENT_BASE/$component_name"
    
    print_info "Creating directory structure for $component_name"
    
    mkdir -p "$component_dir"/{data,entity,screen,service,src/main/groovy,template,test}
    
    print_success "Directory structure created"
}

# Function to create component.xml
create_component_xml() {
    local component_name=$1
    local description=$2
    local dependencies=$3
    local component_dir="$COMPONENT_BASE/$component_name"
    
    print_info "Creating component.xml for $component_name"
    
    # Convert component name to title case for display
    local display_name=$(echo "$component_name" | sed 's/durion-/Durion /' | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1')
    
    cat > "$component_dir/component.xml" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<component xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
           xsi:noNamespaceSchemaLocation="http://moqui.org/xsd/moqui-conf-3.xsd"
           name="$component_name" version="1.0.0">
    <description>$display_name - $description</description>
EOF

    # Add dependencies if provided
    if [[ -n "$dependencies" ]]; then
        # Split by comma using zsh parameter expansion
        local -a DEPS=("${(@s:,:)dependencies}")
        for dep in "${DEPS[@]}"; do
            dep=$(echo "$dep" | xargs) # Trim whitespace
            echo "    <depends-on name=\"$dep\"/>" >> "$component_dir/component.xml"
        done
    fi
    
    cat >> "$component_dir/component.xml" << EOF
</component>
EOF
    
    print_success "component.xml created"
}

# Function to create README.md
create_readme() {
    local component_name=$1
    local description=$2
    local component_dir="$COMPONENT_BASE/$component_name"
    
    print_info "Creating README.md for $component_name"
    
    local display_name=$(echo "$component_name" | sed 's/durion-/Durion /' | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1')
    
    cat > "$component_dir/README.md" << EOF
# $display_name

$description

## Overview

This component is part of the Durion ERP system built on the Moqui Framework.

## Structure

- \`data/\` - Seed and demo data
- \`entity/\` - Entity definitions
- \`screen/\` - UI screens and forms
- \`service/\` - Service definitions
- \`src/\` - Groovy/Java source code
- \`template/\` - Email and document templates
- \`test/\` - Test specifications

## Dependencies

See \`component.xml\` for component dependencies.

## Installation

This component is managed via \`myaddons.xml\` in the Moqui project root.

## License

Same as Durion project.

---

**Last Updated:** $(date +"%B %d, %Y")
EOF
    
    print_success "README.md created"
}

# Function to create .gitignore
create_gitignore() {
    local component_name=$1
    local component_dir="$COMPONENT_BASE/$component_name"
    
    print_info "Creating .gitignore for $component_name"
    
    cat > "$component_dir/.gitignore" << 'EOF'
# Build artifacts
build/
*.class
*.jar

# IDE files
.idea/
*.iml
.vscode/
.settings/
.project
.classpath

# Logs
logs/
*.log

# OS files
.DS_Store
Thumbs.db

# Temporary files
*.tmp
*.bak
*~

# Runtime data (should not be in version control)
runtime/
EOF
    
    print_success ".gitignore created"
}

# Function to initialize git repository
init_git_repo() {
    local component_name=$1
    local component_dir="$COMPONENT_BASE/$component_name"
    
    print_info "Initializing git repository for $component_name"
    
    cd "$component_dir"
    
    if [[ -d .git ]]; then
        print_warning "Git repository already exists, skipping"
        return
    fi
    
    git init
    git add .
    git commit -m "Initial commit: $component_name component structure"
    
    print_success "Git repository initialized"
}

# Function to create GitHub repository
create_github_repo() {
    local component_name=$1
    local description=$2
    local component_dir="$COMPONENT_BASE/$component_name"
    
    print_info "Creating GitHub repository for $component_name"
    
    cd "$component_dir"
    
    # Check if gh CLI is available
    if ! command -v gh &> /dev/null; then
        print_error "GitHub CLI (gh) not found. Please install it: https://cli.github.com/"
        return 1
    fi
    
    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        print_error "GitHub CLI is not authenticated."
        print_error "Please run: gh auth login"
        print_error "When prompted, create a Personal Access Token with 'repo' and 'user:email' scopes"
        return 1
    fi
    
    # Check if repository already exists
    if gh repo view "$GITHUB_ORG/$component_name" &> /dev/null; then
        print_warning "GitHub repository $GITHUB_ORG/$component_name already exists, skipping"
        return
    fi
    
    # Create repository
    if ! gh repo create "$GITHUB_ORG/$component_name" \
        --public \
        --description "$description" \
        --source=. \
        --remote=origin 2>&1 | grep -q "GraphQL"; then
        
        # Push code
        git push -u origin main
        
        print_success "GitHub repository created and code pushed"
    else
        print_warning "GitHub repository creation failed (token may lack 'repo' scope)"
        print_warning "Run: gh auth refresh -s repo,user:email"
    fi
}

# Function to update myaddons.xml
update_myaddons() {
    local component_name=$1
    
    print_info "Updating myaddons.xml for $component_name"
    
    # Check if component already exists in myaddons.xml
    if grep -q "name=\"$component_name\"" "$MYADDONS_FILE"; then
        print_warning "Component $component_name already in myaddons.xml, skipping"
        return
    fi
    
    # Create backup
    cp "$MYADDONS_FILE" "${MYADDONS_FILE}.bak"
    
    # Add component before closing </addons> tag
    sed -i "/<\/addons>/i\\    <component name=\"$component_name\" group=\"$GITHUB_ORG\" version=\"1\" branch=\"main\"/>" "$MYADDONS_FILE"
    
    print_success "myaddons.xml updated"
}

# Main execution
main() {
    print_info "Starting Durion component creation automation"
    echo ""
    
    # Check prerequisites
    print_info "Checking prerequisites..."
    
    if [[ ! -d "$COMPONENT_BASE" ]]; then
        print_error "Component base directory not found: $COMPONENT_BASE"
        exit 1
    fi
    
    if [[ ! -f "$MYADDONS_FILE" ]]; then
        print_error "myaddons.xml not found: $MYADDONS_FILE"
        exit 1
    fi
    
    local SKIP_GITHUB=0
    if ! command -v gh &> /dev/null; then
        print_warning "GitHub CLI (gh) not found. GitHub repository creation will be skipped."
        print_warning "Install from: https://cli.github.com/"
        SKIP_GITHUB=1
    fi
    
    # Process each component
    local total=${#COMPONENTS[@]}
    local current=0
    
    print_info "Found $total components to process"
    echo ""
    
    for component_name in "${(@k)COMPONENTS}"; do
        ((current++)) || true
        echo ""
        print_info "Processing component $current/$total: $component_name"
        echo "----------------------------------------"
        
        # Parse component data
        local component_data="${COMPONENTS[$component_name]}"
        local description="${component_data%%:*}"
        local dependencies="${component_data#*:}"
        
        # Check if component already exists
        if [[ -d "$COMPONENT_BASE/$component_name" ]]; then
            print_warning "Component directory already exists: $component_name"
            read -q "REPLY?Recreate? (y/n) " || REPLY="n"
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_warning "Skipping $component_name"
                continue
            fi
            rm -rf "$COMPONENT_BASE/$component_name"
        fi
        
        # Create component
        create_component_structure "$component_name"
        create_component_xml "$component_name" "$description" "$dependencies"
        create_readme "$component_name" "$description"
        create_gitignore "$component_name"
        
        # Git initialization
        read -q "REPLY?Initialize git repository for $component_name? (y/n) " || REPLY="n"
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            init_git_repo "$component_name"
            
            # GitHub repository creation
            if [[ $SKIP_GITHUB -eq 0 ]]; then
                read -q "REPLY?Create GitHub repository for $component_name? (y/n) " || REPLY="n"
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    create_github_repo "$component_name" "$description"
                fi
            fi
        fi
        
        # Update myaddons.xml
        read -q "REPLY?Add $component_name to myaddons.xml? (y/n) " || REPLY="n"
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            update_myaddons "$component_name"
        fi
        
        print_success "Component $component_name completed"
    done
    
    echo ""
    print_success "All components processed!"
    echo ""
    print_info "Next steps:"
    echo "  1. Review created components in: $COMPONENT_BASE"
    echo "  2. Check myaddons.xml: $MYADDONS_FILE"
    echo "  3. Restart Moqui: ./gradlew cleanAll run"
    echo "  4. Verify components in Moqui Tools > Components"
}

# Parse command line arguments
case "${1:-}" in
    --help|-h)
        cat << EOF
Durion Component Creation Automation Script

Usage:
  $0 [options]

Options:
  --help, -h          Show this help message
  --dry-run           Show what would be created without actually creating
  --skip-git          Skip git initialization
  --skip-github       Skip GitHub repository creation
  --component NAME    Create only the specified component

Examples:
  $0                              # Create all components interactively
  $0 --component durion-crm       # Create only durion-crm
  $0 --skip-github                # Create components but skip GitHub repos

EOF
        exit 0
        ;;
    --component)
        SINGLE_COMPONENT="$2"
        if [[ -z "${COMPONENTS[$SINGLE_COMPONENT]}" ]]; then
            print_error "Unknown component: $SINGLE_COMPONENT"
            exit 1
        fi
        ;;
esac

# Run main
main
