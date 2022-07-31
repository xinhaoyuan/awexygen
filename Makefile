.PHONY: check test

check:
	luacheck . --no-color | grep -v "unused \(loop variable\|variable\|argument\) '_"

test:
	@tests/run.sh

archive-zip:
	mkdir -p archives
	git archive --format zip --output archives/awexygen.zip --prefix awexygen/ HEAD

install-desktop:
	@utils/install_desktop.sh
