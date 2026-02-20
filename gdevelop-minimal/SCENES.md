# Scenes and Objects

Start scene:
- Background: scene color #0D0D14
- TitleText (Text): "CRPG DEMO", size 56, centered
- NewGameText (Text): "New Game", size 36, centered under TitleText
- VersionText (Text): "v0.1-minimal", size 14, bottom-right

Events:
- On Mouse released OR touch end AND cursor on NewGameText -> Change scene to "Inn"

Inn scene:
- Floor (Sprite scaled from 1x1 color or TiledSprite): brown #5A4736, cover window
- Walls (4 Sprites 1x1 scaled): gray #80838C, 24px borders
- Bedroom (Sprite rect): #40352B at (72,72) size (240x160)
- CommonRoom (Sprite rect): #4C3E31 at (360,120) size (560x360)
- WarriorBody (Sprite colored rect): #2F80FF size (24x48) at (160,140)
- WarriorLabel (Text): "Warrior" above body

Inn Events:
- At the beginning of scene -> Center camera to (512,320)
