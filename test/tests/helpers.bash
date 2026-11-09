# Shared by the .bats files. The settings come from the generated chezmoi config.
# Only an explicit false skips: a broken config must fail tests, not skip them.
data() { chezmoi execute-template "{{ .$1 }}"; }
skip_unless() { [ "$(data "$1")" != false ] || skip "$1 disabled"; }
