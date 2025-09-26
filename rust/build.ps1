$targets = @(
    "x86_64-pc-windows-msvc",
    "x86_64-unknown-linux-gnu",
    "x86_64-apple-darwin"
)

foreach ($target in $targets) {
    Write-Host "Building for $target..."
    cargo build --release --target $target
}
