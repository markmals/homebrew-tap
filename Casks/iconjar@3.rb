cask "iconjar@3" do
  version "3.0,1765"
  sha256 "e7b0ae981d7e59aea3d7e930ceeb078010680f99dbb63eadd4f05a1c0652bab0"

  url "https://geticonjar.com/releases/v3/IconJar.app.#{version.csv.second}.zip"
  name "IconJar"
  desc "Icon organiser"
  homepage "https://geticonjar.com/"

  livecheck do
    url "https://geticonjar.com/releases/v3/stable.xml"
    strategy :sparkle
  end

  auto_updates true
  # IconJar 2 ships as the same IconJar.app, so the two cannot share /Applications.
  conflicts_with cask: "iconjar"
  depends_on macos: :tahoe

  app "IconJar.app"
end
