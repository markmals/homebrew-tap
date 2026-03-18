class Wasmer < Formula
  desc "Universal WebAssembly Runtime (with NAPI support)"
  homepage "https://wasmer.io"
  url "https://github.com/wasmerio/wasmer/archive/refs/tags/v7.0.1.tar.gz"
  sha256 "1cd67765b834dd509d29fd7420819af37af852b877bc32b31c07bf92d27ffd31"
  license "MIT"
  head "https://github.com/wasmerio/wasmer.git", branch: "main"

  # The homebrew-core wasmer formula builds with only the cranelift feature.
  # Edge.js --safe mode requires the napi-v8 feature, which is only available
  # when building from source. This formula adds it.

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "rust" => :build
  depends_on "wabt" => :build

  conflicts_with "wasmer", because: "both install a `wasmer` binary"

  def install
    system "cargo", "install", *std_cargo_args(path: "lib/cli", features: "cranelift,napi-v8")

    generate_completions_from_executable(bin/"wasmer", "gen-completions")
  end

  test do
    # Verify NAPI feature is present
    assert_match "NAPI", shell_output("#{bin}/wasmer --version -v")

    wasm = ["0061736d0100000001070160027f7f017f030201000707010373756d00000a09010700200020016a0b"].pack("H*")
    (testpath/"sum.wasm").write(wasm)
    assert_equal "3\n",
      shell_output("#{bin}/wasmer run #{testpath/"sum.wasm"} --invoke sum 1 2")
  end
end
