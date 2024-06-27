# Godot Rollback Fighter Demo
### Built on [Bimdav's Delta Rollback Addon](https://gitlab.com/BimDav/delta-rollback/)
### Built using [David Snopek's SG Physics 2D Addon](https://gitlab.com/snopek-games/sg-physics-2d)
### [Original Godot Rollback Netcode Addon by David Snopek](https://gitlab.com/snopek-games/godot-rollback-netcode)
![Example clip](https://raw.githubusercontent.com/blast-harbour/Godot-Rollback-Fighter-Demo/main/ExampleClip.gif)
## Overview
This project was made both as a resource to provide example implementations of many common fighting game features as well as using SG Physics 2D, a deterministic physics engine designed with rollback netcode in mind, with the Godot Rollback Addon using Godot 4.2.2. Bimdav's "Delta Rollback" is a fork of the original Godot Rollback Netcode addon by David Snopek which ports all of the core functionality to C++ as a GDExtension which gives much better performance! It is generally used in the same way as the original addon so if you want to get started you can follow along [Snopek's absolutely excellent tutorial series!](https://www.youtube.com/watch?v=zvqQPbT8rAE&list=PLCBLMvLIundBXwTa6gwlOUNc29_9btoir) While his tutorial is a great resource, there will be differences in syntax since it was made for Godot 3. I recommend looking through my project and BimDav's example project for getting the addon running within Godot 4.

## Features
- A "FightManager" node which manages the order methods are called on all gameplay-related nodes
- A simple node-based state machine implementation
- An input system with a command buffer to interpret motion inputs such as quarter circles (executed as down, downforward, forward)
- Fighter push interactions
- Fighter hurtbox/hitbox system where hitboxes are assigned behaviors to decide what to do on block, on hit, or on air hit
- High/low blocking
- Projectiles
- Health bars and round restarting once a player is KO'd

All fully functional with rollback netcode, the gold standard solution for fighting game netplay!!!!
