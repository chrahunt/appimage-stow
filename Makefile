.PHONY: all clean appimage gh-continuous-release

APP_NAME ?= Stow
APPIMAGE_NAME ?= $(APP_NAME)-x86_64.AppImage

all: appimage

clean:
	rm -rf build/

appimage: $(APPIMAGE_NAME)
	@echo "::set-output name=name::$(APPIMAGE_NAME)"

gh-continuous-release: $(APPIMAGE_NAME) build/tools/hub
	git tag -fam continuous continuous
	git push -f origin continuous
	if build/tools/hub release | grep '^continuous$$'; then \
		build/tools/hub release delete continuous; \
	fi
	build/tools/hub release create --prerelease --attach $(APPIMAGE_NAME) \
		--message "Continuous build" continuous

# Any directories.
%/:
	mkdir -p "$@"

build/app.AppDir/usr/bin/perl:
	curl -fsSL https://git.io/perl-install | bash -s build/app.AppDir/usr

build/app.AppDir/usr/bin/stow: build/app.AppDir/usr/bin/perl | build/build/ 
	export PATH="$$PWD/build/app.AppDir/usr/bin:$$PATH"; \
	cd build/build/ \
	&& curl -o - --location https://ftp.gnu.org/gnu/stow/stow-2.3.1.tar.gz | tar -xzf - \
	&& cd stow-* \
	&& ./configure --prefix=$$(readlink -f ../../app.AppDir/usr/) \
	&& make && make install

build/app.AppDir/usr/bin/stow-wrapper: stow-wrapper | build/app.AppDir/usr/bin/
	cp stow-wrapper build/app.AppDir/usr/bin/

build/app.AppDir/icon.png: | icon.png build/app.AppDir/
	cp icon.png build/app.AppDir/

build/app.AppDir/stow.desktop: | stow.desktop build/app.AppDir/
	cp stow.desktop build/app.AppDir/

$(APPIMAGE_NAME): build/app.AppDir/stow.desktop build/app.AppDir/icon.png
$(APPIMAGE_NAME): build/app.AppDir/usr/bin/perl build/app.AppDir/usr/bin/stow
$(APPIMAGE_NAME): build/app.AppDir/usr/bin/stow-wrapper
$(APPIMAGE_NAME): build/app.AppDir/AppRun
$(APPIMAGE_NAME): build/tools/appimagetool
	./build/tools/appimagetool build/app.AppDir

build/app.AppDir/AppRun: | build/
	curl --location -o build/app.AppDir/AppRun https://github.com/AppImage/AppImageKit/releases/download/12/AppRun-x86_64
	chmod +x build/app.AppDir/AppRun

# Tools.
build/tools/appimagetool: | build/tools/
	curl --location -o build/tools/appimagetool https://github.com/AppImage/AppImageKit/releases/download/12/appimagetool-x86_64.AppImage
	chmod +x build/tools/appimagetool

build/tools/hub: | build/tools/
	cd build/tools \
	&& curl -fsSL https://github.com/github/hub/raw/master/script/get | bash -s 2.14.1 \
	&& mv bin/hub hub \
	&& rm -r bin/
