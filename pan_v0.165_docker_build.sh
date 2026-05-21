#!/bin/bash

set -e

echo "Starting isolated Ubuntu 24.04 Docker container to build Pan v0.165 via CPack..."

docker run -i --rm -v "$(pwd)":/workspace -w /workspace ubuntu:24.04 /bin/bash <<- 'EOF'
	# 1. Update and install compiler tools and dependencies
	apt-get update
	DEBIAN_FRONTEND=noninteractive apt-get install -y git cmake ninja-build build-essential \
		libgtk-3-dev libgmime-3.0-dev libsecret-1-dev libgspell-1-dev \
		libnotify-dev gnutls-dev gettext itstool

	# 2. Clone the source code
	git clone https://gitlab.gnome.org/GNOME/pan.git
	cd pan
	git checkout v0.165

	# 3. Configure and compile
	rm -rf build
	mkdir build
	cmake -B build \
		-DWANT_GNUTLS=ON \
		-DWANT_GTKSPELL=ON \
		-DCMAKE_INSTALL_PREFIX=/usr
	cmake --build build -j$(nproc)

	# 4. Install into staging directory
	cmake --install build --prefix /usr --strip

	# 5. Generate the .deb package
	cd build
    	cpack -G DEB \
		-D CPACK_PACKAGE_NAME=pan \
		-D CPACK_PACKAGE_VERSION=0.165 \
		-D CPACK_PACKAGE_FILE_NAME=pan-0.165-1-amd64 \
		-D CPACK_PACKAGE_DESCRIPTION="GNOME Pan Newsreader" \
		-D CPACK_PACKAGE_DESCRIPTION_SUMMARY="GNOME Pan Newsreader v0.165" \
		-D CPACK_DEBIAN_PACKAGE_MAINTAINER="Local Build" \
		-D CPACK_CMAKE_GENERATOR="Unix Makefiles" \
		-D CPACK_INSTALL_CMAKE_PROJECTS="$(pwd);pan;ALL;/" \
		.

	# 6. Move the finished package out to the mapped host folder
	ls -lh *.deb
	mv *.deb /workspace/
	cd /workspace
	rm -rf pan
EOF

echo "--------------------------------------------------------"
echo "Success! The container closed out and your clean .deb is ready:"
ls -lh *.deb
