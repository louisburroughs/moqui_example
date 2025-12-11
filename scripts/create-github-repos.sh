#!/bin/bash
# Create GitHub repositories for all Durion components

GITHUB_ORG="louisburroughs"
COMPONENT_BASE="runtime/component"

# Component descriptions
declare -A DESCRIPTIONS=(
    ["durion-common"]="Shared entities, services, and utilities for Durion ERP"
    ["durion-crm"]="Customer Relationship Management component for Durion ERP"
    ["durion-product"]="Product Catalog and Management component for Durion ERP"
    ["durion-inventory"]="Inventory Management component for Durion ERP"
    ["durion-accounting"]="Financial Management and Accounting component for Durion ERP"
    ["durion-workexec"]="Work Execution and Scheduling component for Durion ERP"
    ["durion-experience"]="Customer Experience and Portal component for Durion ERP"
    ["durion-positivity"]="External System Integrations component for Durion ERP"
    ["durion-demo-data"]="Demo and Sample Data component for Durion ERP"
)

echo "Creating GitHub repositories for Durion components..."
echo ""

success_count=0
skip_count=0
fail_count=0

for component_dir in "$COMPONENT_BASE"/durion-*; do
    component_name=$(basename "$component_dir")
    description="${DESCRIPTIONS[$component_name]}"
    
    echo "Processing: $component_name"
    
    # Check if repository already exists
    if gh repo view "$GITHUB_ORG/$component_name" &> /dev/null; then
        echo "  ✓ Already exists, skipping"
        ((skip_count++))
        continue
    fi
    
    # Check if git repo exists
    if [[ ! -d "$component_dir/.git" ]]; then
        echo "  ⚠ No git repository found, initializing..."
        cd "$component_dir"
        git init
        git add .
        git commit -m "Initial commit: $component_name component structure"
        cd - > /dev/null
    fi
    
    # Create repository
    cd "$component_dir"
    if gh repo create "$GITHUB_ORG/$component_name" \
        --public \
        --description "$description" \
        --source=. \
        --remote=origin 2>&1; then
        
        # Push code
        if git push -u origin main 2>&1 | grep -q "To https"; then
            echo "  ✓ Created and pushed"
            ((success_count++))
        else
            echo "  ⚠ Created but push may have issues"
            ((success_count++))
        fi
    else
        echo "  ✗ Failed to create"
        ((fail_count++))
    fi
    cd - > /dev/null
    echo ""
done

echo "════════════════════════════════════════════════════════════════════"
echo "Summary:"
echo "  ✓ Created:  $success_count"
echo "  ⊘ Skipped:  $skip_count"
echo "  ✗ Failed:   $fail_count"
echo "════════════════════════════════════════════════════════════════════"
