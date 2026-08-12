# `make check` is exactly what CI runs. `make check-local` adds the one thing CI
# cannot do: grep for the real values, which requires values.local.env.

.PHONY: check check-local lint help

help:
	@echo "check        structural + shape checks (what CI runs)"
	@echo "check-local  the above, plus a sweep for the real values in values.local.env"
	@echo "lint         shellcheck every shell script"

check:
	@./ci/check.sh

lint:
	@shellcheck hydrate.sh ci/check.sh $$(find collections -name '*.sh')
	@echo "shellcheck clean"

# Never run in CI: values.local.env must not reach a runner.
#
# The guard and the sweep are ONE shell invocation. Split across recipe lines,
# the guard's `exit 0` only ends its own line and the sweep then reads a missing
# file and reports success having checked nothing.
check-local: check
	@set -e; \
	if [ ! -f values.local.env ]; then \
		echo; echo "SKIPPED: no values.local.env — the exact-value sweep needs it"; \
		exit 0; \
	fi; \
	echo; echo "exact-value sweep (local only)"; \
	leaks=0; \
	while IFS='=' read -r k v; do \
		case "$$k" in \#*|"") continue;; esac; \
		[ -z "$$v" ] && continue; \
		case "$$k" in COMPANY|PRODUCT|ITEM|APP_DB|WAREHOUSE_DB|REPORTING_SCHEMA|GITLAB_GROUP|WAREHOUSE_STORAGE|STAGING_JOB|HISTORY_SCHEMA|WORKSPACE_ROOT) continue;; esac; \
		if git ls-files -z | xargs -0 grep -lF "$$v" 2>/dev/null | head -1 | grep -q .; then \
			echo "  FAIL: real value for $$k appears in a tracked file"; leaks=1; \
		fi; \
	done < values.local.env; \
	if [ $$leaks -eq 0 ]; then echo "  ok: no real value appears in any tracked file"; \
	else echo; echo "exact-value sweep failed."; exit 1; fi
