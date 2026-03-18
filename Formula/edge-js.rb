class EdgeJs < Formula
  desc "Secure JavaScript runtime for Edge computing and AI workloads"
  homepage "https://github.com/wasmerio/edgejs"
  url "https://github.com/wasmerio/edgejs-nightlies/releases/download/0.0.0-nightly/edge-darwin-arm64.zip"
  version "0.0.0-nightly"
  sha256 "da039a1c249b8c0e3c3686839492dde8d20f83ac1269b9d19daf9a183d885616"
  license "MIT"

  # No stable releases exist yet — using the nightlies repo.
  # Once wasmerio/edgejs publishes a stable release, switch the URL
  # and drop the nightly version tag.

  depends_on arch: :arm64
  depends_on :macos
  depends_on "markmals/tap/wasmer"

  def install
    # The zip extracts a bundle structured as:
    #   bin/edge        — main binary
    #   bin/edgeenv     — environment helper binary
    #   bin-compat/node — shim that delegates to edge via EDGE_BINARY_PATH
    #   lib/            — JavaScript standard library (~800 files)
    #
    # Install the whole bundle into libexec to preserve the relative
    # path layout the binary expects, then symlink executables into bin.

    libexec.install Dir["*"]

    bin.install_symlink libexec/"bin/edge"
    bin.install_symlink libexec/"bin/edgeenv"
  end

  def caveats
    <<~EOS
      Edge.js installed.

      Run a script:  edge myscript.js
      REPL:          edge

      The node-compatibility shim is available at:
          #{opt_libexec}/bin-compat/node
      To use it, set EDGE_BINARY_PATH=#{opt_bin}/edge in your environment.
    EOS
  end

  test do
    assert_match(/v?\d+\.\d+\.\d+/, shell_output("#{bin}/edge --version").strip)
    assert_equal "hello", shell_output("#{bin}/edge -e 'console.log(\"hello\")'").strip
  end
end
