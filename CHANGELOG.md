# v0.1
* initial release

# v0.2
* added score
* added next block
* attempt to randomize entry points for pieces
* reduced height to 19 blocks

# v0.3
* added visual candy to score
* added support for left and right triggers
* added double down function
* can now restart the game
* added difficulity increase over time

# v0.4
* added support for highscore
* fixed similar color for two pieces
* fixed line_count not resetting after a game_over
* show battery indicator
* sticky direction are now working
 
# v0.5
* fixed issue when game over the vscore was stuck below the reall score
* fixed a bug where user input (left & right) in subsequent game would not be taken
* sprite power icon
* reworked interface
* added level guide
* added buttons as help

# v0.6
* added sound
* added simple animation
* moved increase_speed()
* cleaned up globals
* removed code for version polling

# v0.6.1
* upstream sound fix
* decreased the amount of increase_speed calls
* changed startup img

# v0.7
* added a menu
* added credits screen
* added help screen
* full interface is now touch enabled
* made icon0.png white background (transparant does not work)
* 'redesigned' game interface
* fixed level indication
* fixed score.visual
* switched to a better random seed for blocks
* fixed a score bug, multi lines now count as intended
* added a statistic overview after a game
* added a touch button to restart/exit game
* new background
* changed field size with to 9
* game over now slightly animated
* added animation to level up :)

# v0.8
* added a top 5 highscore on a separate page
* added a function to add a username to a highscore for multiuser
* cleaned up the game over screen
* every level the background changes
* added hold option, based on the implementation of Aurora
* redone interface for classic to accomodate the hold option and stats
* changed the layout of the stats in classic game over screen
* changed line remove animation, its now color based on amount of lines
* added a new font Retroscape
* added a new font Space Meatball
* dropped unfinished color match mode, to complex

# v0.9
* added a loading screen (cause what is a game w/o one?)
* added a slight delay before we pop up the keyboard after a game over
* added pauze option (start button during game)
* added support for a different sound for every amount of lines (single, dubbel, triple, tetra)
* increased score.visual tick if large difference between reall and visible score
* documented the scoring matrix
* in higher levels both single and multi lines give more points
* using double down, increases the points slightly for dropping a block
