# mpackages:
test_prog
------------------------------------
test_prog

# mmodules:
careers character combat game game_examples platform races rpg test_game test_prog
------------------------------------
careers character combat game game_examples platform races rpg test_game test_prog

# mclasses:
Alcoholic Bool Career Character Combatable Dwarf Elf Float Game Human Int List Magician Object Race Starter String Sys Warrior Weapon
------------------------------------
Alcoholic Bool Career Character Combatable Dwarf Elf Float Game Human Int List Magician Object Race Starter String Sys Warrior Weapon

# mproperties:
!= * * + + - - / / == > > OTHER _age _base_endurance _base_intelligence _base_strength _career _endurance_bonus _health _intelligence_bonus _name _race _sex _strength_bonus age age= attack base_endurance base_endurance= base_intelligence base_intelligence= base_strength base_strength= career career= computer_characters defend direct_attack dps endurance_bonus endurance_bonus= health health= hit_points init intelligence_bonus intelligence_bonus= is_dead main max_health name name= pause_game player_characters quit race race= sex sex= start start_game stop_game strength_bonus strength_bonus= to_f total_endurance total_intelligence total_strengh unary -
------------------------------------
!= * * + + - - / / == > > OTHER _age _base_endurance _base_intelligence _base_strength _career _endurance_bonus _health _intelligence_bonus _name _race _sex _strength_bonus age age= attack base_endurance base_endurance= base_intelligence base_intelligence= base_strength base_strength= career career= computer_characters defend direct_attack dps endurance_bonus endurance_bonus= health health= hit_points init intelligence_bonus intelligence_bonus= is_dead main max_health name name= pause_game player_characters quit race race= sex sex= start start_game stop_game strength_bonus strength_bonus= to_f total_endurance total_intelligence total_strengh unary -

# msignatures:
!=(other: OTHER): Bool
*(f: Float): Float
*(i: Int): Int
+(f: Float): Float
+(i: Int): Int
-(i: Int): Int
-(f: Float): Float
/(f: Float): Float
/(i: Int): Int
==(other: OTHER): Bool
>(f: Float): Bool
>(i: Int): Bool
age: Int
age=(age: Int)
attack(target: Combatable, weapon: Weapon): Int
base_endurance: Int
base_endurance=(base_endurance: Int)
base_intelligence: Int
base_intelligence=(base_intelligence: Int)
base_strength: Int
base_strength=(base_strength: Int)
career: nullable Career
career=(career: nullable Career)
computer_characters: List[Character]
defend(hit: Int): Int
direct_attack(target: Combatable, weapon: Weapon): Int
dps: Float
endurance_bonus: Int
endurance_bonus=(endurance_bonus: Int)
health: Int
health=(health: Int)
hit_points: Int
init
intelligence_bonus: Int
intelligence_bonus=(intelligence_bonus: Int)
is_dead: Bool
main
max_health: Int
name: String
name=(name: String)
pause_game
player_characters: List[Character]
quit
race: Race
race=(race: Race)
sex: Bool
sex=(sex: Bool)
start
start_game
stop_game
strength_bonus: Int
strength_bonus=(strength_bonus: Int)
to_f: Float
total_endurance: Int
total_intelligence: Int
total_strengh: Int
unary -: Int
------------------------------------
!=(other: OTHER): Bool
*(f: Float): Float
*(i: Int): Int
+(f: Float): Float
+(i: Int): Int
-(i: Int): Int
-(f: Float): Float
/(f: Float): Float
/(i: Int): Int
==(other: OTHER): Bool
>(f: Float): Bool
>(i: Int): Bool
age: Int
age=(age: Int)
attack(target: Combatable, weapon: Weapon): Int
base_endurance: Int
base_endurance=(base_endurance: Int)
base_intelligence: Int
base_intelligence=(base_intelligence: Int)
base_strength: Int
base_strength=(base_strength: Int)
career: nullable Career
career=(career: nullable Career)
computer_characters: List[Character]
defend(hit: Int): Int
direct_attack(target: Combatable, weapon: Weapon): Int
dps: Float
endurance_bonus: Int
endurance_bonus=(endurance_bonus: Int)
health: Int
health=(health: Int)
hit_points: Int
init
intelligence_bonus: Int
intelligence_bonus=(intelligence_bonus: Int)
is_dead: Bool
main
max_health: Int
name: String
name=(name: String)
pause_game
player_characters: List[Character]
quit
race: Race
race=(race: Race)
sex: Bool
sex=(sex: Bool)
start
start_game
stop_game
strength_bonus: Int
strength_bonus=(strength_bonus: Int)
to_f: Float
total_endurance: Int
total_intelligence: Int
total_strengh: Int
unary -: Int
