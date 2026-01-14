#!/bin/bash
# Claude Code Configuration Installer
# Usage: ./apply-config.sh <domain> <target-project-path>
# Usage: ./apply-config.sh --list

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Show usage
usage() {
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Claude Code Configuration Installer                      ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Usage:"
    echo "  $0 <domain> <target-path>    Apply configuration to project"
    echo "  $0 --list                    List available configurations"
    echo "  $0 --help                    Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 tfx /path/to/ml-project"
    echo "  $0 kubernetes ~/my-k8s-project"
    echo "  $0 helm ."
    echo ""
}

# List available domains
list_domains() {
    echo -e "${BLUE}Available configurations:${NC}"
    echo ""
    for dir in "$SCRIPT_DIR"/*/; do
        if [ -f "$dir/CLAUDE.md" ]; then
            domain=$(basename "$dir")
            desc=""
            # Try to extract description from first line of CLAUDE.md
            if [ -f "$dir/CLAUDE.md" ]; then
                desc=$(head -1 "$dir/CLAUDE.md" | sed 's/^# //')
            fi
            echo -e "  ${GREEN}$domain${NC}"
            [ -n "$desc" ] && echo "    $desc"

            # Count commands
            cmd_count=0
            if [ -d "$dir/.claude/commands" ]; then
                cmd_count=$(find "$dir/.claude/commands" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
            fi
            echo "    Commands: $cmd_count"
            echo ""
        fi
    done
}

# Prompt for action on existing file
prompt_action() {
    local file="$1"
    echo -e "${YELLOW}File exists: $file${NC}"
    read -p "  [o]verwrite / [s]kip / [b]ackup+overwrite? " -n 1 -r
    echo
    echo "$REPLY"
}

# Copy file with conflict handling
copy_file() {
    local src="$1"
    local dst="$2"

    if [ -f "$dst" ]; then
        action=$(prompt_action "$dst")
        case $action in
            [Oo])
                cp "$src" "$dst"
                echo -e "${GREEN}  ✓ Overwritten: $dst${NC}"
                ;;
            [Bb])
                cp "$dst" "$dst.backup"
                cp "$src" "$dst"
                echo -e "${GREEN}  ✓ Backed up and overwritten: $dst${NC}"
                ;;
            *)
                echo -e "${YELLOW}  - Skipped: $dst${NC}"
                ;;
        esac
    else
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
        echo -e "${GREEN}  ✓ Created: $dst${NC}"
    fi
}

# Main installation
install_config() {
    local domain="$1"
    local target="$2"
    local domain_dir="$SCRIPT_DIR/$domain"

    # Validate domain exists
    if [ ! -d "$domain_dir" ] || [ ! -f "$domain_dir/CLAUDE.md" ]; then
        echo -e "${RED}Error: Configuration '$domain' not found.${NC}"
        echo ""
        list_domains
        exit 1
    fi

    # Validate target directory
    if [ ! -d "$target" ]; then
        echo -e "${RED}Error: Target directory does not exist: $target${NC}"
        exit 1
    fi

    target="$(cd "$target" && pwd)"

    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   Installing: $domain ${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Source:${NC} $domain_dir"
    echo -e "${BLUE}Target:${NC} $target"
    echo ""

    # Copy CLAUDE.md
    echo -e "${BLUE}Installing CLAUDE.md...${NC}"
    copy_file "$domain_dir/CLAUDE.md" "$target/CLAUDE.md"

    # Copy .mcp.json (MCP server configuration)
    if [ -f "$domain_dir/.mcp.json" ]; then
        echo ""
        echo -e "${BLUE}Installing .mcp.json (MCP servers)...${NC}"
        copy_file "$domain_dir/.mcp.json" "$target/.mcp.json"
    fi

    # Copy .claude directory
    if [ -d "$domain_dir/.claude" ]; then
        echo ""
        echo -e "${BLUE}Installing .claude/ configuration...${NC}"

        # Settings
        if [ -f "$domain_dir/.claude/settings.json" ]; then
            copy_file "$domain_dir/.claude/settings.json" "$target/.claude/settings.json"
        fi

        # Commands
        if [ -d "$domain_dir/.claude/commands" ]; then
            echo ""
            echo -e "${BLUE}Installing commands...${NC}"
            mkdir -p "$target/.claude/commands"
            for cmd in "$domain_dir/.claude/commands/"*.md; do
                [ -f "$cmd" ] || continue
                cmd_name=$(basename "$cmd")
                copy_file "$cmd" "$target/.claude/commands/$cmd_name"
            done
        fi

        # Skills (if exist)
        if [ -d "$domain_dir/.claude/skills" ]; then
            echo ""
            echo -e "${BLUE}Installing skills...${NC}"
            for skill_dir in "$domain_dir/.claude/skills/"*/; do
                [ -d "$skill_dir" ] || continue
                skill_name=$(basename "$skill_dir")
                mkdir -p "$target/.claude/skills/$skill_name"
                for skill_file in "$skill_dir"*; do
                    [ -f "$skill_file" ] || continue
                    copy_file "$skill_file" "$target/.claude/skills/$skill_name/$(basename "$skill_file")"
                done
            done
        fi
    fi

    # Summary
    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Installation complete!${NC}"
    echo ""
    echo "Installed:"
    echo "  - CLAUDE.md"
    [ -f "$target/.mcp.json" ] && echo "  - .mcp.json (MCP servers)"
    [ -f "$target/.claude/settings.json" ] && echo "  - .claude/settings.json"
    if [ -d "$target/.claude/commands" ]; then
        cmd_count=$(find "$target/.claude/commands" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
        echo "  - .claude/commands/ ($cmd_count commands)"
    fi
    if [ -d "$target/.claude/skills" ]; then
        skill_count=$(find "$target/.claude/skills" -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
        skill_count=$((skill_count - 1))
        [ $skill_count -gt 0 ] && echo "  - .claude/skills/ ($skill_count skills)"
    fi
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. cd $target"
    echo "  2. Review CLAUDE.md and customize for your project"
    echo "  3. Open Claude Code and try the available commands"
    echo ""
}

# Parse arguments
case "${1:-}" in
    --list|-l)
        list_domains
        ;;
    --help|-h|"")
        usage
        ;;
    *)
        if [ -z "${2:-}" ]; then
            echo -e "${RED}Error: Target path required${NC}"
            echo ""
            usage
            exit 1
        fi
        install_config "$1" "$2"
        ;;
esac
