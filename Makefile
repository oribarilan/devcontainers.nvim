.PHONY: test test-watch clean help

# Default target
help:
	@echo "Available targets:"
	@echo "  test       - Run all unit tests"
	@echo "  clean      - Clean up temporary files"
	@echo "  help       - Show this help message"

# Run tests using the built-in test runner
test:
	@echo "Running tests with built-in test runner..."
	@nvim --headless --noplugin -u NONE -c "set runtimepath+=." -c "lua require('devcontainers.test_runner').run()"

# Clean up any temporary files
clean:
	@echo "Cleaning up temporary files..."
	@find . -name "*.tmp" -delete
	@find . -name ".DS_Store" -delete

# Check if dependencies are available
check-deps:
	@which nvim > /dev/null || (echo "Error: nvim not found in PATH" && exit 1)
	@echo "Dependencies OK"