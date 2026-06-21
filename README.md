# bf-bloodeffect v1.0.0

![bf-bloodeffect Preview](html/images/blood.png)

Realistic blood splatter screen effect for **FiveM / QBCore** servers.

## Features
- Damage-intensity scaling (opacity, size, blob count)
- Melee hit detection
- Fall damage detection with configurable height threshold
- Per-weapon damage multipliers
- Dev test command: `/testblood [intensity]`


## Structure
```
bf-bloodeffect/
│
├── client.lua
│   
│
├── html/
│   ├── index.html
│   ├── style.css
│   └── script.js
│
├── fxmanifest.lua
└── README.md
```

## Installation
1. Drop the `bf-bloodeffect` folder into your server `resources/` directory.
2. Add `ensure bf-bloodeffect` to your `server.cfg`.
3. Adjust config You will find it inside file `client.lua` to your server's needs.

***
created by ❤️ with dakhchich 
