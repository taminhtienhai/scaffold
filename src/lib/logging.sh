# --- Colors for Output ---
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# --- Logging Functions ---
log() {
    echo -e "${GREEN}[INFO]${NC} $*" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

debug() {
    if [[ "$DEBUG" -eq 1 ]]; then
        echo -e "${PURPLE}[DEBUG]${NC} $*" >&2
    fi
}

verbose() {
    if [[ "$VERBOSE" -eq 1 ]]; then
        echo -e "${CYAN}[VERBOSE]${NC} $*" >&2
    fi
}
