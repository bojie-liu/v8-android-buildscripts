#!/bin/bash -e

GCLIENT_SYNC_ARGS="--reset --with_branch_head"
while getopts 'r:s' opt; do
  case ${opt} in
    r)
      GCLIENT_SYNC_ARGS+=" --revision ${OPTARG}"
      ;;
    s)
      GCLIENT_SYNC_ARGS+=" --no-history"
      ;;
  esac
done
shift $(expr ${OPTIND} - 1)

source $(dirname $0)/env.sh

# Install NDK
function installNDK() {
  pushd .
  cd "${V8_DIR}"
  if [[ "$(uname)" == "Darwin" ]]; then
    curl https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-darwin-x86_64.zip -o android-ndk-${NDK_VERSION}-darwin-x86_64.zip
    unzip -q android-ndk-${NDK_VERSION}-darwin-x86_64.zip
    rm -f android-ndk-${NDK_VERSION}-darwin-x86_64.zip
    # copy llvm toolchain
    cp ./v8/android-ndk-${NDK_VERSION}/toolchains/llvm/prebuilt/darwin-x86_64/bin/* ./v8/third_party/android_ndk/toolchains/llvm/prebuilt/linux-x86_64/bin/
  else
    wget -q https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux-x86_64.zip
    unzip -q android-ndk-${NDK_VERSION}-linux-x86_64.zip
    rm -f android-ndk-${NDK_VERSION}-linux-x86_64.zip
  fi
  popd
}

if [[ ! -d "${DEPOT_TOOLS_DIR}" || ! -f "${DEPOT_TOOLS_DIR}/gclient" ]]; then
  git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git "${DEPOT_TOOLS_DIR}"
fi

gclient config --name v8 --unmanaged "https://chromium.googlesource.com/v8/v8.git"

if [[ ${MKSNAPSHOT_ONLY} = "1" ]]; then
  gclient sync ${GCLIENT_SYNC_ARGS}
  exit 0
fi

if [[ ${PLATFORM} = "ios" ]]; then
  gclient sync --deps=ios ${GCLIENT_SYNC_ARGS}
  exit 0
fi

if [[ ${PLATFORM} = "android" ]]; then
  gclient sync --deps=android ${GCLIENT_SYNC_ARGS}
  if [[ "$(uname)" != "Darwin" ]]; then
    sudo bash -c 'v8/build/install-build-deps-android.sh'
  fi

  # Workaround to install missing sysroot
  gclient sync

  # Workaround to install missing android_sdk tools
  gclient sync --deps=android ${GCLIENT_SYNC_ARGS}

  installNDK
  exit 0
fi
