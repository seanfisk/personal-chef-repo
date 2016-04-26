# -*- coding: utf-8 -*-
#
# Author:: Sean Fisk <sean@seanfisk.com>
# Copyright:: Copyright (c) 2013, Sean Fisk
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License")
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

default.osx_setup.tap do |o|
  o.home = ENV['HOME']
  o.fonts_dir = "#{o.home}/Library/Fonts"
  o.etc_shells = '/etc/shells'
  o.shells = %w(bash zsh)
  o.iterm2.tap do |i|
    app_support = "#{o.home}/Library/Application Support/iTerm2"
    font = 'InconsolataForPowerline 20'
    gvsu_dir = "#{o.home}/classes"
    system_profile_guid = '4381BB8C-7F7D-4CFD-A5F8-3F1A77185E37'
    i.default_profile_guid = personal_profile_guid =
      '411F060B-E097-4E29-9986-275D5A47F609'
    i.bg_key = 'Background Image Location'
    i.bgs_dir = "#{app_support}/Backgrounds"
    i.dynamic_profiles_dir = "#{app_support}/DynamicProfiles"
    i.profiles = [
      { :Guid => personal_profile_guid,
        # General
        :Name => 'Personal',
        # Text
        'Cursor Type' => 2, # Box cursor
        :'Blinking Cursor' => false,
        :'Normal Font' => font,
        :'Non Ascii Font' => font,
        :'Ambiguous Double Width' => false,
        :'ASCII Anti Aliased' => true,
        :'Non-ASCII Anti Aliased' => true,
        # Window
        i.bg_key => 'holland-beach-sunset.jpg',
        :Blend => 0.4,
        :'Sync Title' => true,
        # Terminal
        :'Character Encoding' => 4, # UTF-8
        :'Terminal Type' => 'xterm-256color',
        :'Mouse Reporting' => true,
        :'Allow Title Reporting' => true,
        :'Allow Title Setting' => true,
        :'Disable Window Resizing' => true,
        :'Silence Bell' => false,
        :'BM Growl' => true,
        :'Visual Bell' => true,
        :'Flashing Bell' => false,
        :'Set Local Environment Vars' => true,
        :'Place Prompt at First Column' => true,
        :'Show Mark Indicators' => true,
        # Session
        :'Close Sessions On End' => true,
        :'Prompt Before Closing 2' => 0, # Do not prompt before closing
        # Keys
        :'Option Key Sends' => 2,
        :'Right Option Key Sends' => 2,
        # Advanced
        :Triggers => [
          # Set the user name to 'root' when the root prompt appears. This is
          # done in order not to have to install shell integration into the
          # root login script.
          {
            partial: true, # Take effect before next newline
            parameter: 'root@',
            regex: '^\w+:.+ root# ',
            action: 'SetHostnameTrigger'
          }
        ]
      },
      { :Guid => '80B90042-691C-42B6-9943-A1924E86A41F',
        :'Dynamic Profile Parent Name' => 'Personal',
        # General
        :Name => 'Root',
        # Window
        i.bg_key => 'volcano.jpg',
        # Advanced
        :'Bound Hosts' => ['root@']
      },
      { :Guid => '3129170E-EE36-4E29-9528-008A8BAB7FB7',
        :'Dynamic Profile Parent Name' => 'Personal',
        # General
        :Name => 'GVSU',
        :'Custom Directory' => 'Yes',
        :'Working Directory' => gvsu_dir,
        # Window
        i.bg_key => 'gvsu.jpg',
        :Blend => 0.35,
        # Advanced
        :'Bound Hosts' => [gvsu_dir]
      }
    ]
    system_bg_names = { [10, 10] => 'Yosemite 4', [10, 11] => 'El Capitan 2' }
    major_minor = node.platform_version.split('.')[0..1].map(&:to_i)
    if system_bg_names.key?(major_minor)
      i.profiles << {
        :Guid => system_profile_guid,
        :'Dynamic Profile Parent Name' => 'Personal',
        # General
        :Name => 'System',
        # Window
        i.bg_key => '/Library/Desktop Pictures/' \
          "#{system_bg_names[major_minor]}.jpg"
      }
      i.default_profile_guid = system_profile_guid
    end
  end
end

###############################################################################
# HOMEBREW FORMULAS
###############################################################################

default.homebrew.taps = %w(
  homebrew/command-not-found
  homebrew/x11
)

default.homebrew.formulas = [
  'ack',
  'aria2',
  'astyle',
  'cask',
  # Although there is a formula for this, it's best to install in a Python
  # environment, because cookiecutter uses the Python under which it runs to
  # execute things. Using /usr/bin/python causes problems...
  # 'cookiecutter',
  'coreutils',
  # An improved version of df with colors.
  'dfc',
  # Dos2Unix / Unix2Dos <http://waterlan.home.xs4all.nl/dos2unix.html> looks
  # superior to Tofrodos <http://www.thefreecountry.com/tofrodos/>. But that
  # was just from a quick look.
  'dos2unix',
  'doxygen',
  'duti',
  'editorconfig',
  'fasd',
  'ghostscript',
  'gibo',
  'gnu-tar',
  # Install both GraphicMagick and ImageMagick. In generally, I prefer
  # GraphicsMagick, but ImageMagick has ICO support so we use it for
  # BetterPlanner.
  'graphicsmagick',
  'graphviz',
  'grc',
  'htop-osx',
  'hub',
  # ImageMagick might already be present on the system (but just 'convert').
  # I'm not sure if it's just an artifact of an earlier build, but it was on my
  # Mavericks system before I installed it (again?).
  'imagemagick',
  # For pygit2 (which is for Powerline).
  'libgit2',
  # For rotating the Powerline log (see dotfiles).
  'logrotate',
  'mercurial',
  'mobile-shell',
  'mplayer', # For https://github.com/TeMPOraL/nyan-mode#features :)
  'mr', # myrepos, for managing multiple repos
  'nmap',
  'node',
  # I prefer ohcount to cloc and sloccount.
  'ohcount',
  'osquery',
  'p7zip',
  'parallel',
  'pdfgrep',
  'pidof',
  'progress',
  'pstree',
  # pwgen and sf-pwgen are both password generators. pwgen is more generic,
  # whereas sf-pwgen uses Apple's security framework. We also looked at APG,
  # but it seems unmaintained.
  'pwgen',
  'sf-pwgen',
  'pyenv',
  'pyenv-virtualenv',
  'pyenv-which-ext',
  'qpdf',
  # Even though the rbenv cookbooks looks nice, they don't work as I'd like.
  # fnichol's supports local install, but insists on templating
  # /etc/profile.d/rbenv.sh *even when doing a local install*. That makes no
  # sense. I don't want that.
  #
  # The RiotGames rbenv cookbook only supports global install.
  #
  # So let's just install through trusty Homebrew.
  #
  # We now also install pyenv through Homebrew, so it's nice to be consistent.
  'rbenv',
  # rbenv plugins
  # For the reason this was chosen over alternatives, see
  # https://github.com/maljub01/rbenv-bundle-exec#similar-plugins
  'rbenv-bundle-exec',
  'rbenv-communal-gems',
  'rbenv-default-gems',
  # reattach-to-user-namespace has options to fix launchctl and shim
  # pbcopy/pbaste. We haven't needed them yet, though.
  'reattach-to-user-namespace',
  'renameutils',
  'ruby-build',
  'ssh-copy-id',
  # Primarily for Sphinx
  'texinfo',
  'thefuck',
  'the_silver_searcher',
  'tmux',
  'tree',
  'valgrind',
  'watch',
  'wget',
  'xz',
  # For downloading videos/audio. ffmpeg is for post-processing; we chose it
  # over libav based on http://blog.pkh.me/p/13-the-ffmpeg-libav-situation.html
  # However, youtube-dl seems to prefer avconv (libav) over ffmpeg, so we may
  # change this at a later time.
  'youtube-dl',
  'ffmpeg',
  # ZeroMQ (zmq) is included to speed up IPython installs. It can install a
  # bundled version to a virtualenv, but it's faster to have a globally built
  # version.
  'zmq',
  'zsh-syntax-highlighting',
  # XML utilities
  'html-xml-utils',
  'xml-coreutils',
  # Fun commands!
  'cmatrix',
  'cowsay',
  'figlet',
  'fortune',
  'ponysay',
  'sl',
  'toilet'
]

###############################################################################
# HOMEBREW CASKS (see http://caskroom.io/)
###############################################################################

default.homebrew.casks = [
  'adium',
  'adobe-reader',
  'atext',
  'caffeine',
  'cathode',
  'chicken',
  'cord',
  'crashplan',
  'dash',
  'deeper',
  'disk-inventory-x',
  # There are a number of different versions of Eclipse. The eclipse-ide cask,
  # described as 'Eclipse IDE for Eclipse Committers', is actually just the
  # standard package without any extras. This is nice, because extras can
  # always be installed using the Eclipse Marketplace.
  'eclipse-ide',
  'firefox',
  'flash',
  'flash-player',
  'flux',
  'gfxcardstatus',
  'gimp',
  'google-chrome',
  # This is 'GoogleVoiceAndVideoSetup', which installs the browser plugins.
  'google-hangouts',
  'iterm2-beta',
  # Java
  #
  # I wish we could avoid installing Java, but I need it for at least these
  # reasons:
  #
  # - Network Connect, GVSU's SSL VPN
  # - Playing TankPit, a Java applet-based game
  # - Eclipse
  #
  # Apple Java 6 was installed, then uninstalled like so:
  #
  #     sudo rm -r /System/Library/Java/JavaVirtualMachines/1.6.0.jdk
  #     sudo pkgutil --forget com.apple.pkg.JavaForMacOSX107
  #
  # See here for the procedure followed: http://superuser.com/a/712783
  #
  # Oracle Java 7 JDK was installed, then uninstalled with:
  #
  #     sudo rm -r /Library/Java/JavaVirtualMachines/jdk1.7.0_60.jdk
  #
  # See here:
  # JDK: http://docs.oracle.com/javase/7/docs/webnotes/install/mac/mac-jdk.html#uninstall
  # JRE: https://www.java.com/en/download/help/mac_uninstall_java.xml
  'java',
  'jettison',
  'karabiner',
  'lastpass', # NOTE: Requires manual intervention
  'libreoffice',
  # This is a maintained fork of the original Slate:
  # https://github.com/mattr-/slate
  'mattr-slate',
  # This cask already applies the fix as shown here:
  # https://github.com/osxfuse/osxfuse/wiki/SSHFS#macfusion
  'macfusion',
  'openemu',
  'osxfuse',
  # Pandoc also has Homebrew formula. There isn't a particular reason to pick
  # one over the other.
  'pandoc',
  'quicksilver',
  'skim',
  'skitch',
  'skyfonts',
  'skype',
  # Recommended by Lifehacker
  # http://lifehacker.com/the-best-antivirus-app-for-mac-488021445
  'speedcrunch',
  'spotify',
  # SQLite browser options:
  #
  # - sqlitebrowser: open-source, cross-platform, well-maintained
  # - sqliteman: looks unmaintained, questionable OS support
  # - mesasqlite: OS X-only, looks unmaintained
  # - sqlprosqlite: OS X-only, proprietary
  # - sqlitestudio: open-source, cross-platform, well-maintained
  # - navicat-for-sqlite: cross-platform, proprietary
  #
  # Also available is SQLite Manager, which is a high-quality Firefox add-on.
  # <https://addons.mozilla.org/en-US/firefox/addon/sqlite-manager/>
  #
  # We've tried DB Browser for SQLite (sqlitebrowser), SQLite Studio
  # (sqlitestudio), and SQLite Manager for Firefox. All are excellent. The
  # first two are written in Qt and look great on OS X. DB Browser and SQLite
  # manager both have options for CSV and SQL export, while SQLite Studio has
  # those in addition to HTML, JSON, PDF, and XML. However, we've decided to go
  # for DB Browser for SQLite because it has an intuitive interface and has
  # packages for both Homebrew and Chocolatey. For Homebrew, both a formula and
  # a cask are available. We've decided to go for the cask to avoid having to
  # build (although it's bottled anyway).
  'sqlitebrowser',
  'sshfs',
  'vagrant',
  'virtualbox',
  'wireshark'
]

###############################################################################
# PREFERENCES
###############################################################################

lastpass_cmd_shift_key = '1179914'
default.mac_os_x.settings = {
  # Apple Apps
  # Set up clock with day of week, date, and 24-hour clock.
  clock: {
    domain: 'com.apple.menuextra.clock',
    DateFormat: 'EEE MMM d  H:mm',
    FlashDateSeparators: false,
    IsAnalog: false
  },
  # Start the character viewer in docked mode. The large window mode doesn't
  # take focus automatically, and can't AFAIK be focused with any keyboard
  # shortcut, rendering it less useful for those who like to stay on the
  # keyboard. The docked mode puts the cursor right in the search field, which
  # is perfect for keyboard users like myself.
  character_viewer: {
    domain: 'com.apple.CharacterPaletteIM',
    CVStartAsLargeWindow: false
  },
  messages: {
    domain: 'com.apple.iChat',
    AddressMeInGroupchat: true, # Notify me when my name is mentioned
    SaveConversationsOnClose: true # Save history when conversations are closed
  },
  # Third-party apps
  atext: {
    domain: 'com.trankynam.aText',
    # Most of aText's settings are [presumably] stored in a giant data blob.
    # XXX These settings are dubiously applied.
    PlayFeedbackSound: false,
    ShowDockIcon: false
  },
  caffeine: {
    domain: 'com.lightheadsw.caffeine',
    ActivateOnLaunch: true, # Turn on Caffeine when the app is started.
    DefaultDuration: 0, # Activate indefinitely
    SuppressLaunchMessage: true
  },
  cathode: {
    domain: 'com.secretgeometry.Cathode',
    # Console and Monitor themes themselves seem not to be stored in
    # preferences.
    CloseOnExit: false,
    JitterWhenWindowMoves: true,
    PositionalPerspective: true,
    RenderingQuality: 3, # High
    UseColorPalette: true,
    UseOptionAsMeta: true,
    UseSounds: false
  },
  deeper: {
    domain: 'com.titanium.Deeper',
    ConfirmQuit: false,
    ConfirmQuitApp: true,
    DeleteLog: true,
    DrawerEffect: true,
    Licence: false, # Don't show the license at startup
    OpenLog: false,
    ShowHelp: false
  },
  gfxcardstatus: {
    domain: 'com.codykrieger.gfxCardStatus-Preferences',
    shouldCheckForUpdatesOnStartup: true,
    shouldUseSmartMenuBarIcons: true
    # Note: shouldStartAtLogin doesn't actually work, because gfxCardStatus uses
    # login items like most other applications. So don't bother setting it.
  },
  iterm2: {
    :domain => 'com.googlecode.iterm2',
    :'Default Bookmark Guid' => node.osx_setup.iterm2.default_profile_guid,
    # General
    ## Closing
    :QuitWhenAllWindowsClosed => false,
    :PromptOnQuit => true,
    ## Services
    :SUEnableAutomaticChecks => true,
    :CheckTestRelease => true,
    ## Window
    :AdjustWindowForFontSizeChange => true,
    :UseLionStyleFullscreen => true,
    # Appearance
    ## Tabs
    :TabViewType => 0, # Tab bar on top
    :TabStyle => 0, # Light tab theme
    :HideTabNumber => false,
    :HideTabCloseButton => true,
    :HideActivityIndicator => false,
    ## Window & Tab Titles
    :WindowNumber => true,
    :JobName => true,
    :ShowBookmarkName => true,
    ## Window
    :UseBorder => false,
    :HideScrollbar => true,
    # Keys
    :Hotkey => true,
    :HotkeyChar => 59,
    :HotkeyCode => 41,
    :HotkeyModifiers => 1_048_840
  },
  jettison: {
    domain: 'com.stclairsoft.Jettison',
    autoEjectAtLogout: false,
    # This really means autoEjectAtSleep.
    autoEjectEnabled: true,
    ejectDiskImages: true,
    ejectHardDisks: true,
    ejectNetworkDisks: true,
    ejectOpticalDisks: false,
    ejectSDCards: false,
    hideMenuBarIcon: false,
    moveToApplicationsFolderAlertSuppress: true,
    playSoundOnFailure: false,
    playSoundOnSuccess: false,
    showRemountProgress: false,
    statusItemEnabled: true,
    toggleMassStorageDriver: false
  },
  lastpass: {
    domain: 'com.lastpass.LastPass',
    # Some preferences are prefixed by a hash, which seems to be stored in
    # 'lp_local_pwhash'. We don't know what that hash means, or whether it's
    # consistent, so just leave those alone.
    global_StartOnLogin: '1',
    # Cmd-Shift-L
    global_SearchHotKeyMod: lastpass_cmd_shift_key,
    global_SearchHotKeyVK: '37',
    # Cmd-Shift-V
    global_VaultHotKeyMod: lastpass_cmd_shift_key,
    global_VaultHotKeyVK: '9'
  },
  tasks_explorer: {
    domain: 'com.macosinternals.Tasks-Explorer',
    highlight_processes: true,
    show_kernel_cpu_time: true,
    update_frequency: 2 # seconds
  },
  xquartz: {
    domain: 'org.macosforge.xquartz.X11',
    # Input
    enable_fake_buttons: false,
    sync_keymap: false,
    enable_key_equivalents: true,
    option_sends_alt: true,
    # Output
    # XXX The idempotency check for this is not working because grep is
    # interpreting it as an option.
    # See https://github.com/chef-osx/mac_os_x/blob/9a63d0a14a3574d32c4adb91377c719d7b533835/providers/userdefaults.rb#L35
    depth: '-1', # use colors from display
    rootless: true,
    fullscreen_menu: true,
    # Pasteboard
    ## Syncing is somewhat broken, see here:
    ## <http://xquartz.macosforge.org/trac/ticket/765>
    ## If you go into XQuartz and press Cmd-C it will usually sync it.
    sync_pasteboard: true,
    sync_clipboard_to_pasteboard: true,
    sync_pasteboard_to_clipboard: true,
    sync_pasteboard_to_primary: true,
    sync_primary_on_select: false,
    # Windows
    wm_click_through: false,
    wm_ffm: false,
    wm_focus_on_new_window: true,
    # Security
    no_auth: false,
    nolisten_tcp: true,
    # Other
    # XXX seems to do nothing, xterm still starts /bin/sh
    # login_shell: '/path/to/zsh'
  },
  # Tweaks from
  # https://github.com/kevinSuttle/OSXDefaults/blob/master/.osx
  # https://github.com/mathiasbynens/dotfiles/blob/master/.osx

  # A note on settings: if the value is zero, set it as an integer 0 instead of
  # float 0.0. Otherwise, it will be "cast" to a float by the defaults system
  # and the resource will be updated every time. In addition, if the dock
  # settings are updated, the mac_os_x cookbook will `killall dock' every time.
  global: {
    :domain => 'NSGlobalDomain',
    # Always show scrollbars
    :AppleShowScrollBars => 'Always',
    # Allow keyboard access to all controls (using Tab), not just text boxes and
    # lists.
    #
    # Note: We used to use
    #
    #     include_recipe 'mac_os_x::kbaccess'
    #
    # which supposedly does the same thing, but its idempotence check was not
    # behaving properly. Moved it to here and it is working fine.
    :AppleKeyboardUIMode => 2,
    # Increase window resize speed for Cocoa applications
    :NSWindowResizeTime => 0.001,
    # Expand save panel by default
    :NSNavPanelExpandedStateForSaveMode => true,
    :NSNavPanelExpandedStateForSaveMode2 => true,
    # Expand print panel by default
    :PMPrintingExpandedStateForPrint => true,
    :PMPrintingExpandedStateForPrint2 => true,
    # Save to disk (not to iCloud) by default
    :NSDocumentSaveNewDocumentsToCloud => false,
    # Disable natural (Lion-style) scrolling
    :'com.apple.swipescrolldirection' => false,
    # Display ASCII control characters using caret notation in standard text
    # views
    # Try e.g. `cd /tmp; echo -e '\x00' > cc.txt; open -e cc.txt`
    :NSTextShowsControlCharacters => true,
    # Disable press-and-hold for keys in favor of key repeat
    :ApplePressAndHoldEnabled => false,
    # Key repeat
    # This is also possible through the mac_os_x::key_repeat recipe, but having
    # it here allows customization of the values.
    ## Set a keyboard repeat rate to fast
    :KeyRepeat => 2,
    ## Set low initial delay
    :InitialKeyRepeat => 15,
    # Finder
    ## Show all filename extensions
    :AppleShowAllExtensions => true,
    ## Enable spring loading for directories
    :'com.apple.springing.enabled' => true,
    # Remove the spring loading delay for directories
    :'com.apple.springing.delay' => 0
  },
  # Automatically quit printer app once the print jobs complete
  print: {
    :domain => 'com.apple.print.PrintingPrefs',
    :'Quit When Finished' => true
  },
  # Set Help Viewer windows to non-floating mode
  helpviewer: {
    domain: 'com.apple.helpviewer',
    DevMode: true
  },
  # Reveal IP address, hostname, OS version, etc. when clicking the clock in the
  # login window
  loginwindow: {
    domain: '/Library/Preferences/com.apple.loginwindow',
    AdminHostInfo: 'HostName'
  },
  # More Finder tweaks
  # Note: Quitting Finder will also hide desktop icons.
  finder: {
    domain: 'com.apple.finder',
    # Allow quitting via Command-Q
    QuitMenuItem: true,
    # Disable window animations and Get Info animations
    DisableAllAnimations: true,
    # Don't show hidden files by default -- this shows hidden files on the
    # desktop, which is just kind of annoying. I've haven't really seen other
    # benefits, since I don't use Finder much.
    AppleShowAllFiles: false,
    # Show status bar
    ShowStatusBar: true,
    # Show path bar
    ShowPathbar: true,
    # Allow text selection in Quick Look
    QLEnableTextSelection: true,
    # Display full POSIX path as Finder window title
    _FXShowPosixPathInTitle: true,
    # When performing a search, search the current folder by default
    FXDefaultSearchScope: 'SCcf',
    # Disable the warning when changing a file extension
    FXEnableExtensionChangeWarning: false,
    # Use list view in all Finder windows by default
    # Four-letter codes for the other view modes: `icnv`, `clmv`, `Flwv`
    FXPreferredViewStyle: 'Nlsv'
  },
  # Avoid creating .DS_Store files on network
  desktopservices: {
    domain: 'com.apple.desktopservices',
    DSDontWriteNetworkStores: true
  },
  networkbrowser: {
    domain: 'com.apple.NetworkBrowser',
    # Enable AirDrop over Ethernet and on unsupported Macs running Lion
    BrowseAllInterfaces: true
  },
  dock: {
    :domain => 'com.apple.dock',
    # Remove the auto-hiding Dock delay
    :'autohide-delay' => 0,
    # Remove the animation when hiding/showing the Dock
    :'autohide-time-modifier' => 0,
    # Automatically hide and show the Dock
    :autohide => true,
    # Make Dock icons of hidden applications translucent
    :showhidden => true
  },
  timemachine: {
    domain: 'com.apple.TimeMachine',
    # Prevent Time Machine from prompting to use new hard drives as backup
    # volume
    DoNotOfferNewDisksForBackup: true
  },
  textedit: {
    # Use plain text mode for new TextEdit documents
    domain: 'com.apple.TextEdit',
    RichText: 0,
    # Open and save files as UTF-8 in TextEdit
    PlainTextEncoding: 4,
    PlainTextEncodingForWrite: 4
  },
  diskutil: {
    :domain => 'com.apple.DiskUtility',
    # Enable the debug menu in Disk Utility
    :DUDebugMenuEnabled => true,
    # enable the advanced image menu in Disk Utility
    :'advanced-image-options' => true
  },
  universalaccess: {
    domain: 'com.apple.universalaccess',
    # All closeView keys control the screen zoom.
    ## 'Zoom style' choices:
    ##
    ##     0. Fullscreen
    ##     1. Picture-in-picture
    ##
    ## Don't set this. Fullscreen is the default anyway, and this way we can
    ## let the user change based upon needs at that point. We have fullscreen
    ## and PIP settings later as well.
    # closeViewZoomMode: 0,
    closeViewHotkeysEnabled: false,
    ## Use scroll gesture with modifier keys to zoom.
    closeViewScrollWheelToggle: true,
    ## Use Ctrl as the modifier key (the number is a key code or something).
    ## This seems not to work correctly (?).
    # closeViewScrollWheelModifiersInt: 262_144,
    closeViewSmoothImages: true,
    ## Don't follow *keyboard* focus.
    closeViewZoomFollowsFocus: false,
    ## Fullscreen zoom settings
    ### Choices: When zoomed in, the screen image moves:
    ###
    ###     0. Continuously with pointer
    ###     1. Only when the pointer reaches an edge
    ###     2. So the pointer is at or near the center of the screen
    closeViewPanningMode: 1,
    ## Picture-in-picture settings
    ### Use system cursor in zoom.
    closeViewCursorType: 0,
    ### Enable temporary zoom (with Ctrl-Cmd)
    closeViewPressOnReleaseOff: true,
    ### Choices:
    ###
    ###     1. Stationary
    ###     2. Follow mouse cursor
    ###     3. Tiled along edge
    closeViewWindowMode: 1
  }
}
