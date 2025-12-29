#!/usr/bin/env bash
set -euo pipefail

ROOT="${LIBYACHAIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
export LIBYACHAIN_ROOT="$ROOT"

echo "========================================="
echo "🚀 Claude Multi-Agent Team Setup"
echo "========================================="
echo ""
echo "This will set up a file-based coordination system for"
echo "multiple Claude Code CLI instances to work together."
echo ""
echo "⚠️  IMPORTANT:"
echo "   - You need to manually open 3-4 terminal windows"
echo "   - Each terminal runs ONE Claude instance"
echo "   - They coordinate through shared JSON files"
echo "   - Much lighter than Codex team (4 processes vs 50+)"
echo ""

# Create coordination structure
python3 "$ROOT/scripts/claude_agent_prompts.py"

# Initialize coordination files
mkdir -p "$ROOT/coordination"/{completed,status,chat,prompts}

# Initialize empty files
echo '[]' > "$ROOT/coordination/work_queue.json"
echo '[]' > "$ROOT/coordination/active_tasks.json"
echo '[]' > "$ROOT/coordination/completed/index.json"

# Initialize objectives (Manager will populate these)
cat > "$ROOT/coordination/objectives.json" << 'EOF'
[
  {
    "id": "obj-001",
    "title": "Core Three-Currency System",
    "description": "Implement LYDD, LYDC, UCBL with mint/burn/convert",
    "status": "not_started",
    "progress_percent": 0,
    "assigned_tasks": [],
    "completed_tasks": []
  },
  {
    "id": "obj-002",
    "title": "Admin Dashboard MVP",
    "description": "Essential admin controls and monitoring",
    "status": "not_started",
    "progress_percent": 0,
    "assigned_tasks": [],
    "completed_tasks": []
  },
  {
    "id": "obj-003",
    "title": "Explorer & Faucet",
    "description": "Public-facing tools for testing",
    "status": "not_started",
    "progress_percent": 0,
    "assigned_tasks": [],
    "completed_tasks": []
  }
]
EOF

# Start dashboard server
echo ""
echo "📊 Starting dashboard server..."

# Simple Python HTTP server for dashboard
cd "$ROOT/scripts"
python3 -m http.server 8790 > /dev/null 2>&1 &
DASHBOARD_PID=$!
echo $DASHBOARD_PID > "$ROOT/.claude_dashboard.pid"

echo "✅ Dashboard running at: http://localhost:8790/claude_dashboard.html"
echo ""

# Show instructions
cat << 'INSTRUCTIONS'
========================================
📋 NEXT STEPS
========================================

1. OPEN 4 TERMINAL WINDOWS:

   Window 1 - Manager (M01):
   --------------------------
   cd ~/libyachain
   claude  # Opens interactive Claude

   Then paste this prompt:
   cat coordination/prompts/manager.md


   Window 2 - Developer 1 (D01):
   ------------------------------
   cd ~/libyachain
   claude

   Then paste:
   cat coordination/prompts/developer.md
   # Change {agent_id} to D01


   Window 3 - Developer 2 (D02):
   ------------------------------
   cd ~/libyachain
   claude

   Then paste:
   cat coordination/prompts/developer.md
   # Change {agent_id} to D02


   Window 4 - Reviewer (R01):
   ---------------------------
   cd ~/libyachain
   claude

   Then paste:
   cat coordination/prompts/reviewer.md


2. OPEN DASHBOARD:

   http://localhost:8790/claude_dashboard.html

   - See team status
   - Monitor objectives
   - Watch active tasks
   - Chat with Manager


3. HOW IT WORKS:

   - Manager creates tasks in coordination/work_queue.json
   - Developers pick up tasks from queue
   - Reviewer validates completed work
   - All coordinate through JSON files
   - Dashboard shows everything in real-time


4. RESOURCE USAGE:

   ✅ 4 Claude processes (vs 50+ with Codex)
   ✅ File-based (no network overhead)
   ✅ Lightweight dashboard
   ✅ Should handle easily on 16GB RAM


5. TO STOP:

   - Close each Claude terminal (Ctrl+C)
   - Stop dashboard: kill $(cat .claude_dashboard.pid)


========================================
🎯 THE MANAGER WILL START BY:
========================================

1. Reading docs/OBJECTIVES.md
2. Assessing current codebase
3. Creating specific tasks
4. Coordinating team work

Just let each agent run their workflow loop!

INSTRUCTIONS

echo ""
echo "Press Enter to continue..."
read

# Open dashboard in browser
open "http://localhost:8790/claude_dashboard.html" 2>/dev/null || \
xdg-open "http://localhost:8790/claude_dashboard.html" 2>/dev/null || \
echo "Open http://localhost:8790/claude_dashboard.html in your browser"

echo ""
echo "✅ Setup complete!"
echo ""
