# TweakCompiler

A powerful iOS tweak development environment built with SwiftUI, inspired by FridaCodeManager but specifically designed for creating iOS tweaks.

## Features

### 🛠️ **Project Management**
- Create new tweak projects with templates
- Manage multiple projects
- Standard Theos project structure
- Built-in project browser

### 📝 **Code Editor**
- Syntax highlighting for tweak files
- Line numbers and auto-indent
- Real-time file editing
- Monospace font with customizable size

### 🔨 **Compilation System**
- Integrated Theos compilation
- Real-time compilation logs
- Progress indicators
- Error handling and reporting

### 📦 **Package Management**
- Generate .deb packages
- Install via Sileo, Zebra, or Filza
- Track installed packages
- Package manager integration

### ⚙️ **Settings & Configuration**
- Theos installation and configuration
- Compilation preferences
- Editor customization
- Package manager settings

## Installation

### Prerequisites
- Jailbroken iOS device (iOS 15.0+)
- Theos installed on your device
- Package manager (Sileo, Zebra, or Filza)

### Method 1: Direct Installation (Recommended)
```bash
# Clone the repository
git clone https://github.com/yourusername/TweakCompiler.git
cd TweakCompiler

# Make scripts executable
chmod +x build.sh install.sh

# Install directly to device
sudo ./install.sh
```

### Method 2: Build .deb Package
```bash
# Build the package
./build.sh

# Install the generated .deb file using your package manager
# The .deb file will be in the packages/ directory
```

### Method 3: Manual Theos Build
```bash
# Set Theos environment
export THEOS=/path/to/theos

# Build package
make package

# Install package
make install
```

## Usage

### Creating a New Project

1. Open the **Projects** tab
2. Tap the **+** button to create a new project
3. Fill in project details:
   - Project name
   - Bundle identifier
   - Target application
4. Choose a template (Basic Hook, UI Modification, Preferences)
5. Tap **Create** to generate the project structure

### Editing Code

1. Go to the **Editor** tab
2. Select a project from the sidebar
3. Choose a file to edit (Tweak.x, Makefile, etc.)
4. Use the built-in editor with syntax highlighting
5. Save your changes

### Compiling

1. Switch to the **Compile** tab
2. Select your project
3. Tap **Compile** to build your tweak
4. Monitor the compilation log for progress
5. Generated .deb files will be in the `packages` folder

### Installing

1. Go to the **Install** tab
2. Choose your preferred package manager:
   - **Sileo**: Modern package manager
   - **Zebra**: Lightweight alternative
   - **Filza**: File manager installation
3. Tap the install button to open in your chosen app

## Project Structure

Each tweak project follows the standard Theos structure:

```
MyTweak/
├── Makefile          # Build configuration
├── Tweak.x           # Main tweak code
├── control           # Package information
├── MyTweak.plist     # Filter configuration
└── packages/         # Generated .deb files
```

## Templates

### Basic Hook Template
```objc
%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    NSLog(@"MyTweak loaded!");
}

%end
```

### UI Modification Template
```objc
%hook UIView

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    %orig;
    // Custom UI modifications
}

%end
```

### Preferences Template
```objc
%hook NSUserDefaults

- (void)setObject:(id)value forKey:(NSString *)defaultName {
    %orig;
    // Handle preference changes
}

%end
```

## Build System

### Theos Integration
TweakCompiler is built using Theos, making it compatible with the iOS development ecosystem:

- **Makefile**: Standard Theos build configuration
- **control**: Package metadata and dependencies
- **plist**: App configuration and entitlements
- **SwiftUI**: Modern iOS user interface

### Compilation Process
1. **Source Compilation**: Swift files compiled to binary
2. **Asset Processing**: App icons and resources bundled
3. **Package Creation**: .deb package generated
4. **Installation**: App installed to /Applications/

### Build Commands
```bash
# Clean build
make clean

# Build package
make package

# Install package
make install

# Build and install
make package install
```

## Compatibility

- **iOS**: 15.0 - 18.3.1
- **Jailbreak Types**: Rootless, RootHide, TrollStore
- **Package Managers**: Sileo, Zebra, Filza
- **Architecture**: arm64, arm64e

## Troubleshooting

### Common Issues

**"Theos not found"**
- Install Theos: `git clone https://github.com/theos/theos.git`
- Set environment: `export THEOS=/path/to/theos`

**"Compilation failed"**
- Check Theos installation
- Verify Swift toolchain
- Check device architecture support

**"Package installation failed"**
- Ensure device is properly jailbroken
- Check package manager compatibility
- Verify .deb file integrity

### Getting Help

1. Check the compilation log for specific error messages
2. Verify your Theos installation
3. Ensure all required dependencies are present
4. Check that your target app bundle ID is correct

## Development

### Building from Source
```bash
# Clone repository
git clone https://github.com/yourusername/TweakCompiler.git
cd TweakCompiler

# Install dependencies
# (Theos should be installed)

# Build
make package

# Install
make install
```

### Contributing
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the build
5. Submit a pull request

## Credits

- **Theos**: iOS development framework
- **SwiftUI**: User interface framework  
- **FridaCodeManager**: UI inspiration and design patterns
- **TheOS Community**: For tweak development resources

## License

This project is licensed under the GPL-3.0 License - see the LICENSE file for details.

## Roadmap

- [ ] Advanced code completion
- [ ] Git integration
- [ ] Multiple project support
- [ ] Cloud sync
- [ ] Team collaboration features
- [ ] Advanced debugging tools
- [ ] Custom templates
- [ ] Plugin system

---

**TweakCompiler** - Making iOS tweak development accessible and enjoyable! 🚀

## Quick Start

1. **Install**: `sudo ./install.sh`
2. **Open**: TweakCompiler app on your device
3. **Create**: New tweak project
4. **Code**: Edit your tweak
5. **Compile**: Build your tweak
6. **Install**: Deploy your tweak

That's it! You're ready to start developing iOS tweaks! 🎉