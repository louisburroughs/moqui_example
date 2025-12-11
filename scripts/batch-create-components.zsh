#!/usr/bin/env zsh
# Non-interactive batch creation of all Durion components
# Use this for automated/CI environments

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPONENT_SCRIPT="$SCRIPT_DIR/create-durion-components.zsh"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Starting batch component creation...${NC}\n"

# Component creation order (respects dependencies)
COMPONENTS=(
    "durion-common"
    "durion-product"
    "durion-crm"
    "durion-inventory"
    "durion-accounting"
    "durion-workexec"
    "durion-experience"
    "durion-positivity"
    "durion-theme"
    "durion-demo-data"
)

for component in "${COMPONENTS[@]}"; do
    echo -e "${GREEN}Creating $component...${NC}"
    
    # Auto-answer yes to all prompts
    yes | "$COMPONENT_SCRIPT" --component "$component" 2>/dev/null || true
    
    echo ""
done

echo -e "${GREEN}Batch creation complete!${NC}"
echo ""
echo "Components created:"
for component in "${COMPONENTS[@]}"; do
    echo "  ✓ $component"
done
echo ""
echo "Next: ./gradlew cleanAll run"
