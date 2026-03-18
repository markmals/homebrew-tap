class Wasmer < Formula
  desc "Universal WebAssembly Runtime"
  homepage "https://wasmer.io"
  license "MIT"

  # The homebrew-core wasmer formula builds from source without NAPI support.
  # This formula installs the official pre-compiled binary which includes
  # NAPI, required by Edge.js for --safe mode.

  depends_on :macos

  if Hardware::CPU.arm?
    url "https://github.com/wasmerio/wasmer/releases/download/v7.0.1/wasmer-darwin-arm64.tar.gz"
    sha256 "3eff017389fb838b0b5af607a4d392edc6039e76343984fcd24307aa027d67ee"
  else
    url "https://github.com/wasmerio/wasmer/releases/download/v7.0.1/wasmer-darwin-amd64.tar.gz"
    sha256 "3a0f44a3aae570b0870d4573fa663c7f0c96a2f9550e38eb22c3be7c77658a1e"
  end

  conflicts_with "wasmer", because: "both install a `wasmer` binary"

  def install
    # The tarball extracts with this layout:
    #   bin/wasmer
    #   bin/wasmer-headless
    #   lib/libwasmer.{a,dylib}
    #   lib/libwasmer-headless.{a,dylib}
    #   include/*.h

    bin.install "bin/wasmer"
    bin.install "bin/wasmer-headless"
    lib.install Dir["lib/*"]
    include.install Dir["include/*"]
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/wasmer --version")
  end
end
