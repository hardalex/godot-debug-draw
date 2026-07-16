# Godot Debug Draw - tool installation and common commands
#
# Initialization (first use):
#   cargo install just  # install just itself if needed
#   just init           # initialize tools and hooks

# --------------------------------------------------
# Tool installation
# --------------------------------------------------

# Initialize tools: check and install missing tools, then enable the commit hook
init:
  @command -v cog >/dev/null 2>&1 || cargo install cocogitto
  @command -v gdscript-formatter >/dev/null 2>&1 || cargo install --git https://github.com/GDQuest/GDScript-formatter
  @if [ -d .git ]; then \
    git config core.hooksPath .githooks; \
    echo "✓ Git hooks enabled"; \
  else \
    echo "! .git not found, skipping Git hooks setup"; \
  fi
  @echo "✓ Initialization complete"

# Update installed tools to the latest versions
upgrade:
  cargo install cocogitto --force
  cargo install --git https://github.com/GDQuest/GDScript-formatter --force

# --------------------------------------------------
# Tests
# --------------------------------------------------

# Run gdUnit4 tests (no args = all tests, with args = selected test file)
test *test_file='':
  @if [ ! -x addons/gdUnit4/runtest.sh ]; then \
    echo "! addons/gdUnit4/runtest.sh not found, skipping tests"; \
  elif [ "{{test_file}}" = "" ]; then \
    GODOT_BIN=$(which godot) bash addons/gdUnit4/runtest.sh --add tests/; \
  else \
    GODOT_BIN=$(which godot) bash addons/gdUnit4/runtest.sh --add "{{test_file}}"; \
  fi

# Same as above, but in headless mode for CI
test-headless *test_file='':
  @if [ ! -x addons/gdUnit4/runtest.sh ]; then \
    echo "! addons/gdUnit4/runtest.sh not found, skipping tests"; \
  elif [ "{{test_file}}" = "" ]; then \
    GODOT_BIN=$(which godot) bash addons/gdUnit4/runtest.sh --headless --ignoreHeadlessMode --add tests/; \
  else \
    GODOT_BIN=$(which godot) bash addons/gdUnit4/runtest.sh --headless --ignoreHeadlessMode --add "{{test_file}}"; \
  fi

# --------------------------------------------------
# Code checks
# --------------------------------------------------

# Check formatting only (no args = whole project, with args = selected files)
check-fmt *files='':
  @if [ "{{files}}" = "" ]; then \
    _gd=$(find . -name "*.gd" -not -path "./.godot/*" -not -path "./addons/gdUnit4/*"); \
    if [ -z "$_gd" ]; then echo "! No GDScript files found, skipping format check"; else echo "$_gd" | xargs gdscript-formatter --use-spaces --indent-size 2 --reorder-code --check; fi; \
  else \
    gdscript-formatter --use-spaces --indent-size 2 --reorder-code --check {{files}}; \
  fi

# Format code (no args = whole project, with args = selected files)
fmt *files='':
  @if [ "{{files}}" = "" ]; then \
    _gd=$(find . -name "*.gd" -not -path "./.godot/*" -not -path "./addons/gdUnit4/*"); \
    if [ -z "$_gd" ]; then echo "! No GDScript files found, skipping formatting"; else echo "$_gd" | xargs gdscript-formatter --use-spaces --indent-size 2 --reorder-code; fi; \
  else \
    gdscript-formatter --use-spaces --indent-size 2 --reorder-code {{files}}; \
  fi

# Lint code (no args = whole project, with args = selected files)
lint *files='':
  @if [ "{{files}}" = "" ]; then \
    _gd=$(find . -name "*.gd" -not -path "./.godot/*" -not -path "./addons/gdUnit4/*"); \
    if [ -z "$_gd" ]; then echo "! No GDScript files found, skipping lint"; else echo "$_gd" | xargs gdscript-formatter lint --disable max-line-length; fi; \
  else \
    gdscript-formatter lint --disable max-line-length {{files}}; \
  fi

# Run all checks (no args = whole project, with args = selected files)
check *files='':
  @set -e; \
  if [ "{{files}}" = "" ]; then \
    _gd=$(find . -name "*.gd" -not -path "./.godot/*" -not -path "./addons/gdUnit4/*"); \
    if [ -z "$_gd" ]; then \
      echo "! No GDScript files found, skipping checks"; \
    else \
      echo "$_gd" | xargs gdscript-formatter --use-spaces --indent-size 2 --reorder-code --check; \
      echo "$_gd" | xargs gdscript-formatter lint --disable max-line-length; \
    fi; \
  else \
    gdscript-formatter --use-spaces --indent-size 2 --reorder-code --check {{files}}; \
    gdscript-formatter lint --disable max-line-length {{files}}; \
  fi

# Validate commit messages (no args = since latest tag, with args = selected message)
lint-commit msg='':
  @if [ "{{msg}}" = "" ]; then \
    cog check --from-latest-tag --ignore-merge-commits; \
  else \
    cog verify "{{msg}}"; \
  fi

# --------------------------------------------------
# Changelog
# --------------------------------------------------

# Generate CHANGELOG.md from conventional commits
changelog:
  @set -e; \
  command -v cog >/dev/null 2>&1 || { echo "! cog is required to generate the changelog" >&2; exit 1; }; \
  tmp=$(mktemp); \
  err="${tmp}.err"; \
  printf "# Changelog\n\n" > "${tmp}"; \
  cog changelog 2> "${err}" >> "${tmp}"; \
  mv "${tmp}" CHANGELOG.md; \
  if [ -s "${err}" ]; then \
    echo "! Some commits were skipped by cocogitto:" >&2; \
    cat "${err}" >&2; \
  fi; \
  rm -f "${err}"; \
  echo "✓ CHANGELOG.md updated"

# --------------------------------------------------
# Release
# --------------------------------------------------

# Create and publish a GitHub release with an addon-only ZIP, e.g. `just release v1.0.0`
release version:
  @set -e; \
  if [ -n "$(git status --porcelain)" ]; then \
    echo "! Working tree is not clean" >&2; \
    exit 1; \
  fi; \
  command -v gh >/dev/null 2>&1 || { echo "! gh is required to create a GitHub release" >&2; exit 1; }; \
  command -v unzip >/dev/null 2>&1 || { echo "! unzip is required to validate the release ZIP" >&2; exit 1; }; \
  case "{{version}}" in \
    v[0-9]*.[0-9]*.[0-9]*) ;; \
    *) echo "! Version must look like v1.0.0" >&2; exit 1 ;; \
  esac; \
  if git rev-parse -q --verify "refs/tags/{{version}}" >/dev/null; then \
    echo "! Tag {{version}} already exists" >&2; \
    exit 1; \
  fi; \
  just check; \
  tmpdir=$(mktemp -d); \
  trap 'rm -rf "${tmpdir}"' EXIT; \
  asset="${tmpdir}/debug-draw-{{version}}.zip"; \
  git archive --format=zip --prefix=addons/debug_draw/ --output "${asset}" HEAD:addons/debug_draw; \
  invalid=$(unzip -Z1 "${asset}" | grep -v '^addons/debug_draw/' || true); \
  if [ -n "${invalid}" ]; then \
    echo "! Release ZIP contains paths outside addons/debug_draw/" >&2; \
    echo "${invalid}" >&2; \
    exit 1; \
  fi; \
  git tag -a "{{version}}" -m "Release {{version}}"; \
  git push origin "{{version}}"; \
  gh release create "{{version}}" "${asset}" --title "{{version}}" --generate-notes
