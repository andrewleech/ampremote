PKG_DIR := micropython/tools/mpremote
PKG_NAME := ampremote
DIST_DIR := $(CURDIR)/dist

.PHONY: install uninstall wheel clean

install:
	uv tool install --editable --force $(PKG_DIR)

uninstall:
	uv tool uninstall $(PKG_NAME)

wheel:
	cd $(PKG_DIR) && uv build --wheel --out-dir $(DIST_DIR)

clean:
	rm -rf $(DIST_DIR)
	rm -rf $(PKG_DIR)/dist $(PKG_DIR)/build
