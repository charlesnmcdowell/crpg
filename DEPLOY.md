# Deploy CRPG Demo to GitHub Pages (iPhone-Ready)

Target URL: **https://charlesnmcdowell.github.io/crpg/**

---

## Step 1: Install Godot Web Export Templates

1. Open **Godot 4.2** on Windows
2. Go to **Editor → Manage Export Templates**
3. Click **Download and Install** (or **Install from File** if you downloaded them)
4. Wait for download to complete — you need the **Web** template

## Step 2: Open the Project

1. Open Godot → **Import**
2. Navigate to the `godot-crpg-demo` folder → select `project.godot`
3. Click **Import & Edit**

## Step 3: Configure Web Export

The `export_presets.cfg` is already configured, but verify:

1. Go to **Project → Export**
2. You should see a **"Web"** preset already listed
3. If not, click **Add → Web**
4. Set these settings:
   - **Export Path:** `docs/index.html`
   - **VRAM Texture Compression:** check both Desktop + Mobile
   - **HTML → Canvas Resize Policy:** `Adaptive`
   - **HTML → Focus Canvas on Start:** ✅
   - **HTML → Experimental Virtual Keyboard:** ✅
   - **Progressive Web App → Enabled:** ✅
   - **PWA → Display:** `Standalone`
   - **PWA → Orientation:** `Portrait`

## Step 4: Export the Build

1. In the Export dialog, click **Export Project...**
2. Navigate to the `docs/` folder inside your project
3. Filename: `index.html`
4. **Uncheck** "Export With Debug" for smaller file size
5. Click **Save**

This generates these files in `docs/`:
- `index.html`
- `index.js`
- `index.wasm`
- `index.pck`
- `index.audio.worklet.js`
- `index.icon.png`
- `index.apple-touch-icon.png`
- `index.offline.html`
- `index.service-worker.js`
- `index.manifest.json`

## Step 5: Fix Base Path for GitHub Pages Subpath

**IMPORTANT:** GitHub Pages serves from `https://charlesnmcdowell.github.io/crpg/` — a subpath, not root.

After exporting, open `docs/index.html` in a text editor and find:

```html
<script src="index.js"></script>
```

Make sure all paths are **relative** (no leading `/`). Godot 4.2 should do this by default, but verify:
- ✅ `src="index.js"` (relative — good)
- ❌ `src="/index.js"` (absolute — bad, won't work on subpath)

If `index.manifest.json` has absolute paths, fix them too:
- Change `/index.html` → `index.html`
- Change `/index.offline.html` → `index.offline.html`

## Step 6: Push to GitHub

Open a terminal (PowerShell or Git Bash) in the project folder:

```bash
# Navigate to project folder
cd path\to\godot-crpg-demo

# Initialize git (if not already)
git init

# Add the remote
git remote add origin https://github.com/charlesnmcdowell/crpg.git

# Add all files
git add .

# Commit
git commit -m "CRPG Demo - initial deploy with HTML5 web export"

# Push (create main branch)
git branch -M main
git push -u origin main
```

If the repo already has commits:
```bash
git pull origin main --allow-unrelated-histories
git push -u origin main
```

## Step 7: Enable GitHub Pages

1. Go to **https://github.com/charlesnmcdowell/crpg**
2. Click **Settings** → **Pages** (left sidebar)
3. Under "Build and deployment":
   - **Source:** Deploy from a branch
   - **Branch:** `main`
   - **Folder:** `/docs`
4. Click **Save**
5. Wait 1-2 minutes for deployment

## Step 8: Verify + iPhone Setup

### Verify on Desktop:
1. Open: **https://charlesnmcdowell.github.io/crpg/**
2. You should see the title screen
3. If blank, check browser console (F12) for path errors

### iPhone (Add to Home Screen):
1. Open **Safari** on iPhone
2. Go to: `https://charlesnmcdowell.github.io/crpg/`
3. Tap the **Share** button (box with arrow)
4. Scroll down → tap **"Add to Home Screen"**
5. Name it "CRPG Demo" → tap **Add**
6. Launch from home screen — runs fullscreen like a native app!

---

## Troubleshooting

### Blank screen / nothing loads
- **Check paths:** Open browser console (F12 → Console). Look for 404 errors on `.wasm`, `.pck`, or `.js` files
- **Fix:** Ensure all paths in `index.html` are relative (no leading `/`)
- **Verify** the `docs/` folder contains all exported files

### WASM/PCK not loading (MIME type errors)
- GitHub Pages handles `.wasm` correctly by default
- If you see MIME errors, add a `.nojekyll` file in `docs/`:
  ```bash
  echo "" > docs/.nojekyll
  ```
  This tells GitHub Pages not to process files through Jekyll

### Game loads but controls don't work on iPhone
- Make sure **Experimental Virtual Keyboard** is enabled in export
- Touch input should work — the project has `emulate_touch_from_mouse` enabled
- If stuck, try rotating to landscape and back

### Cache issues (old version showing)
- **Hard refresh:** Ctrl+Shift+R (desktop) or clear Safari cache (iPhone)
- **Service worker:** If PWA is cached, go to browser DevTools → Application → Service Workers → Unregister
- **iPhone:** Settings → Safari → Clear History and Website Data

### Deployment not updating
- Check GitHub Actions tab for deployment status
- Make sure you pushed to `main` branch
- Verify Pages is set to `main` / `/docs`
- Wait 2-5 minutes — Pages can be slow

### Screen too small / UI cut off on iPhone
- The project uses `canvas_items` stretch mode which should scale
- If needed, adjust in Godot: Project → Project Settings → Display → Window → Stretch
