# Job Icons

Place your job icon images in this folder.

## Requirements
- **Format**: PNG
- **Recommended Size**: 128x128 pixels
- **Transparent Background**: Recommended

## Default Icons Needed

Based on the default configuration, you'll need:
- `logo.png` - Main logo for job center
- `sheriff.png` - Sheriff job icon
- `doctor.png` - Doctor job icon
- `miner.png` - Miner job icon

## Adding Custom Job Icons

1. Create or download your icon image (PNG format)
2. Name it according to your job (e.g., `blacksmith.png`)
3. Place it in this folder
4. Reference it in `html/configNui.js`:
```javascript
{
    "title": "Blacksmith",
    // ...
    "iconName": "blacksmith.png",
    // ...
}
```

## Icon Sources

You can find free icons at:
- [FlatIcon](https://www.flaticon.com/)
- [IconFinder](https://www.iconfinder.com/)
- [Game-Icons.net](https://game-icons.net/)

Make sure to check licensing requirements for any icons you use.

