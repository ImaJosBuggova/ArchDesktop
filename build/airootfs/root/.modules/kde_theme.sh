#!/usr/bin/env bash
set -euo pipefail

NEW_USER="$1"

echo "Extracting cursor themes..."
mkdir -p /usr/share/icons
tar -xf /tmp_bibata.tar.xz -C /usr/share/icons/

USER_HOME="/home/$NEW_USER"
mkdir -p "$USER_HOME/.config"

if [ -f "/tmp_icon.svg" ]; then
    mkdir -p /usr/share/pixmaps
    cp /tmp_icon.svg /usr/share/pixmaps/arch-crystal.svg
    chmod 644 /usr/share/pixmaps/arch-crystal.svg
fi

# Enable hardware compositor desktop blur inside KWin configs
cat <<EOT >> /etc/xdg/kwinrc
[Plugins]
blurEnabled=true
translucencyEnabled=true
EOT

# ----------------------------------------------------------------------
# 1. SDDM & CUSTOM BACKGROUND CONFIGURATION
# ----------------------------------------------------------------------
echo "Customizing login splash screen structure..."

mkdir -p /usr/share/wallpapers/custom
cp /tmp_wallpaper.jpg /usr/share/wallpapers/custom/default_bg.jpg
chmod 644 /usr/share/wallpapers/custom/default_bg.jpg

mkdir -p /etc/sddm.conf.d
cat <<EOT > /etc/sddm.conf.d/kde_custom.conf
[Theme]
Current=breeze

[Wayland]
SessionDir=/usr/share/wayland-sessions
EOT

mkdir -p /usr/share/sddm/themes/breeze
cat <<EOT > /usr/share/sddm/themes/breeze/theme.conf.user
[General]
background=/usr/share/wallpapers/custom/default_bg.jpg
type=image
EOT

BREEZE_SDDM_THEME_CONF="/usr/share/sddm/themes/breeze/theme.conf"
if [ -f "$BREEZE_SDDM_THEME_CONF" ]; then
    sed -i 's|^background=.*|background=/usr/share/wallpapers/custom/default_bg.jpg|' "$BREEZE_SDDM_THEME_CONF"
fi

# ----------------------------------------------------------------------
# 3. FONT LAYER CONFIGURATIONS (Fira Sans & Fira Mono)
# ----------------------------------------------------------------------
echo "Injecting global system font mapping configurations..."

# Set system-wide font configuration profiles
cat <<EOT > /etc/xdg/kdeglobals
[KDE]
lookandfeel=org.kde.breezedark.desktop

[Style]
Theme=breeze-dark
WidgetStyle=Breeze

[Icons]
Theme=Papirus-Dark

[General]
font=Fira Sans,10,-1,5,50,0,0,0,0,0
fixed=Fira Mono,10,-1,5,50,0,0,0,0,0
menuFont=Fira Sans,10,-1,5,50,0,0,0,0,0
toolBarFont=Fira Sans,10,-1,5,50,0,0,0,0,0
smallestReadableFont=Fira Sans,8,-1,5,50,0,0,0,0,0
activeFont=Fira Sans,10,-1,5,75,0,0,0,0,0
titleFont=Fira Sans,10,-1,5,75,0,0,0,0,0
EOT

# Mirror the configurations into the user's home profile directory to block overrides
cp /etc/xdg/kdeglobals "$USER_HOME/.config/kdeglobals"

# ----------------------------------------------------------------------
# 4. ICON & CURSOR SELECTION CONFIGURATIONS
# ----------------------------------------------------------------------
echo "Enforcing cursor and icon style sheets..."

mkdir -p /usr/share/icons/default
cat <<EOT > /usr/share/icons/default/index.theme
[Icon Theme]
Inherits=Bibata-Modern-Ice
EOT

cat <<EOT >> "$USER_HOME/.config/kcminputrc"
[Mouse]
cursorTheme=Bibata-Modern-Ice
EOT

# ----------------------------------------------------------------------
# 5. DUAL PANEL LAYOUT DESIGN (Top & Bottom Taskbars)
# ----------------------------------------------------------------------
echo "Injecting custom dual-taskbar layout script..."

mkdir -p /usr/share/plasma/layout-templates/org.kde.plasma.desktop.defaultPanel/contents/
cat <<'EOT' > /usr/share/plasma/layout-templates/org.kde.plasma.desktop.defaultPanel/contents/layout.js
var desktopsArray = desktops();

// Set background
for (var j = 0; j < desktopsArray.length; ++j) {
    var desk = desktopsArray[j];
    desk.wallpaperPlugin = "org.kde.image";
    desk.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    desk.writeConfig("Image", "/usr/share/wallpapers/custom/default_bg.jpg");
}

var allPanels = panels();
for (var i = 0; i < allPanels.length; ++i) {
    allPanels[i].remove();
}

// ------ 1. TOP PANEL (Full Width, Transparent, Always Visible Status Bar) ------
var topPanel = new Panel();
topPanel.location = "top";
topPanel.height = 26;

topPanel.floating = false;
topPanel.alignment = "center";
topPanel.hidingMode = "none";
topPanel.opacityMode = "translucent";

topPanel.addWidget("org.kde.plasma.panelspacer");

var clock = topPanel.addWidget("org.kde.plasma.digitalclock");

// 1. Configure Layout Shape (Appearance)
clock.currentConfigGroup = ["Appearance"];
clock.writeConfig("showDate", true);
clock.writeConfig("dateFormat", 1);             // 1 = Long Date Standard Format String
clock.writeConfig("displayInSingleLine", true);  // Keeps date right next to time on 1 row

// 2. FIX: Access the sub-group correctly by setting the main group FIRST
clock.currentConfigGroup = ["Appearance"];
// Use the sub-group index configuration mapping property explicitly
clock.configGroup = "Fonts"; 

// 3. Write font options cleanly (Will now switch to MANUAL automatically!)
clock.writeConfig("useCustomFont", true);        // THIS forces manual mode on!
clock.writeConfig("fontFamily", "Fira Sans");
clock.writeConfig("fontStyleName", "Medium");
clock.writeConfig("fontWeight", 57);             // 57 = Medium weighting matrix
clock.writeConfig("fontPixelSize", 11);          // 11px = 8pt

topPanel.addWidget("org.kde.plasma.panelspacer");
topPanel.addWidget("org.kde.plasma.systemtray");

// ------ 2. BOTTOM PANEL (Centered Dock Layout, Auto-Hide, No Pins) ------
var bottomPanel = new Panel();
bottomPanel.location = "bottom";
bottomPanel.height = 46;
bottomPanel.floating = true;
bottomPanel.alignment = "center";
bottomPanel.lengthMode = "fit";
bottomPanel.hiding = "autohide";
bottomPanel.opacity = "translucent";

var launcher = bottomPanel.addWidget("org.kde.plasma.kickoff");
launcher.currentConfigGroup = ["General"];
launcher.writeConfig("icon", "/usr/share/pixmaps/arch-crystal.svg");
launcher.writeConfig("pin", false);

var tasks = bottomPanel.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", "");
tasks.writeConfig("showOnlyCurrentScreen", true);
EOT

# Fix all user ownership attributes across the new profile folder layout
chown -R "$NEW_USER:$NEW_USER" "$USER_HOME/.config"

echo "KDE Theme, Fonts & Panel configurations successfully staged."
