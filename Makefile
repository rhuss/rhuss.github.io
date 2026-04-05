PORT ?= 1313
URL  := http://localhost:$(PORT)

# Colors
C_CYAN   := \033[36m
C_GREEN  := \033[32m
C_YELLOW := \033[33m
C_BOLD   := \033[1m
C_RESET  := \033[0m

.PHONY: help dev build clean

help: ## Show this help
	@printf "\n$(C_BOLD)$(C_CYAN)  ro14nd.de Blog$(C_RESET)\n\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(C_GREEN)%-12s$(C_RESET) %s\n", $$1, $$2}'
	@printf "\n"

dev: ## Start dev server with drafts and open browser
	@printf "\n$(C_BOLD)$(C_CYAN)  ┌─────────────────────────────────────┐$(C_RESET)\n"
	@printf "$(C_BOLD)$(C_CYAN)  │$(C_RESET)  $(C_BOLD)ro14nd.de$(C_RESET) dev server starting...  $(C_BOLD)$(C_CYAN)│$(C_RESET)\n"
	@printf "$(C_BOLD)$(C_CYAN)  │$(C_RESET)  $(C_YELLOW)$(URL)$(C_RESET)                $(C_BOLD)$(C_CYAN)│$(C_RESET)\n"
	@printf "$(C_BOLD)$(C_CYAN)  └─────────────────────────────────────┘$(C_RESET)\n\n"
	@(sleep 2 && open $(URL)) &
	hugo server -D --navigateToChanged --disableFastRender --port $(PORT)

build: ## Build site for production
	hugo --minify

clean: ## Remove generated files
	rm -rf public/ resources/
