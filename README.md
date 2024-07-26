`Godot 4.3`

[test the template here !](https://aexll.github.io/platformer/platformer.html)



# Functionalities

### Jump Buffering
Allows the player to register a jump input slightly before landing, so the character jumps as soon as they hit the ground.

### Coyote Delayed Jump
Permits the player to jump shortly after walking off a platform, making jumps feel more forgiving.

### Variable Jump Height
Lets the player control the jump height based on how long the jump button is held, allowing for precise jumps.

*this is acomplished by multiplying the gravity by a factor when releasing the jump button, until the jump apex is reached (y velocity < 0)*

### Jump Apex Modifier
Adjusts character behavior (like gravity or speed) at the peak of the jump to make the arc feel smoother.

### Wall Jump
Enables the player to jump off walls, providing more movement options and adding verticality to the gameplay.

### Wall Slide
Allows the player to slide down walls at a controlled speed, preventing immediate falls and enabling strategic descents.

### Ground Check Smoothing
Adds a tolerance for detecting ground contact to avoid jittery movements when the player is near the ground.

### Fallspeed Clamping
Limits the maximum falling speed of the character to prevent them from accelerating indefinitely during a fall. This ensures a consistent and controllable fall rate.

### Airdrag
Reduces the character's horizontal speed gradually while they are in the air, simulating air resistance and making mid-air movement feel more controlled.

# TODO list

### Sounds and particles effects for better feedbacks


This code is running in Godot 4.3 to make use of the physics_interpolation for a smooth result,
Note that Godot 4.2 has plugins to achieve the same result
the code should be valid for 4.2, maybe some functions name have been changed

This template is using the coi_serviceworker plugin only to build the project on the web (https://aexll.github.io/platformer/platformer.html) and is not mandatory

