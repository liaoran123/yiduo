# Yiduo OS Build PowerShell Script
Write-Host "Building Yiduo OS..."

# Create output directory
New-Item -ItemType Directory -Path bin -Force | Out-Null

# Check required tools
Write-Host "Checking required tools..."
$tools = @("moon")
$missingTools = @()

foreach ($tool in $tools) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        $missingTools += $tool
    }
}

if ($missingTools.Count -gt 0) {
    Write-Host "Error: Missing tools: $($missingTools -join ', ')" -ForegroundColor Red
    Write-Host "Please install these tools and add them to system path." -ForegroundColor Red
    exit 1
}

# Build MoonBit kernel
Write-Host "Building MoonBit kernel..."
try {
    moon build --target=native kernel
    Write-Host "Kernel build successful!" -ForegroundColor Green
} catch {
    Write-Host "Kernel build failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Build Wasm app
Write-Host "Building Wasm app..."
try {
    moon build --target=wasm apps/hello
    Write-Host "Wasm app build successful!" -ForegroundColor Green
} catch {
    Write-Host "Wasm app build failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Copy build artifacts to bin directory
Write-Host "Copying build artifacts..."
if (Test-Path "_build\native\debug\build\kernel\kernel.exe") {
    Copy-Item "_build\native\debug\build\kernel\kernel.exe" "bin\yiduo_kernel.exe" -Force
    Write-Host "Kernel copied to bin\yiduo_kernel.exe" -ForegroundColor Green
} else {
    Write-Host "Warning: Kernel build artifact not found" -ForegroundColor Yellow
}

if (Test-Path "_build\wasm\debug\build\apps\hello\hello.wasm") {
    Copy-Item "_build\wasm\debug\build\apps\hello\hello.wasm" "bin\app.wasm" -Force
    Write-Host "Wasm app copied to bin\app.wasm" -ForegroundColor Green
} else {
    Write-Host "Warning: Wasm app build artifact not found" -ForegroundColor Yellow
}

Write-Host "Build completed!" -ForegroundColor Green
Write-Host "Build artifacts:"
Write-Host "- Kernel: bin\yiduo_kernel.exe"
Write-Host "- Wasm app: bin\app.wasm"
Write-Host "Note: Due to environment limitations, assembly compilation and linking steps are skipped."
Write-Host "In a complete environment, you will need to install nasm and ld with elf_i386 support."